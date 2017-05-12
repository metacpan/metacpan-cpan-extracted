package Test::Valgrind::Action::Captor;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Action::Captor - Mock Test::Valgrind::Action for capturing output.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class provides helpers for saving, redirecting and restoring filehandles.

It's not meant to be used directly as an action.

=cut

use File::Spec ();

use base qw<Test::Valgrind::Carp>;

=head1 METHODS

=head2 C<new>

Just a croaking stub to remind you not to use this class as a real action.

=cut

sub new { shift->_croak('This mock action isn\'t meant to be used directly') }

# Widely inspired from Capture::Tiny

sub _redirect_fh {
 open $_[1], $_[2], $_[3]
          or $_[0]->_croak('open(' . fileno($_[1]) . ", '$_[2]', '$_[3]'): $!");
}

sub _dup_fh {
 my $fd = fileno $_[3];
 open $_[1], $_[2] . '&' . $fd
             or $_[0]->_croak('open(' . fileno($_[1]) . ", '$_[2]&', $fd): $!");
}

=head2 C<save_fh>

    $tva->save_fh($from, $mode);
    $tva->save_fh($from, $mode, $to);

Save the original filehandle C<$from> opened with mode C<$mode>, and redirect it to C<$to> if it's defined or to F</dev/null> otherwise.

=cut

sub save_fh {
 my ($self, $from, $mode, $to) = @_;

 unless (defined fileno $from) {
  $self->_redirect_fh($from, $mode, File::Spec->devnull);
  push @{$self->{proxies}}, $from;
 }

 $self->_dup_fh(my $save, $mode, $from);
 push @{$self->{saves}}, [ $save, $mode, $from ];

 if ($to and ref $to eq 'GLOB') {
  $self->_dup_fh($from, $mode, $to);
 } else {
  $self->_redirect_fh($from, $mode, defined $to ? $to : File::Spec->devnull);
 }

 return;
}

=head2 C<restore_all_fh>

    $tva->restore_all_fh;

Restore all the filehandles that were saved with L</save_fh> to their original state.

The redirections aren't closed.

=cut

sub restore_all_fh {
 my ($self) = @_;

 for (@{$self->{saves}}) {
  my ($save, $mode, $from) = @$_;
  $self->_dup_fh($from, $mode, $save);
  close $save or $self->_croak('close(saved[' . fileno($save) . "]): $!");
 }
 delete $self->{saves};

 for (@{$self->{proxies}}) {
  close $_ or $self->_croak('close(proxy[' . fileno($_) . "]): $!");
 }
 delete $self->{proxies};

 return;
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Action>.

L<Capture::Tiny>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Action::Captor

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Action::Captor
