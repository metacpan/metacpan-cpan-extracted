#####
#
# $Id: UnpopulateSchema.pm,v 1.2 2003/04/19 04:17:48 trostler Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, 2003, Juniper Networks, Inc.  
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#####

package XML::RDB::UnpopulateSchema;
use vars qw($VERSION);
$VERSION = '1.0';

#####
#
# 'Unpopulate' DB tables back into XML
#
#####

use strict;
use URI::Escape;
use DBIx::Recordset;

sub new {
  my ($class, $rdb, $pkey, $outfile) = @_;

  # Set up DBIx::Recordset to ingore warnings about MySQL
  $DBIx::Recordset::FetchsizeWarn = 0;

  # set up FH
  my $fh = new IO::File;
  if ($outfile) {
    $fh->open("> $outfile") || die "$!";
  } else {
    $fh->fdopen(fileno(STDOUT), 'w') || die "$!";
  }

  # Taken from http://www.w3.org/TR/xmlschema-0/#simpleTypesTable
  my %simple_types = map { $_ => 1 } qw(string normalizedString token byte unsignedByte base64Binary hexBinary integer positiveInteger negativeInteger nonNegativeInteger nonPositiveInteger int unsignedInt long unsignedLong short unsignedShort decimal float double boolean time dateTime duration date gMonth gYear gYearMonth gDay gMonthDay Name QName NCName anyURI language ID IDREF IDREFS ENTITY ENTITIES NOTATION NMTOKEN NMTOKENS);

  my $self = bless { 
    rdb => $rdb,
    nodes => {},  # Hash for in-memory traversal of DB
    pkey => $pkey,
    fake_value => "VALUE0000",
    elements_dumped => {},
    abstract_elements => {},
    simple_types => \%simple_types,
    fh => $fh,
  }, $class;

  $self->{top_table} = $self->msn('schema');
  print $self->{top_table}, "  $pkey\n";

  $self;
}

sub go {
  my ($self) = @_;

  # Create in-memory structure of what's in the DB for eventual output
  $self->{rdb}->un_populate_table($self->{top_table},
                                  $self->{pkey},
                                  $self->{nodes});

 

#  if ((  $self->{nodes}->{$self->msn('element')} ) &&
#      ( !$self->{nodes}->{$self->{top_table}}->{$self->msn('element')})) {
#
#      $self->{nodes}->{$self->{top_table}}->{$self->msn('element')} = 
#               $self->{nodes}->{$self->msn('element')};
#  }
 
  # Dump 'er!
  $self->dump_schema_node($self->{nodes}->{$self->{top_table}}{'0'} 
                                   || $self->{nodes}->{$self->{top_table}}, 0);

}
##
# Now we've got the in-memory data structure - output it the XML
##
sub dump_schema_node {
    my($self, $head, $tab, $nodes) = @_;
    # Get element or group for convenience
    
    my $element = $head->{$self->msn('element')} 
            || $head->{$self->msn('group')};

print Dumper($self->{nodes});

    $self->dump_element($head, $element, $tab);
}
    

sub dump_element
{
    my($self, $head, $element, $tab, $attribute_to_add) = @_;

    my $fh = $self->{fh};
    my $max = defined $element->{'attribute'}{$self->ma('maxoccurs')} ||
        defined $element->{'attribute'}{$self->mg('maxoccurs')};

print $max, "<---- maxoccurs\n";

    # 1:N relationship if $max
    for (0..$max) {

        my $printed = 0;    # Keep track if we've got to tab or not

        # Element name
        my $real_name = $element->{'attribute'}{$self->ma('name')};
        if (!$real_name) {
            # Must be a reference - either element or group
            $real_name = $element->{'attribute'}{$self->ma('ref')} ||
                $element->{'attribute'}{$self->mg('ref')};

print $real_name, "<--- realname\n";
            if ($real_name =~ /:/)
            {
                die "Namespaces not yet supported: $real_name\n";
            }

            # Find ref
            if (!($element = $self->find_node($real_name, 
                                              $head, $self->msn('element'))))
            {
                # Must be a group ref type
                my $group_type = $self->find_node($real_name,
                                              $head, $self->msn('group'));
                return $self->dump_type($real_name, $group_type, $tab);
            }
        }

        # Keep track so we can dump extensions later
        $self->{elements_dumped}->{$real_name} = $element;

        # Track abstract elements
        if ($element->{'attribute'}{$self->ma('abstract')} eq 'true')
        {
            $self->{abstract_elements}->{$real_name} = $element;
            last;
        }

        # Get the type - maybe anonymous maybe not
        my $type = $element->{'attribute'}{$self->ma('type')};
    
        # Start tag
        print $fh $self->{rdb}->{TAB} x $tab, "<$real_name ";
    
        # Dump attributes
        $self->dump_schema_attributes($head);   

        print $fh " $attribute_to_add ";

        my $type_head;

        # Nillable?
        if ($element->{'attribute'}{$self->ma('nillable')} eq 'true')
        {
            # Add xsi:nil="true" attribute
            print $fh "xsi:nil=\"true\" ";
        }
        
        if ($self->simple_type($type)) {
            # Very Simple type - end the maddness
            print $fh ">",$self->{fake_value}++;
            $printed = 1;
        }
        else {
    
            # Simple or Complex type

            if (!$type) {
                # It's right here - (anonymous) either simple or complex
                $type_head = $element->{$self->msn('complextype')} || 
                                        $element->{$self->msn('simpletype')};
            }
            else {
                # Somewheres else - named typed - find it
                $type_head = $self->find_node($type, $head, 
                                  $self->msn('complextype')) 
                          || $self->find_node($type, $head, 
                                  $self->msn('simpletype'));
            }
    
            $printed = $self->dump_type($real_name, $type_head, $tab+1);
        }
    
        print $fh $self->{rdb}->{TAB} x $tab unless ($printed);
        
        # Close tag
        print $fh "</$real_name>\n";

        # That was fun - now find any derived types from this type & dump
        #   that too...
        # <complexType name="USAddress">
        #  <complexContent>
        #    <extension base="ipo:Address">
        my $type_name = 
                  $type_head->{'attribute'}{$self->aa('complextype_name')};
        if ($type_name)
        {
            foreach my $derived_type ($self->find_derived_types($type_name))
            {
                # Do some shuffling...
                my $d_type_name = 
                  $derived_type->{'attribute'}{$self->aa('complextype_name')};
                $element->{'attribute'}{$self->ma('type')} = $d_type_name;

                # Dump it
                $self->dump_element($head, $element, $tab, 
                                              "xsi:type=\"$d_type_name\"");
            }

            # Put the candle back
            $element->{'attribute'}{$self->ma('type')} = $type;
        }
    }
}

#
# Dump a simple or complex Type
#
sub dump_type {
    my($self, $real_name, $head, $tab) = @_;
    my $ret;

    my $fh = $self->{fh};

    # First figure out if it's a simple or complex type

    if ($head->{$self->msn('restriction')} || $head->{$self->msn('list')} ||
            $head->{$self->msn('union')}) {

        # What we got here is a simpleType
        #   close the start tag & output fake value
        print $fh ">", $self->{fake_value}++;

        # This means we did print out some text
        $ret = 1;
    }
    else
    {
        # What we got here is a complexType

        # Attributes
        $self->dump_schema_attributes($head);   
    
        # Mixed content?
        if ($head->{'attribute'}{$self->aa('complextype_mixed')} eq 'true') {
            print $fh ">\n";
            print $fh $self->{rdb}->{TAB} x $tab, $self->{fake_value}++;
        }
    
        # Dump the sequence
        $self->dump_sequence($head, $tab);

        # Simple Content?
        #   Contains only text (character data - no elements) 
        #       & (maybe) attributes
        if (my $simple_content = $head->{$self->msn('simplecontent')}) {
            # Dump attributes
            &dump_schema_attributes($simple_content->{$self->msn('extension')});
            print $fh ">",$self->{fake_value}++;
        }

        # ComplexContent?
        elsif (my $complex_content = $head->{$self->msn('complexcontent')}) {
            # An extension?
            if (my $base = $complex_content->{$self->msn('extension')}) {
                my $base_name = 
                          $base->{'attribute'}{$self->aa('extension_base')};

                # Attributes
                $self->dump_schema_attributes($base);   

                # Let's dump the base type
                my $base_type = 
                  $self->find_node($base_name,$head,$self->msn('complextype'));
                $ret = $self->dump_type($real_name, $base_type, $tab);

                # Now dump the extension
                $self->dump_sequence($base, $tab, 1);
            }
            elsif ( $base = $complex_content->{$self->msn('restriction')}) {
                # A restriction?
                my $base_name = 
                  $base->{'attribute'}{$self->aa('restriction_base')};
                # Dump the restriction
                print $fh ">\n";
                $ret = 
                  $self->dump_schema_node($base->{$self->msn('sequence')}{'0'},
                    $tab);
            }
        }

    }
    $ret;
} 

sub find_derived_types
{
    my($self, $parent_type_name) = @_;
    my @dervied_types;

    my $head = $self->{nodes}->{$self->msn('schema')};

    # They've got to be @ the 'root' level
    foreach my $num (keys %$head)
    {
        next unless $num =~ /^\d$/;

        # Don't wanna auto-vivify it!
        if (defined $head->{$num}{$self->msn('complextype')}{$self->msn('complexcontent')}{$self->msn('extension')})
        {
            if ($head->{$num}{$self->msn('complextype')}{$self->msn('complexcontent')}{$self->msn('extension')}{'attribute'}{$self->aa('extension_base')} eq $parent_type_name)
            {
                push @dervied_types, $head->{$num}{$self->msn('complextype')};
            }
        }
    }

    @dervied_types;
}

#
# Dump out attribute
#
sub dump_schema_attribute {
    my($self, $head) = @_;

    my $fh = $self->{fh};

    # If there is one...
    if ($head->{attribute}) {
        my $attr_name = $head->{'attribute'}{$self->aa('attribute_name')};
        print $fh "$attr_name=\"",$self->{fake_value}++,"\" ";
    }
} 

sub dump_schema_attributes {
    my($self, $head) = @_;

    # There's either 1 or many...

    # Attribute
    $self->dump_schema_attribute($head->{$self->msn('attribute')});

    # Attribute Group
    if (my $attr_group = $head->{$self->msn('attributegroup')}) {
        my $name = $attr_group->{'attribute'}{$self->aa('attributegroup_ref')};

        # Skip namespace stuff...
        if ($name =~ /:/)
        {
            die "Namespaces not yet supported: $name\n";
        }

        my $attr_head = $self->find_node($name, $head, 
                                                $self->msn('attributegroup'));
        $self->dump_schema_attributes($attr_head);
    }

    foreach my $num (keys %{$head}) {
        next unless ($num =~ /^\d+$/);
    
        # convenience
        my $new_head = $head->{$num};

        # Attributes
        $self->dump_schema_attribute($new_head->{$self->msn('attribute')});
    
        # Attribute Groups
        if (my $attr_group = $new_head->{$self->msn('attributegroup')}) {
            my $name = 
              $attr_group->{'attribute'}{$self->aa('attributegroup_ref')};

            # Skip namespace stuff...
            next if ($name =~ /:/);

            my $attr_head = $self->find_node($name, $new_head, 
                                                $self->msn('attributegroup'));
            $self->dump_schema_attributes($attr_head);
        }
    }
}

#
# Can find types, elements, and attributeGroups
#
sub find_node
{
    my($self, $type_name,$current_head,$node_type) = @_;

    my $attr = $node_type."_name_attribute";
    #print "Looking for $node_type named $type_name!\n";

    #print Dumper $current_head;
    # Maybe it's right here...
    if ($current_head->{$node_type}{'attribute'}{$attr} eq $type_name)
    {
        # That was easy
        return $current_head->{$node_type};
    }

    # It's gotta be around here somewhere...
    my $head = $self->{nodes}->{$self->msn('schema')};

    foreach my $num (keys %$head)
    {
        #next unless $num =~ /^\d$/;

        if ($head->{$node_type}{'attribute'}{$attr} eq $type_name)
        {
            return $head->{$node_type};
        }
        elsif ($head->{$num}{$node_type}{'attribute'}{$attr} eq $type_name)
        {
            return $head->{$num}{$node_type};
        }
    }

    # This can't be good
    #print "Can't find $node_type named $type_name!\n";
    0;
}

# Make Schema Name
sub msn
{
    my ($self) = shift;
    # $val -> PRE_xsd_$val
    #TABLE_PREFIX."_xsd_".shift;
    $self->{rdb}->{TABLE_PREFIX} . "_" . shift;
#    $self->{rdb}->{TABLE_PREFIX} . "_xs_" . shift;
} 

# Add Attribute
sub aa
{
    my $self = shift;
    $self->msn(shift() . "_attribute");
}
    
# Make Attribute
sub ma
{
    my $self = shift;
    # $val -> PRE_element_$val_attribute
    $self->aa("element_" . shift);
 #   $self->aa($self->msn("element_") . shift);
}

# Make Group
sub mg
{
    my $self = shift;
    # $val -> PRE_element_$val_attribute
    $self->aa("group_" . shift);
}

sub simple_type
{
    my($self, $type) = @_;

    $type =~ s/xsd://;
    $type =~ s/xs://;
	print $type .' ';
    $self->{simple_types}->{$type};
}

sub dump_sequence {
    my($self, $head, $tab, $derived) = @_;
 
    my $fh = $self->{fh};

    # A Sequence?
    if (my $sequence = $head->{$self->msn('sequence')}) {
        print $fh ">\n" unless $derived;
        foreach my $num (keys %$sequence) {
 
            # A choice element?
            if ($num eq $self->msn('choice') || $num eq $self->msn('all'))
            {
                # Go thru all choices
                foreach my $choice (keys %{$sequence->{$num}})
                {
                    $self->dump_element($sequence->{$num},
                                      $sequence->{$num}{$choice}, $tab+1)
                }
            }

            # Go thru elements of the sequence
            next unless ($num =~ /^\d+$/);

            # Here would lie to path to infinite recursion...
            #print "real name is $real_name next is ",$sequence->{$num}{$self->msn('element')}{'attribute'}{$self->ma('ref')},"\n";
            #next if ($real_name eq $sequence->{$num}{$self->msn('element')}{'attribute'}{$self->ma('name')});
            #next if ($real_name eq $sequence->{$num}{$self->msn('element')}{'attribute'}{$self->ma('ref')});

            $self->dump_schema_node($sequence->{$num}, $tab+1)
        }
    }
}

1;
