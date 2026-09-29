def fail($where; $message): error($where + ": " + $message);
def settings($where):
  if type != "object" then fail($where; "expected a mapping") else . end |
  . as $settings |
  ["release", "namespace", "chart", "repo", "version", "kubeconfig", "context",
   "keyRef", "values", "createNamespace", "useCurrentContext", "timeout",
   "rollbackOnFailure", "imageTagPath", "resourcePrefix"] as $allowed |
  if (keys - $allowed | length) > 0 then fail($where; "unknown fields: " + ((keys - $allowed) | join(", "))) else . end |
  to_entries | all(.[];
    .key as $key | .value as $value |
    if $value == null then true
    elif (["createNamespace", "useCurrentContext", "rollbackOnFailure"] | index($key)) != null then
      if ($value | type) == "boolean" then true else fail($where + "." + $key; "expected a boolean") end
    elif $key == "values" then
      if ($value | type) != "array" then fail($where + ".values"; "expected a list of filenames")
      else $value | all(.[]; if type == "string" and length > 0 and (test("[\r\n]") | not) then true else fail($where + ".values"; "expected nonempty filenames without newlines") end) end
    elif ($value | type) != "string" or $value == "" then fail($where + "." + $key; "expected a nonempty string (quote versions and tags)")
    else true end);

if type != "object" then fail("deployments.yaml"; "expected a mapping") else . end |
if has("environments") then error("Rename environments to deployments for k8s-tools 2.x") else . end |
. as $root |
if (keys - ["$schema", "schemaVersion", "defaults", "deployments", "release", "chart", "repo", "version"] | length) > 0
then error("Unknown top-level configuration fields: " + ((keys - ["$schema", "schemaVersion", "defaults", "deployments", "release", "chart", "repo", "version"]) | join(", "))) else . end |
if has("schemaVersion") and .schemaVersion != 2 then error("schemaVersion must be 2, or omitted for legacy paths") else . end |
if has("$schema") and (."$schema" | type) != "string" then error("$schema must be a string") else . end |
if has("defaults") and (.defaults | type) != "object" then error("defaults must be a mapping") else . end |
if .schemaVersion == 2 and any(["release", "chart", "repo", "version"][]; . as $key | $root | has($key))
then error("schemaVersion 2: move release, chart, repo and version into defaults") else . end |
if (.deployments | type) != "object" or (.deployments | length) == 0 then error("deployments must be a nonempty mapping") else . end |
if any(.deployments | keys[]; length == 0 or test("[\\r\\n\\t]")) then error("deployment names must be nonempty and contain no tabs or newlines") else . end |
(.defaults // {} | settings("defaults")) and
({release, chart, repo, version} | settings("top-level defaults")) and
(.deployments | to_entries | all(.[]; .key as $name | .value | settings("deployments." + $name)))
