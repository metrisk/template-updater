#!/usr/bin/env bash
#
# Auto-updates the repository with the upstream template changes.
# This will be executed by the update_template_files Github Action.
#
# Accepts the following parameters:
# $1: the template repo, e.g. 'username/repo'
# $2: Array of files as a comma delimited list. These are the files to be updated.
# $3: Users name
# $4: Users email
# $5: Branch name
# $6: The repo the script is being executed in.

# Only enable these shell behaviours if we're not being sourced
# Via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2>/dev/null); then
  set -o errexit  # Exit on most errors (see the manual)
  set -o nounset  # Disallow expansion of unset variables
  set -o pipefail # Use last non-zero exit code in a pipeline
fi
scriptdir=$(dirname "$0")

# shellcheck source=./utils.sh
source "$scriptdir/utils.sh"

echo "Starting update"
echo "Checking repo to ensure that it isn't the template repo"
# Stops the script from updating the template repository as it'll already be up to date.
if [[ $6 == "$1" ]]; then
  err "This is the template repo, no need to update"
  exit 1
fi

echo "Setting up SSH"
setup_ssh "$PRIVATE_KEY"

echo "Setting up git"
setup_git "$3" "$4" "$6"

echo "Adding upstream"
git remote add upstream "git@github.com:$1.git"
echo "Upstream added"

declare -a files

IFS=',' read -r -a files <<<"$2"

echo "Fetching the upstream data"
git fetch upstream main
branch="main"

# Checks for the branch name 'update-teamplate-settings'
# Use the existing one if there
echo "Checking for branch name $5"
if [[ $(git rev-parse --verify "$5") ]]; then
  echo "Checking out existing update branch"
  git checkout "$5"
  git merge main --strategy-option ours
  branch=$5
fi

for file in "${files[@]}"; do
  echo "$file"
done

updated=false
# Loop through the template files and diff them
# On the first file with a diff, then the files are checked out of the upstream branch
# The upstream changes are accepted in the event of a conflict
# The changes are committed and pushed up.
for file in "${files[@]}"; do
  echo "$file"
  if [[ ! $(git diff upstream/main "$branch" --quiet -- "$file") ]]; then
    if [ "$branch" = "main" ]; then
      echo "checking out branch $5"
      git checkout -b "$5"
    fi
    for update in "${files[@]}"; do
      echo "Grabbing file: $update"
      git checkout --theirs upstream/main -- "$update" || true
    done
    echo "Committing changes"
    git commit -am "chore: config files updated"
    git push origin -u "$5" --force
    updated=true
    break
  fi
done

echo "$updated"
echo "$GITHUB_REPOSITORY"
git remote rm upstream
echo "::set-output name=updated::$updated"
