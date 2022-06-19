#!/usr/bin/env python3

import argparse
import datetime
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tarfile

from collections import defaultdict


###############################################################################
# K8s helpers


def namespace_arg(namespace):
	if namespace:
		return "--namespace " + namespace
	return "--all-namespaces"


def _kubectl(a, stdout=subprocess.PIPE):
	"""
	:param a: arguments string (without preceding "kubectl")
	:return: stdout as bytes
	"""
	cmd = "kubectl " + a
	logging.debug(cmd)
	completed = subprocess.run(cmd, shell=True, stdout=stdout, stderr=subprocess.PIPE)
	if completed.returncode != 0:
		print("Command returned non-0 ({}): {}".format(completed.returncode, cmd), file=sys.stderr)
		for line in completed.stderr.decode("utf-8", errors="ignore").splitlines():
			logging.warning("stderr: {}".format(line))
	return completed


def kubectl(a):
	return _kubectl(a).stdout


def kubectl_write(a, writer=sys.stdout):
	_kubectl(a, stdout=writer)


def pod_grep(name_pattern, namespace=None):
	"""
	:param name_pattern: full or partial name of a Pod
	:param namespace: if set - use only given namespace
	:return: list of Pod in parsed JSON (i.e. dict) format
	"""
	pods_json = kubectl("get pods {} --output json".format(namespace_arg(namespace)))
	pods = json.loads(pods_json)

	found = []
	for pod in pods["items"]:
		pattern = r".*" + name_pattern + r".*"
		if re.match(pattern, pod["metadata"]["name"]):
			found.append(pod)

	return found


def get_resources_batch(resources, wide=True, namespace=""):
	if not resources:
		print("Nothing found")
		return

	# We batch all resources into 1 kubectl call for efficiency
	found = kubectl("get {} {} {}".format(",".join(resources), "-o wide" if wide else "", namespace_arg(namespace)))

	# resource -> ["NAME ... ", "resource/name ..."]
	lines_by_resource = defaultdict(list)

	title_line = ""
	for line in found.decode("utf-8", errors="ignore").splitlines():
		if not line:
			continue

		if line.startswith("NAME"):
			title_line = line
			continue

		# if len(resources) == 1, k8s does not prepend resource type to the name
		if len(resources) > 1:
			# NAMESPACE   NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE   VOLUMEMODE
			# zcenter     persistentvolumeclaim/data-postgres-postgresql-0   Bound    pvc-a8bf5064-f426-49fe-a1a5-ae0eb907c7f5   8Gi        RWO            csi-hostpath-sc   45h   Filesystem
			#
			# NAMESPACE   NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                STORAGECLASS      REASON   AGE   VOLUMEMODE
			#             persistentvolume/pvc-a8bf5064-f426-49fe-a1a5-ae0eb907c7f5   8Gi        RWO            Delete           Bound    zcenter/data-postgres-postgresql-0   csi-hostpath-sc            45h   Filesystem
			namespaced = title_line.startswith("NAMESPACE") and not line.startswith(" ")
			if namespaced:
				resource = line.split()[1].split("/")[0].strip()
			else:
				resource = line.split("/", maxsplit=1)[0].strip()
			lines_by_resource[resource].append(line)
		else:
			lines_by_resource[resources[0]].append(line)

	return lines_by_resource


###############################################################################
# GET


def k_get(resources, match_names=".*", namespace=None, directory=os.getcwd()):
	lines_by_resource = get_resources_batch(resources, wide=True, namespace=namespace)
	if not lines_by_resource:
		return
	for resource, lines in lines_by_resource.items():
		if not re.match(match_names, resource):
			continue
		filename = os.path.join(directory, resource + ".txt")
		with open(filename, "w") as f:
			f.write(resource + "\n")
			for line in lines:
				f.write(line + "\n")
			f.write("\n")


def k_get_all(match_names=".*", namespace=None, categories=None, directory=os.getcwd()):
	if not categories:
		categories = resource_categories

	output_dir = os.path.join(directory, "kubectl_get")
	os.makedirs(output_dir, exist_ok=True)

	for group, resources in categories.items():
		group_dir = os.path.join(output_dir, group)
		os.makedirs(group_dir, exist_ok=True)

		k_get(resources, match_names=match_names, namespace=namespace, directory=group_dir)


def k_get_all_crds(match_names=".*", match_kinds=".*", namespace=None, directory=os.getcwd()):
	crds_output = kubectl("get crds")
	cr_kinds = []
	for line in crds_output.decode("utf-8", errors="ignore").splitlines()[1:]:
		cr_kinds.append(line.split()[0])

	output_dir = os.path.join(directory, "kubectl_get", "custom-resources")
	os.makedirs(output_dir, exist_ok=True)

	k_get([cr for cr in cr_kinds if re.match(match_kinds, cr)], match_names=match_names, namespace=namespace, directory=output_dir)


###############################################################################
# DESCRIBE


# TODO: support match_names
def k_describe(resources, match_names=".*", namespace=None, directory=os.getcwd()):
	for resource in resources:
		filename = os.path.join(directory, resource + ".txt")
		# TODO: support namespace
		with open(filename, "w") as f:
			kubectl_write("describe {} {}".format(resource, namespace_arg(namespace)), f)
			f.write("\n")


# TODO: support match_names
def k_describe_all(match_names=".*", namespace=None, categories=None, directory=os.getcwd()):
	if not categories:
		categories = resource_categories

	output_dir = os.path.join(directory, "kubectl_describe")
	os.makedirs(output_dir, exist_ok=True)

	for category, resources in categories.items():
		category_dir = os.path.join(output_dir, category)
		os.makedirs(category_dir, exist_ok=True)

		k_describe(resources, namespace=namespace, directory=category_dir)


def k_describe_all_crds(match_names=".*", match_kinds=".*", namespace=None, directory=os.getcwd()):
	crds_output = kubectl("get crds")
	cr_kinds = []
	for line in crds_output.decode("utf-8", errors="ignore").splitlines()[1:]:
		cr_kinds.append(line.split()[0])

	output_dir = os.path.join(directory, "kubectl_describe", "custom-resources")
	os.makedirs(output_dir, exist_ok=True)

	k_describe([cr for cr in cr_kinds if re.match(match_kinds, cr)], namespace=namespace, directory=output_dir)


###############################################################################
# LOGS

def k_logs(match_names=".*", namespace=None, directory=os.getcwd()):
	logs_dir = os.path.join(directory, "logs")
	pods = pod_grep(match_names, namespace)
	for pod in pods:
		pod_name = pod["metadata"]["name"]
		pod_namespace = pod["metadata"]["namespace"]
		ns_logs_dir = os.path.join(logs_dir, pod_namespace)
		os.makedirs(ns_logs_dir, exist_ok=True)
		for container in pod["spec"]["containers"]:
			container_name = container["name"]
			with open(os.path.join(ns_logs_dir, "{}.{}.log".format(pod_name, container_name)), "w") as f:
				f.write("{}/{} {}\n".format(pod_namespace, pod_name, container_name))
				# Note: can't use namespace_arg here, as you cannot use --all-namespaces in logs
				ns_arg = "--namespace " + pod_namespace if pod_namespace else ""
				kubectl_write("logs {} --container {} {} ".format(ns_arg, container_name, pod_name), f)
				f.write("\n")


###############################################################################

# Resource categories are different from api groups,
# these are more logical grouping of resources, like in Lens or other k8s UI.
resource_categories = {
	"nodes": ["node"],
	"storage": ["storageclasses", "pvc", "pv"],
	"csi": [
		"csidrivers",
		"volumesnapshotclasses", "volumesnapshots", "volumesnapshotcontents",
		"volumeattachments.storage.k8s.io",
	],
	"workloads": [
		"deployments", "daemonsets", "statefulsets", "replicasets", "pods", "jobs", "cronjobs",
	],
	"networking": ["services"],
	"configuration": ["configmaps", "secrets"],
}

###############################################################################
# Main and helpers


def parse_args():
	parser = argparse.ArgumentParser(description="ZSnap-like tool [beta] for k8s applications. "
												 "Requires kubectl with access to the cluster. "
												 "Resulting files are placed in the current directory.")

	parser.add_argument("--prefix", help="prefix for the k8snap directory")
	parser.add_argument("--no-tar", action="store_true", help="do not create a tarball")

	return parser.parse_args()


if __name__ == "__main__":
	args = parse_args()

	logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s %(message)s")

	k8snap_dir_name = "k8snap-" + (args.prefix if args.prefix else "") + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
	k8snap_dir = os.path.join(os.getcwd(), k8snap_dir_name)
	logging.info("Creating k8snap directory: {}".format(k8snap_dir))
	os.makedirs(k8snap_dir, exist_ok=True)

	logging.info("Collect info from the cluster")
	k_get_all(directory=k8snap_dir)
	k_get_all_crds(match_kinds=".*zadara.*", directory=k8snap_dir)

	k_describe_all(directory=k8snap_dir)
	k_describe_all_crds(match_kinds=".*zadara.*", directory=k8snap_dir)

	k_logs(match_names=".*zadara.*", directory=k8snap_dir)

	if not args.no_tar:
		logging.info("Creating tarball")
		with tarfile.open(os.path.join(os.getcwd(), k8snap_dir_name + ".tar.gz"), "w:gz") as tar:
			tar.add(k8snap_dir, arcname=k8snap_dir_name)
		shutil.rmtree(k8snap_dir)

	logging.info("Done")
