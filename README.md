# NAME

git-trac - Manage your trac tickets with git.

# VERSION

0.01

# SYNOPSIS

    git trac [--help|-?]
    git trac [--man]
    git trac [--refresh] COMMAND ARGS

Options:

    --help,-h,-?     Brief help message
    --man,-m         Long help message
    --refresh,-r     Force a refresh of Trac tickets
    --version,-v     Print version of Git::Trac

Commands:

    tickets                      List open tickets
    tasks                        List tasks
    start  $number $branch_name  Start working on ticket $number in branch $branch_name
    switch $number               Switch to already started task $number
    commit $message              Commit a change with $message, posting the message to Trac
    delete $number               Will delete the task (but not the branch)

# DESCRIPTION

git-trac is the command line front-end to Git::Trac, a Perl module to allow
git and Trac integration. Written very hastily for `$client`. It needs a lot
of refactoring, but it works for me. I threw it up on github with the
permission of the client in case anyone else wants to hack at it (and
improving it won't be hard).

With git-trac, you have _tickets_ and _tasks_. Tickets are only open tickets
that you have on Trac. `tasks` are tickets that you have started (see
["COMMANDS"](#COMMANDS)).

# CONFIGURATION

To start, you must first create a file named `$ENV{HOME}/.git-trac.ini`, with
permissions of 0600. The file should be an ini-style with the following data:

    [authentication]
    ; Your Trac login name
    user     = your username

    ; Your Trac password
    password = your password

    ; Your base Trac url
    url      = https://example.com/trac/company.dev

    [git]

    ; This is the main branch you will branch from. For personal projects, this is
    ; often 'master'. For a work environment, you often branch from 'devel' or
    ; 'integration', so use that branch name. When you switch to a new branch, git
    ; will check out your integration_branch and branch from there. Obviously this
    ; will fail if you have a dirty working tree
    integration_branch = integration

# COMMANDS

## `tickets`

    git trac tickets

This will connect to the remote Trac instance and fetch all open tickets for
the user listed in the configuration file.

The output will look similar to this:

    492 - 2013-03-26 - assigned     - Possible data consolidation error
    643 - 2013-04-29 - assigned     - Canonicalizer sanity checks
    659 - 2013-05-02 - assigned     - Enhance import process to handle kitties
    867 - 2013-06-28 - new          - Remove sensitive data from output
    874 - 2013-07-02 - accepted     - Write new importer
    887 - 2013-07-09 - new          - git-trac interface

The columns are "ticket number", "date created", "status" and "summary".

Note that the ticket data is cached locally (in the current git directory). To refresh the ticket data:

    git trac -r tickets
    git trac --refresh tickets

## `tasks`

    git trac tasks

This will list any tasks you have started in format as follows:

      -     643 - ticket_643_gimme_sanity_baby (Canonicalizer sanity checks)
      -     867 - ticket_867_u_no_can_haz_passwords (Remove sensitive data from output)
    * -     887 - ticket_887_a_new_branch_for_most_testing (git-trac interface)

Any task starting with an asterisk (\*) is the current task.

The columns are "ticket number", "branch name", "summary"



## `start`

    git trac start $number $branch_name

This starts a new task, based on the ticket number. The task number will be
the same as the ticket number. You must supply a branch name and any non-word
characters are converted to underscores.

Will fail if the current branch is dirty (has uncommitted changes) or the Trac
ticket number does not exist (if you're sure it exists, make sure you're the
owner, the task is not closed, and run `git trac -r` to update your
tickets).

First, it checks out the `integration_branch` listed in your configuration
and then it branches from there. It does not attempt up update anything.

The name of the branch is posted back to Trac. I would have set the status to
`accepted`, but I can't figure out how to do that with [Net::Trac](http://search.cpan.org/perldoc?Net::Trac).

## `switch`

    git trac switch $number

Switches to the task with task number `$number`. You must have previously
`start`ed that task. Use `git trac tasks` to see a list of available
tasks.

Will fail if the current branch is dirty.

## `commit`

    git trac commit -a -m $message
    git trac commit -a
    git trac commit lib/

Attemtps to commit the changes requested. If you don't supply a message, opens
an editor for you to supply a message. This message will be posted back to
Trac.

## `delete`

    git trac delete $number

Deletes a task. Does not delete the branch or update Trac.

## `comment`

    git trac comment
    git trac comment message

Post a comment to Trac for the current task.
