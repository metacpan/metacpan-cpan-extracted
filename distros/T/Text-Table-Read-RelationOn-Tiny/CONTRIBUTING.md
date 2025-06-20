# Contributing to This Perl Module

Thank you for your interest in contributing!

## Reporting Issues

Please open a
[CPAN request](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Table-Read-RelationOn-Tiny)
or a
[GitHub Issue](https://github.com/AAHAZRED/perl-Text-Table-Read-RelationOn-Tiny/issues)
if you encounter a bug or have a suggestion.
Include the following if possible:

- A clear description of the issue
- A minimal code example that reproduces it
- Expected and actual behavior
- Perl version and operating system

## Submitting Code

Pull requests are welcome! To contribute code:

1. Fork the repository and create a descriptive branch name.
2. Write tests for any new feature or bug fix.
3. Ensure all tests pass using `prove -l t/` or `make test`.
4. Follow the existing code style, especially:
   - No Tabs please
   - No trailing whitespace please
   - 2 spaces indentation
5. In your pull request, briefly explain your changes and their motivation.


## Creating a Distribution (Release)

This module uses MakeMaker for creating releases (`make dist`).
An external script is used for the build process.
To make it available, you must execute the following commands in your local Git repository:

    git submodule init
    git submodule update


## Licensing

By submitting code, you agree that your contributions may be distributed under the same license as the project.

Thank you for helping improve this module!
