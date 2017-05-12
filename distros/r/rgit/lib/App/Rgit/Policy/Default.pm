package App::Rgit::Policy::Default;

use strict;
use warnings;

use App::Rgit::Utils qw/:codes/;

use base qw/App::Rgit::Policy/;

=head1 NAME

App::Rgit::Policy::Default - The default policy that stops on error.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

This is the default policy.
It stops as soon as a run returned a non-zero status, but continues if it was signalled.

=head1 METHODS

This class inherits from L<App::Rgit::Policy>.

It implements :

=head2 C<handle>

=cut

sub handle {
 my ($policy, $cmd, $conf, $repo, $status, $signal) = @_;

 $status ? LAST : NEXT;
}

=head1 SEE ALSO

L<rgit>.

L<App::Rgit::Policy>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Policy::Default

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Policy::Default
