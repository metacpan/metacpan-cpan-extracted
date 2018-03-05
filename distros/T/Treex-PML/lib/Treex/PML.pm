#
# Revision: $Id: Treex::PML.pm 3044 2007-06-08 17:47:08Z pajas $

# See the bottom of this file for the POD documentation. Search for the
# string '=head'.

# Authors: Petr Pajas, Jan Stepanek
# E-mail: tred@ufal.mff.cuni.cz
#
# Description:
# Several Perl Routines to handle files in treebank FS format
# See complete help in POD format at the end of this file

package Treex::PML;

use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION $API_VERSION %COMPATIBLE_API_VERSION
            $FSError $Debug $resourcePath $resourcePathSplit @BACKENDS);
BEGIN {
$VERSION = "2.24";        # change when new functions are added etc
}


use Data::Dumper;
use Scalar::Util qw(weaken blessed);
use Storable qw(dclone);
use Treex::PML::Document;

use Treex::PML::Factory;
use Treex::PML::StandardFactory;
BEGIN { Treex::PML::StandardFactory->make_default() }
use Treex::PML::IO;
use UNIVERSAL::DOES qw(does);

use strict;


use Treex::PML::Node;

use Exporter;
use File::Spec;
use Carp;
use URI;
use URI::file;

BEGIN {

@ISA=qw(Exporter);

$API_VERSION = "2.0";    # change when internal data structures change,
                         # in a way that may prevent old binary dumps to work properly

%COMPATIBLE_API_VERSION = map { $_ => 1 }
  (
    qw( 1.1 1.2 ),
    $API_VERSION
  );

@EXPORT = qw/&ImportBackends/;
@EXPORT_OK = qw/&Next &Prev &Cut &DeleteLeaf $FSError &Index &SetParent &SetLBrother &SetRBrother &SetFirstSon &Paste &Parent &LBrother &RBrother &FirstSon ResourcePaths FindInResources FindInResourcePaths FindDirInResources FindDirInResourcePaths ResolvePath &CloneValue AddResourcePath AddResourcePathAsFirst SetResourcePaths RemoveResourcePath UseBackends AddBackends Backends /;

$Debug=$ENV{TREEX_PML_DEBUG}||0;
*DEBUG = \$Debug;

$resourcePathSplit = ($^O eq "MSWin32") ? ',' : ':';

$FSError=0;

}




ImportBackends('FS'); # load FS
UseBackends('PML'); # default will be PML

sub Root {
  my ($node) = @_;
  return ref($node) && $node->root;
}
sub Parent {
  my ($node) = @_;
  return ref($node) && $node->parent;
}

sub LBrother ($) {
  my ($node) = @_;
  return ref($node) && $node->lbrother;
}

sub RBrother ($) {
  my ($node) = @_;
  return ref($node) && $node->rbrother;
}

sub FirstSon ($) {
  my ($node) = @_;
  return ref($node) && $node->firstson;
}

sub SetParent ($$) {
  my ($node,$parent) = @_;
  return ref($node) && $node->set_parent($parent);
}
sub SetLBrother ($$) {
  my ($node,$brother) = @_;
  return ref($node) && $node->set_lbrother($brother);
}
sub SetRBrother ($$) {
  my ($node,$brother) = @_;
  return ref($node) && $node->set_rbrother($brother);
}
sub SetFirstSon ($$) {
  my ($node,$son) = @_;
  return ref($node) && $node->set_firstson($son);
}

sub Next {
  my ($node,$top) = @_;
  return ref($node) && $node->following($top);
}

sub Prev {
  my ($node,$top) = @_;
  return ref($node) && $node->previous($top);
}

sub Cut ($) {
  my ($node)=@_;
  return ref($node) && $node->cut;
}

sub Paste ($$$) {
  my $node = shift;
  return $node->paste_on(@_);
}

sub PasteAfter ($$) {
  my $node = shift;
  return $node->paste_after(@_);
}

sub PasteBefore ($$) {
  my $node = shift;
  return $node->paste_before(@_);
}

sub _WeakenLinks {
  my ($node)=@_;
  while ($node) {
    $node->_weakenLinks();
    $node = $node->following();
  }
}

sub DeleteTree ($) {
  my ($top)=@_;
  return $top->destroy();
}

sub DeleteLeaf ($) {
  my ($node) = @_;
  return $node->destroy_leaf();
}


sub CloneValue {
  my ($what,$old,$new)=@_;
  if (ref $what) {
    my $val;
    if (defined $old) {
      $new = $old unless defined $new;
      # work around a bug in Data::Dumper:
      if (UNIVERSAL::can('Data::Dumper','init_refaddr_format')) {
        Data::Dumper::init_refaddr_format();
      }
# Sometimes occurs, that $new->[1] is undef. This bug appeared randomly, due to reimplimentation of hash in perl5.18 (http://perldoc.perl.org/perldelta.html#Hash-overhaul.
# In previous versions it did not appear, thanks to hash order "new->[1]" < "new->[0]"
      my $dump=Data::Dumper->new([$what],
        		                                         ['val'])
	 ->Seen({map { (ref($old->[$_]) 
	                               and defined($new->[$_]) # bugfix
	                              )? (qq{new->[$_]} => $old->[$_]) : () } 0..$#$old})
	 ->Purity(1)->Indent(0)->Dump;
      eval $dump;
      die $@ if $@;
    } else {
#      return Scalar::Util::Clone::clone($what);
      return dclone($what);
#      eval Data::Dumper->new([$what],['val'])->Indent(0)->Purity(1)->Dump;
#      die $@ if $@;
    }
    return $val;
  } else {
    return $what;
  }
}

sub Index ($$) {
  my ($ar,$i) = @_;
  for (my $n=0;$n<=$#$ar;$n++) {
    return $n if ($ar->[$n] eq $i);
  }
  return;
}

sub _is_url {
  return ($_[0] =~ m(^\s*[[:alnum:]]+://)) ? 1 : 0;
}
sub _is_updir {
  my $uri = Treex::PML::IO::make_URI($_[0]);
  return ($uri->path =~  m{(/|^)\.\.($|/)} ? 1 : 0);
}
sub _is_absolute {
  my ($path) = @_;
  return (_is_url($path) or File::Spec->file_name_is_absolute($path));
}

sub FindDirInResources {
  my ($filename)=@_;
  unless (_is_absolute($filename) or _is_updir($filename)) {
    for my $dir (ResourcePaths()) {
      my $f = File::Spec->catfile($dir,$filename);
      return $f if -d $f;
    }
  }
  return $filename;
}
BEGIN{
*FindDirInResourcePaths = \&FindDirInResources;
}

sub FindInResources {
  my ($filename,$opts)=@_;
  my $all = ref($opts) && $opts->{all};
  my @matches;
  unless (_is_absolute($filename) or _is_updir($filename)) {
    for my $dir (ResourcePaths()) {
      my $f = File::Spec->catfile($dir,$filename);
      if (-f $f) {
	return $f unless $all;
	push @matches,$f;
      }
    }
  }
  return ($all or (ref($opts) && $opts->{strict})) ? @matches : $filename;
}

BEGIN {
*FindInResourcePaths = \&FindInResources;
}
sub ResourcePaths {
  return unless defined $resourcePath;
  return wantarray ? split(/\Q${resourcePathSplit}\E/, $resourcePath) : $resourcePath;
}
BEGIN { *ResourcePath = \&ResourcePaths; } # old name

sub AddResourcePath {
  if (defined($resourcePath) and length($resourcePath)) {
    $resourcePath.=$resourcePathSplit;
  }
  $resourcePath .= join $resourcePathSplit,@_;
}

sub AddResourcePathAsFirst {
  $resourcePath = join($resourcePathSplit,@_) . (($resourcePath ne q{}) ? ($resourcePathSplit.$resourcePath) : q{});
}

sub RemoveResourcePath {
  my %remove;
  @remove{@_} = ();
  return unless defined $resourcePath;
  $resourcePath = join $resourcePathSplit, grep { !exists($remove{$_}) }
    split /\Q$resourcePathSplit\E/, $resourcePath;
}

sub SetResourcePaths {
  $resourcePath=join $resourcePathSplit,@_;
}

sub _is_local {
  my ($url) = @_;
  return (((blessed($url) && $url->isa('URI') && (($url->scheme||'file') eq 'file')) or $url =~ m{^file:/}) ? 1 : 0);
}
sub _strip_file_prefix {
  my $url = $_[0]; # ARGUMENT WILL GET MODIFIED
  if (_is_local($url)) {
      $_[0] = Treex::PML::IO::get_filename($url);
      return 1;
  } else {
      return 0;
  }
}

sub ResolvePath ($$;$) {
  my ($base, $href,$use_resources)=@_;

  my $rel_uri = Treex::PML::IO::make_URI($href);
  my $base_uri = Treex::PML::IO::make_abs_URI($base);
  print STDERR "ResolvePath: rel='$rel_uri', base='$base_uri'\n" if $Treex::PML::Debug;
  my $abs_uri = $rel_uri->abs($base_uri);

  if (_is_absolute($rel_uri)) {
    return $rel_uri;
  } elsif (_is_updir($rel_uri)) {
    return _is_url($base) ? $abs_uri : Treex::PML::IO::get_filename($abs_uri);
  } else {
    my $abs_f = Treex::PML::IO::get_filename($abs_uri);
    my $rel_f = Treex::PML::IO::get_filename($rel_uri);
    if (_is_local($base_uri)) {
      if (-f $abs_f) {
	print STDERR "\t=> (LocalURL-relative) result='$abs_f'\n" if $Treex::PML::Debug;
	return _is_url($base) ? $abs_uri : $abs_f;
      } elsif ( not _is_url($base) ) { # base was a filename: try path relative to cwd
	print STDERR "\t=> (cwd-relative) result='$rel_f'\n" if $Treex::PML::Debug;
	return $rel_f if -f $rel_f;
      }
    }
    if ($use_resources) {
      my ($res) = FindInResources($rel_f,{strict=>1});
      if ($res) {
	print STDERR "\t=> (resources) result='$res'\n" if $Treex::PML::Debug;
	return $res;
      }
    }
    print STDERR "\t=> (relative) result='$abs_uri'\n" if $Treex::PML::Debug;
# The following line has been changed. The resources are handled
# lazily, i.e. relative URL is returned on not found files to be
# searched in resources later. Original line:
#   return _is_url($base) ? $abs_uri : $abs_f;
    return _is_local($base) ?  $rel_uri : $abs_uri;
  }
}

sub ImportBackends {
  my @backends=();
  foreach my $backend (@_) {
    print STDERR "LOADING $backend\n" if $Treex::PML::Debug;
    my $b;
    for my $try (_BackendCandidates($backend)) {
      my $file = $try.'.pm';
      $file=~s{::}{/}g;
      if (eval { require $file; } or $::INC{$file}) {
	$b=$backend;
	last;
      }
    }
    if ($b) {
      push @backends,$b;
    } else {
      warn $@ if $@;
      warn "FAILED TO LOAD $backend\n";
    }
  }
  return @backends;
}

sub UseBackends {
  @BACKENDS = ImportBackends(@_);
  return wantarray ? @BACKENDS : ((@_==@BACKENDS) ? 1 : 0);
}

sub Backends {
  return @BACKENDS;
}

sub AddBackends {
  my %have;
  @have{ @BACKENDS } = ();
  my @new = grep !exists($have{$_}), @_;
  my @imported = ImportBackends(@new);
  push @BACKENDS, @imported;
  $have{ @BACKENDS } = ();
  return wantarray ? (grep exists($have{$_}), @_) : ((@new==@imported) ? 1 : 0);
}

sub _BackendCandidates {
  my ($backend)=@_;
  return (
    ($backend=~/:/ ? ($backend) : ()),
    ($backend=~/^([^:]+)Backend$/ ? ('Treex::PML::Backend::'.$1) : ()),
    ($backend=~/^Treex::PML::Backend::/ ? () : 'Treex::PML::Backend::'.$backend),
    ($backend=~/:/ ? () : ($backend)),
   );
}

sub BackendCanRead {
  my ($backend)=@_;
  my $b;
  for my $try (_BackendCandidates($backend)) {
    if (UNIVERSAL::can($try,'open_backend')) {
      $b = $try;
      last;
    }
  }
  return $b if ($b and UNIVERSAL::can($b,'test') and UNIVERSAL::can($b,'read'));
  return;
}

sub BackendCanWrite {
  my ($backend)=@_;
  my $b;
  for my $try (_BackendCandidates($backend)) {
    if (UNIVERSAL::can($try,'open_backend')) {
      $b = $try;
      last;
    }
  }
  return $b if ($b and UNIVERSAL::can($b,'write'));
  return;
}

1;

__END__

=head1 NAME

Treex::PML - Perl implementation for the Prague Markup Language (PML).

=head1 SYNOPSIS

  use Treex::PML;

  my $file="trees.pml";
  my $document = Treex::PML::Factory->createDocumentFromFile($file);
  foreach my $tree ($document->trees) {
     my $node = $tree;
     while ($node) {
       ...  # do something on node
       $node = $node->following; # depth-first traversal
     }
  }
  $document->save();

=head1 INTRODUCTION

This package provides API for manipulating linguistically annotated
treebanks. The module implements a generic data-model of a XML-based
format called PML (L<http://ufal.mff.cuni.cz/jazz/PML/>) and features
pluggable I/O backends and on-the-fly XSLT transformation to support
other data formats.

=head2 About PML

Prague Marup Language (PML) is an XML-based, universally applicable
data format based on abstract data types intended primarily for
interchange of linguistic annotations. It is completely independent of
a particular annotation schema. It can capture simple linear
annotations as well as annotations with one or more richly structured
interconnected annotation layers, dependency or constituency trees. A
concrete PML-based format for a specific annotation is defined by
describing the data layout and XML vocabulary in a special file called
PML Schema and referring to this schema file from individual data
files (instances). The schema can be used to validate the
instances. It is also used by applications to ``understand'' the
structure of the data and to choose optimal in-memory
representation. The generic nature of PML makes it very easy to
convert data from other formats to PML without loss of information.

=head2 History

PML and was developed at the Institute of Formal and Applied
Linguistics of the Charles University in Prague. It was first used in
the Prague Dependency Treebank 2.0 and several other treebanks
since. Conversion tools for various existing treebank formats are
available, too.

This library was originally developed for the TrEd framework
(L<http://ufal.mff.cuni.cz/tred>) and evolved gradually from an
older library called Fslib, implementing an older data format called
FS format L<http://ufal.mff.cuni.cz/pdt2.0/doc/data-formats/fs/index.html>
(this format is still fully supported by the current
implementation).

=head1 DESCRIPTION

Treex::PML provides among other the following classes:

=over 4

=item L<Treex::PML::Factory>

a factory class which delegates object creation to a default factory
class, which can be specified by the user (defaults to
L<Treex::PML::StandardFactory>).  It is important that both user and
library code uses the create methods from L<Treex::PML::Factory> to
create new objects rather than calling constructors from an explicit
object class.

This classical Factory Pattern allows the user to replace the standard
family of C<Treex::PML> classes with customized versions by setting up
a customized factory as default. Then, all objects created by the
Treex::PML library and applications will be from the customized
family.

=item L<Treex::PML::StandardFactory>

the standard factory class.

=item L<Treex::PML::Document>

representing a PML document consisting of a set of trees.

=item L<Treex::PML::Node>

representing a node of a tree (including the root node, which also
represents the whole tree), see
L<Treex::PML::Node/"Representation of trees"> for details.

=item L<Treex::PML::Schema>

representing a PML schema.

=item L<Treex::PML::Instance>

implementing a PML instance.

=item L<Treex::PML::List>

implementing a PML list.

=item L<Treex::PML::Alt>

implementing a PML alternative.

=item L<Treex::PML::Seq>

implementing a PML sequence.

=item L<Treex::PML::Container>

implementing a PML container.

=item L<Treex::PML::Struct>

implementing a PML attribute-value structure.

=item L<Treex::PML::FSFormat>

representing an old-style document format for documents in the FS
format.

=back

=head2 Resource paths

Since some I/O backends require additional resources (such as schemas,
DTDs, configuration files, XSLT stylesheets, dictionaries, etc.), For
this purpose, Treex::PML maintains a list of so called "resource paths"
which I/O backends may conveniently search for their resources.

See L</"PACKAGE FUNCTIONS"> for description of functions related to
pluggable I/O backends and the list resource paths..

=head1 PACKAGE FUNCTIONS

=over 4

=item Treex::PML::does ($thing,$role)

=over 6

=item Parameters

C<$thing>  - any Perl scalar (an object, a reference or a non-reference)

=item Description

This function is an alias for a very useful function
UNIVERSAL::DOES::does(), which does checks if $thing performs the
inteface (role) $role. If the thing is an object or class, it simply
checks $thing->DOES($role) (see C<UNIVERSAL::DOES> or C<UNIVERSAL> in Perl >= 5.10.1).
Otherwise it tells whether the thing can be dereferenced as an array/hash/etc.

Unlike UNIVERSAL::isa(), it is semantically correct to use does for something unknown and to use it for reftype.

This function also handles overloading. For example, does($thing, 'ARRAY') returns true if the thing is an array reference, or if the thing is an object with overloaded @{}.

Using this function (or UNIVERSAL::DOES::does()) is the recommended
method for testing types of objects in the C<Treex::PML> hierarchy
(L<Treex::PML::Node>, C<Treex::PML::Document>, etc.)

=item Returns

In a list context the list of backends sucessfully loaded, in scalar
context a true value if and only if all requested backends were successfully
loaded.

=back

=item Treex::PML::UseBackends (@backends)

=over 6

=item Parameters

C<@backends>  - a list of backend names

=item Description

Demand loading and using the given modules as the initial set of I/O
backends. The initial set of backends is returned by C<Backends()>.
This set is used as the default set of backends by C<<< Treex::PML::Document->load >>>
(unless a different list of backends was specified in a parameter).

=item Returns

In a list context the list of backends sucessfully loaded, in scalar
context a true value if and only if all requested backends were successfully
loaded.

=back

=item Treex::PML::AddBackends (@backends)

=over 6

=item Parameters

C<@backends>  - a list of backend names

=item Description

In a list context the list of already available backends sucessfully loaded, in scalar
context a true value if and only if all requested backends were already available or successfully
loaded.

=item Returns

A list of backends already available or sucessfully loaded.

=back

=item Treex::PML::Backends ()

=over 6

=item Description

Returns the initial set of backends.  This set is used as the default
set of backends by C<<< Treex::PML::Document->load >>>.

=item Returns

A list of backends already available or sucessfully loaded.

=back


=item Treex::PML::BackendCanRead ($backend)

=over 6

=item Parameters

C<$backend>  - a name of an I/O backend

=item Returns

Returns true if the backend provides all methods required for reading.

=back

=item Treex::PML::BackendCanWrite ($backend)

=over 6

=item Parameters

C<$backend>  - a name of an I/O backend

=item Returns

Returns true if the backend provides all methods required for writing.

=back


=item Treex::PML::ImportBackends (@backends)

=over 6

=item Parameters

C<@backends>  - a list of backend names

=item Description

Demand to load the given modules as I/O backends and return a list of
backend names successfully loaded. This list may then passed to Treex::PML::Document
IO calls.

=item Returns

List of names of successfully loaded I/O backends.

=back

=item Treex::PML::CloneValue ($scalar,$old_values?, $new_values?)

=over 6

=item Parameters

C<$scalar>     - arbitrary Perl scalar
C<$old_values> - array reference (optional)
C<$new_values> - array reference (optional)

=item Description

Returns a deep copy of the Perl structures contained
in a given scalar.

The optional argument $old_values can be an array reference consisting
of values (references) that are either to be preserved (if $new_values
is undefined) or mapped to the corresponding values in the array
$new_values. This means that if $scalar contains (possibly deeply
nested) reference to an object $A, and $old_values is [$A], then if
$new_values is undefined, the resulting copy of $scalar will also
refer to the object $A rather than to a deep copy of $A; if
$new_values is [$B], all references to $A will be replaced by $B in
the resulting copy. Note also that the effect of using [$A] as both
$old_values and $new_values is the same as leaving $new_values
undefined.

=item Returns

a deep copy of $scalar as described above

=back

=item Treex::PML::ResourcePaths ()

Returns the current list of directories used by Treex::PML to search for
resources.

=item Treex::PML::SetResourcePaths (@paths)

=over 6

=item Parameters

C<@paths> - a list of a directory paths

=item Description

Specify the complete set of directories to be used by Treex::PML when
looking up resources.

=back

=item Treex::PML::AddResourcePath (@paths)

=over 6

=item Parameters

C<@paths> - a list of directory paths

=item Description

Add given paths to the end of the list of directories searched by
Treex::PML for resources.

=back

=item Treex::PML::AddResourcePathAsFirst (@paths)

=over 6

=item Parameters

C<@paths> - a list of directory paths

=item Description

Add given paths to beginning of the list of directories
searched for resources.

=back

=item Treex::PML::RemoveResourcePath (@paths)

=over 6

=item Parameters

C<@paths> - a list of directory paths

=item Description

Remove given paths from the list of directories searched for
resources.

=back

=item Treex::PML::FindInResourcePaths ($filename, \%options?)

=over 6

=item Parameters

C<$filename> - a relative path to a file

=item Description

If a given filename is a relative forward path (e.g. containing no
up-dir '..' directory parts) of a file found in the resource paths,
return:

If the option 'all' is true, a list of absolute paths to all
occurrences found (may be empty).

If the option 'strict' is true, an absolute path to the first
occurrence or an empty list if there is no occurrence of the file in the resource paths.

Otherwise act as with 'strict', but return unmodified C<$filename> if
no occurrence is found.

If C<$filename> is an absolute path, it is always returned unmodified
as a single return value.

Options are passed in an optional second argument as key-value pairs
of a HASH reference:

  FindInResources($filename, {
    # 'strict' => 0 or 1
    # 'all'    => 0 or 1
  });

=back

=item Treex::PML::FindInResources ($filename)

Alias for C<FindInResourcePaths($filename)>.

=item Treex::PML::FindDirInResourcePaths ($dirname)

=over 6

=item Parameters

C<$dirname> - a relative path to a directory

=item Description

If a given directory name is a relative path of a sub-directory
located in one of resource directories, return an absolute path for
that subdirectory. Otherwise return dirname.

=back

=item Treex::PML::FindDirInResources ($filename)

Alias for C<FindDirInResourcePaths($filename)>.

=item Treex::PML::ResolvePath ($ref_filename,$filename,$search_resource_path?)

=over 6

=item Parameters

C<$ref_path> - a reference filename

C<$filename> - a relative path to a file

C<$search_resource_paths> - 0 or 1

=item Description

If the C<$filename> is an absolute path or an absolute URL, it is
returned umodified. If it is a relative path and C<$ref_path> is a
local path or a file:// URL, the function tries to locate the file
relatively to C<$ref_path> and if such a file exists, returns an
absolute filename or file:// URL to the file. Otherwise, returns the
value of C<FindInResourcePaths($filename)> if the
C<$search_resource_paths> argument was true or absolute path or URL
resolved relatively to C<ref_path> otherwise.

The rationale behind this function is as follows: paths that are
relative to remote resources are to be preferably located in
ResourcePaths; paths that are relative to a local resource are
preferably located in the actual location and then in ResourcePaths.

=back

=back

=head1 EXPORTED SYMBOLS

For B<backward compatibility reasons> only, Treex::PML exports by default the
following function symbol:

C<ImportBackends>

For this reason, it is recommended to load Treex::PML as:

  use Treex::PML ();

The following function symbols can be imported on demand:

C<ImportBackends>, C<CloneValue>, C<ResourcePaths>, C<FindInResources>, C<FindDirInResources>, C<FindDirInResourcePaths>, C<ResolvePath>, C<AddResourcePath>, C<AddResourcePathAsFirst>, C<SetResourcePaths>, C<RemoveResourcePath>

=head1 SEE ALSO

Tree editor TrEd: L<http://ufal.mff.cuni.cz/tred>

Prague Markup Language (PML) format:
L<http://ufal.mff.cuni.cz/jazz/PML/>

Description of FS format:
L<http://ufal.mff.cuni.cz/pdt/Corpora/PDT_1.0/Doc/fs.html>

Related packages: L<Treex::PML::Schema>, L<Treex::PML::Instance>,
L<Treex::PML::Document>, L<Treex::PML::Node>, L<Treex::PML::Factory>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Treex::PML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Treex-PML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Treex-PML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Treex-PML>

=item * Search CPAN

L<http://search.cpan.org/dist/Treex-PML/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2013 by Petr Pajas, Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

