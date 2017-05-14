#####
#
# $Id: make_tables.pl,v 1.12 2001/09/19 05:44:37 trostler Exp $
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
#####

#####
#
# This script will take an XML document & build a set of RDB tables
#   that can store it & output the table defs to STDOUT
# See 'pop_tables.pl' for a script that will then take the XML & populate
#   these tables with actual values
# See 'unpop_tables.pl' for a script that will read the DB & convert back
#   to XML
#
####
use strict;

# We use DOM to parse the entire XML doc into memory
use XML::DOM;

# For generic schema def
use DBIx::DBSchema;

# A set of 'common' routines 
use common;

# This script is passed the name of the XML file
my $doc = new XML::DOM::Parser->parsefile(shift);
my $head = $doc->getDocumentElement;

# We'll keep table defs in here
my %tables;

# This will find all the 1:N relationships between tags
my $one_to_n = &find_one_to_n_relationships($head);

# This will print out those relationships (preceded by a '#'!)
#   so we can check 'em out
#my $goo = &dump_otn($one_to_n,'#');
#print $goo;

# Create the table defs in memory
&make_tables($head);
&add_in_1_to_n_cols;

# Create DB-generic sequence tables for DBIx::Sequence
&make_sequence_tables;

# Dump them
&dump_dbschema_tables;

###
# The workhorse - recursively plows thru the XML doc & 'table-izes' what
#   it finds
###
sub make_tables {
    my($head) = @_;
    my(@sub_table,@text_field);

    # Blow thru each child node of this node
    foreach my $sub_node ($head->getChildNodes) {
        # Skip these
        next if ($sub_node->getNodeType == XML::DOM::TEXT_NODE);
        next if ($sub_node->getNodeType == XML::DOM::COMMENT_NODE);

        # if (sub node doesn't have attributes) & (it only has 1 child node
        #   that's a next node || it has no sub nodes)
        # NOTE: This is the EXACT SAME 'if' statement as in 'pop_tables.pl'
        #   THEY MUST MATCH or carnage will ensue.
        if (($sub_node->getAttributes && !$sub_node->getAttributes->getLength) && (!$sub_node->getChildNodes || ($#{$sub_node->getChildNodes} == 1 && $sub_node->getChildNodes->[0]->getNodeType == XML::DOM::TEXT_NODE))) {
            # Plain text - just a regular column in table
            push @text_field, $sub_node->getNodeName;
        }
        else {
            # Figure out what kind of relationship this element has to
            #   this sub-table - either 1:1 or 1:N
            if (!$one_to_n->{$head->getNodeName}{$sub_node->getNodeName}) {
                # Foreign key references in this table (1:1 relationship)
                push @sub_table, $sub_node->getNodeName;
            }

            # The FKs in 1:N relationship tables will get dumped at the end

            # We'll need to make tables for these guys
            &make_tables($sub_node);
        }
    }

    # We've got all the info we need - fill out our data structure
    make_table($head->getNodeName,\@sub_table,\@text_field, $head->getAttributes);
}

##
# This function fills out or data structure that describes a table
##
sub make_table
{
    # Takes a pro-spective table name
    #   array refs of sub tables & text field names
    #   and an XML::DOM::NamedNodeMap of XML attributes
    my($o_table_name, $sub_table, $leaf, $attr_ref) = @_;

    # DB-ize table name
    my $table_name = &mtn($o_table_name);

    # Keep original element name
    $tables{__meta__}{$table_name} = $o_table_name;

    # Do foreign keys first - they're integers
    foreach (@$sub_table) {
        $tables{$table_name}{cols}{&mtn($_)."_".PK_NAME}{type} = "integer";
    }

    # Now do 'real' fields - text columns
    foreach (@$leaf) {
        next if ($one_to_n->{$table_name}{$_});

        # Create column name & stash original name for this field
        my $field = &normalize($_); 
        my $col_name = "${table_name}_${field}_value";
        $tables{__meta__}{$col_name} = $_;
        $tables{$table_name}{cols}{$col_name}{type} = TEXT_COLUMN;
    }

    # Now do attributes - these are just text columns
    if ($attr_ref) {
        for(my $i = 0 ; $i < $attr_ref->getLength ; $i++) {
            my $attr = $attr_ref->item($i);
            my $name = &normalize($attr->getName);
            $_ = "${table_name}_${name}_attribute";
            # Stash original name for this column
            $tables{__meta__}{$_} = $attr->getName;
            $tables{$table_name}{cols}{$_}{type} = TEXT_COLUMN;
        }
    }

    # Need this for stuff like <element>Howdy!</element>
    #   unfortunately this also picks up <element/> so
    #   it adds some extra cruft but those cols just won't get
    #   populated...
    if (!@$leaf && !@$sub_table)   {
        $tables{$table_name}{cols}{"${table_name}_value"}{type} = TEXT_COLUMN;
    }
}

# generic-ized dump of tables
#   It's up to DBIx::DBSchema to provide us w/the generic
#       table defs - currently MySQL & PostgreSQL are supported
#       for sure w/very generic SQL for everything else
#       So 'hopefully' it'll 'just work'! (yeah right)
#
sub dump_dbschema_tables {

    my $schema = new DBIx::DBSchema;
    
    # Generic PK column
    my $pk_id = new DBIx::DBSchema::Column(
        {
            name => PK_NAME,
    	    type => 'integer',  # Use DBIx::Sequence to handle PKs
            null => 'NOT NULL'
        }
    );

    foreach my $table_name (keys %tables) {
        # Skip the meta-info stuff
        next if ($table_name eq '__meta__');

        # The table
        my $table = new DBIx::DBSchema::Table($table_name);

        foreach my $col (keys %{$tables{$table_name}{cols}}) {
            my $column = new DBIx::DBSchema::Column(
                {
                    name => $col,
                    type => $tables{$table_name}{cols}{$col}{type},
                    null => !$tables{$table_name}{cols}{$col}{not_null}
                }
            );
            
            $table->addcolumn($column);
        }

	unless ($tables{$table_name}{no_id})
	{
        	$table->addcolumn($pk_id);
        	$table->primary_key(PK_NAME);
	}

        $schema->addtable($table);
    }

    #
    # Now create table with table names & attributes mapped to
    #   their 'real' names
    #
    my $table = new DBIx::DBSchema::Table(REAL_ELEMENT_NAME_TABLE);

    my @sorted_things = sort keys %{$tables{__meta__}};
    my %values;

    # Dump real name table & values mapping table
    my $real_name = new DBIx::DBSchema::Column(
        {
            name => 'db_name',
            type => TEXT_COLUMN,
            null => 'NOT NULL'
        }
    );

    my $xml_name = new DBIx::DBSchema::Column(
        {
            name => 'xml_name',
            type => TEXT_COLUMN,
            null => 'NOT NULL'
        }
    );

    $table->addcolumn($real_name);
    $table->addcolumn($xml_name);

    # Set up real values hash
    foreach my $thing (@sorted_things) {
        # Skip the column info stuff
        next if ($thing eq 'cols');

        $values{$thing} = $tables{__meta__}{$thing};
    }

    $schema->addtable($table);

    local($") = ", ";

    my @sorted_tables = sort keys %{$tables{__meta__}};

    ##
    # Dump link tables table
    #   Store meta-info about 1:N tables in DB itself
    ##
    $table = new DBIx::DBSchema::Table(LINK_TABLE_NAMES_TABLE);
    my $one_column = new DBIx::DBSchema::Column(
        {
            name => 'one_table',
            type => TEXT_COLUMN,
            null => 'NOT NULL'
        }
    );
    my $many_column = new DBIx::DBSchema::Column(
        {
            name => 'many_table',
            type => TEXT_COLUMN,
            null => 'NOT NULL'
        }
    );

    $table->addcolumn($one_column);
    $table->addcolumn($many_column);
    
    $schema->addtable($table);
   
    # Dump out tables real purty like
    local($") = undef;
    my @sql = map { chomp ; $_.=";\n\n" } $schema->sql(DSN);
    print "@sql\n";

    # Dump real element names mappings
    local($") = ",";
    map { print "INSERT INTO ",REAL_ELEMENT_NAME_TABLE," VALUES ('$_','$values{$_}');\n"; } keys %values;

    # Dump 1:N table relationship names
    foreach my $one (keys %$one_to_n) {
        foreach my $many (keys %{$one_to_n->{$one}}) {
            my $table_name = "'".&mtn($one)."'";
            my $link = "'".&normalize($many)."'";
            print "INSERT INTO ",LINK_TABLE_NAMES_TABLE," VALUES ($table_name,$link);\n";
        }
    }
}

#
# DBIx::Sequence needs these tables 
#	Used for DB-generic sequence values
#
#          dbix_sequence_state:
#               | dataset  | varchar(50) |
#               | state_id | int(11)     |
#
#               dbix_sequence_release:
#               | dataset     | varchar(50) |
#               | released_id | int(11)     |
#
sub make_sequence_tables
{
	my $t1 = "dbix_sequence_state";
	my $t2 = "dbix_sequence_release";

    $tables{$t1}{cols}{'dataset'}{type} = TEXT_COLUMN;
    $tables{$t1}{cols}{'state_id'}{type} = "integer";
    $tables{$t1}{no_id} = 1;

    $tables{$t2}{cols}{'dataset'}{type} = TEXT_COLUMN;
    $tables{$t2}{cols}{'released_id'}{type} = "integer";
    $tables{$t1}{no_id} = 1;
}

#
# So the game here is to add in the PK of one column
#	as an FK in the many column
#
sub add_in_1_to_n_cols {
    foreach my $one (keys %$one_to_n) {
        foreach my $many (keys %{$one_to_n->{$one}}) {
		my $many_table = &mtn($many);
		my $col_to_add = &mtn($one."_".FK_NAME);

		$tables{$many_table}{cols}{$col_to_add}{type} = 'integer';
		$tables{$many_table}{cols}{$col_to_add}{not_null} = 1;
		}
	}
}
