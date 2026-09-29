# Produce assignments only for changed nodes; yq retains comments on untouched nodes.
def changes($old; $new; $path):
  if $old == $new then empty
  elif ($old | type) == "object" and ($new | type) == "object" then
    (($old | keys_unsorted) - ($new | keys) | .[] | {delete: ($path + [.])}),
    ($new | keys_unsorted[] as $key |
      if $old | has($key) then changes($old[$key]; $new[$key]; $path + [$key])
      else {path:($path + [$key]), value:$new[$key]} end)
  else {path:$path, value:$new} end;
def yamlpath: "." + (map("[" + tojson + "]") | join(""));
[changes(.[0]; .[1]; []) |
  if has("delete") then "del(" + (.delete | yamlpath) + ")"
  else (.path | yamlpath) + " = " + (.value | tojson) end] | join(" | ")
