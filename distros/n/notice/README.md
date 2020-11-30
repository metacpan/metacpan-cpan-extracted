# NAME

notice - Breaking-Change Acknowledgement

# ABSTRACT

Breaking-Change Acknowledgement Enforcement

# SYNOPSIS

    package Example;

    BEGIN {
      $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;
    }

    use notice unstable => {
      space => 'Example',
      until => '2020-09-01',
      notes => 'See https://example.com/latest/release-notes',
    };

    1;

# DESCRIPTION

This package provides a mechanism for enforcing breaking-change
acknowledgements. When configured under a module namespace, a fatal error
(notice) will be thrown prompting the operator to acknowledge the notice
(unless the notice has already been ackowledged). Notices are acknowledged by
setting a predetermined environment variable. The environment variable always
takes the form of `ACK_NOTICE_CLASS_NOTICENAME`. The fatal error (notice) is
thrown whenever, the encapsulating package is _"used"_, the notice criteria is
met, and the environment variable is missing. Multiple notices can be
configured and each can have a time-based expiry aftewhich the notice will
never be triggered.

# FUNCTIONS

This package implements the following functions:

## check

    check(ClassName $name, Any %args) : Maybe[Tuple[Str, Str, Str, Str, Str | ArrayRef]]

The check method returns truthy or falsy based upon whether the notice criteria
is met. When met, this function returns details about the trigger engaged.

- check example #1

        # given: synopsis

        delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

        # notice: triggered (not acknowledged)

        notice::check('Example', (
          unstable => {
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #2

        # given: synopsis

        delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

        # notice: not triggered (notice expired)

        notice::check('Example', (
          unstable => {
            until => '2000-09-01',
            notes => 'see changelog',
          },
        ));

- check example #3

        # given: synopsis

        delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

        # notice: triggered (not ackowledged)

        notice::check('Example::Agent', (
          unstable => {
            space => 'Example',
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #4

        # given: synopsis

        $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

        # notice: triggered (refactor not ackowledged)

        notice::check('Example::Agent', (
          refactor => {
            space => 'Example',
            until => '9999-09-01',
            notes => 'see refactor',
          },
          unstable => {
            space => 'Example',
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #5

        # given: synopsis

        $ENV{ACK_NOTICE_EXAMPLE_REFACTOR} = 1;
        $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

        # notice: not triggered (unstable and refactor ackowledged)

        notice::check('Example::Agent', (
          refactor => {
            space => 'Example',
            until => '9999-09-01',
            notes => 'see changelog',
          },
          unstable => {
            space => 'Example',
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #6

        # given: synopsis

        $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE} = 1;

        # notice: triggered (wrong namespace ackowledged)

        notice::check('Example::Agent', (
          unstable => {
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #7

        # given: synopsis

        $ENV{ACK_NOTICE_EXAMPLE_AGENT_UNSTABLE} = 1;

        # notice: not triggered (notice ackowledged)

        notice::check('Example::Agent', (
          unstable => {
            until => '9999-09-01',
            notes => 'see changelog',
          },
        ));

- check example #8

        # given: synopsis

        delete $ENV{ACK_NOTICE_EXAMPLE_UNSTABLE};

        # notice: triggered (not ackowledged)

        notice::check('Example', (
          unstable => {
            until => '9999-09-01',
            notes => [
              'see release notes for details',
              'see https://example.com/latest/release-notes',
            ],
          },
        ));

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/notice/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/notice/wiki)

[Project](https://github.com/iamalnewkirk/notice)

[Initiatives](https://github.com/iamalnewkirk/notice/projects)

[Milestones](https://github.com/iamalnewkirk/notice/milestones)

[Contributing](https://github.com/iamalnewkirk/notice/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/notice/issues)
