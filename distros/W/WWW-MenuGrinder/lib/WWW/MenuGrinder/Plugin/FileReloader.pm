package WWW::MenuGrinder::Plugin::FileReloader;
BEGIN {
  $WWW::MenuGrinder::Plugin::FileReloader::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin to reload the menu when a file changes.

use Moose;

with 'WWW::MenuGrinder::Role::OnInit';
with 'WWW::MenuGrinder::Role::BeforeMogrify';

# New versions of Time::HiRes give us subsecond times on stat(). Use it if we
# can just in case we find ourselves racing against two crazy-fast updates.
BEGIN {
  eval {
    require Time::HiRes;
    Time::HiRes->import(qw(stat));
  };
}

has filename => (
  is => 'rw',
);

has timestamp => (
  is => 'rw'
);

sub on_init {
  my ($self) = @_;
  my $time = (stat $self->filename)[9];
  $self->timestamp( $time ) if defined $time;
}

sub before_mogrify {
  my ($self) = @_;

  my $time = (stat $self->filename)[9];

  # It seems odd that we're not setting $self->timestamp here but our on_init
  # is about to get called anyway...
  if (defined $time and $time > $self->timestamp) {
    $self->grinder->init_menu;
  }

  return $self->grinder->menu;

}

sub BUILD {
  my ($self) = @_;

  my $filename = $self->grinder->config->{filename};
  die "config->{filename} is required" unless defined $filename;

  $self->filename($filename);
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::FileReloader - WWW::MenuGrinder plugin to reload the menu when a file changes.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::FileReloader> is a plugin for C<WWW::MenuGrinder>.
You should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

When loaded, this plugin will automatically reload the menu file whenever its
modification time changes.

=head2 Configuration

C<FileReloader> reads the key C<filename> in the global configuration.

=head2 Other Considerations

C<FileReloader> should be loaded before all other plugins, except for the
C<Loader> plugin, to avoid surprises.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

