# Working on DBIx-Squirrel

These are the working rules for this repository. DBIx-Squirrel is written
by Iain Campbell, by hand. Claude reviews it and helps with the work
around the code. That's a different split from scalar and grammar, which
Iain and Claude write together, and the rules below say where the line
is. Each rule comes with the reason for it.

Decisions still to be made, and the plan for the rewrite, are in the
Claude Doc
[DBIx-Squirrel successor: plan](https://claude.ai/artifact/1cnZmM5LRgpgX3F6sF8VqB).

## What DBIx-Squirrel is for

DBI, minus the boilerplate, plus a pipeline. It keeps you writing SQL, as
the DBI does, and takes away the friction around it: placeholders in any
of the common styles, iterators over results, and a pipeline of
transformations declared beside the query. A stage of the pipeline can
change a row (map), drop it by returning nothing (filter), or return
several values (flatMap). The pipeline is the core of the design.

It subclasses the DBI, so everything the DBI does still works. Where
DBIx-Squirrel and plain DBI do the same thing, they should give the same
result: plain DBI is the baseline, as Perl is for scalar.

## Who does what

- **Iain writes the code.** Claude reviews it, suggests, and explains,
  and doesn't edit the code unless Iain asks.
- **Claude helps with the Git Ops and the repository's setup:** branches,
  CI, releases, and the files around the code. Ask before changing
  anything on GitHub.
- **Tests and documentation,** where Iain asks: the pipeline's spec as
  tests, the edge cases of placeholder rewriting, tests comparing
  results with plain DBI, and keeping the POD, README and `Changes` up to
  date with the code.
- **Commit messages:** Claude drafts them when asked, for Iain's commits
  as well as its own.

Why: Perl isn't a struggle for Iain, so writing it by hand suits him, and
a hand-written, reviewed project shows a different side of working with
AI from scalar's partnership.

## Credit

- Iain's commits carry no `Co-Authored-By` trailer, even when Claude
  drafted the message.
- Commits Claude wrote, such as CI, setup files, tests or docs written
  at Iain's request, end with a trailer for the Claude model that wrote
  them, currently
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The README's Acknowledgements say what Claude did. Keep them accurate.

Why: credit goes where the work was done, so a reader can see exactly
what was Iain's.

## Perl

- **Perl 5.36 or later.** Modules start `use v5.36`, which gives strict,
  warnings, `say` and signatures. `try`/`catch` and `builtin::` are
  still experimental in 5.36, so they need the floor raised to 5.40,
  deliberately, not by accident. CI tests from the floor to the newest
  Perl.
- **Minilla** builds and releases the distribution. It's opinionated,
  and that's why it was chosen over Dist::Zilla, whose configuration is
  a tax on an occasional release: the repository is the distribution,
  with the `Build.PL` and `META.json` it generates committed and a
  `cpanfile` listing the dependencies, so CI and `cpanm` from GitHub
  need nothing else. Follow its conventions rather than work around
  them.
- Locally, Iain uses perlbrew with a library of the project's own,
  `perl-5.36.3@dbix-squirrel-2`, so its modules don't mix with other
  projects'. Whatever his default Perl is at the time, run commands with
  the library named, so they don't depend on it, and never `perlbrew
  switch` or `use`, which would change his shell:

  ```
  perlbrew exec --with perl-5.36.3@dbix-squirrel-2 prove -lr t
  ```

  5.38.5, 5.40.5 and 5.42.3 are installed too, for testing across the
  range CI covers.

### Building a new Perl on Iain's Mac

Since Xcode 27.1 (Apple clang 21, with the macOS 27.0 SDK), `perlbrew
install` fails for every new Perl on his Mac, running macOS 26.7: the
build stops at "Failed to build miniperl", with a segmentation fault,
whatever the optimisation and with or without `--notest`. Building
against the older SDK works:

```
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk MACOSX_DEPLOYMENT_TARGET=26.0 perlbrew install perl-5.42.3 --notest
```

XS modules installed with `cpanm` need neither variable: DBI and
DBD::SQLite built, passed their tests and worked on a Perl built this
way, on 2026-10-22. If an XS module ever crashes the same way, try the
same prefix on `cpanm`. Check whether this is still needed after the
next Xcode update.

### Net::SSLeay and OpenSSL 4

Homebrew's `openssl` is now OpenSSL 4, and Net::SSLeay (which
IO::Socket::SSL, and so `cpanm` over HTTPS, needs) doesn't build against
it yet: OpenSSL 4 made `ASN1_TIME` opaque, and Net::SSLeay 1.96 fails
with "incomplete definition of type 'ASN1_TIME'". Point it at Homebrew's
OpenSSL 3 instead:

```
perlbrew exec --with perl-5.36.3@dbix-squirrel-2 sh -c 'OPENSSL_PREFIX=/opt/homebrew/opt/openssl@3 cpanm IO::Socket::SSL'
```

That built Net::SSLeay 1.96 and IO::Socket::SSL 2.099 against OpenSSL
3.5.9 on 2026-10-22, and a TLS connection to metacpan verified its
certificate. Drop the prefix once a Net::SSLeay release supports
OpenSSL 4.

## The name

The repository is DBIx-Squirrel-2 while it's in development. At release
it's renamed to DBIx-Squirrel, as the plan doc's "Cut-over to
DBIx-Squirrel" section describes, and the distribution's metadata names
that final URL from the start.

**Never create anything at `github.com/nukopian/DBIx-Squirrel`**, in any
case: GitHub's names ignore case, so `dbix-squirrel` is the same name.
That name now redirects to the archived DBIx-Squirrel-1, which is how
CPAN's links for 1.6.5 reach it. Anything created there ends the redirect
early.

## Planned work

- **At the start of a session, check for `TODO.md`** at the top of the
  repository, on `develop`. If it's there, read it, ask Iain whether each
  task should still be done, and do the ones he confirms. Remove each
  task in the commit that completes it, so the history shows which
  commit did which, and delete the file with the last one. A task he
  drops is removed too, saying why in the commit message.
- **Work planned for a later session goes into `TODO.md`,** committed on
  `develop`, with enough to do it cold: what, why, the files involved,
  and how to check it's done. Not only in Claude's memory or the chat,
  which Iain can't review and a fresh session may not have.
- **`TODO.md` never reaches `main`.** `main` moves only by a
  fast-forward to `develop`, so a release waits until the file is gone:
  each task done, or moved to a GitHub issue, or for a decision awaiting
  Iain, to the plan doc.

Why: planned work survives between sessions in the open, where Iain
reviews it like any other change, and a release never carries an
unfinished list.

## Commits

- Conventional commits, such as `feat: ...`, `fix: ...`, `docs: ...`,
  `test: ...` or `ci: ...`. Say why as well as what.
- Commits are signed. Work is committed and pushed to `develop`. `main`
  is the latest release, and moves only at a release, by a fast-forward
  to `develop`, with a signed tag on it.
- Add what changed for users to `Changes`, under Unreleased, in the same
  commit.
- gitleaks scans the whole history for secrets in CI on every push, and
  by hand before a tag. A leak stops the work like a failing test: once
  history is published, it can't be taken back.
