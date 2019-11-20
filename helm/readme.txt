Description:
	helm charts for the plugin and example apps

Notes:
	- Use 'make lint' to validate YAMLs
	- Stick to Helm conventions: https://helm.sh/docs/chart_best_practices/
	  Most notable:
		- chart directory name == chart name
		- values names use camelCase
		- quote all strings, don't quote everything else
		- avoid [lists, of, values] in values.yaml - hard to set from CLI
		- comment every parameter in values.yaml, starting comment with parameter name (for grep'ing parameters)
		- name templates using-kebab-case
