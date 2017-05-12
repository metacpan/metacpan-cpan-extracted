package App::Rgit::Command::Each;

use strict;
use warnings;

use base qw/App::Rgit::Command/;

use App::Rgit::Guard;
use App::Rgit::Utils qw/:codes/;

=head1 NAME

App::Rgit::Command::Each - Class for commands to execute for each repository.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

Class for commands to execute for each repository.

This is an internal class to L<rgit>.

=head1 METHODS

This class inherits from L<App::Rgit::Command>.

It implements :

=head2 C<run>

=cut

sub run {
 my $self = shift;
 my $conf = shift;

 my $status = 0;
 my $code;

 my $repos = 0;
 my $guard = App::Rgit::Guard->new(sub { $conf->cwd_repo->chdir if $repos });

 for (@{$conf->repos}) {
  $_->chdir or next;
  ++$repos;

  ($status, my $signal) = $_->run($conf, @{$self->args});

  $code = $self->report($conf, $_, $status, $signal) unless defined $code;

  last if $code & LAST;
  if ($code & REDO) {
   undef $code; # Don't save it, that would be very dumb
   redo;
  }
  undef $code unless $code & SAVE;
 }

 return wantarray ? ($status, $code) : $status;
}

=head1 SEE ALSO

L<rgit>.

L<App::Rgit::Command>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Command::Each

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Command::Each
