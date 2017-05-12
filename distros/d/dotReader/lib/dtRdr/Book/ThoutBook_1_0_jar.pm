package dtRdr::Book::ThoutBook_1_0_jar;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use base 'dtRdr::Book::ThoutBook_1_0::Base';
use Class::Accessor::Classy;
ro 'zip_obj';
no  Class::Accessor::Classy;

sub TYPE {'Thout_1_0_jar';}
use dtRdr::Book (
  register => {
    types => __PACKAGE__->TYPE,
  },
);
use dtRdr::Logger;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Archive::Zip::MemberRead;
use Cwd ();
use File::Basename ();
use File::Temp ();
use File::Copy ();
use URI::Escape;

=head1 NAME

dtRdr::Book::ThoutBook_1_0_jar - zipped Thout 1.0 book plugin

=head1 SYNOPSIS

This pod needs work.

=cut

=head1 Plugin Methods

=head2 identify_uri

Determine whether the uri appears to be on of ours.

=cut

sub identify_uri {
  my $class = shift;
  my ($filename, $cache) = @_;
  $cache ||= {zip => 0};
  return unless(exists($cache->{zip}));

  ($filename =~ m/\.(?:jar|zip)$/i) or return();

  my $zip = $cache->{zip} || Archive::Zip->new;
  unless($cache->{zip}) {
    # better be a zip file
    $zip->read($filename) == AZ_OK or
      die("'$filename' is not a valid zip file.");
  }

  if($zip->memberNamed('thout_package.properties')) {
    #this is a thout 1.0 package
    RL('#book')->info("identified:  '$filename'");
    return("Thout_1_0_jar", {zip => $zip}); # need to get the cache to new()
  }
  else {
    return(0, {zip => $zip});
  }
} # end subroutine identify_uri definition
########################################################################

=head1 Constructors

=head2 new

  $jbook = dtRdr::Book::ThoutBook_1_0_jar->new();

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = $class->SUPER::new(@_);
  my %defaults = (
    zip_obj => undef,
  );
  foreach my $k (keys(%defaults)) { $self->{$k} = $defaults{$k}; }

  return($self);
} # end subroutine new definition
########################################################################

=head2 load_uri

Loads book from a uri.

  $book->load_uri($uri);

=cut

sub load_uri {
  my $self = shift;
  my ($zip_filename) = @_;
  my $zip = Archive::Zip->new();

  (-e $zip_filename) or die "missing file '$zip_filename'";
  RL('#book')->info("load:  '$zip_filename'");
  die 'read error' unless $zip->read($zip_filename) == AZ_OK;
  return($self->load_from_zip($zip));
} # end subroutine load_uri definition
########################################################################

=head2 load_from_zip

Loads the book from an existing zip object.  This enables optimization
where we reuse the zip object that was created during identification.

  $book->load_from_zip($zip_obj);

=cut

sub load_from_zip {
  my $self = shift;
  my ($zip) = @_;

  eval { $zip->isa('Archive::Zip') } or
    croak(($zip || '(undef)') . ' is not an ' .
      ($@ ? 'object' : 'Archive::Zip object'));

  $self->{zip_obj} = $zip;

  my @xmlfiles = $zip->membersMatching( '.*\.xml' );
  # we should have only one xml file in the archive

  # read file into memory
  $self->set_xml_content($zip->contents($xmlfiles[0])) or
      die "no contents for $xmlfiles[0]";

  $self->{location} = Cwd::abs_path($zip->fileName);
  $self->_to_tempdir($zip);

  return $self->finish_load;
} # end subroutine load_from_zip definition
########################################################################

=head2 _to_tempdir

  $self->_to_tempdir($zip);

=cut

sub _to_tempdir {
  my $self = shift;
  my ($zip) = @_;

  # setup the tempdir
  my $name = ''; # TODO maybe debug based on escape($self->location)
  my $tmp_dir = File::Temp::tempdir(
    'dtrdr-' . $name . '-' . 'X'x8,
    TMPDIR => 1,
    CLEANUP => 1,
    ) . '/';
  RL('#book')->debug('extracting to: ' . $tmp_dir);
  $self->set_base_dir($tmp_dir);

  # dump into tmp_dir
  my $status = $zip->extractTree('', $tmp_dir);
  die "error in extract ($status) $!" unless($status == AZ_OK);
} # end subroutine _to_tempdir definition
########################################################################

=head2 add_to_library

  $book->add_to_library($library);

=cut

sub add_to_library {
  my $self = shift;
  my ($library) = @_;

  my $libdir = $library->directory;
  my $basename = File::Basename::basename($self->location);

  # TODO have the library check this
  my $libname = $libdir . '/' . $basename;
  (-e $libname) and
    croak("library destination $libname already exists");

  File::Copy::copy($self->location, $libdir) or
    die "cannot copy myself to $libdir -- $!";

  # NOTE books which have a faulty toc will stay that way.
  # TODO just externalize the toc or something
  unless($self->toc_is_cached) {
    my $zip = Archive::Zip->new("$libdir/$basename");
    my $unhooked = $self->toc->unhooked;
    require YAML::Syck;
    L->info("YAML");
    my $ystring = YAML::Syck::Dump($unhooked);
    L->info("done");
    my $yfile = 'toc_data.toc';
    $zip->addString(
      $ystring, $yfile
    )->desiredCompressionMethod(COMPRESSION_DEFLATED);

    # TODO run this in a fork?
    # how would that work?  -- I guess it would need to get
    # precreated in a tempfile before this call hits.
    if(0) {
      # NOTE Storable doesn't give us unicode trouble, but YAML does
      require Storable;
      my $sstring = '';
      my $sfile = $yfile . '.stb';
      open(my $sfh, '>', \$sstring);
      # XXX we have a responsiveness problem here
      L->info("Storable");
      Storable::store_fd($unhooked, $sfh);
      L->info("done");
      $zip->addString(
        $sstring, $sfile
      )->desiredCompressionMethod(COMPRESSION_DEFLATED);
    }

    my $prop = $zip->contents('thout_package.properties');
    $prop =~ s/toc_data:[^\n]+[\n]//g;
    $prop .= "\ntoc_data: toc_data.toc\n";
    $prop =~ s/\n+/\n/g;
    $zip->contents('thout_package.properties', $prop);
    L->info("Zip");
    my $status = $zip->overwrite;
    L->info("done");
    die "error writing zip ($status) $!" unless(AZ_OK == $status);
  }

  $library->add_book(
    book_id => $self->id,
    uri     => $basename,
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

  return(defined($self->zip_obj->memberNamed($filepath)));
} # end subroutine member_exists definition
########################################################################

=head2 get_member_string

Returns virtual-file content as string.

  $book->get_member_string($file_path);

=cut

sub get_member_string {
  my $self = shift;
  my ($file_path) = @_;
  return $self->zip_obj->contents($file_path);
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
