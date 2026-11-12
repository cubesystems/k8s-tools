# The settings of one deployment: the top-level legacy values, defaults, the
# template it names, then its own settings, each layer overriding the last.
def effective($name):
  .deployments[$name] as $deployment
  | ({release, repo, chart, version} | with_entries(select(.value != null)))
    + (.defaults // {})
    + (.templates[$deployment.template // ""] // {})
    + ($deployment | del(.template));
