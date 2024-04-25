# -*- cperl -*-
package Treex::PML::Schema;


use strict;
use warnings;
no warnings 'uninitialized';

use UNIVERSAL::DOES;

use Carp;
use Treex::PML::Schema::Constants;
use Treex::PML::Resource::URI;

BEGIN {
  our $VERSION = '2.27'; # version template
  require Exporter;
  import Exporter qw(import);
  our @EXPORT = (
    @Treex::PML::Schema::Constants::EXPORT,
    qw(PML_VERSION_SUPPORTED),
  );
  our %EXPORT_TAGS = (
    'constants' => [ @EXPORT ],
  );
} # BEGIN

use constant PML_VERSION_SUPPORTED => "1.2";

use Treex::PML::Schema::XMLNode;
use Treex::PML::Schema::Decl;
use Treex::PML::Schema::Root;
use Treex::PML::Schema::Template;
use Treex::PML::Schema::Derive;
use Treex::PML::Schema::Copy;
use Treex::PML::Schema::Import;
use Treex::PML::Schema::Type;
use Treex::PML::Schema::Struct;
use Treex::PML::Schema::Container;
use Treex::PML::Schema::Seq;
use Treex::PML::Schema::List;
use Treex::PML::Schema::Alt;
use Treex::PML::Schema::Choice;
use Treex::PML::Schema::CDATA;
use Treex::PML::Schema::Constant;
use Treex::PML::Schema::Member;
use Treex::PML::Schema::Element;
use Treex::PML::Schema::Attribute;
use Treex::PML::Schema::Reader;
use Treex::PML::IO;
use XML::Writer;

use base qw(Treex::PML::Schema::Template);

use Scalar::Util qw(weaken isweak);
require Treex::PML;

=head1 NAME

Treex::PML::Schema - Perl implements a PML schema.

=head2 DESCRIPTION

This class implements PML schemas. PML schema consists of a set of
type declarations of several kinds, represented by objects inheriting
from a common base class C<Treex::PML::Schema::Decl>.

=head2 INHERITANCE

This class inherits from L<Treex::PML::Schema::Template>.

=head3 Attribute Paths

Some methods use so called 'attribute paths' to navigate through
nested and referenced type declarations. An attribute path is a
'/'-separated sequence of steps, where step can be one of the
following:

=over 3

=item C<!>I<type-name>

'!' followed by name of a named type (this step can only occur
as the very first step

=item I<name>

name (of a member of a structure, element of a sequence or attribute
of a container), specifying the type declaration of the specified
named component

=item C<#content>

the string '#content', specifying the content type declaration
of a container

=item C<LM>

specifying the type declaration of a list

=item C<AM>

specifying the type declaration of an alt

=item C<[>I<NNN>C<]>

where I<NNN> is a decimal number (ignored) are an equivalent of LM or AM

=back

Steps of the form LM, AM, and [NNN] (except when occuring at the end
of an attribute path) may be omitted.

=head2 EXPORT

This module exports constants for declaration types.

=head2 EXPORT TAGS

=over 3

=item :constants

Export constant symbols (exported by default, too).

=back

=head2 CONSTANTS

See Treex::PML::Schema::Constants.

=cut

=head1 METHODS

=over 3

=item Treex::PML::Schema->new ({ option => value, ... })

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createPMLSchema() instead!

Parses an XML representation of a PML Schema
from a string, filehandle, local file, or URL,
processing the modular instructions as described in

  L<http://ufal.mff.cuni.cz/jazz/PML/doc/pml_doc.html#processing>

and returns the corresponding C<Treex::PML::Schema> object.

One of the following options must be given:

=over 5

=item C<string>

a XML string to parse

=item C<filename>

a file name or URL

=item C<fh>

a file-handle (IO::File, IO::Pipe, etc.) open for reading

=back

The following options are optional:

=over 5

=item C<base_url>

base URL for referred schemas (usefull when parsing from a file-handle or a string)

=item C<use_resources>

if this option is used with a true value, the parser will attempt to
locate referred schemas also in L<Treex::PML> resource paths.

=item C<revision>, C<minimal_revision>, C<maximal_revision>

constraints to the revision number of the schema.

=item C<validate>

if this option is used with a true value, the parser will validate the
schema on the fly using a RelaxNG grammar given using the
C<relaxng_schema> parameter; if C<relaxng_schema> is not given, the
file 'pml_schema_inline.rng' searched for in L<Treex::PML> resource paths
is assumed.

=item C<relaxng_schema>

a particular RelaxNG grammar to validate against. The value may be an
URL or filename for the grammar in the RelaxNG XML format, or a
XML::LibXML::RelaxNG object representation. The compact format is not
supported.

=back

=cut

BEGIN{
  my %parse_opts = (
  KeyAttr => {
    "member"    => "name",
    "attribute" => "name",
    "element"   => "name",
    "type"      => "name",
    "template"  => "name",
    "derive"    => "name",
    "let"       => "param",
    "param"     => "name",
  },
  TextOnly => {
    description => 'content',
    revision    => 'content',
    value       => 'content',
    delete      => 'content',
    constant    => 'value',
  },
  Stringify => {
    description => 'content',
    revision    => 'content',
    value       => 'content',
    delete      => 'content',
  },
  Solitary => {
    map { $_ => 1 }
      qw(description revision root cdata structure container sequence constant list alt choice)
     },
  Bless => {
    member =>  'Treex::PML::Schema::Member',
    attribute =>  'Treex::PML::Schema::Attribute',
    element =>  'Treex::PML::Schema::Element',
    type =>  'Treex::PML::Schema::Type',
    root =>  'Treex::PML::Schema::Root',
    structure =>  'Treex::PML::Schema::Struct',
    container =>  'Treex::PML::Schema::Container',
    sequence =>  'Treex::PML::Schema::Seq',
    list =>  'Treex::PML::Schema::List',
    alt =>  'Treex::PML::Schema::Alt',
    cdata =>  'Treex::PML::Schema::CDATA',
    constant =>  'Treex::PML::Schema::Constant',
    choice =>  'Treex::PML::Schema::Choice',
    template => 'Treex::PML::Schema::Template',
    copy => 'Treex::PML::Schema::Copy',
    import => 'Treex::PML::Schema::Import',
    derive => 'Treex::PML::Schema::Derive',
    '*' => 'Treex::PML::Schema::XMLNode',
  },
  DefaultNs => PML_SCHEMA_NS,
);

sub new {
  my ($class,$opts, $more_opts)=@_;
  if (!ref $opts) {
    # compatibility with older API
    $more_opts ||= {};
    $opts = { %$more_opts, string => $opts };
  }

  my $file = $opts->{filename};

  my $base = $opts->{base_url};
  if (defined $base and length $base) {
    $file = Treex::PML::ResolvePath($base,$file,$opts->{use_resources});
  } elsif ($opts->{use_resources}) {
    $file = Treex::PML::FindInResources($file);
  }
  my $schema;
  my $revision_opts = {
    map { $_ => delete($opts->{$_}) }
      qw(revision_error revision minimal_revision maximal_revision)
  };
  if (defined($file) and ref($schema = $opts->{schemas}{$file})) {
    print STDERR "schema $file already hashed\n" if $Treex::PML::Debug;
    $schema->check_revision($revision_opts);
    return $schema;
  }
  my $parse_opts = {%parse_opts,%$opts};
  $parse_opts->{Bless}{pml_schema}=$class;
  $parse_opts->{URL} = (ref $file && $file->isa('Treex::PML::Resource::URI')) ? $file->file : $file;

  my $pml_reader = Treex::PML::Schema::Reader->new($parse_opts);
  my $reader = $pml_reader->reader;
  my $version;
  eval {
    unless (  $reader->nextElement('pml_schema', PML_SCHEMA_NS)==1 ) {
      die "Not a PML schema: $file!\n";
    }
    $version = $reader->getAttribute('version');
    $reader->moveToElement;
    $schema = $pml_reader->parse_element();
  };
  if ($@) {
    die "Treex::PML::Schema::Reader error while parsing: $file near line ".$reader->lineNumber."\n$@\n";
    return;
  }
  if (defined $version and length $version) {
    unless (cmp_revisions($version,PML_VERSION_SUPPORTED)<=0) {
      die "Unsupported version of PML schema '$file': this module supports versions up to ".PML_VERSION_SUPPORTED."\n";
    }
  } else {
    warn "WARNING: PML schema '$file' does not specify version! Assuming ".PML_VERSION_SUPPORTED."\n";
  }
  $schema->check_revision($revision_opts);
  $schema->{-VERSION}=$Treex::PML::Schema::VERSION;
  return $schema;
}
} # BEGIN


=item Treex::PML::Schema->readFrom (filename,opts)

An obsolete alias for Treex::PML::Schema->new({%$opts, filename=>$filename}).

=cut

sub readFrom {
  my ($self,$file,$opts)=@_;
  return $self->new({%$opts, filename=>$file});
}

=item $schema->write ({option => value})

This method serializes the Treex::PML::Schema object to XML. See Treex::PML::Schema::XMLNode->write for implementation.

IMPORTANT: The resulting schema is simplified, that is all modular instructions 
are processed and removed from it, see L<http://ufal.mff.cuni.cz/jazz/PML/doc/pml_doc.html#processing>

One of the following options must be given:

=over 5

=item C<string>

a scalar reference to which the XML is to be stored as a string

=item C<filename>

a file name

=item C<fh>

a file-handle (IO::File, IO::Pipe, etc.) open for writing

=back

One of the following options are optional:

=over 5

=item C<no_backups>

if this option is used with a true value, the writer will not attempt
to create backup (tilda) files when overwriting an existing file.

=item C<no_indent>

if this option is used with a true value, the writer will not add
additional newlines and indentatin white-space to the result XML.

=back

=cut

# for implementation see XMLNode.pm


=item $schema->get_url ()

Return location of the PML schema file.

=cut

sub get_url                  { return $_[0]->{URL};           }

=item $schema->set_url ($URI)

Set location of the PML schema file.

=cut

sub set_url                  { return $_[0]->{URL} = Treex::PML::IO::make_URI($_[1]) }


=item $schema->get_pml_version ()

Return PML version the schema conforms to.

=cut

sub get_pml_version          { return $_[0]->{version};       }


=item $schema->get_revision ()

Return PML schema revision.

=cut

sub get_revision             { return $_[0]->{revision};      }

=item $schema->get_description ()

Return PML schema description.

=cut

sub get_description          { return $_[0]->{description};   }

=item $schema->get_root_decl ()

Return the root type declaration (see C<Treex::PML::Schema::Root>).

=cut

sub get_root_decl            { return $_[0]->{root};          }

=item $schema->get_root_type ()

Like $schema->get_root_decl->get_content_decl.

=cut

sub get_root_type {
  my ($self,$name) = @_;
  return $self->{root}->get_content_decl;
}
*get_root_type_obj = \&get_root_type;


sub _internal_api_version    { return $_[0]->{'-api_version'} }

=item $decl->get_decl_type ()

Return the  constant PML_SCHEMA_DECL (for compatibility with the Treex::PML::Schema::Decl interface).

=item $decl->get_decl_type_str ()

Return the string 'schema' (for compatibility with the Treex::PML::Schema::Decl interface).

=cut

sub get_decl_type     { return(PML_SCHEMA_DECL); }
sub get_decl_type_str { return('schema'); }

=item $schema->get_root_name ()

Return name of the root element for PML instance.

=cut

sub get_root_name { 
  my $root = $_[0]->{root}; 
  return $root ? $root->{name} : undef; 
}

=item $schema->get_type_names ()

Return names of all named type declarations.

=cut

sub get_type_names {
  my $types = $_[0]->{type};
  return $types ? keys(%$types) : ();
}

=item $schema->get_named_references ()

This method returns a list of HASHrefs containing
information about a named references to PML instances
(each hash will currently have the keys 'name' and 'readas').

=cut

sub get_named_references {
  my ($self, $name) = @_;
  if ($self->{reference}) {
    return map { my $r=$_; my $h = { map { ($_=>$r->{$_}) }  @{$r->{'-attributes'}} }; $h }
      @{$self->{reference}} ;
  }
  return;
}

=item $schema->get_named_reference_info (name)

This method retrieves information about a specific named instance
reference as a hash (currently with keys 'name' and 'readas').

=cut

sub get_named_reference_info {
  my ($self, $name) = @_;
  if ($self->{reference}) {
    return { map { my $r=$_; map { $_=>$r->{$_} }  @{$r->{'-attributes'}} } 
      grep { defined($_->{name}) and $_->{name} eq $name } @{$self->{reference}} };
  }
  return;
}

=item Treex::PML::Schema::cmp_revisions($A, $B)

This function compares two schema revision strings according to the
ruls described in the PML specification. Returns -1 if revision $A
precedes revision $B, 0 if the revisions are equal (equivalent), and 1
if revision $A follows revision $B.

=cut

# compare two revision numbers
sub cmp_revisions {
  my ($my_revision,$revision)=@_;
  my @my_revision = split(/\./,$my_revision);
  my @revision = split(/\./,$revision);
  my $cmp=0;
  while ($cmp==0 and (@my_revision or @revision)) {
    $cmp = (shift(@my_revision) <=> shift(@revision));
  }
  return $cmp;
}

# compare schema revision number with a given revision number
sub _match_revision {
  my ($self,$revision)=@_;
  my $my_revision=$self->{revision} || 0;
  return cmp_revisions($self->{revision} || 0, $revision);
}

# for internal use only
sub _resolve_type {
  my ($self,$type)=@_;
  return $type unless ref($type);
  my $ref = $type->{type};
  if ($ref) {
    my $rtype = $self->{type}{$ref};
    if (ref($rtype)) {
      return $rtype;
    } else {
      # couldn't resolve
      warn "No declaration for type '$ref' in schema '".$self->get_url."'\n";
      return $type->{type};
    }
  } else {
    return $type;
  }
}

=item $schema->for_each_decl (sub{...})

This method traverses all nested declarations and sub-declarations and
calls a given subroutine passing the sub-declaration object as a
parameter.

=cut

sub for_each_decl {
  my ($self,$sub) = @_;
  if (ref $self->{root}) {
    $self->{root}->for_each_decl($sub);
  }
  for my $d (qw(template type)) {
    if (ref $self->{$d}) {
      foreach (values %{$self->{$d}}) {
        $_->for_each_decl($sub);
      }
    }
  }
}

# traverse type data structure and collect types referred via
# type="type-name" declarations in the refferred hash
sub _get_referred_types {
  my ($self,$type,$referred) = @_;
  $type->for_each_decl(
    sub {
      my ($type)=@_;
      return unless ref($type);
      if (defined($type->{type}) and length($type->{type}) and !exists($referred->{$type->{type}})) {
        # this type declaration reffers to another type - get it
        my $resolved = $self->_resolve_type($type);
        $referred->{$type->{type}} = $resolved;
        $self->_get_referred_types($resolved,$referred) if ref $resolved;
      }
    });
}

# import given named type and all named types it requires
# from src_schema into the current schema (self)
sub _import_type {
  my ($self,$src_schema, $name) = @_;
  unless (exists $src_schema->{type}{$name}) {
    croak "Cannot import type '$name' from '$src_schema->{URL}' to '$self->{URL}': type not declared in the source schema\n";
  }
  my $type = $src_schema->{type}{$name};
  my %referred = ($name => $type);
  $src_schema->_get_referred_types($type,\%referred);
  foreach my $n (keys %referred) {
    unless (exists $self->{type}{$n}) {
      my $parent = $referred{$n}->{-parent};
      if (defined $parent) {
        $self->{type}{$n}=Treex::PML::CloneValue($referred{$n},[$parent], [$self]);
      } else {
        $self->{type}{$n}=Treex::PML::CloneValue($referred{$n});
      }
    } else {
      
    }
  }
}

sub __fmt {
  my ($string,$fmt) =@_;
  $string =~ s{%(.)}{ $1 eq "%" ? "%" : 
                        exists($fmt->{$1}) ? $fmt->{$1} : "%$1" }eg;
  return $string;
}

=item $schema->check_revision({ option=>value })

Check that schema revision satisfies given constraints. The following options are suported:

C<revision>: exact revision number to match

C<minimal_revision>: minimal revision number to match

C<maximal_revision>: maximal revision number to match

C<revision error>: an optional error message format string with %f
mark for the schema filename or URL and %e for the error
string. Defaults to 'Error: wrong schema revision of %f: %e';

=cut

sub check_revision {
  my ($self,$opts)=@_;

  my $error = $opts->{revision_error} || 'Error: wrong schema revision of %f: %e';
  if ($opts->{revision} and
        $self->_match_revision($opts->{revision})!=0) {
    croak(__fmt($error, { 'e' => "required $opts->{revision}, got $self->{revision}",
                          'f' => $self->{URL}}));
  } else {
    if ($opts->{minimal_revision} and
          $self->_match_revision($opts->{minimal_revision})<0) {
      croak(__fmt($error, { 'e' => "required at least $opts->{minimal_revision}, got $self->{revision}",
                            'f' => $self->{URL}}));
    }
    if ($opts->{maximal_revision} and
          $self->_match_revision($opts->{maximal_revision})>0) {
      croak(__fmt($error, { 'e' => "required at most $opts->{maximal_revision}, got $self->{revision}",
                            'f' => $self->{URL}}));
    }
  }
}

=item $schema->convert_from_hash

Compatibility method building the schema object from a nested hash
structure created by XML::Simple which was used in older
implementations. This is useful for upgrading objects stored in old
binary dumps.

=cut

sub convert_from_hash {
  my $class = shift;
  my $schema_hash;
  if (ref($class)) {
    $schema_hash = $class;
    $class = ref( $schema_hash );
  } else {
    $schema_hash = shift;
    bless $schema_hash,$class;
  }
  $schema_hash->{-api_version} ||= '2.0';
  $schema_hash->{'-xml_name'}='pml_schema';
  $schema_hash->{-attributes}=[qw(xmlns version)];
  if (ref $schema_hash->{reference}) {
    for my $ref (@{$schema_hash->{reference}}) {
      $ref->{'-xml_name'}='reference';
      $ref->{'-attributes'}=[qw(name readas)];
      bless $ref,'Treex::PML::Schema::XMLNode';
      weaken($ref->{-parent}=$schema_hash);
    }
  }
  my $root = $schema_hash->{root};
  if (defined($root)) {
    bless $root, 'Treex::PML::Schema::Root';
    weaken($root->{-parent}=$schema_hash);
    $root->{'-xml_name'}='root';
    $root->{'-attributes'}=['name','type'];
    Treex::PML::Schema::Decl->convert_from_hash($root,
                                  $schema_hash,
                                  undef  # path = '' for root
                                 );
  }
  my $types = $schema_hash->{type};
  if ($types) {
    my ($name, $decl);
    while (($name, $decl) = each %$types) {
      bless $decl, 'Treex::PML::Schema::Type';
      $decl->{'-xml_name'}='type';
      $decl->{'-attributes'}=['name'];
      Treex::PML::Schema::Decl->convert_from_hash($decl, 
                                    $schema_hash,
                                    '!'.$name
                                   );
    }
  }
  return $schema_hash;
}


=item $schema->find_type_by_path (attribute-path,noresolve,decl)

Locate a declaration specified by C<attribute-path> starting from
declaration C<decl>. If C<decl> is undefined the root type declaration
is used. (Note that attribute paths starting with '/' are always
evaluated startng from the root declaration and paths starting with
'!' followed by a name of a named type are evaluated starting from
that type.) All references to named types are transparently resolved
in each step.

The caller should pass a true value in C<noresolve> to enforce Member,
Attribute, Element, Type, or Root declaration objects to be returned
rather than declarations of their content.

Attribute path is a '/'-separated sequence of steps (member,
attribute, element names or strings matching [\d*]) which identifying
a certain nested type declaration. A step of the aforementioned form
[\d*] is match the content declaration of a List or Alt. Note however, that
named stepsdive into List or Alt declarations automatically, too.

=cut

sub find_type_by_path {
  my ($schema, $path, $noresolve, $decl) = @_;
  if (defined($path) and length($path)) {
    if ($path=~s{^!([^/]+)/?}{}) {
      $decl = $schema->get_type_by_name($1);
      if (defined $decl) {
        $decl = $decl->get_content_decl;
      } else {
        return;
      }
    } elsif ($path=~s{^/}{} or !$decl) {
      $decl = $schema->get_root_decl->get_content_decl;
    }
    for my $step (split /\//, $path,-1) {
      next if $step eq '.';
      if (ref($decl)) {
        my $decl_is = $decl->get_decl_type;
        if ($decl_is == PML_ATTRIBUTE_DECL ||
            $decl_is == PML_MEMBER_DECL ||
            $decl_is == PML_ELEMENT_DECL ||
            $decl_is == PML_TYPE_DECL ) {
          $decl = $decl->get_knit_content_decl;
          next unless defined($step) and length($step);
          redo;
        }
        if ($decl_is == PML_LIST_DECL ||
            $decl_is == PML_ALT_DECL ) {
          $decl = $decl->get_knit_content_decl;
          next if ($step =~ /^\[[-+]?\d+\]$/ or
                     (($decl_is == PML_LIST_DECL) ?
                        ($step eq 'LM' or $step eq '[LIST]')
                       :($step eq 'AM' or $step eq '[ALT]')));
          redo;
        }
        if ($decl_is == PML_STRUCTURE_DECL) {
          my $member = $decl->get_member_by_name($step);
          if ($member) {
            $decl = $member;
          } else {
            $member = $decl->get_member_by_name($step.'.rf');
            return unless $member;
            if ($member->get_knit_name eq $step) {
              $decl = $member;
            } else {
              return;
            }
          }
        } elsif ($decl_is == PML_CONTAINER_DECL) {
          if ($step eq '#content') {
            $decl = $decl->get_content_decl;
            next;
          }
          my $attr = $decl->get_attribute_by_name($step);
          $decl =  $attr;
        } elsif ($decl_is == PML_SEQUENCE_DECL) {
          $step =~ s/^\[\d+\]//; # name must follow
          $decl = $decl->get_element_by_name($step);
        } elsif ($decl_is == PML_ROOT_DECL) {
          if (!(defined($step) and length($step)) or ($step eq $decl->get_name)) {
            $decl = $decl->get_content_decl;
          } else {
            return;
          }
        } else {
          return;
        }
      } else {
#        warn "Can't follow type path '$path' (step '$step')\n";
        return(undef); # ERROR
      }
    }
  } elsif (!$decl) {
    $decl ||= $schema->get_root_decl->get_content_decl;
  }
  my $decl_is = $decl && $decl->get_decl_type;
  return $noresolve ? $decl :
    $decl && (
              $decl_is == PML_ATTRIBUTE_DECL ||
              $decl_is == PML_MEMBER_DECL ||
              $decl_is == PML_ELEMENT_DECL ||
              $decl_is == PML_TYPE_DECL ||
              $decl_is == PML_ROOT_DECL
             )
      ? ($decl->get_knit_content_decl) : $decl;
}


=item $schema->find_types_by_role (role,start_decls)

Return a list of declarations (objects derived from Treex::PML::Schema::Decl)
that have role equal to C<role>.

If C<start_decls> is specified, it must be an ARRAY reference of
declarations; in that case, only declarations nested below the listed
ones are considered.

=cut

sub find_types_by_role {
  my ($self,$role,$start_decls)=@_;
  my @decls;
  my $sub = sub { push @decls, $_[0] if $_[0]->{role} eq $role };
  if (defined($start_decls)) {
    for (@$start_decls) {
      $_->for_each_decl($sub);
    }
  } else {
    $self->for_each_decl($sub);
  }
  return @decls;
}

=item $schema->find_role (role,start_decl,opts)

WARINING: this function can be very slow, esp. if the type
declarations are recursive.

Return a list of attribute paths leading to nested type declarations
of C<decl> with role equal to C<role>.

This is equivalent to

  $schema->find_decl($decl,sub{ $_[0]->{role} eq $role },$opts);

Please, see the documentation for C<find_dec> for more information.

=cut

sub find_role {
  my ($self, $role, $decl, $opts)=@_;
  if (!$decl and wantarray()) {
    $self->{-ROLE_CACHE}{$role} ||= [ $self->_find_role($role,$decl,$opts) ];
    return @{$self->{-ROLE_CACHE}{$role}};
  }
  return $self->_find_role($role,$decl,$opts);
}

sub _find_role {
  my ($self, $role, $decl, $opts)=@_;
  return $self->find_decl(sub{ defined($_[0]->{role}) and $_[0]->{role} eq $role },$decl,$opts);
}

=item $schema->find_decl (callback,start_decl,opts)

WARINING: this function can be very slow, esp. if the type
declarations are recursive.

Return a list of attribute paths leading to nested type declarations
of C<decl> for which a given callback returns a true value. The tested
type declaration is passed to the callback as the first (and only)
argument.

If C<start_decls> is specified, it must be an ARRAY reference of
declarations; in that case, only declarations nested or referred to
from the listed ones are considered.

In array context return all matching nested declarations are
returned. In scalar context only the first one is returned (with early
stopping).

The last argument C<opts> can be used to pass some flags to the
algorithm. Currently only the flag C<no_childnodes> is available. If
true, then the function never recurses into content declaration of
declarations with the role #CHILDNODES.

=cut

sub find_decl {
  my ($self, $sub, $decl, $opts)=@_;
  $decl ||= $self->{root};
  my $first = not(wantarray);
  my @res = grep { defined } $self->_find($decl,$sub,$first,{},$opts);
  return $first ? $res[0] : @res;
}


sub _find {
  my ($self, $decl, $test, $first, $cache, $opts)=@_;

  my @result = ();

  return () unless ref $decl;


  if ($cache->{'#RECURSE'}{ $decl }) {
    return ()
  }
  local $cache->{'#RECURSE'}{ $decl } = 1;

  if ( ref $opts and $opts->{no_childnodes} and defined($decl->{role}) and $decl->{role} eq '#CHILDNODES') {
    return ();
  }

  if ( $test->($decl) ) {
    if ($first) {
      return '';
    } else {
      push @result, '';
    }
  }
  my $type_ref = $decl->get_type_ref;
  my $decl_is = $decl->get_decl_type;
  my $seq_bracket = $opts->{with_Seq_brackets} ? '[0]' : '';

  if ($type_ref) {
    my $cached = $cache->{ $type_ref };
    unless ($cached) {
      $cached = $cache->{ $type_ref } = [ $self->_find( $self->get_type_by_name($type_ref),
                                                             $test, $first, $cache, $opts ) ];
    }
    if ($decl_is == PML_CONTAINER_DECL) {
      push @result,  map { (defined($_) and length($_)) ? '#content/'.$_ : '#content' } @$cached;
    } elsif ($decl_is == PML_LIST_DECL) {
      push @result, map { (defined($_) and length($_)) ? 'LM/'.$_ : 'LM' } @$cached;
    } elsif ($decl_is == PML_ALT_DECL) {
      push @result, map { (defined($_) and length($_)) ? 'AM/'.$_ : 'AM' } @$cached;
    } else {
      push @result, @$cached;
    }
    return $result[0] if ($first and @result);
  }
  if ($decl_is == PML_STRUCTURE_DECL) {
    foreach my $member ($decl->get_members) {
      my @res = map { (defined($_) and length($_)) ? $member->get_name.'/'.$_ : $member->get_name }
        $self->_find($member, $test, $first, $cache, $opts);
      return $res[0] if ($first and @res);
      push @result,@res;
    }
  } elsif ($decl_is == PML_CONTAINER_DECL) {
    my $cdecl = $decl->get_content_decl;
    foreach my $attr ($decl->get_attributes) {
      my @res = map { (defined($_) and length($_)) ? $attr->get_name.'/'.$_ : $attr->get_name }
        $self->_find($attr, $test, $first, $cache, $opts);
      return $res[0] if ($first and @res);
      push @result,@res;
    }
    if ($cdecl) {
      push @result,  map { (defined($_) and length($_)) ? '#content/'.$_ : '#content' } 
        $self->_find($cdecl, $test, $first, $cache, $opts);
      return $result[0] if ($first and @result);
    }
  } elsif ($decl_is == PML_SEQUENCE_DECL) {
    foreach my $element ($decl->get_elements) {
      my @res = map { (defined($_) and length($_)) ? $element->get_name.$seq_bracket.'/'.$_ : $element->get_name.$seq_bracket }
        $self->_find($element, $test, $first, $cache, $opts);
      return $res[0] if ($first and @res);
      push @result,@res;
    }
  } elsif ($decl_is == PML_LIST_DECL) {
    push @result, map { (defined($_) and length($_)) ? 'LM/'.$_ : 'LM' }
      $self->_find($decl->get_content_decl, $test, $first, $cache, $opts);
  } elsif ($decl_is == PML_ALT_DECL) {
    push @result, map { (defined($_) and length($_)) ? 'AM/'.$_ : 'AM' }
      $self->_find($decl->get_content_decl, $test, $first, $cache, $opts);
  } elsif ($decl_is == PML_TYPE_DECL ||
           $decl_is == PML_ROOT_DECL ||
           $decl_is == PML_ATTRIBUTE_DECL ||
           $decl_is == PML_MEMBER_DECL ||
           $decl_is == PML_ELEMENT_DECL ) {
    push @result, $self->_find($decl->get_content_decl, $test, $first, $cache, $opts);
  }
  my %uniq;
  return $first ? (@result ? $result[0] : ()) 
    : grep { !$uniq{$_} && ($uniq{$_}=1) } @result;
}

=item $schema->node_types ()

Return a list of all type declarations with the role C<#NODE>.

=cut

sub node_types {
  my ($self) = @_;
  my @result;
  return $self->find_types_by_role('#NODE');
}



=item $schema->get_type_by_name (name)

Return the declaration of the named type with a given name (see
C<Treex::PML::Schema::Type>).

=cut

sub get_type_by_name {
  my ($self,$name) = @_;
  return $self->{type}{$name};
}
*get_type_by_name_obj = \&get_type_by_name;


# OBSOLETE: for backward compatibility only
sub type {
  my ($self,$decl)=@_;
  if (UNIVERSAL::DOES::does($decl,'Treex::PML::Schema::Decl')) {
    return $decl
  } else {
    return Treex::PML::Type->new($self,$decl);
  }
}

=item $schema->validate_object (object, type_decl, log, flags)

Validates the data content of the given object against a specified
type declaration. The type_decl argument must either be an object
derived from the C<Treex::PML::Schema::Decl> class or the name of a named
type.

An array reference may be passed as the optional 3rd argument C<log>
to obtain a detailed report of all validation errors.

The C<flags> argument can specify flags that influance the
validation. The following constants can binary-OR'ed to obtain the
fags:

PML_VALIDATE_NO_TREES - do not validate nested data with roles
#CHIDLNODES or #TREES and do not require that objects with the role
#NODE implement the Treex::PML::Node role.

PML_VALIDATE_NO_CHILDNODES - do not validate nested data with the
role #CHIDLNODES.

Returns: 1 if the content conforms, 0 otherwise.

=cut

sub validate_object { # (path, base_type)
  my ($schema, $object, $type,$log)=@_;
  if (defined $log and UNIVERSAL::isa($log,'ARRAY')) {
    croak "Treex::PML::Schema::validate_object: log must be an ARRAY reference";
  }
  $type ||= $schema->get_type_by_name($type);
  if (!ref($type)) {
    croak "Treex::PML::Schema::validate_object: Cannot determine data type";
  }
  return $type->validate_object($object,{log => $log});
}


=item $schema->validate_field (object, attr-path, type, log)

This method is similar to C<validate_object>, but in this case the
validation is restricted to the data substructure of C<object>
specified by the C<attr-path> argument.

C<type> is the type of C<object> specified either by the name of a
named type, or as a Treex::PML::Type, or a type declaration.

An array reference may be passed as the optional 3rd argument C<log>
to obtain a detailed report of all validation errors.

Returns: 1 if the content conforms, 0 otherwise.

=cut

sub validate_field {
  my ($schema, $object, $path, $type, $log) = @_;
  if (defined $log and UNIVERSAL::isa($log,'ARRAY')) {
    croak "Treex::PML::Schema::validate_field: log must be an ARRAY reference";
  }
  if (!ref($type)) {
    my $named_type = $schema->get_type_by_name($type);
    croak "Treex::PML::Schema::validate_field: Cannot find type '$type'" 
      unless $named_type;
    $type = $named_type;
  }
  if (!(defined($path) and length($path))) {
    return $type->validate_object($object, { log => $log });
  }
  $type = $type->find($path);
  croak "Treex::PML::Schema::validate_field: Cannot determine data type for attribute-path '$path'" unless $type;
  return 
    $type->validate_object(Treex::PML::Instance::get_data($object,$path),{ path => $path,
                                                                  log => $log
                                                                 });
}


=item $schema->get_paths_to_atoms (\@decls, \%opts)

This method returns a list of all non-periodic canonical paths leading
from given types to atomic values. Currently only the following options
are supported:

  no_childnodes => $bool

If true, the method does not descent to member types with the role
#CHILDNODES.

  no_nodes => $bool

If true, the method does not descent to member types with the role
#NODE (except for the starting types).

  with_LM => $bool

If true, the paths will include a LM step for each List type on the path.

  with_AM => $bool

If true, the paths will include a AM step for each Alt type on the path.

  with_Seq_brackets => $bool

If true, the paths will append a [0] after each step representing a sequence element

=cut

sub get_paths_to_atoms {
  my ($self,$types,$opts) = @_;
  # find node type

  unless (defined $types) {
    $types = [ $self->node_types ];
  }
  $opts||={};
  return $self->_get_paths_to_atoms($types,{},$opts);
}

sub _get_paths_to_atoms {
  my ($self,$types,$seen,$opts)=@_;
  my @result;
  my $no_children = $opts->{no_childnodes};
  my $no_nodes = $opts->{no_nodes};
  my $with_LM = $opts->{with_LM};
  my $with_AM = $opts->{with_AM};
  my $with_Seq_brackets = $opts->{with_Seq_brackets};
  foreach my $type (@$types) {
    next if $seen->{$type};
    my $decl_is = $type->get_decl_type;
    next if $no_children and $type->get_role eq '#CHILDNODES';
    if ($decl_is == PML_TYPE_DECL ||
        $decl_is == PML_ROOT_DECL ||
        $decl_is == PML_ATTRIBUTE_DECL ||
        $decl_is == PML_MEMBER_DECL ||
        $decl_is == PML_ELEMENT_DECL  ||
        (!$with_LM && $decl_is == PML_LIST_DECL) ||
        (!$with_AM && $decl_is == PML_ALT_DECL)) {
      $type = $type->get_knit_content_decl;
      next if $no_nodes and $type->get_role eq '#NODE';
      redo;
    }
    next unless ref($type);
    my @members;
    if ($decl_is == PML_STRUCTURE_DECL) {
      @members = map { [$_,$_->get_knit_name] } $type->get_members;
    } elsif ($decl_is == PML_CONTAINER_DECL) {
      my $cdecl = $type->get_knit_content_decl;
      @members = ((map { [ $_, $_->get_name ] } $type->get_attributes),
                    ($cdecl ? [$cdecl, '#content'] : ()));
    } elsif ($decl_is == PML_SEQUENCE_DECL) {
      if ($with_Seq_brackets) {
        @members = map { [ $_, $_->get_name.'[0]' ] } $type->get_elements;
      } else {
        @members = map { [ $_, $_->get_name ] } $type->get_elements;
      }
    } elsif ($decl_is == PML_LIST_DECL) {
      @members = [$type->get_knit_content_decl,'LM'];
    } elsif ($decl_is == PML_ALT_DECL) {
      @members = [$type->get_knit_content_decl,'AM'];
    } else {
      push @result, qq{};
    }
    if (@members) {
      for my $m (@members) {
        my ($mdecl,$name) = @$m;
        local $seen->{$type}=1;
        push @result, map { (defined($_) and length($_)) ? $name."/".$_ : $name }
          $self->_get_paths_to_atoms([$mdecl],$seen,$opts);
      }
    }
  }
  my %uniq;
  return grep { !$uniq{$_} && ($uniq{$_}=1) } @result;
}


=item $schema->attributes (decl...)

This function tries to emulate the behavior of
C<<< Treex::PML::FSFormat->attributes >>> to some extent.

Return attribute paths to all atomic subtypes of given type
declarations. If no type declaration objects are given, then types
with role C<#NODE> are assumed. This function never descends to
subtypes with role C<#CHILDNODES>.

=cut

sub attributes {
  my ($self,@types) = @_;
  # find node type
  return $self->get_paths_to_atoms(@types ? \@types : undef, { no_childnodes => 1 });
}



sub init {
  my ($schema,$opts)=@_;
  $schema->{URL} = $opts->{URL};
  $schema->{-api_version} = '2.0';
}


# these functions are used internally by the serializer
sub serialize_exclude_keys {
  return qw(URL revision description);
}
sub serialize_get_children {
  my ($self,$opts)=@_;
  my @children = $self->SUPER::serialize_get_children($opts);
  return (
    (grep { defined($_->[1]) and length($_->[1]) } (
      ['revision',$self->{revision}],
      ['description',$self->{description}]
     )
    ),
    (grep { $_->[0] eq 'reference' } @children),
    (grep { $_->[0] eq 'root' } @children),
    (grep { $_->[0] !~ /^(?:root|reference)$/ } @children)
   );
}

=item $schema->post_process($options)

Auxiliary method used internally by the PML Schema parser. It
simplifies the schema and for each declaration object creates back
references to its parent declaration and schema and pre-computes the
type attribute path returned by $decl->get_decl_path().

=cut

sub post_process {
  my ($schema,$opts)=@_;
  $schema->simplify($opts);
  $schema->for_each_decl(sub{
    my ($decl)=@_;
    weaken( $decl->{-schema} = $schema );
    my $parent = $decl->{-parent};
    my $decl_is = $decl->get_decl_type;
    if (
      $decl_is == PML_STRUCTURE_DECL ||
      $decl_is == PML_CONTAINER_DECL ||
      $decl_is == PML_SEQUENCE_DECL ||
      $decl_is == PML_LIST_DECL ||
      $decl_is == PML_ALT_DECL ||
      $decl_is == PML_CHOICE_DECL ||
      $decl_is == PML_CONSTANT_DECL ||
      $decl_is == PML_CDATA_DECL
     ) {
      my $parent_is = $parent->get_decl_type;
      if ($parent_is == PML_TYPE_DECL) {
        $decl->{-path} = '!'.$parent->get_name;
      } elsif ($parent_is == PML_ROOT_DECL) {
        $decl->{-path} = '';
      } elsif ($parent_is == PML_ATTRIBUTE_DECL ||
               $parent_is == PML_MEMBER_DECL    ||
               $parent_is == PML_ELEMENT_DECL) {
        $decl->{-path} = $parent->{-parent}{-path}.'/'.$parent->get_name;
      } elsif ($parent_is == PML_CONTAINER_DECL and $decl_is != PML_ATTRIBUTE_DECL) {
        $decl->{-path} = $parent->{-path}.'/#content';
      } elsif ($parent_is == PML_LIST_DECL) {
        $decl->{-path} = $parent->{-path}.'/LM';
      } elsif ($parent_is == PML_ALT_DECL) {
        $decl->{-path} = $parent->{-path}.'/AM';
      }
      if ($decl_is == PML_LIST_DECL and !$decl->{-decl} and $decl->{role} eq '#KNIT') {
        # warn ("List $decl->{-path} with role=\"#KNIT\" must have a content type declaration: assuming <cdata format=\"PMLREF\">!\n");
        __fix_knit_type($schema,$decl,$decl->{-path}.'/LM');
      }
    } elsif ($decl_is == PML_MEMBER_DECL) {
      if (!$decl->{-decl} and $decl->{role} eq '#KNIT') {
        # warn ("Member  $decl->{-parent}{-path}/$decl->{-name} with role=\"#KNIT\" must have a content type declaration: assuming <cdata format=\"PMLREF\">!\n");
        __fix_knit_type($schema,$decl);
      }
    }
  });
}

sub __fix_knit_type {
  my ($schema,$decl,$path)=@_;
  $decl->{-decl}='cdata';
  my $cdata = $decl->{cdata}= bless {
    format => 'PMLREF',
    -xml_name => 'cdata',
    -attributes => [ 'format' ],
  }, 'Treex::PML::Schema::CDATA';
  weaken( $cdata->{-schema} = $schema );
  weaken( $cdata->{-parent} = $decl );
  if (defined $path) {
    $cdata->{-path} = $path;
  } elsif ($decl->{-parent} and $decl->{-name}) {
    $cdata->{-path} = "$decl->{-parent}{-path}/$decl->{-name}";
  }
}

sub _traverse_data {
  my ($data,$sub,$seen,$hashes_only)=@_;
  $seen->{$data}=1;
  if (UNIVERSAL::isa($data,'ARRAY')) {
    $sub->($data,0) unless $hashes_only;
    foreach my $val (@$data) {
      if (ref($val) and !exists $seen->{$val}) {
        _traverse_data($val,$sub,$seen,$hashes_only);
      }
    }
  } elsif (UNIVERSAL::isa($data,'HASH')) {
    $sub->($data,1);
    foreach my $val (values %$data) {
      if (ref($val) and !exists $seen->{$val}) {
        _traverse_data($val,$sub,$seen,$hashes_only);
      }
    }
  }
}



=back

=head1 CLASSES FOR TYPE DECLARATIONS

=over 3

=item L<Treex::PML::Schema::Decl>

=item L<Treex::PML::Schema::Root>

=item L<Treex::PML::Schema::Type>

=item L<Treex::PML::Schema::Struct>

=item L<Treex::PML::Schema::Container>

=item L<Treex::PML::Schema::Seq>

=item L<Treex::PML::Schema::List>

=item L<Treex::PML::Schema::Alt>

=item L<Treex::PML::Schema::Choice>

=item L<Treex::PML::Schema::CDATA>

=item L<Treex::PML::Schema::Constant>

=item L<Treex::PML::Schema::Member>

=item L<Treex::PML::Schema::Element>

=item L<Treex::PML::Schema::Attribute>

=back

=cut

1;

__END__

=head1 SEE ALSO

Prague Markup Language (PML) format:
L<http://ufal.mff.cuni.cz/jazz/PML/>

Tree editor TrEd: L<http://ufal.mff.cuni.cz/tred>

Related packages: L<Treex::PML>, L<Treex::PML::Schema::Template>,
L<Treex::PML::Schema::Decl>,
L<Treex::PML::Instance>,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

