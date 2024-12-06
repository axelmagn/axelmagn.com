set -exuo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
readonly PUBLISH_TGT="gs://www.axelmagn.com"
export CLOUDSDK_PYTHON="${HOME}/.pyenv/shims/python"

pushd "${PROJECT_DIR}/web"
zola build
gsutil -m rsync -d -r public "${PUBLISH_TGT}"
popd
