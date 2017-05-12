package Percent::Underscore;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;
use Tie::Expression;

sub import {
    untie %_ if tied %_;
    tie %_, 'Tie::Expression';
}

1;

=head1 NAME

Percent::Underscore - let %_ interpolate any expression.

=head1 VERSION

$Id: Underscore.pm,v 0.1 2008/07/01 17:56:27 dankogai Exp dankogai $

=head1 SYNOPSIS

    use Percent::Underscore;
    print "PI = $_{ 4 * atan2(1,1) }.\n";

=head1 DESCRIPTION

This module is just a shothand for C<< tie %_, 'Tie::Expression'; >>.

=head1 SEE ALSO

L<Tie::Expression>

=head1 EXPORT

Nothing.

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-expression at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Expression>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Percent::Underscore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Expression>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Expression>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Expression>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Expression>

=back

=head1 ACKNOWLEDGEMENTS

None so far.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
