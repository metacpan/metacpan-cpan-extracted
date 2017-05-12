package Treex::PML::Document;

############################################################
#
# FS File
# =========
#
#
use Treex::PML::Schema;
use Carp;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
use URI;
use URI::file;
use Cwd;
use Treex::PML::FSFormat;
use Treex::PML::Backend::FS;
use Treex::PML::Node;
use Treex::PML::Factory;

use Scalar::Util qw(blessed weaken);
use UNIVERSAL::DOES;

=head1 NAME

Treex::PML::Document - Treex::PML class representing a document consisting of a set of trees.

=head1 DESCRIPTION

This class implements a document consisting of a set of trees. The
document may be associated with a FS format and a PML schema and can
contain additional meta data, application data, and user data
(implemented as name/value paris).

For backward compatibility, a the document may also contain data
related with the FS format, e.g. a patterns and tail.

=head1 METHODS

=over 4

=cut

=item Treex::PML::Document->load (filename,\%opts ?)

NOTE: Don't call this method as a constructor directly, use Treex::PML::Factory->createDocumentFromFile() instead!

Load a Treex::PML::Document object from a given file.  If called as a class
method, a new instance is created, otherwise the current instance is
reinitialized and reused. The method returns the instance or dies
(using Carp::croak) if loading fails (unless option C<recover> is set,
see below).

Loading options can be passed as a HASH reference in the second
argument. The following keys are supported:

=over 8

=item backends

An ARRAY reference of IO backend names (previously imported using
C<ImportBackends>). These backends are tried additionally to
Treex::PML::Backend::FS. If not given, the backends previously selected using
C<UseBackends> or C<AddBackends> are used instead.

=item encoding

A name of character set (encoding) to be used by text-based I/O
backends such as Treex::PML::Backend::FS.

=item recover

If true, the method returns normally in case of loading failure, but
sets the global variable C<$Treex::PML::FSError> to the value return value
of C<readFile>, indicating the error.

=back

=cut

sub load {
  my ($class,$filename,$opts) = @_;
  $opts||={};
  my $new=ref($class) ? $class : $class->new();
  # the second arg may/may not be encoding string
  $new->changeEncoding($opts->{encoding}) if $opts->{encoding};
  my $error = $new->readFile($filename,@{$opts->{backends} || \@Treex::PML::BACKENDS});
  if ($opts->{recover}) {
    $Treex::PML::FSError = $error;
    return $new;
  } elsif ($error == 1) {
    croak("Loading file '$filename' failed: no suitable backend!");
  } elsif ($error) {
    croak("Loading file '$filename' failed, possible error: $!");
  } else {
    return $new;
  }
}



# # Treex::PML::Document->newFSFile (filename,encoding?,\@backends)

# This is an obsolete interface for loading a Treex::PML::Document from file.
# It is recommended to use Treex::PML::Document->load() instad. 

# This method retruns the new instance. The value of $Treex::PML::FSError
# contains the return value of $document->readFile and should be used to
# check for errors.

# #

sub newFSFile {
  my ($self,$filename) = (shift,shift);
  my $new=$self->new();
  # the second arg may/may not be encoding string
  $new->changeEncoding(shift) unless ref($_[0]);
  $Treex::PML::FSError=$new->readFile($filename,@_);
  return $new;
}

=pod

=item Treex::PML::Document->new (name?, file_format?, FS?, hint_pattern?, attribs_patterns?, unparsed_tail?, trees?, save_status?, backend?, encoding?, user_data?, meta_data?, app_data?)

Creates and returns a new FS file object based on the given values
(optional). For use with arguments, it is more convenient to use the
method C<create()> instead.

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createDocument() instead!

=cut

sub new {
  my $self = shift;
  if (@_==1 and ref($_[0]) eq 'HASH') {
    return $self->create($_[0]);
  }
  my $class = ref($self) || $self;
  my $new = [];
  bless $new, $class;
  $new->initialize(@_);
  return $new;
}

=pod

=item Treex::PML::Document->new({ argument => value, ... })

or

=item Treex::PML::Document->create({ argument => value, ... })

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createDocument() instead!

Creates and returns a new empty Treex::PML::Document object based on the
given parameters.  This method accepts argument => value pairs as
arguments. The following arguments are available:

name, format, FS, hint, patterns, tail, trees, save_status, backend

See C<initialize> for more details.


=cut

sub create {
  my $self = shift;
  my $args = (@_==1 and ref($_[0])) ? $_[0] : { @_ };
  if (exists $args->{filename}) {
    croak(__PACKAGE__."->create: Unknown parameter 'filename'\n");
  }
  return $self->new(@{$args}{qw(name format FS hint patterns tail trees save_status backend encoding user_data meta_data app_data)});
}


=item $document->clone ($clone_trees)

Create a new Treex::PML::Document object with the same file name, file
format, meta data, FSFormat, backend, encoding, patterns, hint and
tail as the current Treex::PML::Document. If $clone_trees is true,
populate the new Treex::PML::Document object with clones of all trees
from the current Treex::PML::Document.

=cut

sub clone {
  my ($self, $deep)=@_;
  my $fs=$self->FS;
  my $new = ref($self)->create(
			   name => $self->filename,
			   format => $self->fileFormat,
			   FS => $fs->clone,
			   trees => [],
			   backend => $self->backend,
			   encoding => $self->encoding,
			   hint => $self->hint,
			   patterns => [ $self->patterns() ],
			   tail => $self->tail
			  );
  # clone metadata
  if (ref($self->[13])) {
    $new->[13] = Treex::PML::CloneValue($self->[13]);
  }
  if ($deep) {
    @{$new->treeList} = map { $fs->clone_subtree($_) } $self->trees();
  }
  return $new;
}

sub _weakenLinks {
  my ($self) = @_;
  foreach my $tree (@{$self->treeList}) {
    Treex::PML::_WeakenLinks($tree);
  }
}

sub DESTROY {
  my ($self) = @_;
  return unless ref($self);
  # this is not needed if all links are weak
  $_->destroy() for (@{$self->treeList});
  undef @$self;
}

=pod

=item $document->initialize (name?, file_format?, FS?, hint_pattern?, attribs_patterns?, unparsed_tail?, trees?, save_status?, backend?, encoding?, user_data?, meta_data?, app_data?)

Initialize a FS file object. Argument description:

=over 4

=item name (scalar)

File name

=item file_format (scalar)

File format identifier (user-defined string). TrEd, for example, uses
C<FS format>, C<gzipped FS format> and C<any non-specific format> strings as identifiers.

=item FS (FSFormat)

FSFormat object associated with the file

=item hint_pattern (scalar)

hint pattern definition (used by TrEd)

=item attribs_patterns (list reference)

embedded stylesheet patterns (used by TrEd)

=item unparsed_tail (list reference)

The rest of the file, which is not parsed by Treex::PML, i.e. Graph's embedded macros

=item trees (list reference)

List of FSNode objects representing root nodes of all trees in the Treex::PML::Document.

=item save_status (scalar)

File save status indicator, 0=file is saved, 1=file is not saved (TrEd
uses this field).

=item backend (scalar)

IO Backend used to open/save the file.

=item encoding (scalar)

IO character encoding for perl 5.8 I/O filters

=item user_data (arbitrary scalar type)

Reserved for the user. Content of this slot is not persistent.

=item meta_data (hashref)

Meta data (usually used by IO Backends to store additional information
about the file - i.e. other than encoding, trees, patterns, etc).

=item app_data (hashref)

Non-persistent application specific data associated with the file (by
default this is an empty hash reference). Applications may store
temporary data associated with the file into this hash.

=back


=cut

sub initialize {
  my $self = shift;
  # what will we do here ?
  $self->[1] = $_[1];  # file format (scalar)
  $self->[2] = ref($_[2]) ? $_[2] : Treex::PML::Factory->createFSFormat(); # FS format (FSFormat object)
  $self->[3] = $_[3];  # hint pattern
  $self->[4] = ref($_[4]) eq 'ARRAY' ? $_[4] : []; # list of attribute patterns
  $self->[5] = ref($_[5]) eq 'ARRAY' ? $_[5] : []; # unparsed rest of a file
  $self->[6] = UNIVERSAL::isa($_[6],'ARRAY') ?
    Treex::PML::Factory->createList($_[6],1) :
    Treex::PML::Factory->createList(); # trees
  $self->[7] = $_[7] ? $_[7] : 0; # notsaved
  $self->[8] = undef; # storage for current tree number
  $self->[9] = undef; # storage for current node
  $self->[10] = $_[8] ? $_[8] : 'Treex::PML::Backend::FS'; # backend;
  $self->[11] = $_[9] ? $_[9] : undef; # encoding;
  $self->[12] = $_[10] ? $_[10] : {}; # user data
  $self->[13] = $_[11] ? $_[11] : {}; # meta data
  $self->[14] = $_[12] ? $_[12] : {}; # app data

  $self->[15] = undef;
  if (defined $_[0]) {
    $self->changeURL($_[0]);
  } else {
    $self->[0] = undef;
  }
  return ref($self) ? $self : undef;
}

=pod

=item $document->readFile ($filename, \@backends)

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createDocumentFromFile() instead!

Read a document from a given file.  The first argument
must be a file-name. The second argument may be a list reference
consisting of names of I/O backends. If no backends are given, only
the Treex::PML::Backend::FS is used. For each I/O backend, C<readFile> tries to
execute the C<test> function from the appropriate class in the order
in which the backends were specified, passing it the filename as an
argument. The first I/O backend whose C<test()> function returns 1 is
then used to read the file.

Note: this function sets noSaved to zero.

Return values:
   0 - succes
   1 - no suitable backend
  -1 - backend failed

=cut

sub readFile {
  my ($self,$url) = (shift,shift);
  my @backends = UNIVERSAL::isa($_[0],'ARRAY') ? @{$_[0]} : scalar(@_) ? @_ : qw(Treex::PML::Backend::FS);
  my $ret = 1;
  croak("readFile is not a class method") unless ref($self);
  $url =~ s/^\s*|\s*$//g;
  my ($file,$remove_file) = eval { Treex::PML::IO::fetch_file($url) };
  print STDERR "Actual file: $file\n" if $Treex::PML::Debug;
  return -1 if $@;
  foreach my $backend (@backends) {
    print STDERR "Trying backend $backend: " if $Treex::PML::Debug;
    $backend = Treex::PML::BackendCanRead($backend);
    if ($backend &&
	eval {
	  no strict 'refs';
	  &{"${backend}::test"}($file,$self->encoding);
	}) {
      $self->changeBackend($backend);
      $self->changeFilename($url);
      print STDERR "success\n" if $Treex::PML::Debug;
      eval {
	no strict 'refs';
	my $fh;
	print STDERR "calling ${backend}::open_backend\n" if $Treex::PML::Debug;
	$fh = &{"${backend}::open_backend"}($file,"r",$self->encoding);
	&{"${backend}::read"}($fh,$self);
	&{"${backend}::close_backend"}($fh) || warn "Close failed.\n";
      };
      if ($@) {
	print STDERR "Error occured while reading '$url' using backend ${backend}:\n";
	my $err = $@; chomp $err;
	print STDERR "$err\n";
	$ret = -1;
      } else {
	$ret = 0;
      }
      $self->notSaved(0);
      last;
    }
    print STDERR "fail\n" if $Treex::PML::Debug;
#     eval {
#       no strict 'refs';
#       print STDERR "TEST",$backend->can('test'),"\n";
#       print STDERR "READ",$backend->can('read'),"\n";
#       print STDERR "OPEN",$backend->can('open_backend'),"\n";
#       print STDERR "REAL_TEST($file): ",&{"${backend}::test"}($file,$self->encoding),"\n";
#     } if $Treex::PML::Debug;
    if ($@) {
      my $err = $@; chomp $err;
      print STDERR "$err\n";
    }
  }
  if ($ret == 1) {
    my $err = "Unknown file type (all IO backends failed): $url\n";
    $@.="\n".$err;
  }
  if ($url ne $file and $remove_file) {
    local $!;
    unlink $file || warn "couldn't unlink tmp file $file: $!\n";
  }
  return $ret;
}

=pod

=item $document->save ($filename?)

Save Treex::PML::Document object to a given file using the corresponding I/O backend
(see $document->changeBackend) and set noSaved to zero.

=item $document->writeFile ($filename?)

This is just an alias for $document->save($filename).

=cut

sub writeFile {
  my ($self,$filename) = @_;
  return unless ref($self);

  $filename = $self->filename unless (defined($filename) and $filename ne "");
  my $backend=$self->backend || 'Treex::PML::Backend::FS';
  print STDERR "Writing to $filename using backend $backend\n" if $Treex::PML::Debug;
  my $ret;
  #eval {
  no strict 'refs';

  my $fh;
  $backend = Treex::PML::BackendCanWrite($backend) || die "Backend $backend is not loaded or does not support writing\n";
  ($fh=&{"${backend}::open_backend"}($filename,"w",$self->encoding)) || die "Open failed on '$filename' using backend $backend\n";
  $ret=&{"${backend}::write"}($fh,$self) || die "Write to '$filename' failed using backend $backend\n";
  &{"${backend}::close_backend"}($fh) || die "Closing file '$filename' failed using backend $backend\n";
  #};
  #if ($@) {
  #  print STDERR "Error: $@\n";
  #  return 0;
  #}
  $self->notSaved(0) if $ret;
  return $ret;
}

BEGIN {
*save = \&writeFile;
}

=item $document->writeTo (glob_ref)

Write FS declaration, trees and unparsed tail to a given file (file handle open for
reading must be passed as a GLOB reference). Sets noSaved to zero.

=cut

sub writeTo {
  my ($self,$fileref) = @_;
  return unless ref($self);

  my $backend=$self->backend || 'Treex::PML::Backend::FS';
  print STDERR "Writing using backend $backend\n" if $Treex::PML::Debug;
  my $ret;
  eval {
    no strict 'refs';
#    require $backend;
    $ret=$backend->can('write')  && &{"${backend}::write"}($fileref,$self);
  };
  print STDERR "$@\n" if $@;
  return $ret;
}

=pod

=item $document->filename

Return the FS file's file name. If the actual file name is a file:// URL,
convert it to system path and return it. If it is a different type of URL,
return the corresponding URI object.

=cut


#
# since URI::file->file is expensive, we cache the value in $self->[15]
#
# $self->[0] should always be an URI object (if not, we upgrade it)
#
#


sub filename {
  my ($self) = @_;
  return unless $self;

  my $filename = $self->[15]; # cached filename
  if (defined $filename) {
    return $filename
  }
  $filename = $self->[0] or return undef; # URI
  if (!ref($filename)) {
    $self->[15] = undef; # clear cache
    $filename = $self->[0] = Treex::PML::IO::make_URI($filename);
  }
  if ((blessed($filename) and $filename->isa('URI::file'))) {
    return ($self->[15] = $filename->file);
  }
  return $filename;
}

=item $document->URL

Return the FS file's URL as URI object.

=cut


sub URL {
  my ($self) = @_;
  my $filename = $self->[0];
  if ($filename and !(blessed($filename) and $filename->isa('URI'))) {
    $self->[15]=undef;
    return ($self->[0] = Treex::PML::IO::make_URI($filename));
  }
  return $filename;
}

=pod

=item $document->changeFilename (new_filename)

Change the FS file's file name.

=cut


sub changeFilename {
  my ($self,$val) = @_;
  return unless ref($self);
  my $uri =  $self->[0] = Treex::PML::IO::make_abs_URI($val);
  $self->[15]=undef; # clear cache
  return $uri;
}

=item $document->changeURL (uri)

Like changeFilename, but does not attempt to absoultize the filename.
The argument must be an absolute URL (preferably URI object).

=cut


sub changeURL {
  my ($self,$val) = @_;
  return unless ref($self);
  my $url = $self->[0] = Treex::PML::IO::make_URI($val);
  $self->[15]=undef;
  return $url;
}

=pod

=item $document->fileFormat

Return file format identifier (user-defined string). TrEd, for
example, uses C<FS format>, C<gzipped FS format> and C<any
non-specific format> strings as identifiers.

=cut

sub fileFormat {
  my ($self) = @_;
  return ref($self) ? $self->[1] : undef;
}

=pod

=item $document->changeFileFormat (string)

Change file format identifier.

=cut

sub changeFileFormat {
  my ($self,$val) = @_;
  return unless ref($self);
  return $self->[1]=$val;
}

=pod

=item $document->backend

Return IO backend module name. The default backend is Treex::PML::Backend::FS, used
to save files in the FS format.

=cut

sub backend {
  my ($self) = @_;
  return ref($self) ? $self->[10] : undef;
}

=pod

=item $document->changeBackend (string)

Change file backend.

=cut

sub changeBackend {
  my ($self,$val) = @_;
  return unless ref($self);
  return $self->[10]=$val;
}

=pod

=item $document->encoding

Return file character encoding (used by Perl 5.8 input/output filters).

=cut

sub encoding {
  my ($self) = @_;
  return ref($self) ? $self->[11] : undef;
}

=pod

=item $document->changeEncoding (string)

Change file character encoding (used by Perl 5.8 input/output filters).

=cut

sub changeEncoding {
  my ($self,$val) = @_;
  return unless ref($self);
  return $self->[11]=$val;
}


=pod

=item $document->userData

Return user data associated with the file (by default this is an empty
hash reference). User data are not supposed to be persistent and IO
backends should ignore it.

=cut

sub userData {
  my ($self) = @_;
  return ref($self) ? $self->[12] : undef;
}

=pod

=item $document->changeUserData (value)

Change user data associated with the file. User data are not supposed
to be persistent and IO backends should ignore it.

=cut

sub changeUserData {
  my ($self,$val) = @_;
  return unless ref($self);
  return $self->[12]=$val;
}

=pod

=item $document->metaData (name)

Return meta data stored into the object usually by IO backends. Meta
data are supposed to be persistent, i.e. they are saved together with
the file (at least by some IO backends).

=cut

sub metaData {
  my ($self,$name) = @_;
  return ref($self) ? $self->[13]->{$name} : undef;
}

=pod

=item $document->changeMetaData (name,value)

Change meta information (usually used by IO backends). Meta data are
supposed to be persistent, i.e. they are saved together with the file
(at least by some IO backends).

=cut

sub changeMetaData {
  my ($self,$name,$val) = @_;
  return unless ref($self);
  return $self->[13]->{$name}=$val;
}

=item $document->listMetaData (name)

In array context, return the list of metaData keys. In scalar context
return the hash reference where metaData are stored.

=cut

sub listMetaData {
  my ($self) = @_;
  return unless ref($self);
  return wantarray ? keys(%{$self->[13]}) : $self->[13];
}

=item $document->appData (name)

Return application specific information associated with the
file. Application data are not persistent, i.e. they are not saved
together with the file by IO backends.

=cut

sub appData {
  my ($self,$name) = @_;
  return ref($self) ? $self->[14]->{$name} : undef;
}

=pod

=item $document->changeAppData (name,value)

Change application specific information associated with the
file. Application data are not persistent, i.e. they are not saved
together with the file by IO backends.

=cut

sub changeAppData {
  my ($self,$name,$val) = @_;
  return unless ref($self);
  return $self->[14]->{$name}=$val;
}

=item $document->listAppData (name)

In array context, return the list of appData keys. In scalar context
return the hash reference where appData are stored.

=cut

sub listAppData {
  my ($self) = @_;
  return unless ref($self);
  return wantarray ? keys(%{$self->[14]}) : $self->[13];
}

=pod


=item $document->schema

Return a reference to the associated PML schema (if any).  Note: The
pointer to the schema is stored in the metaData field 'schema'.

=cut

sub schema {
  my($self)=@_;
  return $self->metaData('schema');
}

=item $document->schemaURL

Return URL of the PML schema the document is associated with (if any).
Note that unlike $document->schema->get_url, the URL is not resolved
and is returned exactly as referenced in the document PML header.

Note: The URL is stored in the metaData field 'schema-url'.

=cut

sub schemaURL {
  my($self)=@_;
  return $self->metaData('schema-url');
}

=item $document->changeSchemaURL($newURL)

Return URL of the PML schema the document is associated with (if any).
Note: The URL is stored in the metaData field 'schema-url'.

=cut

sub changeSchemaURL {
  my($self,$url)=@_;
  return $self->changeMetaData('schema-url',Treex::PML::IO::make_URI($url));
}

=item $document->documentRootData()

Return the root data structure of the PML instance (with trees, prolog and epilog taken out)
Note: The URL is stored in the metaData field 'pml_root'.

=cut

sub documentRootData {
  my($self,$url)=@_;
  return $self->metaData('pml_root');
}

=item $document->treesProlog()

Return a sequence of non-tree elements preceding trees in the PML
sequence (with role #TREES) from which trees were extracted (if any).
Note: The prolog is stored in the the metaData field 'pml_prolog'.

=cut

sub treesProlog {
  my($self,$url)=@_;
  return $self->metaData('pml_prolog');
}

=item $document->treesEpilog()

Return a sequence of non-tree elements following trees in the PML
sequence (with role #TREES) from which trees were extracted (if any).
Note: The epilog is stored in the the metaData field 'pml_epilog'.

=cut

sub treesEpilog {
  my($self,$url)=@_;
  return $self->metaData('pml_epilog');
}

=item $document->lookupNodeByID($id)

Lookup a node by its #ID. Note that the ID-hash is created when the
document is loaded (and if not, when first queried), but is not
maintained by this class. It must therefore be maintained by the
application.

=cut

sub lookupNodeByID {
  my ($self,$id)=@_;
  if (defined($id)) {
    return $self->nodeIDHash()->{$id};
  }
  return;
}

=item $document->deleteNodeIDHashEntry($node)

Remove a given node from the ID-hash. Returns the value removed from
the ID hash (note: the function does not check if the entry for the
given node's ID actually was mapped to the given node) or undef if the
node's ID was not hashed.

=cut

sub deleteNodeIDHashEntry {
  my ($self,$node)=@_;
  my $id_hash = $self->appData('id-hash');
  if (ref($id_hash)) {
    my $id =$node->get_id;
    if (defined $id) {
      return delete $id_hash->{$id};
    }
  }
  return undef;
}

=item $document->deleteIDHashEntry($id)

Remove a given ID from the ID-hash. Returns the removed hash entry (or
undef if ID was not hashed).

=cut

sub deleteIDHashEntry {
  my ($self,$id)=@_;
  my $id_hash = $self->appData('id-hash');
  if (ref($id_hash)) {
    return delete $id_hash->{$id};
  }
  return undef;
}


=item $document->hashNodeByID($node)

Hash a node by its #ID. Note that the ID-hash is created when the
document is loaded (and if not, when first queried), but is not
maintained by this class. It must therefore be maintained by the
application.

=cut

sub hashNodeByID {
  my ($self,$node)=@_;
  my $id = $node->get_id;
  if (defined $id) {
    weaken( $self->nodeIDHash()->{$id} = $node );
  }
  return $id;
}

=item $document->nodeIDHash()

Return a hash reference mapping node IDs to node objects.  If the ID
hash did not exist, it is rebuilt. Note: the ID hash, if exists, is
stored in the 'id-hash' appData entry.

=cut

sub nodeIDHash {
  my ($self,$id)=@_;

  my $id_hash = $self->appData('id-hash');
  if (ref($id_hash)) {
    return $id_hash;
  } else {
    return $self->rebuildIDHash();
  }
}

=item $document->hasIDHash()

Returns 1 if the document has an ID-to-node hash map, 0 otherwise.

=cut

sub hasIDHash {
  my ($self)=@_;
  if (ref($self->appData('id-hash'))) {
    return 1;
  } else {
    return 0;
  }
}

=item $document->rebuildIDHash()

Empty and rebuild document's ID-to-node hash.

=cut

sub rebuildIDHash {
  my ($self)=@_;

  my $id_hash = $self->appData('id-hash');
  if (ref($id_hash)) {
    %$id_hash=();
  } else {
    $id_hash = {};
    $self->changeAppData('id-hash',$id_hash);
  }

  my %id_member;
  for my $root ($self->trees) {
    my $node = $root;
    while ($node) {
      my $member = $id_member{$node->type} ||= $node->get_id_member_name;
      if ($member) {
	weaken($id_hash->{ $node->{$member} } = $node);
      }
      $node = $node->following;
    }
  }
  return $id_hash;
}

=item $document->referenceURLHash

Returns a HASHref mapping file reference IDs to URLs.

=cut

sub referenceURLHash {
  my ($self)=@_;
  return $self->metaData('references') || {};
}

=item $document->referenceNameHash

Returns a HASHref mapping file reference names to reference IDs.  Each
value of the hash is either a ID string (if there is just one
reference with a given name) or a L<Treex::PML::Alt> containing all IDs
associated with a given name.

=cut

sub referenceNameHash {
  my ($self)=@_;
  return $self->metaData('refnames') || {};
}

=item $document->referenceObjectHash()

Returns a HASH whose keys are reference IDs and whose values are
either DOM or C<Treex::PML::Instance> representations of the
corresponding related resources.  Unless related tree documents were
loaded with loadRequiredDocuments(), this hash only contains resources
declared as readas='dom' or readas='pml' in the PML schema.


Note: the hash is stored in the document's appData entry 'ref'.

=cut

sub referenceObjectHash {
  my ($self)=@_;
  return $self->appData('ref');
}

=item $document->relatedDocuments()

Returns a list of [id, URL] pairs of related tree documents declared
in the PML schema of this document as C<readas='trees'> (if any).
Note that C<Treex::PML::Document> does not load related tree documents
automatically.

Note: the hash is stored in the document's metaData entry
'fs-require'.

=cut

sub relatedDocuments {
  my ($self)=@_;
  return @{$self->metaData('fs-require') || []};
}


=item $document->loadRelatedDocuments($recurse,$callback)

Loads related tree documents declared in the PML schema of this
document as C<readas='trees'> (if any), unless already loaded. 

Both arguments are optional:

the $recurse argument is a boolean flag indicating whether the
loadRelatedDocuments() should be called on the loaded related
docuemnts as well.

the $calback may contain a callback (anonymouse subroutine) which will
then be invoked before retrieveing a related tree document.  The
callback will receive two arguments; the current $document and an URL of
the related tree document to retrieve.

If the callback returns undef or empty list), the related document
will be retrieved in a standard way (using
C<< Treex::PML::Factory->createDocumentFromFile >>). If it returns a
defined but false value (e.g. 0) the related document will not be
retrieved at all.  If it returns a defined value which is either a
string or an URI object, the related document will be retrieved from
that address. Finally, if the callback returns an object implementing
the C<Treex::PML::Document> interface, the object will be associated
with the current docment.

=cut

sub loadRelatedDocuments {
  my ($self,$recurse,$callback)=@_;
  my @requires = $self->relatedDocuments();
  my $ref = $self->referenceObjectHash();
  my @loaded;
  for my $req (@requires) {
    next if ref($ref->{$req->[0]});
    my $req_URL = Treex::PML::ResolvePath($self->filename,$req->[1]);
    my $req_fs;
    if (ref($callback) eq 'CODE') {
      my $result = $callback->($self,$req_URL);
      if (defined $result) {
	if (!$result) {
	  next;
	} elsif (UNIVERSAL::DOES::does($result,'Treex::PML::Document')) {
	  $req_fs=$result;
	} elsif (blessed($result) and $result->isa('URI')) {
	  $req_URL = $result->as_string;
	} else {
	  $req_URL = $result;
	}
      }
    }
    if (!defined $req_fs) {
      warn "Pre-loading dependent $req_URL ($req->[1]) as appData('ref')->{$req->[0]}\n" if $Treex::PML::Debug;
      $req_fs = Treex::PML::Factory->createDocumentFromFile($req_URL);
    }
    push @loaded,$req_fs;
    my $part_of = $req_fs->appData('fs-part-of');
    if (!ref($part_of)) {
      $part_of = [];
      $req_fs->changeAppData('fs-part-of',$part_of);
    }
    push @$part_of, $self;
    weaken($part_of->[-1]); # we rather weaken the back reference
    $self->appData('ref')->{$req->[0]}=$req_fs;
    push @loaded, $req_fs->loadRelatedDocuments(1,$callback) if $recurse;
  }
  return @loaded;
}

=item $document->relatedSuperDocuments()

Returns a list of C<Treex::PML::Document> objects representing related
superior documents (i.e. documents that loaded the current documents
using loadRelatedDocuments()).

Note: these documents are stored in the document's appData entry
'fs-part-of'.

=cut

sub relatedSuperDocuments {
  my ($self)=@_;
  return @{ $self->appData('fs-part-of')||[] };
}

=item $document->FS

Return a reference to the associated FSFormat object.

=cut

sub FS {
  return $_[0]->[2];
  # my ($self) = @_;
  # return ref($self) ? $self->[2] : undef;
}

=pod

=item $document->changeFS (FSFormat_object)

Associate FS file with a new FSFormat object.

=cut

sub changeFS {
  my ($self,$val) = @_;
  return unless ref($self);
  $self->[2]=$val;
  
  my $enc = $val->special('E');
  if ($enc) {
    $self->changeEncoding($enc);
    delete $val->specials->{E};
  }
  return $self->[2];
}

=pod

=item $document->hint

Return the Tred's hint pattern declared in the Treex::PML::Document.

=cut


sub hint {
  my ($self) = @_;
  return ref($self) ? $self->[3] : undef;
}

=pod

=item $document->changeHint (string)

Change the Tred's hint pattern associated with this Treex::PML::Document.

=cut


sub changeHint {
  my ($self,$val) = @_;
  return unless ref($self);
  return $self->[3]=$val;
}

=pod

=item $document->pattern_count

Return the number of display attribute patterns associated with this Treex::PML::Document.

=cut

sub pattern_count {
  my ($self) = @_;
  return ref($self) ? scalar(@{ $self->[4] }) : undef;
}

=item $document->pattern (n)

Return n'th the display pattern associated with this Treex::PML::Document.

=cut


sub pattern {
  my ($self,$index) = @_;
  return ref($self) ? $self->[4]->[$index] : undef;
}

=item $document->patterns

Return a list of display attribute patterns associated with this Treex::PML::Document.

=cut

sub patterns {
  my ($self) = @_;
  return ref($self) ? @{$self->[4]} : undef;
}

=pod

=item $document->changePatterns (list)

Change the list of display attribute patterns associated with this Treex::PML::Document.

=cut

sub changePatterns {
  my $self = shift;
  return unless ref($self);
  return @{$self->[4]}=@_;
}

=pod

=item $document->tail

Return the unparsed tail of the FS file (i.e. Graph's embedded macros).

=cut


sub tail {
  my ($self) = @_;
  return ref($self) ? @{$self->[5]} : undef;
}

=pod

=item $document->changeTail (list)

Modify the unparsed tail of the FS file (i.e. Graph's embedded macros).

=cut


sub changeTail {
  my $self = shift;
  return unless ref($self);
  return @{$self->[5]}=@_;
}

=pod

=item $document->trees

Return a list of all trees (i.e. their roots represented by FSNode objects).

=cut

## Two methods to work with trees (for convenience)
sub trees {
  my ($self) = @_;
  return ref($self) ? @{$self->treeList} : undef;
}

=pod

=item $document->changeTrees (list)

Assign a new list of trees.

=cut

sub changeTrees {
  my $self = shift;
  return unless ref($self);
  return @{$self->treeList}=@_;
}

=pod

=item $document->treeList

Return a reference to the internal array of all trees (e.g. their
roots represented by FSNode objects).

=cut

# returns a reference!!!
sub treeList {
  my ($self) = @_;
  return ref($self) ? $self->[6] : undef;
}

=pod

=item $document->tree (n)

Return a reference to the tree number n.

=cut

# returns a reference!!!
sub tree {
  my ($self,$n) = @_;
  return ref($self) ? $self->[6]->[$n] : undef;
}


=pod

=item $document->lastTreeNo

Return number of associated trees minus one.

=cut

sub lastTreeNo {
  my ($self) = @_;
  return ref($self) ? $#{$self->treeList} : undef;
}

=pod

=item $document->notSaved (value?)

Return/assign file saving status (this is completely user-driven).

=cut

sub notSaved {
  my ($self,$val) = @_;

  return unless ref($self);
  return $self->[7]=$val if (defined $val);
  return $self->[7];
}

=item $document->currentTreeNo (value?)

Return/assign index of current tree (this is completely user-driven).

=cut

sub currentTreeNo {
  my ($self,$val) = @_;

  return unless ref($self);
  return $self->[8]=$val if (defined $val);
  return $self->[8];
}

=item $document->currentNode (value?)

Return/assign current node (this is completely user-driven).

=cut

sub currentNode {
  my ($self,$val) = @_;

  return unless ref($self);
  return $self->[9]=$val if (defined $val);
  return $self->[9];
}

=pod

=item $document->nodes (tree_no, prev_current, include_hidden)

Get list of nodes for given tree. Returns two value list
($nodes,$current), where $nodes is a reference to a list of nodes for
the tree and current is either root of the tree or the same node as
prev_current if prev_current belongs to the tree. The list is sorted
according to the ordering attribute (obtained from FS->order) and
inclusion of hidden nodes (in the sense of FSFormat's hiding attribute
FS->hide) depends on the boolean value of include_hidden.

=cut

sub nodes {
# prepare value line and node list with deleted/saved hidden
# and ordered by real Ord

  my ($document,$tree_no,$prevcurrent,$show_hidden)=@_;
  my @nodes=();
  return \@nodes unless ref($document);


  $tree_no=0 if ($tree_no<0);
  $tree_no=$document->lastTreeNo() if ($tree_no>$document->lastTreeNo());

  my $root=$document->treeList->[$tree_no];
  my $node=$root;
  my $current=$root;

  while($node) {
    push @nodes, $node;
    $current=$node if ($prevcurrent eq $node);
    $node=$show_hidden ? $node->following() : $node->following_visible($document->FS);
  }

  my $attr=$document->FS->order();
  # schwartzian transform
  if (defined($attr) or length($attr)) {
    use sort 'stable';
    @nodes =
      map { $_->[0] }
      sort { $a->[1] <=> $b->[1] }
      map { [$_, $_->get_member($attr) ] } @nodes;
  }
  return (\@nodes,$current);
}

=pod

=item $document->value_line (tree_no, no_tree_numbers?)

Return a sentence string for the given tree. Sentence string is a
string of chained value attributes (FS->value) ordered according to
the FS->sentord or FS->order if FS->sentord attribute is not defined.

Unless no_tree_numbers is non-zero, prepend the resulting string with
a "tree number/tree count: " prefix.

=cut

sub value_line {
  my ($document,$tree_no,$no_numbers)=@_;
  return unless $document;

  return ($no_numbers ? "" : ($tree_no+1)."/".($document->lastTreeNo+1).": ").
    join(" ",$document->value_line_list($tree_no));
}

=item $document->value_line_list (tree_no)

Return a list of value (FS->value) attributes for the given tree
ordered according to the FS->sentord or FS->order if FS->sentord
attribute is not defined.

=cut

sub value_line_list {
  my ($document,$tree_no,$no_numbers,$wantnodes)=@_;
  return unless $document;

  my $node=$document->treeList->[$tree_no];
  my @sent=();

  my $sentord=$document->FS->sentord();
  my $val=$document->FS->value();
  $sentord=$document->FS->order() unless (defined($sentord));

  # if PML schemas are in use and one of the attributes
  # is an attr-path, we have to use $node->attr(...) instead of $node->{...}
  # (otherwise we optimize and use hash keys).
  if (($val=~m{/} or $sentord=~m{/}) and ref($document->metaData('schema'))) {
    while ($node) {
      my $value = $node->attr($val);
      push @sent,$node
	unless ($value eq '' or
		$value eq '???' or
		$node->attr($sentord)>=999); # this is a PDT-TR specific hack
      $node=$node->following();
    }
    @sent = sort { $a->attr($sentord) <=> $b->attr($sentord) } @sent;
    if ($wantnodes) {
      return (map { [$_->attr($val),$_] } @sent);
    } else {
      return (map { $_->attr($val) } @sent);
    }
  } else {
    while ($node) {
      push @sent,$node 
	unless ($node->{$val} eq '' or
		$node->{$val} eq '???' or
		$node->{$sentord}>=999); # this is a PDT-TR specific hack
      $node=$node->following();
    }
    @sent = sort { $a->{$sentord} <=> $b->{$sentord} } @sent;
    if ($wantnodes) {
      return (map { [$_->{$val},$_] } @sent);
    } else {
      return (map { $_->{$val} } @sent);
    }
  }
}


=pod

=item $document->insert_tree (root,position)

Insert new tree at given position.

=cut

sub insert_tree {
  my ($self,$nr,$pos)=@_;
  splice(@{$self->treeList}, $pos, 0, $nr) if $nr;
  return $nr;
}

=pod

=item $document->set_tree (root,pos)

Set tree at given position.

=cut

sub set_tree {
  my ($self,$nr,$pos)=@_;
  croak('Usage: $document->set_tree(root,pos)') if !ref($nr) or ref($pos);
  $self->treeList->[$pos]=$nr;
  return $nr;
}

=item $document->append_tree (root)

Append tree at given position.

=cut

sub append_tree {
  my ($self,$nr)=@_;
  croak('Usage: $document->append_tree(root,pos)') if !ref($nr);
  push @{$self->treeList},$nr;
  return $nr;
}


=pod

=item $document->new_tree (position)

Create a new tree at given position and return pointer to its root.

=cut

sub new_tree {
  my ($self,$pos)=@_;

  my $nr=Treex::PML::Factory->createNode(); # creating new root
  $self->insert_tree($nr,$pos);
  return $nr;

}

=item $document->delete_tree (position)

Delete the tree at given position and return pointer to its root.

=cut

sub delete_tree {
  my ($self,$pos)=@_;
  my ($root)=splice(@{$self->treeList}, $pos, 1);
  return $root;
}

=item $document->destroy_tree (position)

Delete the tree on a given position and destroy its content (the root and all its descendant nodes).

=cut

sub destroy_tree {
  my ($self,$pos)=@_;
  my $root=$self->delete_tree($pos);
  return  unless $root;
  $root->destroy;
  return 1;
}

=item $document->swap_trees (position1,position2)

Swap the trees on given positions in the tree list.
The positions must be between 0 and lastTreeNo inclusive.

=cut

sub swap_trees {
  my ($self,$pos1,$pos2)=@_;
  my $tree_list = $self->treeList;
  unless (defined($pos1) and 0<=$pos1 and $pos1<=$self->lastTreeNo and
	  defined($pos2) and 0<=$pos2 and $pos2<=$self->lastTreeNo) {
    croak("Fsfile->delete_tree(position1,position2): The positions must be between 0 and lastTreeNo inclusive!");
  }
  return if $pos1 == $pos2;
  my $root1 = $tree_list->[$pos1];
  $tree_list->[$pos1]=$tree_list->[$pos2];
  $tree_list->[$pos2]=$root1;
  return;
}

=item $document->move_tree_to (position1,position2)

Move the tree on position1 in the tree list so that its position after
the move is position2.
The positions must be between 0 and lastTreeNo inclusive.

=cut

sub move_tree_to {
  my ($self,$pos1,$pos2)=@_;
  unless (defined($pos1) and 0<=$pos1 and $pos1<=$self->lastTreeNo and
	  defined($pos2) and 0<=$pos2 and $pos2<=$self->lastTreeNo) {
    croak("Fsfile->delete_tree(position1,position2): The positions must be between 0 and lastTreeNo inclusive!");
  }
  return if $pos1 == $pos2;
  my $root = $self->delete_tree($pos1);
  $self->insert_tree($root,$pos2);
  return $root;
}

=item $document->test_tree_type ( root_type )

This method can be used before a C<insert_tree> or a similar operation
to test if the root node provided as an argument is of a type valid
for this Treex::PML::Document.  More specifically, return 1 if the current file is
not associated with a PML schema or if the tree list represented by
PML list or sequence with the role #TREES permits members of the type
of C<root>.  Otherwise return 0.

A type-declaration object can be passed directly instead of
C<root_type>.

=cut

sub test_tree_type {
  my ($self, $obj) = @_;
  die 'Usage: $document->test_tree_type($node_or_decl)' unless ref($obj);
  my $type = $self->metaData('pml_trees_type');
  return 1 unless $type;
  if (UNIVERSAL::DOES::does($obj,'Treex::PML::Schema::Decl')) {
    if ($obj->get_decl_type == PML_TYPE_DECL) {
      # a named type decl passed, no problem
      $obj = $obj->get_content_decl;
    }
  } else {
    # assume it's a node
    $obj = $obj->type;
    return 0 unless $obj;
  }
  my $type_is = $type->get_decl_type;
  if ($type_is == PML_ELEMENT_DECL) {
    $type = $type->get_content_decl;
    $type_is = $type->get_decl_type;
  } elsif ($type_is == PML_MEMBER_DECL) {
    $type = $type->get_content_decl;
    $type_is = $type->get_decl_type;
  }

  if ($type_is == PML_SEQUENCE_DECL) {
    return 1 if $type->find_elements_by_content_decl($obj);
  } elsif ($type_is == PML_LIST_DECL) { 
    return 1 if $type->get_content_decl == $obj;
  }
}

sub _can_have_children {
  my ($parent_decl)=@_;
  return unless $parent_decl;
  my $parent_decl_type = $parent_decl->get_decl_type;
  if ($parent_decl_type == PML_ELEMENT_DECL()) {
    $parent_decl = $parent_decl->get_content_decl;
    $parent_decl_type = $parent_decl->get_decl_type;
  }
  if ($parent_decl_type == PML_STRUCTURE_DECL()) {
    return 1 if $parent_decl->find_members_by_role('#CHILDNODES');
  } elsif ($parent_decl_type == PML_CONTAINER_DECL()) {
    my $content_decl = $parent_decl->get_content_decl;
    return 1 if $content_decl and $content_decl->get_role eq '#CHILDNODES';
  }
  return 0;
}



=item $document->determine_node_type ( node, { choose_command => sub{...} } )

If the node passed already has a PML type, the type is returned.

Otherwise this method tries to determine and set the PML type of the current
node based on the type of its parent and possibly the node's '#name'
attribute.

If the node type cannot be determined, the method dies.

If more than one type is possible for the node, the method first tries
to run a callback routine passed in the choose_command option (if
available) passing it three arguments: the $document, $node and an ARRAY
reference of possible types. If the callback returns back one of the
types, it is assigned to the node. Otherwise no type is assigned and
the method returns a list of possible node types.

=cut

sub determine_node_type {
  my ($document,$node,$opts)=@_;
  my $type = $node->type;
  return $type if $type;
  my $ntype;
  my @ntypes;
  my $has_children = $node->firstson ? 1 : 0;
  if ($node->parent) {
    # is parent's type known?
    my $parent_decl = $node->parent->type;
    if (ref($parent_decl)) {
      # ok, find #CHILDNODES
      my $parent_decl_type = $parent_decl->get_decl_type;
      my $member_decl;
      if ($parent_decl_type == PML_STRUCTURE_DECL()) {
	($member_decl) = map { $_->get_content_decl } 
	  $parent_decl->find_members_by_role('#CHILDNODES');
      } elsif ($parent_decl_type == PML_CONTAINER_DECL()) {
	$member_decl = $parent_decl->get_content_decl;
	undef $member_decl unless $member_decl and $member_decl->get_role eq '#CHILDNODES';
      }
      if ($member_decl) {
	my $member_decl_type = $member_decl->get_decl_type;
	if ($member_decl_type == PML_LIST_DECL()) {
	  $ntype = $member_decl->get_content_decl;
	  undef $ntype unless $ntype and $ntype->get_role eq '#NODE'
	    and (!$has_children or _can_have_children($ntype));
	} elsif ($member_decl_type == PML_SEQUENCE_DECL()) {
	  my $elements = 
	  @ntypes =
	    grep { !$has_children or _can_have_children($_->[1]) }
	    grep { $_->[1]->get_role eq '#NODE' }
	    map { [ $_->get_name, $_->get_content_decl ] }
	      $member_decl->get_elements;
	  if (defined $node->{'#name'}) {
	    ($ntype) = grep { $_->[0] eq $node->{'#name'} } @ntypes;
	    $ntype=$ntype->[1] if $ntype;
	  }
	} else {
	  die "I'm confused - found role #CHILDNODES on a ".$member_decl->get_decl_path().", which is neither a list nor a sequence...\n";
	}
      }
    } else {
      # ask the user to set the type of the parent first
      die("Parent node type is unknown.\nYou must assign node-type to the parent node first!");
      return;
    }
  } else {
    # find #TREES sequence representing the tree list
    my @tree_types;
    if (ref $document) {
      my $pml_trees_type = $document->metaData('pml_trees_type');
      if (ref $pml_trees_type) {
	@tree_types = ($pml_trees_type);
      } else {
	my $schema = $document->metaData('schema');
	@tree_types = $schema->find_types_by_role('#TREES');
      }
    }
    foreach my $tt (@tree_types) {
      if (!ref($tt)) {
	die("I'm confused - found role #TREES on something which is neither a list nor a sequence: $tt\n");
      }
      my $tt_is = $tt->get_decl_type;
      if ($tt_is == PML_ELEMENT_DECL or $tt_is == PML_MEMBER_DECL or $tt_is == PML_TYPE_DECL) {
	$tt = $tt->get_content_decl;
	$tt_is = $tt->get_decl_type;
      }

      if ($tt_is == PML_LIST_DECL()) {
	$ntype = $tt->get_content_decl;
	undef $ntype unless $ntype and $ntype->get_role eq '#NODE'
	  and (!$has_children or _can_have_children($ntype));
      } elsif ($tt_is == PML_SEQUENCE_DECL()) {
	my $elements =
	  @ntypes =
	    grep { !$has_children or _can_have_children($_->[1]) }
	    grep { $_->[1]->get_role eq '#NODE' }
	    map { [ $_->get_name, $_->get_content_decl ] }
	    $tt->get_elements;
	  if (defined $node->{'#name'}) {
	    ($ntype) = grep { $_->[0] eq $node->{'#name'} } @ntypes;
	    $ntype=$ntype->[1] if $ntype;
	  }
      } else {
	die ("I'm confused - found role #TREES on something which is neither a list nor a sequence: $tt\n");
      }
    }
  }
  my $base_type;
  if ($ntype) {
    $base_type = $ntype;
    $node->set_type($base_type);
  } elsif (@ntypes == 1) {
    $node->{'#name'} = $ntypes[0][0];
    $base_type = $ntypes[0][1];
    $node->set_type($base_type);
  } elsif (@ntypes > 1) {
    my $i = 1;
    if (ref($opts) and $opts->{choose_command}) {
      my $type = $opts->{choose_command}->($document,$node,[@ntypes]);
      if ($type and grep { $_==$type } @ntypes) {
	$node->set_type($type->[1]);
	$node->{'#name'} = $type->[0];
	$base_type=$node->type;
      } else {
	return;
      }
    }
  } else {
    die("Cannot determine node type: schema does not allow nodes on this level...\n");
    return;
  }
  return $node->type;
}

=back

=cut

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Node>, L<Treex::PML::Instance>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
