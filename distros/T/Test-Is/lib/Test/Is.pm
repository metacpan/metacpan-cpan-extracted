use strict;
use warnings;
package Test::Is;
$Test::Is::VERSION = '20140823.1';
sub import
{
    shift;
    die "missing arguments for Test::Is" unless @_;

    # TODO: check if a Test::Builder exists. If this is the case,
    # this means we are running too late and this is wrong!

    while (@_) {
	if ($_[0] eq 'interactive') {
	    skip_all($_[0]) if env('NONINTERACTIVE_TESTING');
	} elsif ($_[0] eq 'extended') {
	    skip_all($_[0]) unless env('EXTENDED_TESTING');
        } elsif ($_[0] =~ /^(?:perl[- ])?(v?5\.[0-9.]+)\+?$/) {
            eval "require $1" or skip_all("perl $1");
	} else {
	    die "invalid Test::Is argument";
	}
	shift;
    }
}

sub env
{
    exists $ENV{$_[0]} && $ENV{$_[0]} eq '1'
}


sub skip_all
{
    my $kind = shift;
    print "1..0 # SKIP $kind test";
    exit 0
}

1;

=encoding UTF-8

=head1 NAME

Test::Is - Skip test in a declarative way, following the Lancaster Consensus

=head1 VERSION

version 20140823.1

=head1 SYNOPSIS

I want that this runs only on interactive environments:

    use Test::Is 'interactive';

This test is an extended test: it takes much time to run or may have special
running conditions that may inconvenience a user that just want to install the
module:

    use Test::Is 'extended';

Both:

    use Test::Is 'interactive', 'extended';

This test is only for perl 5.10+:

    use Test::Is 'perl v5.10';
    use feature 'say';
    ...


=head1 DESCRIPTION

This module is a simple way of following the
L<specifications of the environment|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md#environment-variables-for-testing-contexts>
variables available for Perl tests as defined as one of the
"L<Lancaster Consensus|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md>"
at Perl QA Hackathon 2013. Those variables
(C<NONINTERACTIVE_TESTING>, C<EXTENDED_TESTING>) define which tests should be
skipped.

If the environment does not match what the author of the test expected, the
complete test is skipped (in the same way as C<use L<Test::More> skip_all =E<gt>
...>).

As an author, you can also expect that you will automatically benefit of later
evolutions of this specification just by upgrading the module.

As a CPAN toolchain author (CPAN client, smoker...) you may want to ensure at
runtime that the installed version of this module matches the environment
you set yourself.

=head1 SEE ALSO

=over 4

=item *

L<Environment variables for testing contexts|https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md#environment-variables-for-testing-contexts>:
the specification of the Lancaster Consensus.

=item *

L<Test::DescribeMe> by WOLFSAGE, also created at Perl QA Hackathon 2013.

=back

=head1 AUTHOR

Olivier Mengué, L<mailto:dolmen@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2013 Olivier Mengué.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

# vim: set et sw=4 sts=4 :
