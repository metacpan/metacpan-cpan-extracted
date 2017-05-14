###
#
# $Id: pop_tables.pl,v 1.8 2001/07/28 00:03:39 trostler Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, Juniper Networks, Inc.  
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
###

###
#
# Pull XML data out of file & put into RDB tables created by make_tables.pl
# 
####
use strict;
use XML::DOM;
use DBIx::Recordset;
use DBIx::Sequence;

# Grab common routines
use common;

# Read/parse XML
my $doc = new XML::DOM::Parser->parsefile(shift);
my $head = $doc->getDocumentElement;

# Set up sequence
my $sequence = new DBIx::Sequence({db_dsn => DSN});

# Set up DBIx::Recordset - it doesn't like MySQL
$DBIx::Recordset::FetchsizeWarn = 0;

# Get 1:N relationships
my $one_to_n = &get_one_to_n_db(DSN);

# Get to work!
my $root_pk = &populate_table($head);

# Tell them what they've won...
my $root_table_name = &mtn($head->getNodeName);
print "\n\tTo re-create this data back into XML use:\n";
print "\t% perl unpop_tables.pl $root_table_name $root_pk\n\n";
print "\tIf this is an XML Schema and you want fully-specified XML back use:\n";
print "\t% perl unpop_schema.pl $root_pk\n\n";

# 
# The recursive work-horse - pulls out XML data & puts into RDB
#
# So the strategy here is to build up a 'values' hash who's keys
#   are column names & values are column values.  Plain text columns
#   are what they are - 1:1 relationship columns are recursively 
#   determined and 1:N columns are recursively filled out & then stored
#   and then output once this table is completely filled - since we
#   can't fill out the 'N' tables until we know this table's primary key value,
#   which we don't know until we insert it & it gets generated!
#
sub populate_table {
    my($head) = @_;
    my(%values,%set_our_pk_in_table);
    use vars qw(*insert);   # DBIx::Recordset deals with GLOBs

    # Get this element's name
    my $name = $head->getNodeName;

    # Get 'real' Database names for this element
    my $db_table_name = &mtn($name);

    # Check for attributes - easy plain text columns
    if (my $attributes = $head->getAttributes) {
        for(my $i = 0 ; $i < $attributes->getLength ; $i++) {
            my $attr = $attributes->item($i);
            my $name = &normalize($attr->getName);
            my $value = $attr->getValue;
            $values{"${db_table_name}_${name}_attribute"} = $value;
        }
    }

    # Now created each sub-element of this element
    foreach my $sub_table ($head->getChildNodes) {
        my($db_st_name) = &normalize($sub_table->getNodeName);

        # Text node - just a '_value' in this table
        if ($sub_table->getNodeType == XML::DOM::TEXT_NODE) {
            next if (!defined $sub_table->getNodeValue || 
                        $sub_table->getNodeValue =~ /^\s*$/);
            $values{"${db_table_name}_value"} = $sub_table->getNodeValue;
            next;
        }

        #
        # Note this 'if' statement is EXACTLY the same one as in make_tables.pl
        #   used to determine what's a text element & what isn't - otherwise
        #   carnage would ensue
        #
        if (($sub_table->getAttributes && !$sub_table->getAttributes->getLength) && (!$sub_table->getChildNodes || ($#{$sub_table->getChildNodes} == 1 && $sub_table->getChildNodes->[0]->getNodeType == XML::DOM::TEXT_NODE))) {
            # This subtable's value is in this table for one various
            #   reason or another...

            my($val,$parent);
            if ($sub_table->hasChildNodes) {
                # if this guy has child nodes & it's in this table it
                #   must be 'cuz it only has one child node & it's
                #   a TEXT node
                $val = $sub_table->getChildNodes->[0]->getNodeValue || 'null';
            }
            else {
                # This sub table don't got no child nodes so we're
                #   only interested in if this tag is there or not
                #   & since we're here it must be here!
                $val = 'present';
            }

            # Now figure out what the name of this field is
            $parent = &normalize($sub_table->getNodeName);

            # We've hit bottom!
            $values{"${db_table_name}_${parent}_value"} = $val;
        }
        else {
            # At this point we're dealing with either a 1:1 or 1:N relationship

            # XML comments also fall to here - maybe one day we'll keep 'em
            next if ($sub_table->getNodeName eq '#comment');

            # Get PK of sub table
            my $sub_table_index = populate_table($sub_table);
   
            # Check our handy-dandy one_to_n data structure
            if ($one_to_n->{&mtn($head->getNodeName)}{&normalize($sub_table->getNodeName)}) {
                # This is a 1:N reference!
                # So this table can have multiple references to $sub_table
                #   So we need to stick ourself into the $sub_table as a FK
		        #
                # Our ID in this table is called:
                #   ${db_table_name}_FK_NAME
		        #
                # So we just got the PK of the 'N' table ($sub_table_index)
                # Later when we get the PK for this table we gotta update
		        #	that row we just created with that value
		        # BUT we won't know our PK 
                #   until we've actually been totally created - see below
                #   So we'll just remember to do it 4 now...
		        #
		        # Store sub table name & it's index so later we can put
		        #	our PK in there as the FK
		        my $stn = &mtn($sub_table->getNodeName);
                $set_our_pk_in_table{"$stn"}{$sub_table_index} = 1;
            }
            else {
                # Plain old 1:1 sub table - just get this table's PK
                #   & stick it in appropriate slot
                $values{&mtn("${db_st_name}_".PK_NAME)} = $sub_table_index;
            }
        }
    }

    #
    # We've completely filled out this table SO
    #   dump values into DB
    #   insert into $db_table_name %values...
    *insert = DBIx::Recordset->Setup({'!DataSource' => DSN,
                              '!Table' => "$db_table_name"});

    #
    # We can have a table that only has an PK_NAME value 
    #   we don't want that (it's like a <node/> entity)
    #   so fill in the 'value' column
    #
    if (!keys %values) {
        $values{$db_table_name."_value"} = 'present';
    }

    # Add the row

    # First generate a unique ID for this table
    my $PK = &generate_id($db_table_name);
    $values{"".PK_NAME} = $PK;

    # And add record
    $insert->Insert(\%values);

	# 
	# Now we just want to add a value into an existing record
	#	namely our PK in any 1:N table relationships
	#
    foreach my $sub_table_name (keys %set_our_pk_in_table) {
        foreach my $FPK (keys %{$set_our_pk_in_table{$sub_table_name}}) {

		        # Set up values
		        my (%insert);
		        $insert{id} = $FPK;
            	$insert{$db_table_name."_".FK_NAME} = $PK;

                # And update the table with our PK in its FK column
            	DBIx::Recordset->Update({%insert, 
				    ('!DataSource' => DSN, '!Table' => $sub_table_name,
			        	'!PrimKey' => PK_NAME)});
		}
	}
            
    # and return our PK - simple enough!
    return $PK
}

##
# Handy dandy sub to generate unique IDs using DBIx::Sequence
#   based on table name
##
sub generate_id
{
	my($table_name) = shift;
	$sequence->Next($table_name);
}

