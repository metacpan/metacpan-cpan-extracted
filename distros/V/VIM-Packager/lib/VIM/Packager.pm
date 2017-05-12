package VIM::Packager;
use warnings;
use strict;
use Exporter::Lite;
our @EXPORT = qw(say);
sub say { print @_ , "\n" }

=head1 NAME

VIM::Packager

=cut

our $VERSION = 2010.03218 ;

=head1 SYNOPSIS

    use VIM::Packager;

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut

=head1 REPOSITORY 

L<http://github.com/c9s/vim-packager>

=head1 AUTHOR

Cornelius(c9s), C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vim-packager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VIM-Packager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VIM::Packager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VIM-Packager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VIM-Packager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VIM-Packager>

=item * Search CPAN

L<http://search.cpan.org/dist/VIM-Packager/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of VIM::Packager
