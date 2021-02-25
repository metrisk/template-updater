const core = require('@actions/core')
const exec = require('@actions/exec')
const path = require('path')

async function run () {
  try {
    const templateRepo = core.getInput('template_repo')
    const sshKey = core.getInput('ssh_key')
    const files = core.getInput('files_to_update')
    const username = core.getInput('username')
    const email = core.getInput('email')
    const branchName = core.getInput('branch_name')
    await exec.exec(`bash ${path.join(__dirname, '../scripts/updater.sh')} ${templateRepo} ${files} ${username} ${email} ${branchName} ${process.env.GITHUB_REPOSITORY}`)
  } catch (err) {
    core.setFailed(err.message)
  }
}

run()
