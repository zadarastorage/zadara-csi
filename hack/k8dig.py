#!/usr/bin/env python3

import argparse
import json
import logging
import re
import subprocess

from collections import defaultdict


###############################################################################
# Print tools


class Color:
	BOLD = '\33[1m'
	ITALIC = '\33[3m'
	UNDERLINE = '\033[4m'

	BLACK = '\033[30m'
	GREY = '\33[90m'
	RED = '\033[31m'
	GREEN = '\033[32m'
	YELLOW = '\033[33m'
	BLUE = '\033[34m'
	MAGENTA = '\033[35m'
	CYAN = '\033[36m'
	WHITE = '\033[37m'

	RESET = '\033[0m'

	@staticmethod
	def wrap(s, color):
		return "{}{}{}".format(color, s, Color.RESET)

	@staticmethod
	def green(s):
		return Color.wrap(s, Color.GREEN)

	@staticmethod
	def red(s):
		return Color.wrap(s, Color.RED)


def log(s, indent=0, color=None, verbose=False):
	if verbose and not args.verbose:
		return

	if color:
		print("{}{}{}{}".format(" " * indent, color, s, Color.RESET))
	else:
		print("{}{}".format(" " * indent, s))


###############################################################################
# K8s helpers

class KNN:
	def __init__(self, kind, namespace, name):
		self.kind = kind
		self.namespace = namespace
		self.name = name

	@classmethod
	def for_object(cls, o):
		# alternative constructor, for use with resources in parsed JSON format
		return KNN(o["kind"], o["metadata"]["namespace"], o["metadata"]["name"])

	def __str__(self):
		return "{} {}/{}".format(self.kind, self.namespace, self.name)

	def __repr__(self):
		# used when printing lists of KNN (why not __str__, Python?)
		return self.__str__()

	def kubectl_str(self):
		# return reference to the object for use in kubectl commands (without `kubectl get` or other prefix)
		return "{} -n {} {}".format(self.kind.lower(), self.namespace, self.name)

	def NN(self):
		return "{}/{}".format(self.namespace, self.name)


def namespace_arg(namespace):
	if namespace:
		return "--namespace " + namespace

	return "--all-namespaces"


def kubectl(a):
	"""
	:param a: arguments string (without preceding "kubectl")
	:return: stdout as bytes
	"""
	cmd = "kubectl " + a
	logging.debug(cmd)
	completed = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	if completed.returncode != 0:
		logging.warning("Command returned non-0 ({}): {}".format(completed.returncode, cmd))
		for line in completed.stderr.decode("utf-8", errors="ignore").splitlines():
			logging.warning("stderr: {}".format(line))
	return completed.stdout


def kubectl_logs(namespace, pod, container, tail=50):
	return kubectl("logs --namespace {} --container {} --tail {} {}".format(namespace, container, tail, pod))


def pod_grep(name_pattern, namespace=None):
	"""
	:param name_pattern: full or partial name of a Pod
	:param namespace: if set - use only given namespace
	:return: list of Pod in parsed JSON (i.e dict) format
	"""
	pods_json = kubectl("get pods {} --output json".format(namespace_arg(namespace)))
	pods = json.loads(pods_json)

	found = []
	for pod in pods["items"]:
		logging.debug("POD: {}".format(pods))
		pattern = r".*" + name_pattern + r".*"
		if re.match(pattern, pod["metadata"]["name"]):
			found.append(pod)
	logging.debug("Found pods: {}".format(pods))

	return found


def pod_is_healthy(pod):
	conditions = pod["status"]["conditions"]
	for c in conditions:
		if c["type"] == "ContainersReady":
			return c["status"] == "True"  # Yes, they use boolean strings here
	logging.warning("ContainersReady condition not found. Pod conditions: {}".format(pod["status"]["conditions"]))
	return False


def pod_ids(pod_or_pods):
	f = lambda pod: KNN.for_object(pod).NN()
	if isinstance(pod_or_pods, list):
		return [f(pod) for pod in pod_or_pods]
	return f(pod_or_pods)


def pod_owners(pod):
	"""
	:param pod:
	:return: list of KNN
	"""
	refs = []
	if not pod["metadata"].get("ownerReferences"):
		return refs
	for ref in pod["metadata"]["ownerReferences"]:
		# ownerReference does not include namespace,
		# since owners can only be from the same namespace (of pod in our case)
		refs.append(KNN(ref["kind"], pod["metadata"]["namespace"], ref["name"]))
	return refs


def print_resources(resources, wide=True, namespace=""):
	wide_arg = "-o wide" if wide else ""
	ns_arg = "-n {}" if namespace else ""
	for crd in resources:
		print(crd)
		found = kubectl("get {} {} {}".format(crd, wide_arg, ns_arg))
		log("kubectl get {} {} {}".format(crd, wide_arg, ns_arg), color=Color.GREY, verbose=True)
		for line in found.decode("utf-8", errors="ignore").splitlines():
			log(line, indent=2)
		print()


def print_resources_batch(resources, wide=True, namespace=""):
	if not resources:
		print("Nothing found")
		return

	wide_arg = "-o wide" if wide else ""
	ns_arg = "-n {}" if namespace else ""

	# We batch all resources into 1 kubectl call for efficiency
	found = kubectl("get {} {} {}".format(",".join(resources), wide_arg, ns_arg))

	# NAME                                 STATUS   DISPLAY NAME   CAPACITY MODE   VSC                      AGE
	# vpsa.storage.zadara.com/vpsa-qa9     Ready    Example VPSA   normal          vscstorageclass-sample   68m
	# vpsa.storage.zadara.com/vpsa-other   Ready    Another VPSA   normal          vscstorageclass-sample   68m
	#
	# NAME                                         IP             IQN                                       AGE
	# vscnode.storage.zadara.com/k8s-base-master   10.10.100.61   iqn.2005-03.org.open-iscsi:e9c4f0d828cf   69m

	# resource -> ["NAME ... ", "resource/name ..."]
	lines_by_resource = defaultdict(list)

	title_line = ""
	for line in found.decode("utf-8", errors="ignore").splitlines():
		if not line:
			continue

		if line.startswith("NAME"):
			title_line = line
			continue
		# TODO: if len(resources) == 1, k8s does not prepend resource type to the name
		resource_and_rest = line.split("/", maxsplit=1)
		resource, rest_of_fields = resource_and_rest[0], resource_and_rest[1]
		if title_line != "":
			# delete same amount of whitespace after "NAME", as we delete from rest_of_fields
			# 4 for "NAME", 1 for "/"
			lines_by_resource[resource].append("NAME" + title_line[5 + len(resource):])
			title_line = ""
		lines_by_resource[resource].append(rest_of_fields)

	for resource, lines in lines_by_resource.items():
		print(resource)
		log("$ kubectl get {} {} {}".format(resource, wide_arg, ns_arg), color=Color.GREY, verbose=True)
		for line in lines:
			log(line, indent=2)
		print()


###############################################################################
# Top-level commands
# - Should start with "dig_" (to show that this is top-level command)
# - Should be able to run without any arguments (for use in 'all')


def dig_pod(name_pattern=".*", namespace=None, logs=False):
	only_unhealthy = not args.all
	pods = pod_grep(name_pattern, namespace)
	if len(pods) == 0:
		logging.error("No pods found")
		return

	at_least_one_printed = False
	for pod in pods:
		if only_unhealthy and pod_is_healthy(pod):
			continue
		if pod_is_healthy(pod):
			pod_status = Color.green("OK")
		else:
			pod_status = Color.red("ERR")

		pod_knn = KNN.for_object(pod)

		owners = pod_owners(pod)
		log("POD [{}]: {} | Owners: {}".format(pod_status, Color.wrap(pod_ids(pod), Color.BOLD), owners))
		for owner in owners:
			# ReplicaSet almost always is owned by Deployment, show it as well.
			# We guess Deployment name, to skip another kubectl call.
			if owner.kind == "ReplicaSet":
				parts = owner.name.split("-")
				deployment_name = "-".join(parts[:len(parts) - 1])
				log("$ kubectl describe {}".format(KNN("Deployment", owner.namespace, deployment_name).kubectl_str()),
					color=Color.GREY, indent=2, verbose=True)
			log("$ kubectl describe {}".format(owner.kubectl_str()), color=Color.GREY, indent=2, verbose=True)
		log("$ kubectl describe {}".format(pod_knn.kubectl_str()), color=Color.GREY, indent=2, verbose=True)

		for cs in pod["status"]["containerStatuses"]:
			if only_unhealthy and cs["ready"]:
				continue

			at_least_one_printed = True
			container = cs["name"]
			log("{:30}: {}".format(container, Color.green("Ready") if cs["ready"] else Color.red("Not ready")),
				indent=4)
			if logs:
				logs = kubectl_logs(pod_knn.namespace, pod_knn.name, container, args.tail)
				log("$ kubectl logs -n {} -c {} {}".format(pod_knn.namespace, container, pod_knn.name),
					color=Color.GREY, indent=8, verbose=True)
				for line in logs.decode("utf-8", errors="ignore").splitlines():
					log(line, indent=8)
				log("", color=Color.RESET)  # reset color (logs may mess it up)

	if only_unhealthy and not at_least_one_printed:
		log("Everything is fine", color=Color.GREEN)


def dig_crd(name_pattern=".*"):
	crds_output = kubectl("get crds")
	crd_names = []
	for line in crds_output.decode("utf-8", errors="ignore").splitlines()[1:]:
		crd_names.append(line.split()[0])

	pattern = r".*" + name_pattern + r".*"
	print_resources_batch([crd for crd in crd_names if re.match(pattern, crd)])


def dig_storage():
	# TODO: snapshots version (and skip if snapshot.storage.k8s.io CRDs not installed)
	# TODO: There are also "csinodes", but there is nothing really interesting there
	print_resources_batch([
		"csidrivers",
		"storageclasses",
		"pvc", "pv",
		"volumeattachments.storage.k8s.io",
	])
	print_resources_batch([
		"volumesnapshotclasses", "volumesnapshots", "volumesnapshotcontents",
	], wide=False)  # These are too verbose


###############################################################################
# Main and helpers

class DefaultSubcommandArgParse(argparse.ArgumentParser):
	"""
	This workaround allows to choose one of subparsers as default,
	mainly to allow running this script without any arguments.
	"""
	__default_subparser = None

	def set_default_subparser(self, name):
		self.__default_subparser = name

	def _parse_known_args(self, arg_strings, *args, **kwargs):
		in_args = set(arg_strings)
		d_sp = self.__default_subparser
		if d_sp is not None and not {'-h', '--help'}.intersection(in_args):
			for x in self._subparsers._actions:
				subparser_found = (
						isinstance(x, argparse._SubParsersAction) and
						in_args.intersection(x._name_parser_map.keys())
				)
				if subparser_found:
					break
			else:
				# insert default in first position, this implies no
				# global options without a sub_parsers specified
				arg_strings = [d_sp] + arg_strings
		return super(DefaultSubcommandArgParse, self)._parse_known_args(arg_strings, *args, **kwargs)


def parse_args():
	"""
	Arguments schema tries to mimic kubectl where applicable (common arguments, resources aliases)
	:return: parsed args
	"""
	common_flags = argparse.ArgumentParser()
	common_flags.add_argument("-v", "--verbose", help="Show kubectl commands to dig even deeper", action="store_true")

	parser = DefaultSubcommandArgParse(description="Diagnostic tool for k8s application")
	subparsers = parser.add_subparsers(dest="command", title="Commands")
	subparsers.required = False
	parser.set_default_subparser("pods")

	subparsers.add_parser("all", help="Overview of all resources", parents=[common_flags], add_help=False)

	subp = subparsers.add_parser("pods", aliases=["po", "pod"], help="Pod utils", parents=[common_flags],
								 add_help=False)
	subp.add_argument("pod_pattern", nargs='?', default=".*", help="Name of Pod (partial names allowed)")
	subp.add_argument("--all", help="Show all pods (by default only unhealthy are shown)", action="store_true")
	subp.add_argument("-n", "--namespace", help="Namespace")
	subp.add_argument("--logs", default=False, action="store_true", help="Print container logs")
	subp.add_argument("--tail", type=int, default=16, help="How much logs to show (default: 16)")

	subp = subparsers.add_parser("storage", help="Storage utils", parents=[common_flags], add_help=False)

	subp = subparsers.add_parser("crd", aliases=["crds"], help="CRD utils", parents=[common_flags], add_help=False)
	subp.add_argument("pattern", nargs='?', default=".*", help="Name of CRD (partial names allowed)")

	return parser.parse_args()


if __name__ == "__main__":
	args = parse_args()

	if args.command == "all":
		dig_pod()
		dig_storage()
		dig_crd()
	if args.command in {"pods", "pod", "po"}:
		dig_pod(args.pod_pattern, args.namespace, logs=args.logs)
	if args.command in {"crd", "crds"}:
		dig_crd(args.pattern)
	if args.command in {"storage"}:
		dig_storage()
