# bats-core support library
# version: 0.4.1

# Source all support files in directory.
for support_file in "${BATS_SUPPORT_HOME:-"$BATS_ROOT/libexec"}"/bats-support-*.bash; do
  if [[ -f "$support_file" ]]; then
    # shellcheck source=/dev/null
    source "$support_file"
  fi
done