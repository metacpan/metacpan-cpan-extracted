package dtRdr;
$VERSION = eval{require version}?version::qv($_):$_ for(0.11.2);

use dtRdr::0; # the rest of this package

use warnings;
use strict;
use Carp;

use dtRdr::Plugins;
use dtRdr::User;
use dtRdr::Logger;
use File::Copy ();

use Class::Accessor::Classy;
rs_c user     => \ (my $set_user) => '';
rw_c user_dir => './';
no  Class::Accessor::Classy;

use constant {
  home_page => 'http://localhost/',
};

=head1 NAME

dtRdr - toplevel data/environment for dotReader

=head1 SYNOPSIS

For the dotReader documentation, see L<dtRdr::doc>.

This module handles the initialization and locations.  It will probably
eventually absorb most of the functionality currently found in the
dtRdr::User modules.

=cut


=head2 init

  dtRdr->init;

=cut

my $reloader;
my $did_init = 0;

sub init {
  my $package = shift;

  # only run once
  if($did_init) {
    # Wouldn't be any reason to make noise, except if we start passing
    # parameters here, I better remind me to fix that. --Eric
    @_ and carp "cannot init";
    return;
  }
  $did_init = 1;

  $package->_init_logger;

  my $user = dtRdr::User->new();
  $user->init_config($package->user_dir . 'drconfig.yml');
  $package->$set_user($user);

  dtRdr::Plugins->init;
  $package->_init_reloader;

} # end subroutine init definition
########################################################################

=head2 plugin_dirs

  my @dirs = dtRdr->plugin_dirs;

=cut

sub plugin_dirs {
  my $package = shift;

  my @dirs;
  foreach my $spot (qw(data_dir user_dir)) {
    my $dirname = $package->$spot . 'plugins';
    push(@dirs, $dirname) if(-e $dirname);
  }
  return(@dirs);
} # end subroutine plugin_dirs definition
########################################################################


=head2 _init_reloader

  dtRdr->_init_reloader

=cut

sub _init_reloader {
  my $package = shift;
  eval { require Module::Refresh };
  $@ and return;
  $reloader = Module::Refresh->new;
} # end subroutine _init_reloader definition
########################################################################

=head2 _init_logger

  dtRdr->_init_logger;

=cut

sub _init_logger {
  my $package = shift;
  my $config = $package->data_dir . 'log.conf';
  unless(-e $config) {
    (-e "$config.tmpl") or die "cannot find '$config' or '$config.tmpl'";
    File::Copy::copy("$config.tmpl", $config);
  }
  dtRdr::Logger->init(filename => $config);
} # end subroutine _init_logger definition
########################################################################

=head2 init_app_dir

In most cases, this should be called before init().

Set app dir to PAR_TEMP (or other various environmentally defined
places) if it exists.

  dtRdr->init_app_dir(__FILE__); # must be next to data/

The app directory is what would typically be found next to the
executable in an installed situation.  It contains things like 'data/'

This call also initializes various other parts of the environment.

=cut

sub init_app_dir {
  my $package = shift;
  my ($filename) = @_;
  # TODO do we need an 'app_dir' accessor?

  my $app_dir = $package->program_dir($filename);

  $package->_init_user_dir;
} # end subroutine init_app_dir definition
########################################################################

=head2 set_user_dir

  dtRdr->set_user_dir($dirname);

=cut

sub set_user_dir {
  my $package = shift;
  my ($dir) = @_;
  $dir =~ s#\\#/#g if($^O eq 'MSWin32');
  $dir ||= './';
  $dir =~ s#/*$#/#;
  $package->SUPER::set_user_dir($dir);
} # end subroutine set_user_dir definition
########################################################################

=head2 _init_user_dir

Uses program_base() to determine where dtRdr->user_dir is.  Currently,
the answer is './' or next to the application.

  dtRdr->_init_user_dir;

The environment variable C<DOTREADER_USER_DIR> can be used to override
this iff it is set at init() time.

Eventually, we'll support the ~/.dotreader/ directory.

=cut

# This might want to go live in the dtRdr::User object instead.

my $did_init_user_dir = 0;
sub _init_user_dir {
  my $package = shift;

  # only DWIM once
  $did_init_user_dir and return;
  $did_init_user_dir = 1;

  if(my $dir = $ENV{DOTREADER_USER_DIR}) {
    return $package->set_user_dir($dir);
  }

  # TODO check ~/.dotreader and such

  my $loc = $package->program_base . '-data';
  unless(-d $loc) { L->warn("no $loc"); return; }

  $package->set_user_dir($loc);
} # end subroutine _init_user_dir definition
########################################################################

=head2 _reload

Reload changed modules.

  dtRdr->_reload;

=cut

sub _reload {
  my $package = shift;

  unless($reloader) {
    RL('#reload')->warn("no reloader available\n ");
    $package->_init_reloader;
    if($reloader) {
      RL('#reload')->info("we reloaded ourselves");
      $package->_reload;
    }
    return;
  }
  # XXX 'no warnings' doesn't actually work

  # oh well.  If it's really a problem, let's grab stderr and filter it
  no warnings qw(redefine);
  local $SIG{__WARN__};
  $reloader->refresh;
  RL('#reload')->info('reloaded');
} # end subroutine _reload definition
########################################################################

=head2 release_number

  dtRdr->release_number;

=cut

sub release_number {
  my $package = shift;
  my $file = $package->data_dir . 'dotreader_release';
  (-e $file) or return('UNKNOWN');
  open(my $fh, '<', $file);
  # TODO make that a YAML file
  my $number = <$fh>;
  chomp($number);
  return($number);
} # end subroutine release_number definition
########################################################################

=head2 first_time

Returns true if this is the first time the app has been run.

  dtRdr->first_time;

=cut

sub first_time {
  my $package = shift;
  my $file = $package->user_dir . 'first_time';
  if(-e $file) {
    warn "look at $file";
    return(unlink($file));
  }
  return(0);
} # end subroutine first_time definition
########################################################################

=head2 get_LICENSE

  my $text = dtRdr->get_LICENSE;

=cut

sub get_LICENSE {
  my $package = shift;
  return($package->_get_THIS('LICENSE'));
} # end subroutine get_LICENSE definition
########################################################################

=head2 get_COPYING

  my $text = dtRdr->get_COPYING;

=cut

sub get_COPYING {
  my $package = shift;
  return($package->_get_THIS('COPYING'));
} # end subroutine get_COPYING definition
########################################################################

=head2 _get_THIS

  dtRdr->_get_THIS('LICENSE|COPYING');

=cut

sub _get_THIS {
  my $package = shift;
  my ($THIS) = @_;

  # TODO class data for caching
  my $file = $package->data_dir . $THIS;
  my $text;
  unless(-e $file) {
    if(-e $THIS) { # fallback to current directory
      $file = $THIS;
    }
    else {
      $text = <<"        ---";
        Your copy of this software appears to be without a $THIS file.
        This is against the terms of distribution.  Please report this
        infringement at http://dotreader.com/
        ---
      $text =~ s/^\s+//mg;
      return($text);
    }
  }
  open(my $fh, '<', $file) or die "failed to read $file $!";
  local $/;
  return(<$fh>);
} # end subroutine _get_THIS definition
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
