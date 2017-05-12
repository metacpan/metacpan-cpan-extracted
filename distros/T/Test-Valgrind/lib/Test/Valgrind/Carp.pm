package Test::Valgrind::Carp;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Carp - Carp-like private methods for Test::Valgrind objects.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class only provides a C<_croak> method that lazily requires L<Carp> and then croaks with the supplied message.

The class should not be used outside from L<Test::Valgrind> and may be removed without notice.

=cut

sub _croak {
 shift;
 require Carp;
 local $Carp::CarpLevel = ($Carp::CarpLevel || 0) + 1;
 Carp::croak(@_);
}

=head1 SEE ALSO

L<Test::Valgrind>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Carp

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Carp
