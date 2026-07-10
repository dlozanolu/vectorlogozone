#!/usr/bin/env bash
#
# build the site!
#

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "${SCRIPT_DIR}/.." && pwd )"

echo "INFO: build starting at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "DEBUG: uname=$(uname -a)"

export PYTHON_UNBUFFERED=1


echo "INFO: generating ar21's with a white background"
"${REPO_DIR}/bin/gen_bgwhite.py"

echo "INFO: updating frontmatter"
"${REPO_DIR}/bin/frontmatter_update.py" --directory="${REPO_DIR}/src/content/logos"

echo "INFO: installing javascript dependencies"
cd "${REPO_DIR}"
npm install

echo "INFO: running astro build"
npm run build

echo "INFO: merging index files"
tar cvzf dist/util/sourceData.tgz dist/api/search-*.json

echo "INFO: CI=${CI:-not set}"
echo "INFO: CF_PAGES=${CF_PAGES:-not set}"
echo "INFO: WORKERS_CI=${WORKERS_CI:-not set}"
echo "INFO: WORKERS_CI_COMMIT_SHA=${WORKERS_CI_COMMIT_SHA:-not set}"

if [ "${CI:-0}" == "true" ]; then
    echo "INFO: running Cloudflare Pages post-build script"
    HTML_PAGES=$(find dist -type f -name "*.html" | grep -v "index.html$" | grep -v "404.html$")
    for PAGE in $HTML_PAGES; do
        echo "INFO: renaming $PAGE"
        mv "${PAGE}" "${PAGE}.html"
    done
else
    echo "INFO: skipping Cloudflare Pages post-build script"
fi


echo "INFO: build completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
