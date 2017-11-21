package Test::XS::Check;

use strict;
use warnings;

our $VERSION = '0.01';

use Test2::API qw( context );
use XS::Check 0.07;

our @EXPORT_OK = qw( xs_ok );

use Exporter qw( import );

sub xs_ok {
    my $file = shift;

    my $context = context();

    my @errors;
    my $check = XS::Check->new( reporter => sub { push @errors, {@_} } );
    $check->check_file($file);

    $context->ok( !@errors, "XS check for $file" );
    if (@errors) {
        $context->diag("$_->{message} at line $_->{line}") for @errors;
    }
    $context->release;

    return !@errors;
}

1;

# ABSTRACT: Test that your XS files are problem-free with XS::Check

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::XS::Check - Test that your XS files are problem-free with XS::Check

=head1 VERSION

version 0.01

=head2 SYNOPSIS

    use Test2::V0;
    use Test::XS::Check qw( xs_ok );

    xs_ok('path/to/File.xs');

    done_testing();

=head2 DESCRIPTION

This module wraps Ben Bullock's L<XS::Check> module in a test module that you
can incorporate into your distribution's test suite.

=head2 EXPORTS

This module exports one subroutine on request.

=head3 xs_ok($path)

Given a path to an XS file, this subroutine will run that file through
L<XS::Check>. If any XS issues are found, the test fails and the problems are
emitted as diagnostics. If no issues are found, the test passes.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Test-XS-Check/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-XS-Check can be found at L<https://github.com/houseabsolute/Test-XS-Check>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
