package dtRdr;

use warnings;
use strict;

use Carp;

use File::Spec ();
use File::Basename ();
use Time::HiRes ();

my $start_time = Time::HiRes::time();
# equals the beginning of this module's runtime
# (undef if we're not there yet)
  sub start_time {$start_time};


=head1 NAME

dtRdr::0 - nothing to see here, move along

=head1 SYNOPSIS

This file contains dependency-free bits of the dtRdr package for early
loading in various wacky environments.

=cut


=head2 program_dir

Not for consumption.

A place where we look for internal resources.

The first call will initialize and return the location, latter calls
will just return it.

  dtRdr->program_dir($filename);

=cut

my $app_dir;
sub program_dir {
  my $package = shift;
  my ($filename) = @_;

  defined($app_dir) and return($app_dir);
  defined($filename) or croak("I don't know where I am");

  # must make sure we are running in a par (vs perl -MPAR=foo ...)
  # before changing to PAR_TEMP
  if($ENV{PAR_ARGV_0} and $ENV{'PAR_TEMP'}) {
    $app_dir = $ENV{'PAR_TEMP'} . '/inc/';
  }
  else {
    if(my $location = eval {PerlWrapper->ResourcesPath}) {
      $app_dir = $location;
    }
    elsif(-d $filename) {
      $app_dir = $filename;
    }
    else {
      $app_dir = File::Basename::dirname($filename);
    }
    # TODO is pwd a good enough answer for -e? (shouldn't matter in those cases)
    (-e $app_dir) or die "no app directory: '$app_dir'";
    $app_dir = File::Spec->rel2abs($app_dir);
  }

  $package->_init_data_dir($app_dir);

  return($app_dir);
} # end subroutine program_dir definition
########################################################################

=head2 _init_data_dir

This one is for application data.

  dtRdr->_init_data_dir($app_dir);

=cut

  my $data_dir;
  sub data_dir {$data_dir};
sub _init_data_dir {
  my $package = shift;
  my ($app_dir) = @_;

  $app_dir =~ s#\\#/#g if($^O eq 'MSWin32');
  $app_dir =~ s#/*$#/#; # must have a slash at the end

  $data_dir = $app_dir . 'data/';
} # end subroutine _init_data_dir definition
########################################################################



=head2 program_base

Returns a lowercase version of the program path + basename, up to the
first non-word character.

  dtRdr->program_base;

=cut

my $program_base;
my $app_name;
sub program_base {
  my $package = shift;

  defined($program_base) and return($program_base);

  my $loc = eval{PerlWrapper->BundlePath} || $0;
  my $dir = File::Basename::dirname($loc);
  $loc = File::Basename::basename($loc);

  $app_name = $loc;

  # remove extension and anything else odd
  $loc =~ s/^(\w+).*$/$1/;

  # setup the application name
  if($app_name =~ m/\.pl/) {
    $app_name = 'dotReader';
  }
  else {
    $app_name = $loc;
    $app_name =~ s/_+/ /g;
  }

  #warn "loc is $loc\n";
  $dir =~ s#\\#/#g if($^O eq 'MSWin32');
  $dir =~ s#/*$#/#;
  $loc = $dir . lc($loc);
  return($program_base = $loc);
} # end subroutine program_base definition
########################################################################

=head2 app_name

  $self->app_name;

=cut

sub app_name {
  my $self = shift;

  defined($app_name) and return($app_name);
  $self->program_base; # seed it
  $app_name or croak "could not determine application name";
  return($app_name);
} # end subroutine app_name definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
