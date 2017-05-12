package dtRdr::Config;
$VERSION = eval{require version}?version::qv($_):$_ for(0.1.1);

use warnings;
use strict;
use Carp;

# somebody said "use Universal", so bah
sub import {}

# TODO should we let the plugins loader do this:
#use dtRdr::Config::FileConfig;
#use dtRdr::Config::SQLConfig;
use dtRdr::Config::YAMLConfig;

use Class::Accessor::Classy;
ro 'location';
rw 'library_data';
no  Class::Accessor::Classy;

# TODO break these out into a separate loadable module?
# note:  all the attribs need to be read-only for storage to work unless
# we use a set() method
{
  package dtRdr::ConfigData::LibraryInfo;
  use Class::Accessor::Classy;
  with 'new';
  #ro 'id';
  ro 'intid';
  ro 'uri';
  ro 'type';
  no  Class::Accessor::Classy;
}
{
  package dtRdr::ConfigData::Server;
  use Scalar::Util ();
  use Class::Accessor::Classy;
  with 'new';
  ro 'intid';
  ro 'id';
  ro 'type';
  setter {
    my $self = shift;
    my ($k, $v) = @_;
    ($k eq 'config') and Carp::croak("can't SUPER::set_config");
    $self->{$k} = $v;
    if(my $config = $self->config) {
      $config->update_server($self);
    }
    $v;
  };
  rw 'name';
  rw 'uri';
  rw 'username';
  rw 'password';
  lw 'books';
  ro 'config';
  # TODO last sync?
  no  Class::Accessor::Classy;
  sub set_config {
    my $self = shift;
    my ($config) = @_;
    $self->{config} and Carp::confess("I already have a config object");
    $self->{config} = $config;
    # the auto-update makes a circular ref
    Scalar::Util::weaken($self->{config});
  };
  #sub DESTROY { warn "bye $_[0] ", join("|", keys(%{$_[0]})), "\n"; }
  # XXX TODO XXX Class::Accessor::Classy needs to honor setter() on lists
  foreach my $method (qw(add_books set_books)) {
    my $smethod = 'SUPER::' . $method;
    my $sub = sub {
      my $self = shift;
      my @ans = $self->$smethod(@_);
      if(my $config = $self->config) {
        $config->update_server($self);
      }
      return(@ans);
    };
    no strict 'refs';
    *{__PACKAGE__ . '::' . $method} = $sub;
  }
} # end package

=head1 NAME

dtRdr::Config - configuration storage

=cut

=head1 Factory Methods

=head2 new_from_uri

  my $obj = dtRdr::Config->new_from_uri($file);

=cut

sub new_from_uri {
  my $package = shift;
  my ($file) = @_;

  # TODO allow uri foo:// scheme?
  $file =~ m/\.([^\.]*)$/ or croak("bad filename '$file'");
  my $type = $1;
  $type or croak("type undefined");

  # TODO replace with plugins code?
  my %dispatch = (
    yml  => 'dtRdr::Config::YAMLConfig',
    conf => 'dtRdr::Config::FileConfig',
    remote => sub {
      die "No remote configurations yet";
    },
    db   => 'dtRdr::Config::SQLConfig',
  );

  if(my $res = $dispatch{$type}) {
    ((ref($res) || '') eq 'CODE') and
      return($res->($file));

    $res->can('read_config') or die "incompetent class:  $res";
    my $conf = $res->new();
    $conf->read_config($file);
    return($conf);
  }
  else {
    croak("Invalid configuration type $type");
  }
} # end subroutine new_from_uri definition
########################################################################

=head2 new

  $conf = dtRdr::Config->new($file);

=cut

sub new {
  my $package = shift;
  my $caller = caller;
  if(defined($caller) and $caller->isa(__PACKAGE__)) {
    # being inherited => be a base class
    my $class = ref($package) || $package;
    my $self = {@_};
    bless($self, $class);
    return($self);
  }
  else {
    # being called => be a factory
    return($package->new_from_uri(@_));
  }
} # end subroutine new definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

Dan Sugalski <dan@sidhe.org>

=head1 COPYRIGHT

Copyright (C) 2006-2007 Eric L. Wilhelm, Dan Sugalski, and OSoft, All
Rights Reserved.

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

1;
# vim:ts=2:sw=2:et:sta
