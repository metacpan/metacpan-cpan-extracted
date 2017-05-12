package dtRdr::Config::YAMLConfig;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.2);

use warnings;
use strict;
use Carp;


use base 'dtRdr::Config';
use dtRdr::Config (
  register => {
    type => 'YAMLConfig'
  },
);
use constant type => 'YAMLConfig'; # needs to go away when plugins work?

use YAML::Syck qw(
  LoadFile
  DumpFile
);

use Class::Accessor::Classy;
ls servers => \ (my $set_servers), add => \ (my $add_servers);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::Config::YAMLConfig - a config file

=head1 SYNOPSIS

=cut

=head1 ConfigData Items

ConfigData::* items (such as the result of libraries() or servers()
methods) are now persistent and linked to the config.  If the data item
has a config attribute, it will auto-update on disk when any set_foo()
methods are called on it.

=head1 Methods

=head2 new

Constructor.

=head2 create

Create a new file.

  dtRdr::Config::YAMLConfig->create($filename);

=cut

sub create {
  my $package = shift;
  my ($file) = @_;
  my %data = (
    version      => $package->VERSION . '', # ensure stringification
    user_info    => {},
    module       => [], # XXX probably not
    book_handler => {}, # XXX doubtful
    library      => [],
    servers      => [],
  );
  DumpFile($file, \%data);
} # end subroutine create definition
########################################################################

########################################################################
# accessors for yaml bits
foreach my $item (qw(library servers)) {
  my $subref = eval("sub { \$_[0]->{yml}{$item};}");
  $@ and die;
  no strict 'refs';
  *{'_y' . $item} = $subref;
}
########################################################################


=head2 read_config

  $conf->read_config($uri);

=cut

sub read_config {
  my $self = shift;
  my ($filename) = @_;

  if (!-e $filename) {
    $self->create($filename);
  }

  $self->{location} = $filename;
  $self->_load;

  # TODO do them all like this?
  my $S = $self->_yservers;
  $self->$set_servers(map({
    my $s = dtRdr::ConfigData::Server->new(
      %{$S->[$_]},
      intid  => $_,
    );
    $s->set_config($self);
    $s
  } 0..$#$S));

} # end subroutine read_config definition
########################################################################

=head2 _dump

  $self->_dump;

=cut

sub _dump {
  my $self = shift;
  DumpFile($self->location, $self->{yml});
} # end subroutine _dump definition
########################################################################

=head2 _load

  $self->_load;

=cut

sub _load {
  my $self = shift;
  $self->{yml} = LoadFile($self->location);
} # end subroutine _load definition
########################################################################

=head2 add_library

  my $intid = $conf->add_library($library_info);

=cut

sub add_library {
  my $self = shift;
  my ($lib) = @_;

  my %data = %$lib;

  my $L = $self->_ylibrary;
  if(defined(my $intid = delete($data{intid}))) {
    ($intid == @$L) or croak("cannot use intid '$intid'");
  }

  exists($data{$_}) or croak("must have field $_") for(qw(uri type));
  my $v = push(@$L, \%data) - 1;

  # TODO set an update callback in the library

  $self->_dump;
  return($v);
} # end subroutine add_library definition
########################################################################

=head2 libraries

  $conf->libraries;

=cut

sub libraries {
  my $self = shift;

  my $L = $self->_ylibrary;
  # TODO set config callbacks in those
  return(map({
    dtRdr::ConfigData::LibraryInfo->new(%{$L->[$_]}, intid => $_)
  } 0..$#$L));
} # end subroutine libraries definition
########################################################################

=head2 add_server

  my $intid = $conf->add_server($server_obj);

=cut

sub add_server {
  my $self = shift;
  my ($server) = @_;

  my $S = $self->_yservers;
  my %data = %$server;
  delete($data{intid});
  delete($data{config});
  my $v = push(@$S, \%data) - 1;

  # set config props
  $server->{intid} = $v;
  $server->set_config($self);

  $self->_dump;
  return($v);
} # end subroutine add_server definition
########################################################################

=head2 update_server

  $conf->update_server($server_obj);

=cut

sub update_server {
  my $self = shift;
  my ($server) = @_;

  my $S = $self->_yservers;
  my %data = %$server;
  my $n = delete($data{intid});
  delete($data{config});
  $S->[$n]{id} eq $data{id} or die "not the right server";
  $S->[$n] = \%data;
  $self->_dump;
} # end subroutine update_server definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
