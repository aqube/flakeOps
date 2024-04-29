#!/usr/bin/env bash
#
# Checks if all sops secrets are encrypted

readonly SOPS_FILES="${1?pattern for sops files is required}"
readonly ROOT_DIR="${2-.}"

echo "Checking ${SOPS_FILES} files under ${ROOT_DIR}"

FAIL=false
COUNTER=0
# preserve leading and trailing whitespaces, slashes and use the null character as delimiter
while IFS= read -r -d '' file; do
    COUNTER=$((COUNTER + 1))
    extra_args=''
    # Check for known file extensions. If the extension is unknown, expect the whole file to be encrypted.
    # In that case it must be of json format, otherwise sops can't figure out if the file is encrypted or not.
    if [[ ! "$file" =~ \.(json|ya?ml|ini)$ ]]; then
        extra_args='--input-type=json'
    fi

    sops -e $extra_args "$file" >/dev/null 2>&1
    SOPS_RET=$?

    # Error codes: https://github.com/mozilla/sops/blob/master/cmd/sops/codes/codes.go
    case "$SOPS_RET" in
    203)
        # File encrypted! Nothing to do.
        ;;
    *)
        FAIL=true
        echo -e "$file \033[3;31mis not encrypted\033[0m" >&2
        ;;
    esac
done < <(find "${ROOT_DIR}" -name "${SOPS_FILES}" -print0) # print0 to use the null character as delimiter

echo "Checked $COUNTER files"

if [[ "$FAIL" != "false" ]]; then
    echo "Some files are not encrypted"
    exit 1
else
    echo "All files are encrypted"
fi
