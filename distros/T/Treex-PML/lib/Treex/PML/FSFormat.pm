
############################################################
#
# FS Format
# =========
#
#

package Treex::PML::FSFormat;
use Carp;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.24'; # version template
}
use UNIVERSAL::DOES;

my $attr_name_re='[^\\\\ \\n\\r\\t{}(),=|]+';

# this is extendible
our $SpecialTypes='WNVH';
our %Specials = (sentord => 'W', order => 'N', value => 'V', hide => 'H');

=head1 NAME

Treex::PML::FSFormat - Treex::PML class representing the file header of a FS file.

=over 4

=item Treex::PML::FSFormat->new (array_ref_or_GLOB)

NOTE: Don't call this constructor directly, use
Treex::PML::Factory->createFSFormat() instead!

Create a new FS format instance object by parsing a given input as a
FS file header. If the argument is an ARRAY reference, each element is
assumed to represent a single line.

=item Treex::PML::FSFormat->new (attributes_hash_ref?, ordered_names_list_ref?, unparsed_header?)

NOTE: Don't call this constructor directly, use
Treex::PML::Factory->createFSFormat() instead!

Create a new FS format instance object and C<initialize> it with the
optional values.

=cut

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $new = [];
  bless $new, $class;
  if (@_==1 and ref($_[0]) and !UNIVERSAL::isa($_[0],'HASH')) {
    $new->initialize();
    $new->readFrom(@_);
  } else {
    $new->initialize(@_);
  }
  return $new;
}

=item Treex::PML::FSFormat->create (@header)

NOTE: Don't call this constructor directly, use
Treex::PML::Factory->createFSFormat() instead!

Same as Treex::PML::FSFormat->new (\@header).

=cut

sub create {
  my $self = shift;
  my $new=$self->new();
  $new->readFrom([@_]);
  return $new;
}

=item $format->clone

Duplicate FS format instance object.

=cut

sub clone {
  my ($self) = @_;
  return unless ref($self);
  return $self->new(
		    {%{$self->defs()}},
		    [$self->attributes()],
		    [@{$self->unparsed()}],
		    undef, # specials
		   );
}


=pod

=item $format->initialize (attributes_hash_ref?, ordered_names_list_ref?, unparsed_header?)

Initialize a new FS format instance with given values. See L<Treex::PML>
for more information about attribute hash, ordered names list and unparsed headers.

=cut

sub initialize {
  my $self = $_[0];
  return unless ref($self);

  $self->[0] = ref($_[1]) ? $_[1] : { }; # attribs  (hash)
  $self->[1] = ref($_[2]) ? $_[2] : [ ]; # atord    (sorted array)
  $self->[2] = ref($_[3]) ? $_[3] : [ ]; # unparsed (sorted array)
  $self->[3] = ref($_[4]) ? $_[4] : undef; # specials
  return $self;
}

=pod

=item $format->addNewAttribute (type, colour, name, list)

Adds a new attribute definition to the Treex::PML::FSFormat. Type must be one of
the letters [KPOVNWLH], colour one of characters [A-Z0-9]. If the type
is L, the fourth parameter is a string containing a list of possible
values separated by |.

=cut

sub addNewAttribute {
  my ($self,$type,$color,$name,$list)=@_;
  $self->list->[$self->count()]=$name if (!defined($self->defs->{$name}));
  if (index($SpecialTypes, $type)+1) {
    $self->set_special($type,$name);
  }
  if ($list) {
    $self->defs->{$name}.=" $type=$list"; # so we create a list of defchars separated by spaces
  } else {                 # a value-list may follow the equation mark
    $self->defs->{$name}.=" $type";
  }
  if ($color) {
    $self->defs->{$name}.=" $color"; # we add a special defchar for color
  }
}

=pod

=item $format->readFrom (source,output?)

Reads FS format instance definition from given source, optionally
echoing the unparsed input on the given output. The obligatory
argument C<source> must be either a GLOB or list reference.
Argument C<output> is optional and if given, it must be a GLOB reference.

=cut

sub readFrom {
  my ($self,$handle,$out) = @_;
  return unless ref($self);
  require Treex::PML::Backend::FS;
  my $read = \&Treex::PML::Backend::FS::ReadEscapedLine;
  my %result;
  my $count=0;
  local $_;
  while ($_=$read->($handle)) {
    s/\r$//o;
    if (ref($out)) {
      print $out $_;
    } else {
      push @{$self->unparsed}, $_;
    }
    if (/^\@([KPOVNWLHE])([A-Z0-9])* (${attr_name_re})(?:\|(.*))?/o) {
      if ($1 eq 'E') {
	  unless (defined $self->special('E')) {
	      $self->set_special('E',$3);
	      if (ref($handle) ne 'ARRAY') {
		  binmode $handle, ':raw:perlio:encoding('.$3.')';
		  if ($count>0) {
		      warn "\@E should be on the first line!\n";
		  }
	      }
	  } else {
	      warn __PACKAGE__.": There should be just one encoding (\@E) and that should occur on the very first line. Ignoring $_!\n";
	  }
	  next;
      }
      if (index($SpecialTypes, $1)+1) {
	$self->set_special($1,$3);
      }
      $self->list->[$count++]=$3 if (!defined($self->defs->{$3}));
      if ($4) {
	$self->defs->{$3}.=" $1=$4"; # so we create a list of defchars separated by spaces
      } else {                 # a value-list may follow the equation mark
	$self->defs->{$3}.=" $1";
      }
      if ($2) {
	$self->defs->{$3}.=" $2"; # we add a special defchar for color
      }
      next;
    } elsif (/^\r*$/o) {
      last;
    } else {
      return 0;
    }
  }
  return 1;
}

=item $format->toArray

Return FS declaration as an array of FS header declarations.

=cut

sub toArray {
  my ($self) = @_;
  return unless ref($self);
  my $defs = $self->defs;
  my @ad;
  my @result;
  my $l;
  my $vals;
  foreach (@{$self->list}) {
    @ad=split ' ',$defs->{$_};
    while (@ad) {
      $l='@';
      if ($ad[0]=~/^L=(.*)/) {
	$vals=$1;
	shift @ad;
	$l.="L";
	$l.=shift @ad if (@ad and $ad[0]=~/^[A0-3]/);
	$l.=" $_|$vals\n";
      } else {
	$l.=shift @ad if @ad;
	$l.=shift @ad if (@ad and $ad[0]=~/^[A0-3]/);
	$l.=" $_\n";
      }
      push @result, $l;
    }
  }
  push @result,"\n";
  return @result;
}

=item $format->writeTo (glob_ref)

Write FS declaration to a given file (file handle open for
reading must be passed as a GLOB reference).

=cut

sub writeTo {
  my ($self,$fileref) = @_;
  return unless ref($self);
  print $fileref $self->toArray;
  return 1;
}


=pod

=item $format->sentord (), order(), value(), hide()

Return names of special attributes declared in FS format as @W, @N,
@V, @H respectively.

=cut

{
  my ($sub, $key);
  while (($sub,$key)= each %Specials) {
    eval "sub $sub { \$_[0]->special('$key'); }";
  }
}

sub DESTROY {
  my ($self) = @_;
  return unless ref($self);
  $self->[0]=undef;
  $self->[1]=undef;
  $self->[2]=undef;
  $self=undef;
}

=pod

=item $format->isHidden (node)

Return the lowest ancestor-or-self of the given node whose value of
the FS attribute declared as @H is either C<'hide'> or 1. Return
undef, if no such node exists.

=cut

sub isHidden {
  # Tests if given node is hidden or not
  # Returns the ancesor that hides it or undef
  my ($self,$node)=@_;
  my $hide=$self->special('H');
  return unless defined $hide;
  my $h;
  while ($node and !(($h = $node->get_member($hide)) eq 'hide'
		       or $h eq 'true'
		       or $h == 1 )) {
    $node=$node->parent;
  }
  return ($node||undef);
}

=pod

=item $format->defs

Return a reference to the internally stored attribute hash.

=cut

sub defs {
  my ($self) = @_;
  return ref($self) ? $self->[0] : undef;
}

=pod

=item $format->list

Return a reference to the internally stored attribute names list.

=cut

sub list {
  my ($self) = @_;
  return ref($self) ? $self->[1] : undef;
}

=pod

=item $format->unparsed

Return a reference to the internally stored unparsed FS header. Note,
that this header must B<not> correspond to the defs and attributes if
any changes are made to the definitions or names at run-time by hand.

=cut

sub unparsed {
  my ($self) = @_;
  return ref($self) ? $self->[2] : undef;
}


=pod

=item $format->renew_specials

Refresh special attribute hash.

=cut

sub renew_specials {
  my ($self)=@_;
  my $re = " ([$SpecialTypes])";
  my %spec;
  my $defs = $self->[0]; # defs
  my ($k,$v);
  while (($k,$v)=each  %$defs) {
    $spec{$1} = $k if $v=~/$re/o;
  }
  return $self->[3] = \%spec;
}

# obsolete
sub findSpecialDef {
  my ($self,$defchar)=@_;
  my $defs = $self->defs;
  foreach (keys %{$defs}) {
    return $_ if (index($defs->{$_}," $defchar")>=0);
  }
  return undef; # we want an explicit undef here!!
}

=item $format->specials

Return a reference to a hash of attributes of special types. Keys
of the hash are special attribute types and values are their names.

=cut

sub specials {
  my ($self) = @_;
  return ($self->[3] || $self->renew_specials());
}

=pod

=item $format->attributes

Return a list of all attribute names (in the order given by FS
instance declaration).

=cut

sub attributes {
  my ($self) = @_;
  return @{$self->list};
}

=pod

=item $format->atno (n)

Return the n'th attribute name (in the order given by FS
instance declaration).

=cut


sub atno {
  my ($self,$index) = @_;
  return ref($self) ? $self->list->[$index] : undef;
}

=pod

=item $format->atdef (attribute_name)

Return the definition string for the given attribute.

=cut

sub atdef {
  my ($self,$name) = @_;
  return ref($self) ? $self->defs->{$name} : undef;
}

=pod

=item $format->count

Return the number of declared attributes.

=cut

sub count {
  my ($self) = @_;
  return ref($self) ? $#{$self->list}+1 : undef;
}

=pod

=item $format->isList (attribute_name)

Return true if given attribute is assigned a list of all possible
values.

=cut

sub isList {
  my ($self,$attrib)=@_;
  return (index($self->defs->{$attrib}," L")>=0) ? 1 : 0;
}

=pod

=item $format->listValues (attribute_name)

Return the list of all possible values for the given attribute.

=cut

sub listValues {
  my ($self,$attrib)=@_;
  return unless ref($self);

  my $defs = $self->defs;
  my ($I,$b,$e);
  $b=index($defs->{$attrib}," L=");
  if ($b>=0) {
    $e=index($defs->{$attrib}," ",$b+1);
    if ($e>=0) {
      return split /\|/,substr($defs->{$attrib},$b+3,$e-$b-3);
    } else {
      return split /\|/,substr($defs->{$attrib},$b+3);
    }
  } else { return (); }
}

=pod

=item $format->color (attribute_name)

Return one of C<Shadow>, C<Hilite> and C<XHilite> depending on the
color assigned to the given attribute in the FS format instance.

=cut

sub color {
  my ($self,$arg) = @_;
  return unless ref($self);

  if (index($self->defs->{$arg}," 1")>=0) {
    return "Shadow";
  } elsif (index($self->defs->{$arg}," 2")>=0) {
    return "Hilite";
  } elsif (index($self->defs->{$arg}," 3")>=0) {
    return "XHilite";
  } else {
    return "normal";
  }
}

=pod

=item $format->special (letter)

Return name of a special attribute declared in FS definition with a
given letter. See also sentord() and similar.

=cut

sub special {
  my ($self,$defchar)=@_;
  return ($self->[3]||$self->renew_specials)->{$defchar};
}

sub set_special {
  my ($self,$defchar,$value)=@_;
  my $spec = ($self->[3]||$self->renew_specials);
  $spec->{$defchar}=$value;
  return;
}

=pod

=item $format->indexOf (attribute_name)

Return index of the given attribute (in the order given by FS
instance declaration).

=cut

sub indexOf {
  my ($self,$arg)=@_;
  return
    ref($self) ? Treex::PML::Index($self->list,$arg) : undef;
}

=item $format->exists (attribute_name)

Return true if an attribute of the given name exists.

=cut

sub exists {
  my ($self,$arg)=@_;
  return
    ref($self) ?
      (exists($self->defs->{$arg}) &&
       defined($self->defs->{$arg})) : undef;
}


=pod

=item $format->make_sentence (root_node,separator)

Return a string containing the content of value (special) attributes
of the nodes of the given tree, separated by separator string, sorted by
value of the (special) attribute sentord or (if sentord does not exist) by
(special) attribute order.

=cut

sub make_sentence {
  my ($self,$root,$separator)=@_;
  return unless ref($self);
  $separator=' ' unless defined($separator);
  my @nodes=();
  my $sentord = $self->sentord || $self->order;
  my $value = $self->value;
  my $node=$root;
  while ($node) {
    push @nodes,$node;
    $node=$node->following($root);
  }
  return join ($separator,
	       map { $_->getAttribute($value) }
	       sort { $a->getAttribute($sentord) <=> $b->getAttribute($sentord) } @nodes);
}


=pod

=item $format->clone_node

Create a copy of the given node.

=cut

sub clone_node {
  my ($self,$node)=@_;
  my $new = ref($node)->new();
  if ($node->type) {
    foreach my $atr ($node->type->get_normal_fields,'#name') {
      if (ref($node->{$atr})) {
	$new->{$atr} = Treex::PML::CloneValue($node->{$atr});
      } else {
	$new->{$atr} = $node->{$atr};
      }
    }
    $new->set_type($node->type);
  } else {
    foreach (@{$self->list}) {
      $new->{$_}=$node->{$_};
    }
  }
  return $new;
}

=item $format->clone_subtree

Create a deep copy of the given subtree.

=cut

sub clone_subtree {
  my ($self,$node)=@_;
  my $nc;
  return 0 unless $node;
  my $prev_nc=0;
  my $nd=$self->clone_node($node);
  foreach ($node->children()) {
    $nc=$self->clone_subtree($_);
    $nc->set_parent($nd);
    if ($prev_nc) {
      $nc->set_lbrother($prev_nc);
      $prev_nc->set_rbrother($nc);
    } else {
      $nd->set_firstson($nc);
    }
    $prev_nc=$nc;
  }
  return $nd;
}


=pod

=back

=cut

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Document>, L<Treex::PML::Schema>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
