=pod

=head1 NAME

XML::TreePP::Editor - An editor for an XML::TreePP parsed XML document

=head1 SYNOPSIS

To use stand-alone:

    use strict;
    use XML::TreePP;
    use XML::TreePP::Editor;
    
    my $tpp = XML::TreePP->new();
    my $tree = $tpp->parse('file.xml');
    my $tppe = new XML::TreePP::Editor();
    $tppe->replace( $tree, '/path[2]/element[2]/node', { '-myattribute' => "new value" } );
    $tppe->insert( $tree, '.', \%{<new_root_node>} );

=head1 DESCRIPTION

This module is used for editing a C<XML::TreePP> parsed XML Document.

=head1 REQUIREMENTS

The following perl modules are depended on by this module:

=over 4

=item *     XML::TreePP

=item *     XML::TreePP::XMLPath  >= version 0.61

=back

=head1 Editor PHILOSOPHY

=head2 XML Node and Attribute Identification

The identification of XML document nodes for modification is handled by the
C<XML::TreePP::XMLPath> module.

The idenfication of attributes in XML nodes is via the C<attr_prefix> property
in the C<XML::TreePP> module.

The idenfication of XML text (or CDATA) nodes is via the C<text_node_key>
property in the C<XML::TreePP> module.

Please review the XMLPath PHILOSOPHY section in it's POD for further
information.

=head2 C<XML::TreePP::XMLPath> dependency on C<XML::TreePP>

The C<XML::TreePP::XMLPath> module has a dependence on C<XML::TreePP>
When C<XML::TreePP::Editor::tpp()> and C<XML::TreePP::Editor::tppx()> methods
are called without parameters, this module checks to see if either of these
objects have been previously created, and links them together.

If you provide your own C<XML::TreePP> or C<XML::TreePP::XMLPath> objects, this
module does not attempt to link them together. Instead you would want to do
it yourself in the following fashion.

    my $tpp = new XML::TreePP;
    my $tppx = new XML::TreePP::XMLPath;
    $tppx->tpp($tpp);
    my $tppe = new XML::TreePP::Editor( tpp => $tpp, tppx => $tppx );

This is essentially similar to how the C<XML::TreePP::Editor::tpp()> and
C<XML::TreePP::Editor::tppx()> methods associate the objects.

=head1 METHODS

=cut

package XML::TreePP::Editor;

use 5.005;
use warnings;
use strict;
use Carp;
use XML::TreePP;
use XML::TreePP::XMLPath 0.61;
use Data::Dumper;

BEGIN {
    use vars      qw(@ISA @EXPORT @EXPORT_OK);
    @ISA        = qw(Exporter);
    @EXPORT     = qw();
    @EXPORT_OK  = qw();

    use vars      qw($REF_NAME);
    $REF_NAME   = "XML::TreePP::Editor";  # package name

    use vars      qw( $VERSION $DEBUG $TPPKEYS );
    $VERSION    = '0.13';
    $DEBUG      = 0;
    $TPPKEYS    = "force_array force_hash cdata_scalar_ref user_agent http_lite lwp_useragent base_class elem_class xml_deref first_out last_out indent xml_decl output_encoding utf8_flag attr_prefix text_node_key ignore_error use_ixhash";
}


=pod

=head2 tpp

This module is an extension of the C<XML::TreePP module>. As such, it uses the
module in many different methods to parse XML Docuements, and when the user
calls the C<set()> and C<get()> methods to set and get properties specific to
the module.

The C<XML::TreePP module>, is loaded upon requesting a new object.

The caller can override the loaded instance of C<XML::TreePP> in favor of
another instance the caller posses, by providing it to this method.

Additionally, this module's loaded instance of C<XML::TreePP> can be directly
accessed or retrieved through this method.

=over 4

=item * C<XML::TreePP>

An instance of C<XML::TreePP> that this object should use instead of, when needed,
loading its own copy. If not provided, the currently loaded instance is
returned. If an instance is not loaded, an instance is loaded and then returned.

=item * I<returns>

Returns the result of setting an instance of C<XML::TreePP> in this object.
Or returns the internally loaded instance of C<XML::TreePP>.
Or loads a new instance of C<XML::TreePP> and returns it.

=back

    $tppe->tpp( new XML::TreePP );  # Sets the XML::TreePP instance to be used by this object
    my $tppobj = $tppe->tpp();  # Retrieve the currently loaded XML::TreePP instance

=cut

sub tpp(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (!defined $self) {
        return new XML::TreePP;
    } else {
        # If being given the object, set it and return result
        return $self->{'tpp'} = shift if @_ >= 1 && ref($_[0]) eq "XML::TreePP";
        # If wanting object, and XMLPath object exists, retrieve it, set it, and return it
        if ((defined $self->{'tppx'}) && (ref($self->{'tppx'}) eq "XML::TreePP::XMLPath")) {
            $self->{'tpp'} = $self->{'tppx'}->tpp();
            return $self->{'tpp'};
        }
        # If wanting object and XMLPath object does not exist, create it and return it
        $self->{'tpp'} = new XML::TreePP;
        return $self->{'tpp'};
    }
}


=pod

=head2 tppx

This module is an extension of the C<XML::TreePP::XMLPath> module. As such,
it uses the module in many different methods to access C<XML::TreePP> parsed XML
Documents, and when the user calls the C<set()> and C<get()> methods to set
and get properties specific to the module.

The C<XML::TreePP::XMLPath> module, is loaded upon requesting a new object.

The caller can override the loaded instance of C<XML::TreePP::XMLPath> in favor of
another instance the caller posses, by proving it to this method.

Additionally, this module's loaded instance of C<XML::TreePP::XMLPath> can be
directly accessed or retrieved through this method.

=over 4

=item * C<XML::TreePP::XMLPath>

An instance of C<XML::TreePP::XMLPath> that this object should use instead of,
when needed, loading its own copy. If not provided, the currently loaded
instance is returned. If an instance is not already loaded, a new instance is
loaded and then returned.

=item * I<returns>

Returns the result of setting an instance of C<XML::TreePP::XMLPath> in this object.
Or returns the internally loaded instance of C<XML::TreePP::XMLPath>.
Or loads a new instance of C<XML::TreePP::XMLPath> and returns it.

=back

    $tppe->tppx( new XML::TreePP::XMLPath );  # Sets the XML::TreePP instance to be used by this object
    my $tppxobj = $tppe->tppx();  # Retrieve the currently loaded XML::TreePP instance

=cut

sub tppx(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    if (!defined $self) {
        return new XML::TreePP::XMLPath;
    } else {
        # If being given the object, set it and return result
        return $self->{'tppx'} = shift if @_ >= 1 && ref($_[0]) eq "XML::TreePP::XMLPath";
        # If wanting object, and XML::TreePP object exists, create it, associate it, and return it
        # Create
        $self->{'tppx'} = new XML::TreePP::XMLPath;
        # Associate
        if ((defined $self->{'tpp'}) && (ref($self->{'tpp'}) eq "XML::TreePP")) {
            $self->{'tppx'}->tpp( $self->{'tpp'} );
        }
        # Return
        return $self->{'tppx'};
    }
}


=pod

=head2 set

Set the value for a property in this object instance.
This method can only be accessed in object oriented style.

=over 4

=item * C<propertyname>

The property to set the value for.

=item * C<propertyvalue>

The value of the property to set.
If no value is given, the property is deleted.

=item * I<returns>

Returns the result of setting the value of the property, or the result of
deleting the property.

=back

    $tppe->set( 'property_name' );            # deletes the property property_name
    $tppe->set( 'property_name' => 'val' );   # sets the value of property_name

=cut

sub set(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || return undef;
    my %args    = @_;
    while (my ($key,$val) = each %args) {
        if ( defined $val ) {
            $self->{$key} = $val;
        }
        else {
            delete $self->{$key};
        }
    }
}


=pod

=head2 get

Retrieve the value set for a property in this object instance.
This method can only be accessed in object oriented style.

=over 4

=item * C<propertyname>

The property to get the value for

=item * I<returns>

Returns the value of the property requested

=back

    $tppe->get( 'property_name' );

=cut

sub get(@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || return undef;
    my $key     = shift;
    return $self->{$key} if exists $self->{$key};
    return undef;
}


=pod

=head2 new

Create a new object instances of this module.

=over 4

=item * B<tpp>

An instance of C<XML::TreePP> to be used instead of letting this module load
its own.

=item * B<tppx>

An instance of C<XML::TreePP::XMLPath> to be used instead of letting this
module load its own.

=item * B<debug>

The debug level to set on this object.

=item * I<returns>

An object instance of this module.

=back

    my $cfg = new XML::TreePP::Editor();

=cut

sub new () {
    my $pkg         = shift; 
    my $class       = ref($pkg) || $pkg;
    my $self        = bless {}, $class;
    my %args        = @_;

    $self->tpp($args{'tpp'}) if exists $args{'tpp'};
    $self->tppx($args{'tppx'}) if exists $args{'tppx'};
    $args{'debug'} ||= $DEBUG;
    $self->debug($args{'debug'});

    return $self;
}


=pod

=head2 debug

Set the debug level

=over 4

=item * B<val> - optional

A value that is >= 0

=item * I<returns>

If passing in B<val>, then the result of setting that value to the object's debug variable.

If not passing in B<val>, then the current set value of the object's debug variable.

=back

    $tppe->debug(0);  # turn off debug
    $tppe->debug(9);  # turn on debug with value of 9
    my $debuglevel = $tppe->debug();

=cut

sub debug {
    my $self = shift;
    if (@_ == 0) {
        return $DEBUG if !defined $self->{'_debug'};
        return $self->{'_debug'};
    }
    return $self->{'_debug'} = shift;
}


=pod

=head2 modify

modify( XMLTree, XMLPath, %OPTIONS )

where %options = ( action => %value )

and action is one of ( insert, replace, delete, mergeadd, mergereplace, mergedelete, mergeappend )

and %value is a XML Node Hash, either a partial node or full node

=over 4

=item * B<XML::TreePP parsed tree>

The parsed XML Document.

=item * B<XML::TreePP::XMLPath path>

The XML Path to the node, attribute or element to modify

=item * B<options>

The options for modifying the node.

=over 4

=item * insert => C<\%node> - insert the new node at XMLPath

=item * replace => C<\%node> - replace the node at XMLPath with this new node

=item * delete => C<undef> - delete the node at the XMLPath

=item * mergeadd => C<\%node> - merge this node into the node at XMLPath,
only adding elements and attributes that do not exist

=item * mergereplace => C<\%node> - merge this node into the node at XMLPath,
replacing elements and attributes, and adding them if they do not exist

=item * mergedelete => C<\%node> - merge this node into the node at XMLPath,
deleting elements and attributes that exist in both nodes

=item * mergeappend => C<\%node> - merge this node into the node at XMLPath,
appending the values of text elements

=back

B<note:> This method uses the values retrieved from
$self->tpp()->get('attr_prefix') and $self->tpp()->get('text_node_key') to
define how to interpret how to identify attributes and text (CDATA) nodes.

=back

Example:

    my $xmltree => { path => { to => { node => "Brown bears" } } };
    $tppe->modify( $xmltree, '/path/to/node', mergeappend => { '#text' => " with blue shoes." } )
    # or: $tppe->modify( $xmltree, '/path/to/node/#text', mergeappend => { '#text' => " with blue shoes." } )
    # or: $tppe->modify( $xmltree, '/path/to/node/#text', mergeappend => " with blue shoes." )
    print $xmltree->{'path'}->{'to'}->{'node'};
    
    output:
    
    Brown bears with blue shoes.

=cut

sub modify (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    unless (@_ >= 3) { carp 'method modify() requires at least three arguments.'; return undef; }
    my $xtree   = shift;
    my $xmlpath = shift; # XML::TreePP::XMLPath
    my %options = @_;    # replace=>\%val; insert=>\%val; etc.
    my $numAffected = 0;

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    my ($tpp,$tppx,$xml_text_id,$xml_attr_id);

    if ((defined $self) && (defined $self->get('tpp'))) {
        $tpp         = $self ? $self->tpp() : tpp();
        $tppx        = $self ? $self->tppx() : tppx();
        $xml_text_id = $tpp->get( 'text_node_key' ) || '#text';
        $xml_attr_id = $tpp->get( 'attr_prefix' )   || '-';
    } else {
        $xml_text_id = '#text';
        $xml_attr_id = '-';
    }

    my $whatisnode = sub ($) {
        my $nodename = shift;
        return undef        if ref($nodename);
        return "text"       if $nodename eq $xml_text_id;
        return "attribute"  if $nodename =~ /^$xml_attr_id\w+$/;
        return "parent"     if $nodename eq '..';
        return "current"    if $nodename eq '.';
        return "element";
    };
    my $isnodetype = sub ($) {
        my $nodename = shift;
        my $compare = shift;
        return 1 if $whatisnode->($nodename) eq $compare;
        return 0;
    };

    my $nodeMerge = sub (@) {};
    $nodeMerge = sub (@) {
        my $parentnode  = shift; # ref - must be HASH ref, or ARRAY if merging to multiple parents
        my $childname   = shift; # ref->ref                            # merge into the node with this child name | or append to $stringname of existing child node
        my $childpos    = shift; # ref->ref->[#] - can be undef        # merge into the node at this position, undef to merge into all | or append to $stringname of existing child node at this position
        my $stringname  = shift; # ref->ref->[#]->name - can be undef  # append to this $stringname of the child node
        my $value       = shift;
        my %options     = @_;
        my $mergetype   = $options{'mergetype'} || "add";  # add|replace|delete|append
        my $result      = 0;

        if (!ref($parentnode)) {
            croak "Cannot merge a child node to a non referencing parent node.";
            return undef;
        } elsif (ref($parentnode) eq "ARRAY") {
            if (@{$parentnode} == 0) {
                push(@{$parentnode}, {});
            }
            foreach my $single_parentnode (@{$parentnode}) {
                my $newresult = $nodeMerge->($single_parentnode,$childname,$childpos,$stringname,$value);
                $result += $newresult;
            }
        } elsif (ref($parentnode) eq "HASH") {
            # In every case (but for appending to $stringname), we are merging into an existing child node
            my $newchildnode;
            if ((!ref($value)) && (defined $value) && (defined $stringname)) {
                $newchildnode   = [{ $stringname => $value }];
            } elsif ((!ref($value)) && (!defined $stringname)) {
                $newchildnode   = [{ $xml_text_id => $value }];
            } elsif (ref($value)) {
                $newchildnode = [ $value ] if ref($value) eq "HASH";
                $newchildnode = $value if ref($value) eq "ARRAY";
            } else {
                return undef;
            }

            if (ref($parentnode->{$childname}) eq "ARRAY") {
                if ((defined $childpos) && ($childpos >= 1) && ($childpos <= @{$parentnode->{$childname}})) {
                    if ((defined $stringname) && ($isnodetype->($stringname, "text"))) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        # append to #text
                        if (ref($parentnode->{$childname}->[($childpos - 1)]) eq "HASH") {
                            $parentnode->{$childname}->[($childpos - 1)]->{$stringname} .= $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif (!ref($parentnode->{$childname}->[($childpos - 1)])) {
                            $parentnode->{$childname}->[($childpos - 1)] .= $newchildnode->[0]->{$stringname};
                            $result++;
                        }
                    } elsif (defined $stringname) {
                        # do not replace @attributes, parentnode is priority on keeping attribute values - use replace to replace them
                        # $parentnode->{$childname}->[($childpos - 1)]->{$stringname} = $newchildnode->[0]->{$stringname};
                        # $result++;
                    } else {
                        foreach my $vk (keys %{$newchildnode->[0]}) {
                            if (!exists $parentnode->{$childname}->[($childpos - 1)]->{$vk}) {
                                $parentnode->{$childname}->[($childpos - 1)]->{$vk} = $newchildnode->[0]->{$vk};
                                $result++;
                            } elsif (exists $parentnode->{$childname}->[($childpos - 1)]->{$vk}) {
                                if ($isnodetype->($vk, "text")) {
                                    # Merge #text/CDATA
                                    $parentnode->{$childname}->[($childpos - 1)]->{$vk} = ($parentnode->{$childname}->[($childpos - 1)]->{$vk} . $newchildnode->[0]->{$vk})
                                } elsif ($isnodetype->($vk, "attribute")) {
                                    # Do not replace attributes
                                    #$parentnode->{$childname}->[($childpos - 1)]->{$vk} = $newchildnode->[0]->{$vk} if $isnodetype->($vk, "attribute");
                                } elsif (ref($parentnode->{$childname}->[($childpos - 1)]->{$vk}) eq "ARRAY") {
                                    # append new merged ones
                                    push (@{$parentnode->{$childname}->[($childpos - 1)]->{$vk}},$newchildnode->[0]->{$vk}) if ref($newchildnode->[0]->{$vk}) ne "ARRAY";
                                    push (@{$parentnode->{$childname}->[($childpos - 1)]->{$vk}},@{$newchildnode->[0]->{$vk}}) if ref($newchildnode->[0]->{$vk}) eq "ARRAY";
                                    $result++;
                                } else {
                                    # convert to array, and append new merged ones
                                    $parentnode->{$childname}->[($childpos - 1)]->{$vk} = [$parentnode->{$childname}->[($childpos - 1)]->{$vk},$newchildnode->[0]->{$vk}] if ref($newchildnode->[0]->{$vk}) ne "ARRAY";
                                    $parentnode->{$childname}->[($childpos - 1)]->{$vk} = [$parentnode->{$childname}->[($childpos - 1)]->{$vk},@{$newchildnode->[0]->{$vk}}] if ref($newchildnode->[0]->{$vk}) eq "ARRAY";
                                    $result++;
                                }
                            }
                        }
                    }
                } elsif (!defined $childpos) {
                    my $i = 0;
                    while ($i < @{$parentnode->{$childname}}) {
                        if ((defined $stringname) && ($isnodetype->($stringname, "text"))) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                            if (ref($parentnode->{$childname}->[($childpos - 1)]) eq "HASH") {
                                $parentnode->{$childname}->[$i]->{$stringname} .= $newchildnode->[0]->{$stringname};
                                $result++;
                            } elsif (!ref($parentnode->{$childname}->[($childpos - 1)])) {
                                $parentnode->{$childname}->[$i] .= $newchildnode->[0]->{$stringname};
                                $result++;
                            }
                        } elsif (defined $stringname) {
                            $parentnode->{$childname}->[$i]->{$stringname} = $newchildnode->[0]->{$stringname};
                            $result++;
                        } else {
                            $result += $nodeMerge->($parentnode,$childname,$i,undef,$newchildnode->[0]);
                        }
                        $i++;
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            } else {
                if ((!defined $childpos) || ($childpos == 1)) {
                    if ((defined $stringname) && ($isnodetype->($stringname, "text"))) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        # The parent node keeps all attribute values, but combines #text or CDATA
                        if (ref($parentnode->{$childname}) eq "HASH") {
                            $parentnode->{$childname}->{$stringname} .= $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif (!ref($parentnode->{$childname})) {
                            $parentnode->{$childname} .= $newchildnode->[0];
                            $result++;
                        }
                    } elsif (defined $stringname) {
                        # The parent node keeps all attribute values - use replace to replace them
                        # $parentnode->{$childname}->{$stringname} = $newchildnode->[0]->{$stringname};
                    } else {
                        $parentnode->{$childname} = $newchildnode->[0];
                        $result++;
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            }
        }
        return $result;
    };

    my $nodeMergeActionSingle = sub (@) {};
    $nodeMergeActionSingle = sub (@) {
        my $targetnode  = shift;
        my $mergenode   = shift;
        my $action      = shift;  # add | append | replace | delete
        my $result      = 0;
        # print Dumper({ targetnode => $targetnode, mergenode => $mergenode, action => $action });
        unless ( (ref($targetnode) eq "HASH") && (ref($mergenode) eq "HASH") && (defined $action) ) {
            return undef;
        }
        foreach my $vk (keys %{$mergenode}) {
            if ($action eq "mergeadd") {
                if      (   (exists $targetnode->{$vk})
                         && (ref($targetnode->{$vk}))  ) {
                    # do nothing, already exists as a referenced element
                } elsif (   (exists $targetnode->{$vk})
                         && (!ref($targetnode->{$vk}))
                         && (defined $targetnode->{$vk})
                         && ($targetnode->{$vk} ne "") ) {
                    # do nothing, already exists as text string or CDATA
                } else {
                    $targetnode->{$vk} = $mergenode->{$vk};
                    $result++;
                }
            } elsif ($action eq "mergeappend") {
                # we can only append if the target value and merge value are text or CDATA
                if (   ($isnodetype->($vk, "text"))
                    || ($isnodetype->($vk, "attribute"))
                    || ((!ref($targetnode->{$vk})) && ($mergenode->{$vk} =~ /\w+/)) ) {
                    $targetnode->{$vk} .= $mergenode->{$vk};
                    $result++;
                }
            } elsif ($action eq "mergereplace") {
                $targetnode->{$vk} = $mergenode->{$vk};
                $result++;
            } elsif ($action eq "mergedelete") {
                if (exists $targetnode->{$vk}) {
                    delete $targetnode->{$vk};
                    $result++;
                }
            }
        }
        return $result;
    };
    my $nodeMergeAction = sub (@) {};
    $nodeMergeAction = sub (@) {
        my $parentnode  = shift; # ref - must be HASH ref, or ARRAY if merging to multiple parents
        my $childname   = shift; # ref->ref                            # merge into the node with this child name | or append to $stringname of existing child node
        my $childpos    = shift; # ref->ref->[#] - can be undef        # merge into the node at this position, undef to merge into all | or append to $stringname of existing child node at this position
        my $stringname  = shift; # ref->ref->[#]->name - can be undef  # append to this $stringname of the child node
        my $value       = shift;
        my %options     = @_;
        my $action      = $options{'mergetype'} || "add";  # add|replace|delete|append
        my $result      = 0;

        if (!ref($parentnode)) {
            croak "Cannot merge a child node to a non referencing parent node.";
            return undef;
        } elsif (ref($parentnode) eq "ARRAY") {
            if (@{$parentnode} == 0) {
                push(@{$parentnode}, {});
            }
            foreach my $single_parentnode (@{$parentnode}) {
                my $newresult = $nodeMergeAction->($single_parentnode,$childname,$childpos,$stringname,$value);
                $result += $newresult;
            }
        } elsif (ref($parentnode) eq "HASH") {
            # In every case (but for appending to $stringname), we are merging into an existing child node
            my $newchildnode;
            if ((!ref($value)) && (defined $value) && (defined $stringname)) {
                $newchildnode   = [{ $stringname => $value }];
            } elsif ((!ref($value)) && (!defined $stringname)) {
                $newchildnode   = [{ $xml_text_id => $value }];
            } elsif (ref($value)) {
                $newchildnode = [ $value ] if ref($value) eq "HASH";
                $newchildnode = $value if ref($value) eq "ARRAY";
            } else {
                return undef;
            }

            if (ref($parentnode->{$childname}) eq "ARRAY") {
                my @childpositions;
                if ((defined $childpos) && ($childpos >= 1) && ($childpos <= @{$parentnode->{$childname}})) {
                    push (@childpositions,$childpos);
                } elsif (!defined $childpos) {
                    for (my $i=1; $i <= @{$parentnode->{$childname}}; $i++) {
                        push (@childpositions,$i);
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
                foreach my $tchildpos (@childpositions) {
                    if (ref($parentnode->{$childname}->[($tchildpos - 1)]) eq "HASH") {
                        if (defined $stringname) {
                            $result += $nodeMergeActionSingle->($parentnode->{$childname}->[($tchildpos - 1)], { $stringname => $newchildnode->[0]->{$stringname} }, $action);
                        } else {
                            $result += $nodeMergeActionSingle->($parentnode->{$childname}->[($tchildpos - 1)], $newchildnode->[0], $action);
                        }
                    } elsif (!ref($parentnode->{$childname}->[($tchildpos - 1)])) {
                        if ((defined $stringname) && ($isnodetype->($stringname, "text"))) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                            # append to #text
                            if ($action eq "replace") {
                                $parentnode->{$childname}->[($tchildpos - 1)] = $newchildnode->[0]->{$stringname};
                                $result++;
                            } elsif ($action eq "append") {
                                $parentnode->{$childname}->[($tchildpos - 1)] .= $newchildnode->[0]->{$stringname};
                                $result++;
                            } elsif ($action eq "add") {
                                if ($parentnode->{$childname}->[($tchildpos - 1)] !~ /\w+/) {
                                    $parentnode->{$childname}->[($tchildpos - 1)] = $newchildnode->[0]->{$stringname};
                                    $result++;
                                }
                            } elsif ($action eq "delete") {
                                $parentnode->{$childname}->[($tchildpos - 1)] = undef;
                                $result++;
                            }
                        } else {
                            if ((defined $parentnode->{$childname}->[($tchildpos - 1)]) && ($parentnode->{$childname}->[($tchildpos - 1)] =~ /\w+/)) {
                                $parentnode->{$childname}->[($tchildpos - 1)] = { $xml_text_id => $parentnode->{$childname}->[($tchildpos - 1)] };
                            } else {
                                $parentnode->{$childname}->[($tchildpos - 1)] = {};
                            }
                            if (defined $stringname) {
                                $result += $nodeMergeActionSingle->($parentnode->{$childname}->[($tchildpos - 1)], { $stringname => $newchildnode->[0]->{$stringname} }, $action);
                            } else {
                                $result += $nodeMergeActionSingle->($parentnode->{$childname}->[($tchildpos - 1)], $newchildnode->[0], $action);
                            }
                        }
                    }
                }
            } elsif (ref($parentnode->{$childname}) eq "HASH") {
                if ( ((defined $childpos) && ($childpos == 1)) || (!defined $childpos) ) {
                    if (defined $stringname) {
                        $result += $nodeMergeActionSingle->($parentnode->{$childname}, { $stringname => $newchildnode->[0]->{$stringname} }, $action);
                    } else {
                        $result += $nodeMergeActionSingle->($parentnode->{$childname}, $newchildnode->[0], $action);
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            } else {
                if ( ((defined $childpos) && ($childpos == 1)) || (!defined $childpos) ) {
                    if ((defined $stringname) && ($isnodetype->($stringname, "text"))) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        # append to #text
                        if ($action eq "replace") {
                            $parentnode->{$childname} = $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif ($action eq "append") {
                            $parentnode->{$childname} .= $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif ($action eq "add") {
                            if ($parentnode->{$childname} !~ /\w+/) {
                                $parentnode->{$childname} = $newchildnode->[0]->{$stringname};
                                $result++;
                            }
                        } elsif ($action eq "delete") {
                            $parentnode->{$childname} = undef;
                            $result++;
                        }
                    } else {
                        if ((defined $parentnode->{$childname}) && ($parentnode->{$childname} =~ /\w+/)) {
                            $parentnode->{$childname} = { $xml_text_id => $parentnode->{$childname} };
                        } else {
                            $parentnode->{$childname} = {};
                        }
                        if (defined $stringname) {
                            $result += $nodeMergeActionSingle->($parentnode->{$childname}, { $stringname => $newchildnode->[0]->{$stringname} }, $action);
                        } else {
                            $result += $nodeMergeActionSingle->($parentnode->{$childname}, $newchildnode->[0], $action);
                        }
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            }
        }
        return $result;
    };

    my $nodeInsert = sub (@) {};
    $nodeInsert = sub (@) {
        my $parentnode  = shift; # ref - must be HASH ref, or ARRAY if inserting to multiple parents
        my $childname   = shift; # ref->ref                            # insert a new node with this child name | or insert $stringname to this existing node
        my $childpos    = shift; # ref->ref->[#] - can be undef        # insert the new node at this position, undef to append | or insert $stringname to existing node at this position
        my $stringname  = shift; # ref->ref->[#]->name - can be undef  # insert this $stringname with $value to the child node | or append $value if $stringname exists
        my $value       = shift; # ref->ref->[#]->name = $value        # the string value for $stringname if defined | or the value for the node named $childname
        my $result      = 0;

        if (!ref($parentnode)) {
            croak "Cannot insert a child node to a non referencing parent node.";
            return undef;
        } elsif (ref($parentnode) eq "ARRAY") {
            if (@{$parentnode} == 0) {
                push (@{$parentnode}, {});
            }
            foreach my $single_parentnode (@{$parentnode}) {
                my $newresult = $nodeInsert->($single_parentnode,$childname,$childpos,$stringname,$value);
                $result += $newresult;
            }
        } elsif (ref($parentnode) eq "HASH") {
            # In every case here, we are inserting a new child node
            my $newchildnode;
            if ((!ref($value)) && (defined $value) && (defined $stringname)) {
                $newchildnode   = [{ $stringname => $value }];
            } elsif ((!ref($value)) && (!defined $stringname)) {
                $newchildnode   = [{ $xml_text_id => $value }];
            } elsif (ref($value)) {
                $newchildnode = [ $value ] if ref($value) eq "HASH";
                $newchildnode = $value if ref($value) eq "ARRAY";
            } else {
                return undef;
            }

            if (!ref($parentnode->{$childname})) {
                if ($parentnode->{$childname} =~ /\w+/) {
                    my $currentchildnode = { $xml_text_id => $parentnode->{$childname} };
                    if ($childpos == 1) {
                        $parentnode->{$childname} = [ @{$newchildnode}, $currentchildnode ];
                        $result += @{$newchildnode};
                    } else {
                        $parentnode->{$childname} = [ $currentchildnode, @{$newchildnode} ];
                        $result += @{$newchildnode};
                    }
                } else {
                    $parentnode->{$childname} = $newchildnode;
                    $result += @{$newchildnode};
                }
            } elsif (ref($parentnode->{$childname}) eq "HASH") {
                if ($childpos == 1) {
                    push (@{$newchildnode}, $parentnode->{$childname});
                    $result += @{$newchildnode};
                } else {
                    unshift (@{$newchildnode}, $parentnode->{$childname});
                    $result += @{$newchildnode};
                }
                $parentnode->{$childname} = $newchildnode
            } elsif (ref($parentnode->{$childname}) eq "ARRAY") {
                my $size = @{$parentnode->{$childname}};
                if (($childpos >= 1) && ($childpos <= $size)) {
                    splice(@{$parentnode->{$childname}},($childpos - 1), 0, @{$newchildnode});
                    $result += @{$newchildnode};
                } else {
                    push(@{$parentnode->{$childname}}, @{$newchildnode});
                    $result += @{$newchildnode};
                }
            }
        }
        return $result;
    };

    my $nodeReplace = sub (@) {};
    $nodeReplace = sub (@) {
        my $parentnode  = shift; # ref - must be HASH ref, or ARRAY if replacing to multiple parents
        my $childname   = shift; # ref->ref                            # replace the node with this child name | or replace $stringname of existing child node
        my $childpos    = shift; # ref->ref->[#] - can be undef        # replace the node at this position, undef to replace all | or replace $stringname of existing child node at this position
        my $stringname  = shift; # ref->ref->[#]->name - can be undef  # replace this $stringname of the child node
        my $value       = shift;
        my $result      = 0;
        # print Dumper({ parentnode => $parentnode, childname => $childname, childpos => $childpos, stringname => $stringname, value => $value });

        if (!ref($parentnode)) {
            croak "Cannot replace a child node to a non referencing parent node.";
            return undef;
        } elsif (ref($parentnode) eq "ARRAY") {
            if (@{$parentnode} == 0) {
                $parentnode = [{}];
            }
            foreach my $single_parentnode (@{$parentnode}) {
                my $newresult = $nodeReplace->($single_parentnode,$childname,$childpos,$stringname,$value);
                $result += $newresult;
            }
        } elsif (ref($parentnode) eq "HASH") {
            # In every case (but for replacing $stringname), we are replacing a new child node, having deleted any existing at the same path
            my $newchildnode;
            if ((!ref($value)) && (defined $value) && (defined $stringname)) {
                $newchildnode   = [{ $stringname => $value }];
            } elsif ((!ref($value)) && (!defined $stringname)) {
                $newchildnode   = [{ $xml_text_id => $value }];
            } else {
                $newchildnode = [ $value ] if ref($value) eq "HASH";
                $newchildnode = $value if ref($value) eq "ARRAY";
            }

            if (ref($parentnode->{$childname}) eq "ARRAY") {
                if ((defined $childpos) && ($childpos >= 1) && ($childpos <= @{$parentnode->{$childname}})) {
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        # Node could just be CDATA (#text) and not HASH
                        if (ref($parentnode->{$childname}->[($childpos - 1)]) eq "HASH") {
                            $parentnode->{$childname}->[($childpos - 1)]->{$stringname} = $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif (($parentnode->{$childname}->[($childpos - 1)] =~ /\w+/) && ($isnodetype->($stringname, "text"))) {
                            $parentnode->{$childname}->[($childpos - 1)] = $newchildnode->[0]->{$stringname};
                            $result++;
                        }
                    } else {
                        splice(@{$parentnode->{$childname}},($childpos - 1), 1, @{$newchildnode});
                        $result += @{$newchildnode};
                    }
                } elsif (!defined $childpos) {
                    # If not $childpos, then all items of node are affected
                    my $i = 0;
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        while ($i < @{$parentnode->{$childname}}) {
                            print "-replace array $childname $i\n" if $DEBUG;
                            # Node could just be CDATA (#text) and not HASH
                            if (ref($parentnode->{$childname}->[$i]) eq "HASH") {
                                $parentnode->{$childname}->[$i]->{$stringname} = $newchildnode->[0]->{$stringname};
                                $result++;
                            } elsif (($parentnode->{$childname}->[$i] =~ /\w+/) && ($isnodetype->($stringname, "text"))) {
                                $parentnode->{$childname}->[$i] = $newchildnode->[0]->{$stringname};
                                $result++;
                            }
                            $i++;
                        }
                    } else {
                        print "-replace ALL $childname $i\n" if $DEBUG;
                        $parentnode->{$childname} = $newchildnode;
                        $result++;
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            } else {
                if ((!defined $childpos) || ($childpos == 1)) {
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
# print Dumper( { parentnode => $parentnode, childname => $childname, stringname => $stringname, newchildname => $newchildnode } );
                        if (ref($parentnode->{$childname}) eq "HASH") {
                            $parentnode->{$childname}->{$stringname} = $newchildnode->[0]->{$stringname};
                            $result++;
                        } elsif (($parentnode->{$childname} =~ /\w+/) && ($isnodetype->($stringname, "text"))) {
                            $parentnode->{$childname} = $newchildnode->[0]->{$stringname};
                            $result++;
                        }
                    } else {
                        $parentnode->{$childname} = $newchildnode;
                        $result++;
                    }
                } else {
                    croak "Cannot replace child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot replace child node items, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            }
        }
        return $result;
    };

    my $nodeDelete = sub (@) {};
    $nodeDelete = sub (@) {
        my $parentnode  = shift; # ref - must be HASH ref, or ARRAY if replacing to multiple parents
        my $childname   = shift; # ref->[#]->ref                            # delete the node with this child name | or delete $stringname of existing child node
        my $childpos    = shift; # ref->[#]->ref->[#] - can be undef        # delete the node at this position, undef to delete all | or delete $stringname of existing child node at this position
        my $stringname  = shift; # ref->[#]->ref->[#]->name - can be undef  # delete this $stringname of the child node
        my $result      = 0;

        if (!ref($parentnode)) {
            croak "Cannot delete a child node to a non referencing parent node.";
            return undef;
        } elsif (ref($parentnode) eq "ARRAY") {
            if (@{$parentnode} == 0) {
                $parentnode = [{}];
            }
            foreach my $single_parentnode (@{$parentnode}) {
                my $newresult = $nodeDelete->($single_parentnode,$childname,$childpos,$stringname);
                $result += $newresult;
            }
        } elsif (ref($parentnode) eq "HASH") {
            if (ref($parentnode->{$childname}) eq "ARRAY") {
                if ((defined $childpos) && ($childpos >= 1) && (($childpos - 1) <= @{$parentnode->{$childname}})) {
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        if (ref($parentnode->{$childname}->[($childpos - 1)]) eq "HASH") {
                            delete $parentnode->{$childname}->[($childpos - 1)]->{$stringname};
                            $result++;
                        } elsif (($parentnode->{$childname}->[($childpos - 1)] =~ /\w+/) && ($isnodetype->($stringname, "text"))) {
                            $parentnode->{$childname}->[($childpos - 1)] = undef;
                            $result++;
                        }
                    } else {
                        #delete $parentnode->{$childname}->[($childpos - 1)];
                        splice (@{$parentnode->{$childname}},($childpos - 1),1);
                        $result++;
                    }
                } elsif (!defined $childpos) {
                    my $i = 0;
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        while ($i < @{$parentnode->{$childname}}) {
                            if (ref($parentnode->{$childname}->[$i]) eq "HASH") {
                                delete $parentnode->{$childname}->[$i]->{$stringname};
                                $result++;
                            } elsif (($parentnode->{$childname}->[$i] =~ /\w+/) && ($isnodetype->($stringname, "text"))) {
                                $parentnode->{$childname}->[$i] = undef;
                                $result++;
                            }
                            $i++;
                        }
                    } else {
                        delete $parentnode->{$childname};
                        $result++;
                    }
                } else {
                    my $num = @{$parentnode->{$childname}};
                    croak "Cannot delete child node $childname at position $childpos when there is $num." if !defined $stringname;
                    croak "Cannot delete from child node $childname, none exists at position $childpos when there is $num." if defined $stringname;
                    return undef;
                }
            } else {
                if ((!defined $childpos) || ($childpos == 1)) {
                    if (defined $stringname) {  # Make sure we account for { node => <CDATA> } opposed to { node => { #text => <CDATA> } }
                        delete $parentnode->{$childname}->{$stringname};
                    } else {
                        delete $parentnode->{$childname};
                    }
                } else {
                    croak "Cannot delete child node, none exists at position $childpos." if !defined $stringname;
                    croak "Cannot delete from child node, none exists at position $childpos." if defined $stringname;
                    return undef;
                }
            }
        }
        return $result;
    };

    # This can be the function $mod->($parent_nodes,insert|replace|delete|mergeadd|mergereplace|mergedelete|mergeappend,$child_path,string,$value);
    my $mod = sub (@) {
        my $parent_nodes    = shift;  # @{$parent_nodes}
        my $action          = shift;  # insert|replace|delete|mergeadd|mergereplace|mergedelete|mergeappend
        my $child_path      = shift;  # XMLPath
        my $string_element  = shift;  # @attrname | #text
        my $value           = shift;  # "value"
        my $numAffected     = 0;

        if (($action ne "insert") && ($action ne "replace") && ($action ne "delete")
             && ($action ne "mergeadd") && ($action ne "mergeappend") && ($action ne "mergereplace") && ($action ne "mergedelete") ) {
            croak "Modify only supports insert, replace, merge or delete";
        }

        # Extract positional
        my ($positionFilter,$position);
        if ($child_path->[1]) {
            if ($child_path->[1]->[0]->[0] =~ /^\d*$/) {
                $positionFilter = shift @{$child_path->[1]};
                $position       = $positionFilter->[0] || undef;
            }
        }
        foreach my $xref (@{$parent_nodes}) {
            if (ref($xref) eq "HASH") {

                my @positions;
                if ((!defined $position) && (ref($xref->{ $child_path->[0] }) eq "ARRAY") && (defined $child_path->[1]) && (@{$child_path->[1]} > 0)) {
                    my $ipos = 0;
                    while ($xref->{ $child_path->[0] }->[$ipos]) {
                        if ( my $pass = $tppx->filterXMLDoc($xref->{ $child_path->[0] }->[$ipos], [[ ".", $child_path->[1] ]]) ) {
                            push( @positions, ($ipos +1) );
                        }
                        $ipos++;
                    }
                } else {
                    push (@positions,$position);
                }

                foreach my $pos (@positions) {
                    $numAffected += $nodeInsert->($xref,$child_path->[0],$pos,$string_element,$value)   if $action eq "insert";
                    $numAffected += $nodeReplace->($xref,$child_path->[0],$pos,$string_element,$value)  if $action eq "replace";
                    $numAffected += $nodeDelete->($xref,$child_path->[0],$pos,$string_element)          if $action eq "delete";
                    $numAffected += $nodeMergeAction->($xref,$child_path->[0],$pos,$string_element,$value, mergetype => "mergeadd" )     if $action eq "mergeadd";
                    $numAffected += $nodeMergeAction->($xref,$child_path->[0],$pos,$string_element,$value, mergetype => "mergeappend" )  if $action eq "mergeappend";
                    $numAffected += $nodeMergeAction->($xref,$child_path->[0],$pos,$string_element,$value, mergetype => "mergereplace" ) if $action eq "mergereplace";
                    $numAffected += $nodeMergeAction->($xref,$child_path->[0],$pos,$string_element,$value, mergetype => "mergedelete" )  if $action eq "mergedelete";
                }

            } elsif (ref($xref) eq "ARRAY") {

                foreach my $e (@$xref) {
                    my @positions;
                    if ((!defined $position) && (ref($e->{ $child_path->[0] }) eq "ARRAY") && (defined $child_path->[1]) && (@{$child_path->[1]} > 0)) {
                        my $ipos = 0;
                        while ($e->{ $child_path->[0] }->[$ipos]) {
                            if ( my $pass = $tppx->filterXMLDoc($e->{ $child_path->[0] }->[$ipos], [[ ".", $child_path->[1] ]]) ) {
                                push( @positions, ($ipos +1) );
                            }
                            $ipos++;
                        }
                    } else {
                        push (@positions,$position);
                    }

                    foreach my $pos (@positions) {
                        $numAffected += $nodeInsert->($e,$child_path->[0],$pos,$string_element,$value)  if $action eq "insert";
                        $numAffected += $nodeReplace->($e,$child_path->[0],$pos,$string_element,$value) if $action eq "replace";
                        $numAffected += $nodeDelete->($e,$child_path->[0],$pos,$string_element)         if $action eq "delete";
                        $numAffected += $nodeMergeAction->($e,$child_path->[0],$pos,$string_element,$value, mergetype => "mergeadd" )     if $action eq "mergeadd";
                        $numAffected += $nodeMergeAction->($e,$child_path->[0],$pos,$string_element,$value, mergetype => "mergeappend" )  if $action eq "mergeappend";
                        $numAffected += $nodeMergeAction->($e,$child_path->[0],$pos,$string_element,$value, mergetype => "mergereplace" ) if $action eq "mergereplace";
                        $numAffected += $nodeMergeAction->($e,$child_path->[0],$pos,$string_element,$value, mergetype => "mergedelete" )  if $action eq "mergedelete";
                    }
                }

            }
        }
        return $numAffected;
    };

    #pp (\%options);
    my $resultmaps = $self->tppx->filterXMLDoc($xtree, $xmlpath, structure => "ParentMAP");
    #pp ({ xmldoc => $xtree, xmlpath => $xmlpath, options => \%options, map => $resultmaps });
    foreach my $parentmap (@{$resultmaps}) {
        foreach my $action (keys %options) {
            my $value = $options{$action} || undef;
            if ($action eq "insert") {
                my $child = $parentmap->{'child'}->[0];
                my $child_path = [ $child->{'name'}, [[$child->{'position'}, undef]] ];
                $numAffected += $mod->([$parentmap->{'root'}],$action,$child_path,$child->{'target'},$value);
                next;
            }
            if ($action eq "delete") {
                foreach my $child (reverse @{$parentmap->{'child'}}) {
                    my $tmp_value = eval(Dumper($value));
                    my $child_path = [ $child->{'name'}, [[$child->{'position'}, undef]] ];
                    $numAffected += $mod->([$parentmap->{'root'}],$action,$child_path,$child->{'target'},$tmp_value);
                }
                next;
            }
            foreach my $child (@{$parentmap->{'child'}}) {
                my $tmp_value = eval(Dumper($value));
                my $child_path = [ $child->{'name'}, [[$child->{'position'}, undef]] ];
                $numAffected += $mod->([$parentmap->{'root'}],$action,$child_path,$child->{'target'},$tmp_value);
            }
        }
    }

    return $numAffected;

}


#How do we execute an add() ?
#
#Add will first check to see if xmlpath exists
#If the path does not exist, then the $value is insert()ed into the xmldoc at the path indicated:
#  and path is #text - create node if it does not already exist, set #text
#  and path is @attribute - create node if it does not already exist, set @attribute
#  and path is node, $value is CDATA - create node if it does not already exist, set #text
#  and path is node, $value is REF - create the node as $value
#If the path does exist, then we must asssume the $value is to be merge()d:
#  and path is #text - FAILURE, #text already exists - use merge to add additional content, or replace to change it
#  and path is @attribute - FAILURE, attribute already exists - use replace to change it
#  and path is node - FAILURE, node already exists - use insert to add additional nodes, merge to update this one, replace to change this one

=pod

=head2 insert

insert( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, insert => $value )

=cut
sub insert (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, insert => $value ) if defined $self;
    return modify( $xtree, $path, insert => $value );
}

=pod

=head2 mergeadd

mergeadd( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, mergeadd => $value )

=cut
sub mergeadd (@) {  # mergeAdd mergeReplace mergeAppend mergeDelete
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, mergeadd => $value ) if defined $self;
    return modify( $xtree, $path, mergeadd => $value );
}

=pod

=head2 mergereplace

mergereplace( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, mergereplace => $value )

=cut
sub mergereplace (@) {  # mergeAdd mergeReplace mergeAppend mergeDelete
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, mergereplace => $value ) if defined $self;
    return modify( $xtree, $path, mergereplace => $value );
}

=pod

=head2 mergeappend

mergeappend( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, mergeappend => $value )

=cut
sub mergeappend (@) {  # mergeAdd mergeReplace mergeAppend mergeDelete
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, mergeappend => $value ) if defined $self;
    return modify( $xtree, $path, mergeappend => $value );
}

=pod

=head2 mergedelete

mergedelete( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, mergedelete => $value )

=cut
sub mergedelete (@) {  # mergeAdd mergeReplace mergeAppend mergeDelete
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, mergedelete => $value ) if defined $self;
    return modify( $xtree, $path, mergedelete => $value );
}

=pod

=head2 replace

replace( XMLTree, XMLPath, $value )

This is the same as modify( XMLTree, XMLPath, replace => $value )

=cut
sub replace (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    my $value   = shift;
    return $self->modify( $xtree, $path, replace => $value ) if defined $self;
    return modify( $xtree, $path, replace => $value );
}

=pod

=head2 delete

delete( XMLTree, XMLPath )

This is the same as modify( XMLTree, XMLPath, delete => undef )

=cut
sub delete (@) {
    my $self    = shift if ref($_[0]) eq $REF_NAME || undef;
    my $xtree   = shift;
    my $path    = shift;
    return $self->modify( $xtree, $path, delete => undef ) if defined $self;
    return modify( $xtree, $path, delete => undef );
}


1;
__END__

=pod

=head1 EXAMPLES

    #!/usr/bin/perl
    use XML::TreePP;
    use XML::TreePP::XMLPath;
    use XML::TreePP::Editor;
    
    # Parse the XML document.
    my $tpp  = new XML::TreePP;
    my $tppx = new XML::TreePP::XMLPath;
    my $tppe = new XML::TreePP::Editor;
    
    $tpp->set( indent => 4 );
    
    my $xmldoc = $tpp->parse(<<XMLEND
        <paragraph>
            <sentence language="german">
                <words>Do red cats eat yellow food</words>
                <punctuation>?</punctuation>
            </sentence>
            <sentence language="english">
                <words>Brown cows eat green grass</words>
                <punctuation>.</punctuation>
            </sentence>
        </paragraph>
    XMLEND
    );
        
    print $tpp->write($xmldoc);
    print "="x20,"\n";
    
    my $sentence_node = { 'words'          => "No, cats eat green food",
                          '-language'      => "spanish",
                          'punctuation'    => '!' };
    $tppe->insert( $xmldoc, '/paragraph/sentence', $sentence_node  );
    print $tpp->write($xmldoc);
    print "="x20,"\n";
    
    my $wordsnode = { '#text' => "Do cats really eat green food" };
    $tppe->mergereplace( $xmldoc, '/paragraph/sentence[@language="german"]/words', $wordsnode  );
    print $tpp->write($xmldoc);

Output:

    <?xml version="1.0" encoding="UTF-8" ?>
    <paragraph>
        <sentence language="german">
            <punctuation>?</punctuation>
            <words>Do red cats eat yellow food</words>
        </sentence>
        <sentence language="english">
            <punctuation>.</punctuation>
            <words>Brown cows eat green grass</words>
        </sentence>
    </paragraph>
    ====================
    <?xml version="1.0" encoding="UTF-8" ?>
    <paragraph>
        <sentence language="german">
            <punctuation>?</punctuation>
            <words>Do red cats eat yellow food</words>
        </sentence>
        <sentence language="spanish">
            <punctuation>!</punctuation>
            <words>No, cats eat green food</words>
        </sentence>
        <sentence language="english">
            <punctuation>.</punctuation>
            <words>Brown cows eat green grass</words>
        </sentence>
    </paragraph>
    ====================
    <?xml version="1.0" encoding="UTF-8" ?>
    <paragraph>
        <sentence language="german">
            <punctuation>?</punctuation>
            <words>Do cats really eat green food</words>
        </sentence>
        <sentence language="spanish">
            <punctuation>!</punctuation>
            <words>No, cats eat green food</words>
        </sentence>
        <sentence language="english">
            <punctuation>.</punctuation>
            <words>Brown cows eat green grass</words>
        </sentence>
    </paragraph>

=head1 AUTHOR

Russell E Glaue, http://russ.glaue.org

=head1 SEE ALSO

C<XML::TreePP>

C<XML::TreePP::XMLPath>

XML::TreePP::Editor on Codepin: http://www.codepin.org/project/perlmod/XML-TreePP-Editor

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2013 Russell E Glaue,
Center for the Application of Information Technologies,
Western Illinois University.
All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

