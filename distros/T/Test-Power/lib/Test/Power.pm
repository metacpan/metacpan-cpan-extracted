package Test::Power;
use 5.014000;
use strict;
use warnings;

our $VERSION = "0.14";

use parent qw(Exporter);

use Test::More 0.98 ();
use Data::Dumper ();
use Text::Truncate qw(truncstr);
use Devel::CodeObserver 0.11;

use Test::Power::FromLine;

our @EXPORT = qw(expect);

use constant {
    RESULT_VALUE => 0,
    RESULT_OPINDEX => 1,
};

our $DUMP_CUTOFF = 80;

sub expect(&;$) {
    my ($code, $description) = @_;

    my ($package, $filename, $line_no, $line) = Test::Power::FromLine::inspect_line(0);
    $description ||= "L$line_no" . (length($line) ? " : $line" : '');

    my $BUILDER = Test::More->builder;

    my ($retval, $result) = Devel::CodeObserver->new->call($code);

    $BUILDER->ok($retval, $description);

    unless ($retval) {
        for my $pair (@{$result->dump_pairs}) {
            my ($code, $dump) = @$pair;
            $BUILDER->diag("${code}");
            $BUILDER->diag("   => " . truncstr($dump, $DUMP_CUTOFF, '...'));
        }
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Test::Power - With great power, comes great responsibility.

=head1 SYNOPSIS

    use Test::Power;

    sub foo { 4 }
    expect { foo() == 3 };
    expect { foo() == 4 };

Output:

    not ok 1 - L12 : expect { foo() == 3 };
    #   Failed test 'L12 : ok { foo() == 3 };'
    #   at foo.pl line 12.
    # foo()
    #    => 4
    ok 2 - L13 : expect { foo() == 4 };
    1..2
    # Looks like you failed 1 test of 2.

=head1 DESCRIPTION

B<WARNINGS: This module is currently on ALPHA state. Any APIs will change without notice. Notice that since this module uses the B power, it may cause segmentation fault.>

B<WARNINGS AGAIN: Current version of Test::Power does not support ithreads.>

Test::Power is yet another testing framework.

Test::Power shows progress data if it fails. For example, here is a testing script using Test::Power. This test may fail.

    use Test::Power;

    sub foo { 3 }
    expect { foo() == 2 };
    done_testing;

Output is:

    not ok 1 - L6: expect { foo() == 2 };
    # foo()
    #    => 3
    1..1

Woooooooh! It's pretty magical. C<Test::Power> shows the calculation progress! You don't need to use different functions for different testing types, like ok, cmp_ok, is...

=head1 EXPORTABLE FUNCTIONS

=over 4

=item C<< expect(&code) >>

    expect { $foo };

This simply runs the C<&code>, and uses that to determine if the test succeeded or failed.
A true expression passes, a false one fails.  Very simple.

=back

=head1 REQUIRED PERL VERSION

Perl5.14+ is required. 5.14+ provides better support for custom ops.
L<B::Tap> required this. Under 5.14, perl5 can't do B::Deparse.

Patches welcome to support 5.12, 5.10, 5.8.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Test::More>

=cut

