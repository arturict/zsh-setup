# Resume one persistent workspace for interactive remote shells.
if [[ -o interactive && -n ${SSH_CONNECTION:-} && -z ${TMUX:-} && ${TERM:-} != dumb ]]; then
  exec tmux new-session -A -s main
fi
