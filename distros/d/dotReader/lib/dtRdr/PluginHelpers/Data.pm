package dtRdr::PluginHelpers::Data;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use YAML::Syck ();
use File::Spec (); use constant {fs => 'File::Spec'};

=head1 NAME

dtRdr::PluginHelpers::Data - DATA_DIR and FIND_FILE class methods

=head1 SYNOPSIS

  use dtRdr::PluginHelpers::Data qw(DATA_DIR);

  ...
  my $dirname = __PACKAGE__->DATA_DIR;

or

  sub foo {
    my $self = shift;

    my $dir = $self->DATA_DIR;
    ...
  };

=cut

BEGIN {
  use Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT_OK = qw(
    DATA_DIR
    FIND_FILE
    load_yml_files
    fs
  );
}


=head2 DATA_DIR

  my $dirname = YourPackage->DATA_DIR;

=cut

sub DATA_DIR {
  my $package = shift;

  my $fname = (caller())[1];
  (-e $fname) or die "no such file '$fname'";
  # TODO return the first of a list of what exists?
  return($fname . '.DATA/');
} # end subroutine DATA_DIR definition
########################################################################

=head2 FIND_FILE

  my $filename = YourPackage->FIND_FILE($basename);

=cut

sub FIND_FILE {
  my $package = shift;
  die "not done";
  # basically, just run through some list of directories (like
  # dtRdr->user_dir, etc?)
} # end subroutine FIND_FILE definition
########################################################################

=head2 load_yml_files

Load all of the *.yml files from a directory.  Returns a hash keyed by
filename.

  my %file_info = YourPackage->load_yml_files($directory);

=cut

sub load_yml_files {
  my $package = shift;
  my ($dir) = @_;

  (-d $dir) or die "directory '$dir' does not exist";

  opendir(my $dh, $dir) or die "cannot open $dir ($!)";
  my @files = grep(/\.yml$/, readdir($dh));
  my %out;
  foreach my $file (@files) {
    my $fname = File::Spec->catfile($dir, $file);
    my $data = YAML::Syck::LoadFile($fname);
    $out{$file} = $data;
  }
  return(%out);
} # end subroutine load_yml_files definition
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
