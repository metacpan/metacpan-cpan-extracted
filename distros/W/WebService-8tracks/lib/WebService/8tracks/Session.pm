package WebService::8tracks::Session;
use Any::Moose;

=pod

=head1 NAME

WebService::8tracks::Session - 8tracks mix playing session

=head1 SYNOPSIS

  my $session = $api->create_session($mix_id); # start playing mix

  # to start playing
  my $res = $session->play;
  my $media_url = $res->{set}->{track}->{url};
  ...
  # to play next track
  $res = $session->next;
  ...
  # to skip a track
  $res = $session->skip;

  if ($res->{set}->{at_end}) {
      # played all tracks, does not contain URL
      ...
  }

=cut

has 'api', (
    is  => 'rw',
    isa => 'WebService::8tracks',
    required => 1,
);

has 'mix_id', (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has 'play_token', (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has '_started', (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'at_beginning', (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'at_end', (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub update_status {
    my ($self, $res) = @_;

    foreach (qw(at_beginning at_end)) {
        $self->$_(!!$res->{set}->{$_}) if defined $res->{set}->{$_};
    }
}

sub execute {
    my ($self, $command) = @_;

    my $res = $self->api->request_api(
        GET => "sets/$self->{play_token}/$command",
        { mix_id => $self->mix_id },
    );
    $self->update_status($res);
    return $res;
}

=head1 METHODS

=over 4

=item play

  my $res = $session->play;

Start playing.

=cut

sub play {
    my $self = shift;
    $self->_started(1);
    return $self->execute('play');
}

=item next

  my $res = $session->next;

Go to next track. Calls play() if playing is not started.

=cut

sub next {
    my $self = shift;
    if ($self->_started) {
        return $self->execute('next');
    } else {
        $self->_started(1);
        return $self->execute('play');
    }
}

=item skip

  my $res = $session->skip;

Skip to next track.

=back

=cut

sub skip {
    my $self = shift;
    return $self->execute('skip');
}

1;

__END__

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
