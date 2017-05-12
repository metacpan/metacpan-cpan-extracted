package dtRdr::Book::ThoutBook_1_0;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use Carp;

use File::Basename ();
use Cwd ();


=head1 NAME

dtRdr::Book::ThoutBook_1_0 - unpacked ThoutBook reader

=head1 SYNOPSIS

  mkdir foo
  cd foo
  unzip ../mybook.jar

  dotreader mybook.xml

=head1 ABOUT

for authoring

=cut

use base 'dtRdr::Book::ThoutBook_1_0::Base';
sub TYPE {'Thout_1_0';}
use dtRdr::Book (
  register => {
    types => __PACKAGE__->TYPE,
  },
);
use dtRdr::Logger;

# BEGIN {
#   dtRdr::Plugins::add_potential_handler(BOOK_READER, 'Thout_1_0', 'Thout_1_0_simple', \&book_open);
#   dtRdr::Plugins::add_potential_checker(BOOK_ID, "ThoutBook_1_0.pm checker", \&is_a_Thout_1_0_Book);
#
# }

=head1 Class Methods

=head2 identify_uri

  dtRdr::Book::ThoutBook_1_0->identify_uri($uri);

=cut

sub identify_uri {
  my $class = shift;
  my ($filename, $cache) = @_;

  # TODO inspect file contents (dtd?) and maybe surrounding directory
  # is a single XML file enough to make a complete book?
  if($filename =~ m/\.xml$/) {
    (-e File::Basename::dirname($filename) .'/thout_package.properties') or
      L->warn("All your XML are belong to us...");
    return(1);
  }

  return(0);
}

=head1 Constructor

=head2 new

  my $tbook = dtRdr::Book::ThoutBook_1_0->new();

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = $class->SUPER::new(@_);
  my %defaults = (
  );
  foreach my $k (keys(%defaults)) { $self->{$k} = $defaults{$k}; }

  return($self);
} # end subroutine new definition
########################################################################

=head2 load_uri

  $tbook->load_uri($uri);

=cut

sub load_uri {
  my $self = shift;
  my ($filename) = @_;

  (-e $filename) or die "no such file '$filename'";
  {
    open(my $fh, '<', $filename) or die "Can't open $filename, $!/$^E";
    binmode $fh;
    local $/;
    $self->set_xml_content(<$fh>);
  }

  $filename = $self->{location} = Cwd::abs_path($filename);
  $self->set_base_dir(File::Basename::dirname($filename).'/');

  return $self->finish_load;
} # end subroutine load_uri definition
########################################################################

=head2 add_to_library

  $book->add_to_library($library);

=cut

sub add_to_library {
  my $self = shift;
  my ($library) = @_;

  my $dirname = $self->base_dir;
  $dirname or die "no base dir?";
  my $basename = $dirname;
  $basename =~ s#[\\/]+$##;
  $basename = File::Basename::basename($basename);
  $basename or die "cannot make a basename out of $dirname :-(";

  my $libname = $library->directory . '/' . $basename;

  # XXX I guess...
  (-e $libname) and
    croak("library destination $libname already exists");

  # NOTE this won't skip .svn directories, that's not our problem

  mkdir($libname) or die "cannot mkdir $libname $!";
  # WISHLIST:  please write me a cross-platform recursive copy module
  # that just throws exceptions, lets me copy to a non-existent
  # destination name, etc!
  require File::NCopy;
  File::NCopy->new(
    recursive      => 1,
    set_permission => sub {chmod(0700, $_[1]) or die $!},
    )->copy($dirname, $library->directory) or die "copy failed $!";

  unless($self->toc_is_cached) {
    # TODO how to abstract this
    # also TODO rewrite the entire propsheet
    my $unhooked = $self->toc->unhooked;

    # Ick
    my $yfile = "$libname/toc_data.toc";
    require YAML::Syck;
    YAML::Syck::DumpFile($yfile, $unhooked);
    my $sfile = $yfile . '.stb';
    require Storable;
    Storable::store($unhooked, $sfile);

    # Ick x2
    my $propfile = "$libname/thout_package.properties";
    my $prop = do {
      open(my $fh, '<', $propfile) or die " '$propfile' $!";
      local $/;
      <$fh>
    };
    $prop =~ s/toc_data:[^\n]+[\n]//g;
    $prop .= "\ntoc_data: toc_data.toc\n";
    $prop =~ s/\n+/\n/g;
    {
      open(my $fh, '>', $propfile) or die "cannot write '$propfile' $!";
      print $fh $prop;
    }
  }

  $library->add_book(
    book_id => $self->id,
    uri     => $basename . '/' .
      File::Basename::basename($self->location),
    title   => $self->title,
    type    => $self->TYPE,
  );
} # end subroutine add_to_library definition
########################################################################

=head2 member_exists

  my $bool = $book->member_exists($filepath);

=cut

sub member_exists {
  my $self = shift;
  my ($filepath) = @_;

  my $file = $self->base_dir . $filepath;
  return(-e $file);
} # end subroutine member_exists definition
########################################################################

=head2 get_member_string

See L<dtRdr::Book>.

  $book->get_member_string($filepath);

=cut

sub get_member_string {
  my $self = shift;
  my ($filepath) = @_;

  my $file = $self->base_dir . $filepath;
  (-e $file) or croak("no file '$file'");

  open(my $fh, '<', $file);
  local $/;
  return(<$fh>);
} # end subroutine get_member_string definition
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
# vim:sts=2:sw=2:et:sta
