package Test::Instance::Apache::Config;

use Moo;
use List::Util qw/ pairs /;
use IO::All;
use namespace::clean;

=head1 NAME

Test::Instance::Apache::Config - Create Apache Config File

=head1 SYNOPSIS

  use FindBin qw/ $Bin /;
  use Test::Instance::Apache::Config;

  my $config_manager = Test::Instance::Apache::Config->new(
    filename => "$Bin/conf/httpd.conf",
    config => [
      PidFile => "$Bin/httpd.pid",
      Include => "$Bin/mods_enabled/*.load",
      Include => "$Bin/mods_enabled/*.conf",
    ],
  );

  $config_manager->write_config;

=head1 DESCRIPTION

Test::Instance::Apache allows you to spin up a complete Apache instance for
testing. This is useful when developing various plugins for Apache, or if your
application is tightly integrated to the webserver.

=head2 Attributes

These are the attributes available to set on a new object.

=head3 filename

The target filename to write the new config file to.

=cut

has filename => ( is => 'ro', required => 1 );

=head3 config

The arrayref to use to create the configuration file

=cut

has config => (
  is => 'ro',
  default => sub { return [] },
);

has _config_string => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->_gen_string( $self->config );
  },
);

sub _gen_string {
  my ( $self, $data, $level ) = @_;

  $level ||= 0;

  return join '', map {
    my ($key, $value) = @$_;
    (ref($value) eq 'ARRAY'
     ? join('',
       (sprintf "<%s>\n", $key),
       $self->_gen_string($value, $level + 1),
       (sprintf "</%s>\n", split( ' ', $key ))
       )
     : ('    ' x $level).$key.' '.$value."\n"
    )
  } pairs @$data;
}

=head2 Methods

=head3 write_config

Write the config to the target filename.

=cut

sub write_config {
  my $self = shift;

  io( $self->filename )->print( $self->_config_string );
}

=head1 AUTHOR

Tom Bloor E<lt>t.bloor@shadowcat.co.ukE<gt>

=head1 COPYRIGHT

Copyright 2016 Tom Bloor

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Test::Instance::Apache>

=item * L<Test::Instance::Apache::Modules>

=back

=cut

1;
