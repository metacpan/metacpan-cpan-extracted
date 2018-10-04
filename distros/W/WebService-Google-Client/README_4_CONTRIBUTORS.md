# THINKING OF CONTRIBUTING? READ ME!

LAST UPDATE: 2018-10-04

## Project Mission

The goal of this project is to enhance the code quality from its pre-fork
condition and make contributing to this project easier and more developer
friendly to allow for further development and improvements.

A secondary goal is to strive to exercise the best software development
practices. While creating a good, high quality product is important to us, we
think the journey is where 95% of the fun lies. We're approaching this project
as professionally as our present skills allow with an aim in mind to improve
them. We're not here to provide all the answers and we make no claims on having
them. If you have recommendations for improving the project, we definitely
welcome them and an opportunity to learn from you. We have no product deadline
here and we are happier doing things well and right instead of as fast as we
can. This is a project for stopping and smelling the software roses.

## Development Status

This module was recently forked from
[`Moo::Google`](https://metacpan.org/pod/Moo::Google) on 2018-10-03. The
`Moo::Google` project stalled sometime in January 2018 during the middle of
renaming the module to `WebService::Google::Client.` The fork has successfully
completed renaming the module and is [available on metacpan for
download](https://metacpan.org/pod/WebService::Google::Client) for download
and installation using traditional Perl installer programs (cpan and cpanm).

This module is currently undergoing an overhaul in an attempt to make it easier
for contributors to chip in and help improve the quality and functionality of
the module. While functional and bugfree, the module has some large gaps in its
API coverage which are in the process of getting documented. These gaps can be
overcome by lower-level API calls for now so the module can still be used but
some Google API calls will take a little more effort to code.

Once the overhaul is complete, work will begin on a second phase to overhaul
the code as necessary and enhance its ability to make API calls using a higher
level interface.

## How to Contribute

Though the module uses `Dist::Zilla` to automate the build generation and
release process. `Dist::Zilla` has a reputation for being difficult to learn and
a pain to work with. The truth is, though, that most contributors don't even
need to know much about it and you don't even need to have it installed to
contribute to this project. There are some simple things to be aware of,
however. See the section on `Working with Dist::Zilla` below for more
information. The bottom line is, don't ket `Dist::Zilla` dissuade you from
contributing.

## Reporting Bugs

All bugs should be reported via this module's [GitHub home
page](https://github.com/sdondley/WevService-Google-Client). Bug reports and
questions will be responded to quickly and courteously to the best of our
ability. Please be as considerate and thorough in your posts as possible. And
we like asking really dumb questions as well as answering them, so don't be
shy.

## Contributing Code and Documentation

For now, there is only one maintainer of the main GitHub repo. Therefore, if
you wish to make code contributions, you should fork the project on GitHub and
make pull requests from the fork.

### Making Obvious or Simple Contributions

If your contribution is small and obvious, feel free to push directly to the
`devel` branch of this repository if you don't have your own branch on this
repository. Examples of "small and obvious" contributions include:

* Fixing typos, spelling and grammar mistakes
* Obvious bug fixes
* Small enhancements to improve code quality, no more than 1 to 10 lines and
  all in the same function. These enhancements should not change the behavior
  of the module in any significant way.
* Fixes for existing, failed tests that don't require new functions to be
  written.
* Relatively minor documentation additions, not more than a paragraph or two.
* If it requires a new test get written, it is **not** a small contribution.
  See the next section below on that.

If in doubt over whether your proposed contribution is "small" or not, feel
free to open an issue to discuss.

### Making Larger Contributions

If you have an idea for a new feature for a way to vastly improve this module,
we are all ears. But we want to understand what you intend to do before you go
forward and we definitely don't want you spinning your wheels. So we ask that
you please consult with the developer so there is agreement on the scope of the
contribution, a rough game plan for accomplishing it and the tests that will be
needed.

Once that's done, we will then create a new branch for you. Once the branch is
created, you should reate a new branch in your fork and set it the branch in
this repo that was set up for you as the upstream branch for your new local
branch. If you need help with this, feel free to ask. We will have a procedure
for this once we test it and make sure it works well and is easy.

### Clean Commits, Please

If you are making a lot of small commits, please don't pile up a bunch of
unrelated commits after another in a single pull request. Instead, set up a
separate branch for each group of related commits. Branching is easy:

`git co -b <new_branch_name>`

Then you can go to work on the related commits on that branch. Then do a pull
request for that branch.

### No Holy Wars on Best Approach to Using Git, Please

We know everyone has a preferred way for using Git. But please respect the git
workflow we have chosen for this project. We realize this isn't a huge project.
But part of the reason we have chosen this workflow is to help get more
comfortable with using git on more complicated projects. We are open for ways to
make things simpler, but we aren't willing to change the entire workflow we have
established which was chosen for a reason: learning. Please don't take offense
and we greatly appreciate your patience even if you think we're being slightly
(or really) ridiculous.

### Test-Driven Development, Please

Much of what was said in last section applies to this one as well. Yes, it may
seem like a bit of overkill for a project like this, but before any code for a
new feature or bug fix is released, we'd like to see a test for it first.
Again, we are using this project to help form good coding habits and help cut
our teeth practicing them. Thanks for your understanding.

## Working with, or Around, `Dist::Zilla`

This is a short list of stuff **not** to do or worry about:

* DO NOT make edits directly to README.md file. This file is generated
  automatically from the inline POD. So any changes you want to make should go to
  POD.
* DO NOT edit the `dist.ini` configuration file.
* DO NOT edit the `weaver.ini` configuration files.
* DO NOT change the `our $VERSION` code in any of the module files. These are
  all automated.

OK, that's it as far as the "do nots" go. Only other thing you should know is
how to run tests with `Dist::Zilla` (if you have `Dist::Zilla` installed). Read
the next section for more on this.

## Running Tests

Coming soon...we're tired...zzzzz
