_k8s_tools_complete() {
  local directory=${words[1]:h}
  local command_name=${words[1]:t}
  if [[ $command_name == secrets && $CURRENT == 2 ]]; then
    compadd set edit encrypt decrypt rekey recover
  elif [[ $command_name == config && $CURRENT == 2 ]]; then
    compadd show validate
  else
    local -a names
    names=("${(@f)$("$directory/list" --names)}")
    compadd -- "${names[@]}"
  fi
}
