_k8s_tools_complete() {
  local current directory name command_name
  current=${COMP_WORDS[COMP_CWORD]}
  directory=$(dirname "${COMP_WORDS[0]}")
  command_name=$(basename "${COMP_WORDS[0]}")
  COMPREPLY=()
  if [ "$command_name" = secrets ] && [ "$COMP_CWORD" = 1 ]; then
    COMPREPLY=($(compgen -W 'set edit encrypt decrypt rekey recover' -- "$current"))
  elif [ "$command_name" = config ] && [ "$COMP_CWORD" = 1 ]; then
    COMPREPLY=($(compgen -W 'show validate' -- "$current"))
  else
    while IFS= read -r name; do
      case "$name" in "$current"*) COMPREPLY+=("$name");; esac
    done < <("$directory/list" --names)
  fi
}
