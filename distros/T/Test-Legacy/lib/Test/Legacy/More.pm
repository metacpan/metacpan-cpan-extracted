package Test::Legacy::More;

use strict;
use vars qw(@ISA);

require Test::More;
@ISA = qw(Test::More);

sub import {
    my $class = shift;
    my $caller = caller;

    my $ret = eval qq{
        package $caller;
        Test::More->import(\@_, import => [qw(!ok !skip !plan)]);
    };

    die $@ if $@;

    return $ret;
}


=head1 NAME

Test::Legacy::More - Test::More wrapper for use with Test::Legacy

=head1 SYNOPSIS

  use Test::Legacy;
  use Test::Legacy::More;

  ...use Test::Legacy and Test::More as normal...

=head1 DESCRIPTION

Both Test::Legacy and Test::More export functions called ok(), skip()
and plan().  When you use them together you have to tell Test::More
not to export those functions.

  use Test::Legacy;
  use Test::More import => [qw(!ok !skip !plan)];

Since the purpose of Test::Legacy is to transition to Test::More it
can be a bit annoying to have to write that all the time.
Test::Legacy::More simply does that work for you.  It loads Test::More
and supresses the exporting of any functions which might conflict with
Test::Legacy.  It otherwise works just like Test::More.


=cut

1;
