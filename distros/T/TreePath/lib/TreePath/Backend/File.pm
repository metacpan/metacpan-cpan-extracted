package TreePath::Backend::File;
$TreePath::Backend::File::VERSION = '0.22';

use Moose::Role;
use Config::JFDI;
use YAML qw(LoadFile);
use Carp qw/croak/;

sub _load {
  my $self = shift;

  my $config  = $self->conf;
  my $file    = $config->{$self->configword}->{backend}->{args}->{file}
    or die "'file' is not defined in conf file !";

  $self->_log("Loading tree from file $file");

  # Can not use a arrayref with this, only hashref :(
  # my ($jfdi_h, $jfdi) = Config::JFDI->open($file)
  #    or croak "Error (conf: $file) : $!\n";
  #  return $jfdi->get;

  return LoadFile($file);
}

sub _create {
    my $self = shift;
    my $node = shift;

}

sub _update {
    my $self = shift;
    my $node = shift;

}

sub _delete {
    my $self  = shift;
    my $nodes = shift;

}

=head1 NAME

TreePath::Backend::File - Backend 'File' for TreePath

=head1 VERSION

version 0.22

=head1 CONFIGURATION

See t/conf/treefromfile.yml

         TreePath:
           debug: 0
           backend:
             name: File


=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
