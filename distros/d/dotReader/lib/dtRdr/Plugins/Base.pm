package dtRdr::Plugins::Base;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use Carp;


=head1 NAME

dtRdr::Plugins::Base - base class for plugin backends

=head1 SYNOPSIS

  use base 'dtRdr::Plugins::Base';

=cut

use constant {
  DEBUG => ($ENV{PLUGINS_DEBUG} || 0),
};

my %p_classes; # plugin classes (e.g. "dtRdr::Plugins::Book")
my %p_data;    # data store
my %did_init;

=head2 init

  dtRdr::Plugins::Foo->init();

=cut

sub init {
  my $self = shift;
  $self eq __PACKAGE__ and croak("cannot call me directly");
  (@_ % 2) and croak('odd number of elements in argument list');
  my %args = @_;
  # TODO take a config object

  return() if($did_init{$self}); # TODO reset() method

  # initialize the class list and data store
  $p_classes{$self} ||= [];
  $p_data{$self}    ||= {};

  DEBUG and warn "init for $self";
  my @loaded;
  # find all of our plugins
  foreach my $mod ($self->plugins) {
    DEBUG and warn "found $mod";
    # check that it isn't loaded
    unless(eval {$mod->isa('UNIVERSAL')}) {
      DEBUG and warn "use $mod";
      eval "require $mod";
      if($@) {
        warn 'REQUIRE ERROR:  ', " ($mod) ", $@;
        next;
      }
    }

    # mod should have registered some stuff?
    DEBUG and warn "loaded $mod v", $mod->VERSION || '-' ,
      " in ", __PACKAGE__, "\n";

    push(@loaded, $mod);
  }
  return(@loaded);
} # end subroutine init definition
########################################################################

=head2 add_class

Add a class to the Foo plugins registry.

  dtRdr::Plugins::Foo->add_class(class => 'dtRdr::Foo::Bar', %opts);

=cut

sub add_class {
  my $package = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my %args = @_;

  my $class = $args{class};
  $class or croak("must have class => 'Your::Class' argument");
  $p_classes{$package} ||= [];
  DEBUG and warn 'classes for ' . $package . ':' .
    join(", ", @{$p_classes{$package}});
  push(@{$p_classes{$package}}, $class);
} # end subroutine add_class definition
########################################################################

=head2 get_classes

Get the list of registered classes.

  my @classes = dtRdr::Plugins::Foo->get_classes;

=cut

sub get_classes {
  my $self = shift;

  return(@{$p_classes{$self}});
} # end subroutine get_classes definition
########################################################################

=head2 init_data

Initialize plugin data for a given class.

  my $data = dtRdr::Plugins::Foo->init_data($key, $val);

=cut

sub init_data {
  my $class = shift;
  my ($key, $val) = @_;
  # TODO just use class accessors here?
  defined($p_data{$class}{$key}) and return($p_data{$class}{$key});
  return($p_data{$class}{$key} = $val);
} # end subroutine init_data definition
########################################################################

=head2 get_data

  dtRdr::Plugins::Foo->get_data($key);

=cut

sub get_data {
  my $self = shift;
  my ($key) = @_;
  return($p_data{$self}{$key});
} # end subroutine get_data definition
########################################################################

=head2 set_data

  dtRdr::Plugins::Foo->set_data();

=cut

sub set_data {
  my $self = shift;
  my ($key, $val) = @_;
  return($p_data{$self}{$key} = $val);
} # end subroutine set_data definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

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
