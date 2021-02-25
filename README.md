# template-updater

[Github template repositories](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-template-repository) are great for creating base config repos for the whole of your organisation but what happens when that base config changes?

The usual way to keep your repositories up to date with each other would be to add the template repository as a 'upstream' remote, similar to if you had forked it.

This is manual, it's easy to forget to do it, or even not know that you should do it.

This Action will automatically update the files you require from the template repository, so you could set up a cron workflow to check daily/weekly/monthly if your repo has new ESLint/Rubocop/whatever rules to follow.

## Usage

A simple example of how to use this action is shown below.

```yml
name: Update Template Config
on:
  schedule:
    - cron: "00 08 * * 1-5"
jobs:
  updatetypescripttemplate:
    name: Update config from template
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2.3.4
      - uses: metrisk/template-updater@main
        with:
          template_repo: "your-org/typescript-template"
          files_to_update: .github/workflows/update_template_files.yml,.github/workflows/update_docs.yml
        env:
          PRIVATE_KEY: ${{ secrets.PRIVATE_SSH_KEY }}
```

The full list of inputs are as follows:

`template_repo`: The name of the template repository, e.g. 'your-org/super-template'

`files_to_update`: The files you want to update from the template repository as a comma delimited string

`username`: The name of the user who will be making the changes. e.g. 'Wade Wilson'

`email`: The email address for the user making the changes. 'wade@unicorn.love'

`branch_name`: (optional) The branch name where you would like the changes to be pushed to. The default is `update-template-settings`

The required environment variable is:

`PRIVATE_KEY`: This is the private SSH key for the user who is making the changes. This **must** match the email provided and **must** be the private key match to a public key in the users Github settings.

The reason for the action needing this key is excellently explained [here](https://www.webfactory.de/blog/use-ssh-key-for-private-repositories-in-github-actions).

The output is a boolean value named: `updated`

## How it works

The core of the action is the [updater](./scripts/updater.sh) bash script.

The flow is:

1. Check that the repository running the action isn't the same as the template repository. Fail if it is.
2. Setup SSH - i.e. add the private key to `ssh-agent`
3. Configure Git with the provided name/email
4. Adds the template repository as the upstream remote
5. Fetches the `main` branch from the template repository
6. Checks for the branch name provided, if it exists switch to that branch, else stay on `main`
7. Checks each file you have supplied to see if there is a diff between your repo and the template. If there is a diff, then it performs the update, otherwise the Action finishes.
