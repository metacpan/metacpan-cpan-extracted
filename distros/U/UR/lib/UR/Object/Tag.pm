package UR::Object::Tag;

#TODO: update these to be UR::Value objects instead of some ancient hack

=pod

=head1 NAME

UR::Object::Tag - Transitory attribute tags for a UR::Object at a given time.

=head1 SYNOPSIS

  if (my @attribs = grep { $_->type eq 'invalid' } $obj->attribs()) {
      print $obj->display_name . " has invalid attributes.  They are:\n";
      for my $atrib (@attribs) {
          print join(",",$attrib->properties) . ":" . $attrib->desc . "\n";
      }
  }

  Project H_NHF00 has invalid attributes, they are:
  project_subdirectory : Directory does not exist.
  target, status : Target cannot be null for projects with an active status.

=head1 DESCRIPTION

Objects of this class are created by create_attribs() on classes
derived from UR::Object.  They are retrieved by
UR::Object->attribs().

=head1 INHERITANCE

This class inherits from UR::ModuleBase.

=head1 OBJECT METHODS

=over 4

=item type

A single-word description of the attribute which categorizes the
attribute.  Common attribute types are:

=over 6

=item invalid

Set when the object has invalid properties and cannot be saved.

=item changed

Set when the object is different than its "saved" version.

=item hidden

Set when the object has properties which should not be shown.

=item editable

Set when some part of the object is editable in the current context.

=item warning

Set when a warning about the state of the object is in effect.

=item match

Set when a search which is in effect matches this object's property(s).

=item comment

Set when this attribute is just an informational message.

=back

=item properties

A list of properties to which the attribute applies.  This is null
when the attribute applies to the whole object, but typically returns
one property name.  Occasionally, it returns more than one property.
Very rarely (currently never), the property may be in the form of an
arrayref like: [ class_name, id, property_name ], in which case the
property may actually be that of another related object.

=item desc

A string of text giving detail to the attribute.

=back

=head1 CLASS METHODS

=over 4

=item create

Makes a new UR::Object::Tag.

=item delete

Throws one away.

=item filter

Sets/gets a filter to be applied to all attribute lists returned in
the application.  This gives the application developer final veto
power over expressed attributes in the app.  In most cases, developers
will write view components which use attributes, and will ignore
them rather than plug-in at this low level to augment/mangle/suppress.

The filter will be given an object reference and a reference to an
array of attributes which are tentatively to be delivered for the
object.

=cut

# set up package
require 5.006_000;
use warnings;
use strict;
our $VERSION = "0.46"; # UR $VERSION;

# set up module
use base qw(UR::ModuleBase);
our (@EXPORT, @EXPORT_OK);
@EXPORT = qw();
@EXPORT_OK = qw();

##- use UR::Util;

our %default_values =
(
    type => undef,
    properties => [],
    desc => undef
);
UR::Util->generate_readwrite_methods(%default_values);

*type_name = \&type;
*property_names = \&properties;
*description = \&description;

sub create($@)
{
    my ($class, @initial_prop) = @_;
    my $self = bless({%default_values,@initial_prop},$class);
    if (not ref($self->{properties}) eq 'ARRAY') {
        $self->{properties} = [ $self->{properties} ];
    }
    return $self;
}

sub delete($)
{
    UR::DeletedRef->bury($_[0])
}

our $filter;
sub filter
{
    if (@_ > 1)
    {
        my $old = $filter;
        $filter = $_[1];
        return $old;
    }
    return $filter;
}

sub __display_name__ {
    my $self = shift;
    my $desc = $self->desc;
    my $prefix = uc($self->type);
    my @properties = map { "'$_'" } $self->properties;
    my $prop_noun = scalar(@properties) > 1 ? 'properties' : 'property';
    my $msg = "$prefix: $prop_noun " . join(', ', @properties) . ": $desc";
    return $msg;
}

1;
__END__

=pod

=back

=head1 SEE ALSO

UR::Object(3)

=cut

#$Header$
