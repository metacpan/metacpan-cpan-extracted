package dtRdr::Plugins;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use Carp;

use Module::Pluggable (
  search_path => ['dtRdr::Plugins'],
  except => [qw(dtRdr::Plugins::Base)],
  inner => 0,
  );


use constant {
  DEBUG => ($ENV{PLUGINS_DEBUG} || 0),
};

=head1 NAME

dtRdr::Plugins - plugin system frontend

=cut

=head2 init

  dtRdr::Plugins->init(config => $config);

=cut

sub init {
  my $self = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my %args = @_;
  # TODO take a config object
  # if it says what modules to load, don't discover, just load them
  # might also say only which ones to *not* load

  DEBUG and warn "dtRdr::Plugins->init";
  # find all of our plugins
  foreach my $mod ($self->plugins) {
    DEBUG and warn "use $mod";
    eval "require $mod";
    if($@) {
      warn 'REQUIRE ERROR:  ', " ($mod) ", $@;
      next;
    }

    # mod should have registered some stuff?
    DEBUG and warn "loaded $mod v", $mod->VERSION || '-' ,
      " in ", __PACKAGE__, "\n";

    unless($mod->can('init')) {
      warn "$mod has no init() method -- skipping";
      next;
    }
    # and then ???
    # XXX maybe breakdown config and feed to children?
    $mod->init(%args);
    DEBUG and warn "loaded $mod v", $mod->VERSION || '-' ,
      " in ", __PACKAGE__, "\n";

  }

} # end subroutine init definition
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

1;
# vim:ts=2:sw=2:et:sta
