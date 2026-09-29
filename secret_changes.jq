# Compare canonical Secret values privately; print identities and key names only.
def secrets:
  [.. | objects | select(.kind? == "Secret") |
    {key: ([.metadata.namespace // $namespace, .metadata.name] | tojson),
     value: ((.data // {}) + ((.stringData // {}) | with_entries(.value |= @base64)))}] | from_entries;
(.[0] | secrets) as $before | (.[1] | secrets) as $after |
((($before | keys) + ($after | keys)) | unique[]) as $resource |
($before[$resource] // {}) as $old | ($after[$resource] // {}) as $new |
((($old | keys) + ($new | keys)) | unique[]) as $key |
select(($old | has($key)) != ($new | has($key)) or $old[$key] != $new[$key]) |
"Secret change: " + $resource + " key " + ($key | tojson) + " " +
(if ($old | has($key) | not) then "added" elif ($new | has($key) | not) then "removed" else "changed" end)
