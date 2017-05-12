package dtRdr::Plugins::Book;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

use base 'dtRdr::Plugins::Base';

use Module::Pluggable (
  search_path => ['dtRdr::Book'],
  only => qr/^dtRdr::Book::\w*$/,
  inner => 0, # gotta have it
);


use constant {
  DEBUG => ($ENV{PLUGINS_DEBUG} || 0),
};

=head1 NAME

dtRdr::Plugins::Book - Handle book plugins

=head1 SYNOPSIS

=cut


=head2 init

  dtRdr::Plugins::Book->init(config => $config);

=cut

# see base

=head2 add_class

  dtRdr::Plugins::Book->add_class(%args);

=cut

sub add_class {
  my $self = shift;
  (@_ %2) and croak("odd number of elements in argument hash");
  my %args = @_;

  my $class = delete($args{class});
  $self->SUPER::add_class(class => $class);

  # extract and store registration data
  my $types = $args{type} || $args{types};
  $types or die "$class has no types";
  $types = [$types] unless ref($types);

  my $type_map = $self->init_data('type_map', {});
  foreach my $type (@$types) {
    DEBUG and warn "push $class to map for $type";
    push(@{$type_map->{$type}}, $class);
  }

} # end subroutine add_class definition
########################################################################

=head2 class_for_type

  dtRdr::Plugins::Book->class_for_type($type);

=cut

sub class_for_type {
  my $self = shift;
  my ($type) = @_;
  my $type_map = $self->init_data('type_map', {});
  DEBUG and warn "got ", ($type_map->{$type} || 'nil'), " as map for $type";
  $type_map->{$type} ||= [];
  DEBUG and warn "map: ", join("|", @{$type_map->{$type}});
  my $class = $type_map->{$type}[0];
  return($class);
} # end subroutine class_for_type definition
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
