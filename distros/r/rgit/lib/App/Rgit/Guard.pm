package App::Rgit::Guard;

use strict;
use warnings;

=head1 NAME

App::Rgit::Guard - Scope guard helper for App::Rgit.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

This class implements a simple scope guard object.

This is an internal module to L<rgit>.

=head1 METHODS

=head2 C<new $callback>

Creates a new C<App::Rgit::Guard> object that will call C<$callback> when it is destroyed.

=cut

sub new {
 my $class = shift;
 $class = ref $class || $class;

 bless \($_[0]), $class;
}

=head2 C<DESTROY>

Invokes the callback when the guard object goes out of scope.

=cut

sub DESTROY { ${$_[0]}->() }

=head1 SEE ALSO

L<rgit>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Guard

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Guard
