package Test::Harness::FileFilter;

use warnings;
use strict;

use File::Spec::Functions qw(splitpath);

use vars qw($VERSION);

$VERSION = '0.01';

my $IgnorePattern = $ENV{HARNESS_IGNORE_FILES} ? qr/$ENV{HARNESS_IGNORE_FILES}/ : undef;
my $AcceptPattern = $ENV{HARNESS_ACCEPT_FILES} ? qr/$ENV{HARNESS_ACCEPT_FILES}/ : undef;

# Replace _run_all_tests from Test::Harness;
{
    require Test::Harness;
    no warnings 'redefine';
    my $orig_func = \&Test::Harness::_run_all_tests;

    *Test::Harness::_run_all_tests = sub {
        my @tests = @_;

        # Always comply to ignore first
        if (defined $IgnorePattern) {
            @tests = grep {
                my (undef, undef, $filename) = splitpath($_);
                $filename !~ $IgnorePattern;
            } @tests;
        }

        # Then continue filter by accepting those matching next
        if (defined $AcceptPattern) {            
            @tests = grep {
                my (undef, undef, $filename) = splitpath($_);
                $filename =~ $AcceptPattern;
            } @tests; 
        }

        # Run original function
        &$orig_func(@tests);
    }
}

1; # End of Test::Harness::FileFilter
__END__
=head1 NAME

Test::Harness::FileFilter - Run only tests whose filename matches a pattern.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

When using Test::Harness::FileFilter with a dist that has a standard distribution Makefile

 # Enable Test::Harness::FileFilter
 export PERL5OPT=${PERL5OPT}:-MTest::Harness::FileFilter

 # Only run 00-load.t, 01-test-function.t etc....
 export HARNESS_ACCEPT_FILES '^\d+(-\w+)+\.t'

 # Run suite
 make test

=head1 DESCRIPTION

Test::Harness::FileFilter is an "extension" to Test::Harness that lets you selectivly
accept or ignore files by matching each filename with an regular expression.

=head1 ENVIRONMENT

=over 12

=item PERL5OPT

Used by perl to include extra command-line switches such as B<-I...> or B<-M...>. This environment variable is used to "load" Test::Harness::FileFilter. It should be set to include B<-MTest::Harness::FileFilter>.

=item HARNESS_IGNORE_FILES

Sets the regexp that will be matched on all files in the set. If it matches, the file is removed from the set.

=item HARNESS_ACCEPT_FILES

Sets the regep that will be matched on all files in the set. If it matches, the file is included in the set.

=back

=head1 CAUTIONARY NOTE

If both I<HARNESS_IGNORE_FILES> and I<HARNESS_ACCEPT_FILES> are defined the set will first be reduced by the "ignore"-regexp and the resulting set will be futher reduced by the "accept"-regexp.

=head1 BUGS

B<Test::Harness::FileFilter> will not work thru I<PERL5OPT> if perl is invoked with B<-T> (taint mode).

=head1 AUTHOR

Claes Jacobsson, C<< <claesjac@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-harness-filefilter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Harness-FileFilter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Claes Jacobsson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut
