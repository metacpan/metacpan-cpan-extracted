package Test::Valgrind::Parser::XML;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Parser::XML - Parse valgrind output as an XML stream.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This is a base class for L<Test::Valgrind::Parser> objects that can parse C<valgrind>'s XML output.

=cut

use base qw<Test::Valgrind::Parser>;

=head1 METHODS

=head2 C<args>

    my @args = $tvp->args($session, $fh);

Returns the arguments needed to tell C<valgrind> to print in XML to the filehandle C<$fh>.

=cut

sub args {
 my $self = shift;
 my ($session, $fh) = @_;

 my $fd_opt = $session->version >= '3.5.0' ? '--xml-fd=' : '--log-fd=';

 return (
  $self->SUPER::args(@_),
  '--xml=yes',
  $fd_opt . fileno($fh),
 );
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Parser>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Parser::XML

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Parser::XML
