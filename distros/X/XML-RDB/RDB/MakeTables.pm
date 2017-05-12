#####
#
# $Id: MakeTables.pm,v 1.2 2003/04/19 04:17:48 trostler Exp $
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

package XML::RDB::MakeTables;
use vars qw($VERSION);
$VERSION = '1.2';

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
# We use DOM to parse the entire XML doc into memory
# use XML::DOM;  XML::RDB loads it
use strict;

# For generic schema def
use DBIx::DBSchema;

sub new {
#  my ($class, $rdb, $xmlfile, $outfile) = @_;
  my ($class, $rdb, $doc, $head, $outfile) = @_;

  # set up FH
  my $fh = new IO::File;
  if ($outfile) {
    $fh->open("> $outfile") || die "$!";
  } else {
    $fh->fdopen(fileno(STDOUT), 'w') || die "$!";
  }

#  my $doc = new XML::DOM::Parser->parsefile($xmlfile) || die "$!";
#  my $head = $doc->getDocumentElement;
    my $self = bless { 
      rdb => $rdb,
      doc => $doc,
      head => $head,
      one_to_n => $rdb->find_one_to_n_relationships($head),
      tables => {},   # where our tree is built
      headers => $rdb->{_HEADERS} || 0,
      selects => $rdb->{_SELECTS} || 0,
      outfile  => $outfile,
      fh => $fh,
                    }, $class;
  
  $self;
}

sub go {
  my($self) = @_;

  $self->_headers if ($self->{headers});
  # Create the table defs in memory
  $self->_make_tables($self->{head});
  $self->_add_in_1_to_n_cols;
  # Create DB-generic sequence tables for DBIx::Sequence
  #   XML root and primary key, used in unpopulating this table set.
  $self->_make_work_tables;

  # Dump them
  $self->_dump_dbschema_tables;
  # Select statemetents for viewing data
  $self->_dump_select_statements if ($self->{selects});
  $self->{fh}->close;
}

sub _headers {
  my $self = shift;
  my @t = localtime();
  my $datetime = sprintf("%4d-%02d-%02d %02d:%02d:%02d", 
                 $t[5] +1900,$t[4] +1,$t[3],$t[2],$t[1],$t[0]);

  $self->_p( <<"HEADER"
-- DSN : $self->{rdb}->{DSN}
--
-- XML::RDB SQL Generation 
-- XML file :  $self->{rdb}->{_XMLFILE}
-- SQL file :  $self->{outfile}
--     date :  $datetime
-- 
-- TABLE_PREFIX : $self->{rdb}->{TABLE_PREFIX}
--      PK_NAME : $self->{rdb}->{PK_NAME}
--      FK_NAME : $self->{rdb}->{FK_NAME}
--   TEXT_WIDTH : $self->{rdb}->{TEXT_WIDTH}
 
-------   ONE  to  MANY ------
------------------------------
HEADER
);

  # This will print out those relationships (preceded by a '--'!)
  #   so we can check 'em out
  $self->_p($self->{rdb}->dump_otn(\%{$self->{one_to_n}}, '--'));
  $self->_p( "\n" .'-- Gerated Tables'. "\n"
                  .'---------------------------------'. "\n");

  return $self;

}

sub _dump_select_statements {
  my $self = shift;
  my $buff;
  my @one2one;
  my $PK = $self->{rdb}->{PK_NAME};
  my $FK = $self->{rdb}->{FK_NAME};
  my $meta = \%{$self->{tables}{__meta__}};

  $self->_p( "\n" .'-- Flattened views of related tables'. "\n"
                 .'------------------------------------'. "\n")
      if ($self->{headers});

  foreach my $one (map { $self->{rdb}->mtn($_) } 
                      (sort(keys(%{$self->{one_to_n}})))) {
    # select columns
    $buff  = "-- SELECT \n";
    my @ns = (map {$self->{rdb}->mtn($_) } 
                  (sort(keys(%{$self->{one_to_n}{$meta->{$one}}}))));
    foreach my $t ($one, @ns) {
      foreach my $f  (sort(keys(%{$self->{tables}{$t}{cols}}))) {
        #[ table.field, lookup_table ] into ref_array
        if  ( $f =~ /^(\w+)_$PK$/ ) {
          push @one2one, ["$t.$f", $1]; 
        }
        # $one.field & $n's.field from column list
        elsif ( $f !~ /^($PK|\w+_$FK)$/ ) {
          $buff .= "--   $t.$f ,\n";
        }
      }
    }

    # lookup_table.field column list
    foreach my $t (@one2one) {
      map { $buff .= '--   '. $t->[1] .".$_ ,\n" } 
         sort(grep (!/^($PK|\w+_$FK|\w+_$PK)$/,
               (keys(%{$self->{tables}{$t->[1]}{cols}}))));
    }
    $buff =~ s/,$//;

    # from
    my $tables = "-- FROM \n--   ". ('(' x  (scalar(@ns) + scalar(@one2one))) ."$one  \n";
    my $space  = (' ' x  (scalar(@ns) + scalar(@one2one)));
    # one -> many are inner joins
    foreach my $t (@ns) {
      my $inner = '--   '. $space ."INNER JOIN $t ON  ";   
      map { $tables .= "$inner  $one.$PK = $t.$_ ) \n" } 
          sort(grep (/^${one}_$FK$/,
               (keys(%{$self->{tables}{$t}{cols}}))));
    }
    # lookup tables are left joins
    foreach my $t (@one2one) { 
      my $left = '--   '. $space ." LEFT JOIN $t->[1] ON  ";   
      $tables .= "$left ".  $t->[0] .' = '. $t->[1] .'.'. $PK ." ) \n";
    }
    # rap it, print it
    @one2one = ();
    $tables .= "-- LIMIT 500;\n\n";
    $self->_p($buff,$tables);
  }
  return $self;
}

sub _make_tables {
    my($self, $head) = @_;
    my(@stack, $sub_table, $text_field);
    my $rdb = $self->{rdb};
    TOP_TBLS:
    my $nodes = [ $head->getChildNodes ];
    ($sub_table, $text_field) = ();
    TOPLESS_TBLS:
    # Blow thru each child node of this node
    while ( scalar(@{$nodes}) ) {
        my $sub_node = shift(@{$nodes}); 
        # Skip these
        next if ($sub_node->getNodeType == XML::DOM::TEXT_NODE);
        next if ($sub_node->getNodeType == XML::DOM::COMMENT_NODE);

        # if (sub node doesn't have attributes) & (it only has 1 child node
        #   that's a next node || it has no sub nodes)
        # NOTE: This is the EXACT SAME 'if' statement as in 'PopulateTables.pm'
        #   THEY MUST MATCH or carnage will ensue.
        if (($sub_node->getAttributes && !$sub_node->getAttributes->getLength) && 
            (!$sub_node->getChildNodes 
             || ($#{$sub_node->getChildNodes} == 1 
                 && $sub_node->getChildNodes->[0]->getNodeType == XML::DOM::TEXT_NODE))) {
            # Plain text - just a regular column in table
            push @{$text_field}, $sub_node->getNodeName;
        }
        else {
            # Figure out what kind of relationship this element has to
            #   this sub-table - either 1:1 or 1:N
            if (!$self->{one_to_n}->{$head->getNodeName}{$sub_node->getNodeName}) {
                # Foreign key references in this table (1:1 relationship)
                push @{$sub_table}, $sub_node->getNodeName;
            }

            # The FKs in 1:N relationship tables will get dumped at the end

            # We'll need to make tables for these guys
            push(@stack, [$head, $nodes, $sub_table, $text_field]);
            $head = $sub_node;
            goto TOP_TBLS;
        }
    }
    
    # NOTE : Replaced the recursive sub loop with goto's & lifo @stack,
    # then combined make_tables & make_table. For about 500 xml nodes 
    # we where penilized for about 2000 calls on each routine. 
    # Now 1 call is made, replacing 4000 calls.
    # Makes it a little harder to read, but not much.
    # -------------------------------------------------------------
    # We've got all the info we need - fill out our data structure
    ##
    # This function fills out or data structure that describes a table
    ##
    # sub _make_table
    # Takes a pro-spective table name
    #   array refs of sub tables & text field names
    #   and an XML::DOM::NamedNodeMap of XML attributes
    # my($self, $o_table_name, $sub_table, $leaf, $attr_ref) = @_;

    # DB-ize table name
    my $table_name = $rdb->mtn($head->getNodeName);

    # Keep original element name
    $self->{tables}->{__meta__}{$table_name} = $head->getNodeName;

    # Do foreign keys first - they're integers
    foreach (@$sub_table) {
        $self->{tables}->{$table_name}{cols}{$rdb->mtn($_)."_".$rdb->{PK_NAME}}{type} = "integer";
    }

    # Now do 'leaf/real' fields - text columns
    foreach (@$text_field) {
        next if ($self->{one_to_n}->{$table_name}{$_});

        # Create column name & stash original name for this field
        my $field = XML::RDB::normalize($_); 
        my $col_name = "${table_name}_${field}_value";
        $self->{tables}->{__meta__}{$col_name} = $_;
        $self->{tables}->{$table_name}{cols}{$col_name}{type} = $rdb->{TEXT_COLUMN};
    }

    # Now do attributes - these are just text columns
    my $attr_ref = $head->getAttributes;
    if ($attr_ref) {
        for(my $i = 0 ; $i < $attr_ref->getLength ; $i++) {
            my $attr = $attr_ref->item($i);
            my $name = XML::RDB::normalize($attr->getName);
            $_ = "${table_name}_${name}_attribute";
            # Stash original name for this column
            $self->{tables}->{__meta__}{$_} = $attr->getName;
            $self->{tables}->{$table_name}{cols}{$_}{type} = $rdb->{TEXT_COLUMN};
        }
    }

    # Need this for stuff like <element>Howdy!</element>
    #   unfortunately this also picks up <element/> so
    #   it adds some extra cruft but those cols just won't get
    #   populated...
    if (!@$text_field && !@$sub_table)   {
        $self->{tables}->{$table_name}{cols}{"${table_name}_value"}{type} = $rdb->{TEXT_COLUMN};
    }

  if (scalar(@stack) > 0) {
    ($head, $nodes, $sub_table, $text_field) = @{pop(@stack)};
    goto TOPLESS_TBLS;
  }
}

# generic-ized dump of tables
#   It's up to DBIx::DBSchema to provide us w/the generic
#       table defs - currently MySQL & PostgreSQL are supported
#       for sure w/very generic SQL for everything else
#       So 'hopefully' it'll 'just work'! (yeah right)
sub _dump_dbschema_tables {
    my($self) = @_;
    my %tables = %{$self->{tables}};
    my $schema = new DBIx::DBSchema;
    
    # Generic PK column
    my $pk_id = new DBIx::DBSchema::Column({
                  name => $self->{rdb}->{PK_NAME},
                  type => 'integer',  # Use DBIx::Sequence to handle PKs
                  null => 'NOT NULL'
                  });

    foreach my $table_name (keys %tables) {
      # Skip the meta-info stuff
      next if ($table_name eq '__meta__');

      # The table
	  my (@columns,$table);
      foreach my $col (keys %{$tables{$table_name}{cols}}) {
	    push @columns,  new DBIx::DBSchema::Column({
                          name => $col,
                          type => $tables{$table_name}{cols}{$col}{type},
                          null => !$tables{$table_name}{cols}{$col}{not_null}
                          });
      }

	  if ((exists($tables{$table_name}{no_id})) and ($tables{$table_name}{no_id} == 1)) {
        $table = new DBIx::DBSchema::Table({ name => $table_name,
                                             columns     => \@columns });
      }
      else {
        push @columns, $pk_id;
        $table = new DBIx::DBSchema::Table({ name => $table_name,
                                             primary_key => $self->{rdb}->{PK_NAME}, 
                                             columns     => \@columns });
      }
      $schema->addtable($table) if ($table);
    }

    #
    # Now create table with table names & attributes mapped to
    #   their 'real' names
    my %values;
    foreach my $thing (sort keys %{$tables{__meta__}}) {
        next if ($thing eq 'cols');
        $values{$thing} = $tables{__meta__}{$thing};
    }

    # local($") = ", ";
   
    # Dump out tables real purty like
    local($") = '';
    my @sql = map { chomp ; $_.=";\n\n" } $schema->sql($self->{rdb}->{DBH});
    $self->_p("@sql\n");

    # Dump real element names mappings
    $self->_p( "\n" .'-- Real XML element names mapping'. "\n"
                    .'---------------------------------'. "\n")
        if ($self->{headers});

    local($") = ",";
    map { $self->_p("INSERT INTO ", $self->{rdb}->{REAL_ELEMENT_NAME_TABLE}," VALUES ('$_','$values{$_}');\n"); } keys %values;

   # Dump 1:N table relationship names
     $self->_p("\n" .'-- 1:N table relationship names'. "\n"
                    .'-------------------------------'. "\n")
        if ($self->{headers});
    foreach my $one (keys %{$self->{one_to_n}}) {
        foreach my $many (keys %{$self->{one_to_n}->{$one}}) {
            my $table_name = "'" . $self->{rdb}->mtn($one) . "'";
            my $link = "'" . XML::RDB::normalize($many) . "'";
            $self->_p("INSERT INTO ", $self->{rdb}->{LINK_TABLE_NAMES_TABLE}, 
              " VALUES ($table_name,$link);\n");
        }
    }
}

sub _make_work_tables
{
  my ($self) = @_;

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

#  my $t1 = "dbix_sequence_state";
#  my $t2 = "dbix_sequence_release";
#
#  $self->{tables}->{$t1}{cols}{'dataset'}{type} = $self->{rdb}->{TEXT_COLUMN};
#  $self->{tables}->{$t1}{cols}{'state_id'}{type} = "integer";
#  $self->{tables}->{$t1}{no_id} = 1;
#
#  $self->{tables}->{$t2}{cols}{'dataset'}{type} = $self->{rdb}->{TEXT_COLUMN};
#  $self->{tables}->{$t2}{cols}{'released_id'}{type} = "integer";
#  $self->{tables}->{$t1}{no_id} = 1;

  # Table added to hold primary key and root table for dumping the XML
  $self->{tables}->{$self->{rdb}->{ROOT_TABLE_N_PK_TABLE}}{cols}{'root'}{type} = $self->{rdb}->{TEXT_COLUMN};
  $self->{tables}->{$self->{rdb}->{ROOT_TABLE_N_PK_TABLE}}{cols}{'pk'}{type} = "integer";
  $self->{tables}->{$self->{rdb}->{ROOT_TABLE_N_PK_TABLE}}{cols}{'root'}{not_null} = 1;
  $self->{tables}->{$self->{rdb}->{ROOT_TABLE_N_PK_TABLE}}{cols}{'pk'}{not_null} = 1; 
  $self->{tables}->{$self->{rdb}->{ROOT_TABLE_N_PK_TABLE}}{no_id} = 1;

  $self->{tables}->{$self->{rdb}->{REAL_ELEMENT_NAME_TABLE}}{cols}{'db_name'}{type} = $self->{rdb}->{TEXT_COLUMN};
  $self->{tables}->{$self->{rdb}->{REAL_ELEMENT_NAME_TABLE}}{cols}{'xml_name'}{type} = $self->{rdb}->{TEXT_COLUMN};
  $self->{tables}->{$self->{rdb}->{REAL_ELEMENT_NAME_TABLE}}{cols}{'db_name'}{not_null} = 1;
  $self->{tables}->{$self->{rdb}->{REAL_ELEMENT_NAME_TABLE}}{cols}{'xml_name'}{not_null} = 1;
  $self->{tables}->{$self->{rdb}->{REAL_ELEMENT_NAME_TABLE}}{no_id} = 1;

  $self->{tables}->{$self->{rdb}->{LINK_TABLE_NAMES_TABLE}}{cols}{'one_table'}{type} = $self->{rdb}->{TEXT_COLUMN};
  $self->{tables}->{$self->{rdb}->{LINK_TABLE_NAMES_TABLE}}{cols}{'many_table'}{type} = $self->{rdb}->{TEXT_COLUMN};
  $self->{tables}->{$self->{rdb}->{LINK_TABLE_NAMES_TABLE}}{cols}{'one_table'}{not_null} = 1;
  $self->{tables}->{$self->{rdb}->{LINK_TABLE_NAMES_TABLE}}{cols}{'many_table'}{not_null} = 1;
  $self->{tables}->{$self->{rdb}->{LINK_TABLE_NAMES_TABLE}}{no_id} = 1;

  return $self;
}

#
# So the game here is to add in the PK of one column
#	as an FK in the many column
#
sub _add_in_1_to_n_cols {
  my ($self) = @_;
    foreach my $one (keys %{$self->{one_to_n}}) {
        foreach my $many (keys %{$self->{one_to_n}->{$one}}) {
		my $many_table = $self->{rdb}->mtn($many);
		my $col_to_add = $self->{rdb}->mtn($one . "_" . $self->{rdb}->{FK_NAME});

		$self->{tables}->{$many_table}{cols}{$col_to_add}{type} = 'integer';
        # MySQL allows this, 
        # SQLite3 does not.
        # Postgresql does not.
        # and I do not, well maybe add a constraint after load.
#	$self->{tables}->{$many_table}{cols}{$col_to_add}{not_null} = 1;
		}
	}
}

sub _p {
  my($self) = shift;
  local($") = "";
  my $fh = $self->{fh};
  print $fh "@_";
}

1;
