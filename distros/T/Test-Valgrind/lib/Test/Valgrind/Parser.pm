package Test::Valgrind::Parser;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Parser - Base class for Test::Valgrind parsers.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class is the base for L<Test::Valgrind> parsers.

=cut

use base qw<Test::Valgrind::Component Test::Valgrind::Carp>;

=head1 METHODS

=head2 C<new>

    my $tvp = Test::Valgrind::Parser->new;

The parser constructor, called without arguments.

Defaults to L<Test::Valgrind::Component/new>.

=head2 C<start>

    $tvp->start($session);

Called when the C<$session> starts.

Defaults to set L<Test::Valgrind::Component/started>.

=head2 C<args>

    my @args = $tvp->args($session, $fh);

Returns the list of parser-specific arguments that are to be passed to the C<valgrind> process spawned by the session C<$session> and whose output will be captured by the filehandle C<$fh>.

Defaults to the empty list.

=cut

sub args { }

=head2 C<parse>

    my $aborted = $tvp->parse($session, $fh);

Parses the output of the C<valgrind> process attached to the session C<$session> received through the filehandle C<$fh>.
Returns true when the output indicates that C<valgrind> has aborted.

This method must be implemented when subclassing.

=cut

sub parse;

=head2 C<finish>

    $tvp->finish($session);

Called when the C<$session> finishes.

Defaults to clear L<Test::Valgrind::Component/started>.

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Component>, L<Test::Valgrind::Session>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Parser

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Parser
