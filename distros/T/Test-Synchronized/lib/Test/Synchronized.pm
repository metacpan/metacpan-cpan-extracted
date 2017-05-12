package Test::Synchronized;
use strict;
use warnings;

use Test::Synchronized::FileLock;
use Test::Synchronized::Extensible lock_class => 'Test::Synchronized::FileLock';

our $VERSION = '0.04';

1;

=head1 NAME

Test::Synchronized

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::Synchronized;
  
  ...
  
  ok(cant_run_with_other_tests());

=head1 DESCRIPTION

Test::Synchronized provides simple (and giant) lock for your tests.

If you have a few test that not works in parallel,
you should not give up to run whole tests in parallel.

=head1 EXTENSIBILITY

The default lock is based on process ID.
If you want to use different system,
Please try Test::Synchronized::Extensible.

=head1 AUTHOR

Kato Kazuyoshi E<lt>kato.kazuyoshi@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
