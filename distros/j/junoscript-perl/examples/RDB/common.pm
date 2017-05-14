#####
#
# $Id: common.pm,v 1.9 2003/04/18 00:33:16 trostler Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, 2003, Juniper Networks, Inc.  All rights reserved.
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
# Copyright (c) 2001, Juniper Networks, Inc.
# All rights reserved.
#
# Set of common routines & constants
# 
#####

# All tables names will being with this string
use constant TABLE_PREFIX => 'gen';

# Name appended to primary key of every generated table
use constant PK_NAME => 'id';

# Name appended to foreign key of every generated table
use constant FK_NAME => 'fk';

# Used to print things out real pretty-like
use constant TAB => " " x 4;

# Default width & type of text columns
use constant TEXT_WIDTH => 50;
use constant TEXT_COLUMN => 'varchar(' . TEXT_WIDTH . ')';

###
# YOU MUST CHANGE THIS TO REFLECT YOUR CONFIGURATION!!!
###
use constant DSN => "DBI:mysql:database=JUN_TEST";
use constant USERNAME => '';
use constant PASSWORD => '';

#
# Blow thru all nodes & find 1:N relationships between them
#   Need to pass the root of yer XML::DOM tree
# Quite pleasant really
# Basically just count the number of duplicate elements under
#   this one - if > 1 then 1:N relationship
#
sub find_one_to_n_relationships {
    my($head) = @_;
    my(%saw);

    # Count duplicates
    grep($saw{$_->getNodeName}++, $head->getChildNodes);
    foreach (keys %saw) {
        next if /#text/;
        next if /#comment/;
        next if ($one_to_n->{$head->getNodeName}{$_});
        if ($saw{$_} > 1) {
            $one_to_n->{$head->getNodeName}{$_} = 1;
        }
    }

    # And recurse on down the road
    foreach my $sub_node ($head->getChildNodes) {
        next if ($sub_node->getNodeType == XML::DOM::TEXT_NODE);
        &find_one_to_n_relationships($sub_node);
    }

    # Done is Done
    $one_to_n;
}

#
# Helper function to dump the 'one_to_n' datastructure out
#
sub dump_otn {
    my($otn,$char) = @_;
    my $ret;

    foreach my $one (keys %$otn) {
        foreach my $many (keys %{$otn->{$one}}) {
            $ret .= "${char}\t$one -> $many\n";
        }
    }

    $ret;
}

#
# Need this stuff in BEGIN block
#   Since that 'use constant' down there calls these functions
#
BEGIN {

    #
    # 'mtn' = 'Make Table Name' - cleans up text so it's a valid
    #   DB table name & adds TABLE_PREFIX
    #
    sub mtn {   
        my($base) = @_;
        &normalize(TABLE_PREFIX."_$base");
    }
    
    # Normalize column/table names - No ':' or '-' & all lower case
    sub normalize {
        my($in,$out) = shift;
    
        # Get rid of funny stuff 
        ($out = $in) =~ s/[#:\.-]/_/g;
        lc $out;
    }
}

# Some handy constants
use constant REAL_ELEMENT_NAME_TABLE => &mtn('element_names');
use constant LINK_TABLE_NAMES_TABLE => &mtn('link_tables');

#
# Pulls out one_to_n data structures from the DB itself
#
sub get_one_to_n_db {
    my($dsn) = @_;

    *link_tables = DBIx::Recordset->Search({'!DataSource' => $dsn,
                                    '!Username' => USERNAME,
                                    '!Password' => PASSWORD,
                                    '!Table' => LINK_TABLE_NAMES_TABLE
                                  });

    foreach my $links (@link_tables) {
        $one_to_n{$links->{one_table}}{$links->{many_table}} = 1;
    }

    \%one_to_n;
}

#
# Set up hash to convert table/column names back to their original
#   XML forms - we only want to do this once!
#
sub set_up_real_names_hash {
    my($dsn) = @_;
    # Get 'real' element names
    *real_names = DBIx::Recordset->Search({'!DataSource' => $dsn,
                                    '!Username' => USERNAME,
                                    '!Password' => PASSWORD,
                                    '!Table' => REAL_ELEMENT_NAME_TABLE
                                  });
}

#
# Get the corresponding 'xml_name' from this 'db_name'
#
sub get_xml_name
{
    my($real_names, $db_name) = @_;

    $real_names->Search({ 
                         '!Username' => USERNAME,
                         '!Password' => PASSWORD,
                          db_name => $db_name 
                        });
    $real_names{xml_name};
}

use vars qw(@EXPORT);

# Export some handy constants
@EXPORT = qw(REAL_ELEMENT_NAME_TABLE LINK_TABLE_NAMES_TABLE DSN);

# Convenience
my $primary_id = PK_NAME;
my $foreign_id = FK_NAME;

#
# Recursive routine to unpopulate DB into in-memory data structure
#
# Takes a table name, PK of a row, & a hash ref of where in this
#   giant monstrous data in-memory data-structure we've created to
#   stick this row's values
#
sub un_populate_table {
    my($table_name,$id,$put_it_here) = @_;
    use vars qw(*schema);   # DBIx::Recordset likes GLOBs, yummy

    # Get 1:N relationships out of the database itself
    my $one_to_n = &get_one_to_n_db(DSN);


    # This'll get the ball rolling...
    *schema = DBIx::Recordset->Search({
                                    '!DataSource' => DSN,
                                    '!Username' => USERNAME,
                                    '!Password' => PASSWORD,
                                    '!Table' => $table_name,
                                      $primary_id => $id
                                    });

    # Any column that ends in '_id' we gotta assume is a 1:1 map
    # Any column that ends in '_value' is text in this element
    # Any column that ends in '_attribute' is an attribute
    foreach my $col (@{$schema->Names}) {
        my $val = $schema{$col};

        my $match = "_${primary_id}";
        if ($col =~ /${match}$/) {
            # 1:1
            next if (!$val);

            # Unpopulate sub table since this is a foreign key
            my $other_table;
            ($other_table = $col) =~ s/${match}$//;
            un_populate_table($other_table,$val,\%{$put_it_here->{$other_table}});
            # Put the candle - back
            *schema = DBIx::Recordset->Search({'!DataSource' => DSN,
                                    '!Username' => USERNAME,
                                    '!Password' => PASSWORD,
                                    '!Table' => $table_name,
                                    $primary_id => $id
                                  });

        }
        elsif ($col =~ /_value$/) {
            # text between tag
            $put_it_here->{value} = $val if (defined $val);
        }
        elsif ($col =~ /_attribute$/) {
            # attribute
            $put_it_here->{attribute}{$col} = $val if (defined $val);
        }
        elsif ($col eq $primary_id) {
            # PK - don't do anything
        }
        elsif ($col =~ /_$foreign_id$/ ) {
            # FK - don't do anything
        }
        else {
            # Keep us honest
            die "I don't know what to do with column name $col = $val!\n";
        }
    }

    # Now get 1:N relationships
    if ($one_to_n->{$table_name}) {
        # Go thru each 'N' relationship table to this one
        foreach my $link (keys %{$one_to_n->{$table_name}}) {
            # Look up other PK via our PK (which is an FK in the sub_table)
            my $other_table = &mtn($link);
		    my $fk_field = $table_name."_".FK_NAME;

            # Look up matching row in other (linked) table
		    # Get rows from other table with a $fk_field matching
		    #	this one's
            *schema = DBIx::Recordset->Search({'!DataSource' => DSN,
                                    '!Username' => USERNAME,
                                    '!Password' => PASSWORD,
                                    '!Table' => $other_table,
                                    "$fk_field" => $id
                                  });
            my $i = 0;
            while(my $other_pk = $schema[$i]{$primary_id}) {
                next if (!$other_pk);
                # use $i in name to keep 'em seperate
                #   & recursively unpopulate that other table
                un_populate_table($other_table,$other_pk,\%{$put_it_here->{$i}{"${other_table}"}});

                # Put The Candle - Back
                *schema = DBIx::Recordset->Search({'!DataSource' => DSN,
                                                '!Username' => USERNAME,
                                                '!Password' => PASSWORD,
                                                '!Table' => $other_table,
                                                "$fk_field" => $id
                                              });
                $i++;
            }
        }
    }
}

1;
