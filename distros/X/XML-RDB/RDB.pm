#####
#
# $Id: RDB.pm,v 1.1 2003/04/18 00:33:17 trostler Exp $
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

package XML::RDB;

use XML::DOM;
use XML::RDB::MakeTables;
use XML::RDB::PopulateTables;
use XML::RDB::UnpopulateTables;
use XML::RDB::UnpopulateSchema;
use strict;

#####
#
# Copyright (c) 2001-2003  Juniper Networks, Inc.
# All rights reserved.
#
# Set of common routines & constants
# 
#####
BEGIN {
        use Exporter ();
        use vars qw($VERSION); # @ISA @EXPORT);
        $VERSION = "1.3";
#        @ISA = qw(Exporter);
#        @EXPORT = qw(
#                    );
      }

sub new {
    my ($class, %arg) = @_;
    my $config;

    if ($arg{config_file}) {
      open(C, "$arg{config_file}") || die "$!";
      while(<C>) {
        next if (/^(#|$)/);
        next unless (my ($key, $value) = $_ =~ /^([A-Z_]+)=(.+)/);
        chomp $value;
        $key =~ s/\s//g;
        $value =~ s/\s//g;
        $config->{$key} = $value if ($key);
      }
      close(C);
    }
    elsif ( scalar(keys(%arg)) > 0 ) {
      $config = \%arg;
    }
    else {
      warn "$class requires a DSN for DBI->connect\n";
      return undef;
    }

    # setup connection
    my $dbh = DBI->connect(
                    $config->{DSN}, 
                    ($config->{DB_USERNAME} || ''), 
                    ($config->{DB_PASSWORD} || ''),
                    { RaiseError => $config->{DB_RAISEERROR} || 0,
                      PrintError => $config->{DB_PRINTERROR} || 0,
                      # NOTE :
                      # autocommit needs to be on for this app in its current state.
                      # 1. the method of inserts, and updates
                      # 2. DBIx::Sequence
                      AutoCommit => 1 } 
            ) or (( warn $!) and ( return undef));
   
    if ( $config->{DSN} =~ /dbi:sqlite/i) {
      warn("SQLite detected...setting SQLite PRAGMA: synchronus = OFF; locking_mode = EXCLUSIVE\n") 
        if ($config->{DB_PRINTERR});
      $dbh->do('PRAGMA synchronous = OFF') || warn $dbh->errstr;
      $dbh->do('PRAGMA locking_mode = EXCLUSIVE') || warn $dbh->errstr;
    }
    
    $DBIx::Recordset::Debug         = $config->{DBIX_DEBUG}         || 0;
    $DBIx::Recordset::FetchsizeWarn = $config->{DBIX_FETCHSIZEWARN} || 0;

    my $self = bless { 
                    DSN          => $config->{DSN},
                    DB_CATALOG   => (defined $config->{DB_CATALOG}) 
                                    ? $config->{DB_CATALOG}
                                    : undef,
                    DBH          => $dbh,
                    TEXT_COLUMN  => ($config->{TEXT_WIDTH})
                                    ? 'varchar('. $config->{TEXT_WIDTH} .')'
                                    : 'varchar(50)',
                    TEXT_WIDTH   => $config->{TEXT_WIDTH} || 50,
                    TAB          => ($config->{TAB}) ? ' ' x $config->{TAB} : '  ',
                    PK_NAME      => $config->{PK_NAME} || 'id',
                    FK_NAME      => $config->{FK_NAME} || 'fk',
                    TABLE_PREFIX => $config->{TABLE_PREFIX} || 'gen',
                    DB_USERNAME  => $config->{DB_USERNAME} || '',
                    DB_PASSWORD  => $config->{DB_PASSWORD} || '',
                    _HEADERS     => (defined $config->{SQL_HEADERS}) 
                                    ? $config->{SQL_HEADERS} : 1,
                    _SELECTS     => (defined $config->{SQL_SELECTS}) 
                                    ? $config->{SQL_SELECTS} : 1,
                    _SQLITE      => ($config->{DSN} =~ /dbi:sqlite/i) ? 1 : 0,
                  }, $class;

    $self->{REAL_ELEMENT_NAME_TABLE} = $self->mtn('element_names');
    $self->{LINK_TABLE_NAMES_TABLE}  = $self->mtn('link_tables');
    $self->{ROOT_TABLE_N_PK_TABLE}   = $self->mtn('root_n_pk');
    return $self;
}

sub done { my $self = shift; $self->DESTROY; return $self};

sub DESTROY {
  my $self = shift;

  # NOTE :  Recordset specific
  # Undef takes the name of a typglob and will destroy the array, the
  # hash, and the object. All unwritten data is  written to the db.
  # All db connections are closed and all memory is freed.
  # DBIx::Recordset::Undef ($name)
  # DBIx::Recordset->Flush(); 
  $self->{DBH}->disconnect() if ($self->{DBH});
  $self->{_DOC}->dispose     if ($self->{_DOC});
}

sub drop_tables {
  my $self = shift;
  return warn "Please add DB_CATALOG for the dsn supplied for dropping tables.\n"
    unless ( defined $self->{DB_CATALOG} );
  my $dbh = $self->{DBH};
  my ($driver, $dbname) = $self->{DSN} =~ /dbi:(\w+):\w+=(\w+)/i;
  my $sth;

  if    ( $self->{DB_CATALOG} == 0 ) {
    $sth = $dbh->table_info(undef, $dbname, undef, undef);
  }
  elsif ( $self->{DB_CATALOG} == 1 ) {
    $sth = $dbh->table_info($dbname, 'public', undef, undef);
  }
  else {
    return warn 'Please fix DB_CATALOG to boolean (1|0) in your dsn config file.'
               .'examples : Postgres 1, SQLite 0, Mysql 0' ."\n";
  }
  
  my $d_tables;
  my $regex = '^'. $self->{TABLE_PREFIX} .'_\w+';
  for my $rel (@{$sth->fetchall_arrayref({})}) {
    if ($rel->{TABLE_NAME} =~ /$regex/o) {
      push(@{ $d_tables }, $rel->{TABLE_NAME});     
      $dbh->do('DROP TABLE '. $rel->{TABLE_NAME}) 
    }
  }
  return $d_tables;
}

sub create_tables {
my ($self, $file) = @_;
my $statement;  
	
  open (F, $file) || die $!;
  while (<F>) {
    next if (/^(-|$)/); chomp;
    
    if (s/;$//) {
      $self->{DBH}->do($statement . $_) || die $self->{DBH}->errstr;
      $statement = '';
    }
    else {
      $statement .= $_;
    }
  }
  close(F);
  return $self;
}

sub _get_xml {
  my $self = shift;
  my $xmlfile = shift;

  if  (($self->{_XMLFILE}) and 
       ((!$xmlfile) or ($self->{_XMLFILE} eq $xmlfile))) {
    undef; 
  }
  elsif ($self->{DOC}) {
    $self->{_DOC}->dispose;
    $self->{_XMLFILE} = $xmlfile;
    $self->{_DOC} = $self->{_XMLPARSER}->parsefile($xmlfile);
    $self->{_HEAD} = $self->{_DOC}->getDocumentElement;
  }
  else {
    $self->{_XMLFILE} = $xmlfile;
    $self->{_XMLPARSER} = new XML::DOM::Parser;
    $self->{_DOC} = $self->{_XMLPARSER}->parsefile($xmlfile) || die "$!";
    $self->{_HEAD} = $self->{_DOC}->getDocumentElement;
  }
  return ($self->{_DOC},$self->{_HEAD});
}

sub make_tables {
  my ($self, $xmlfile, $outfile) = @_;
  my ($doc, $head) = $self->_get_xml($xmlfile);
  my $mt = new XML::RDB::MakeTables($self, $doc, $head, $outfile);
  $mt->go;
}

sub populate_tables {
  my ($self, $xmlfile) = @_;
  my ($doc, $head) = $self->_get_xml($xmlfile);
  my $pt = new XML::RDB::PopulateTables($self, $doc, $head);
  $pt->go;
}

sub unpopulate_tables {
  my $self = shift;
  my $outfile = shift;
  my $root_n_pk = $self->get_root_n_pk_db();
  my $ut = new XML::RDB::UnpopulateTables($self,$outfile);
  $ut->go($root_n_pk->{root}, $root_n_pk->{pk});
}

sub unpopulate_schema {
  my $us = new XML::RDB::UnpopulateSchema(@_);
  $us->go;
}

#
# Blow thru all nodes & find 1:N relationships between them
#   Need to pass the root of yer XML::DOM tree
# Quite pleasant really
# Basically just count the number of duplicate elements under
#   this one - if > 1 then 1:N relationship
#
sub find_one_to_n_relationships {
# NOTE : Replaced the recursive loop with goto's with a @stack 
    my($self, $head) = @_;
    my (@stack,%saw,$one_to_n);
    TOP_REL:
    my $nodes = [ $head->getChildNodes ];
    %saw = ();

    # Count duplicates
    grep($saw{$_->getNodeName}++, @{$nodes});
    foreach (keys %saw) {
        next if /#text/;
        next if /#comment/;
        next if ($one_to_n->{$head->getNodeName}{$_});
        if ($saw{$_} > 1) {
            $one_to_n->{$head->getNodeName}{$_} = 1;
        }
    }

    TOPLESS_REL:
    # And recurse on down the road
    while (scalar(@{$nodes})) {
      my $sub_node =  shift(@{$nodes});
      next if ($sub_node->getNodeType == XML::DOM::TEXT_NODE);
      push(@stack, $nodes);
      $head = $sub_node;
      goto TOP_REL;
    }

  if (scalar(@stack) > 0) {
    $nodes = pop(@stack);
    goto TOPLESS_REL;
  }

  # Done is Done
  return $one_to_n;
}

#
# Helper function to dump the 'one_to_n' datastructure out
#
sub dump_otn {
  my $self = shift;
    my($otn, $char) = @_;
    my $ret;

    foreach my $one (keys %$otn) {
        foreach my $many (keys %{$otn->{$one}}) {
            $ret .= "${char}\t$one -> $many\n";
        }
    }
    return $ret;
}

#
# 'mtn' = 'Make Table Name' - cleans up text so it's a valid
#   DB table name & adds TABLE_PREFIX
#
sub mtn {   
    my($self, $base, $out) = @_;
    ($out = $self->{TABLE_PREFIX} . "_$base") =~ y/#:\.-/_____/;
    lc $out;
}
    
# Normalize column/table names - No ':' or '-' & all lower case
sub normalize {
    my($in,$out) = shift;
    
    # Get rid of funny stuff 
#    ($out = $in) =~ s/[#:\.-]/_/go;
    ($out = $in) =~ y/#:\.-/_____/;
    lc $out;
}

#
# Pulls out root_n_pk data from the DB itself
#
sub get_root_n_pk_db {
  my $self = shift;
  my $rt_n_pk;

  if ($self->{_SQLITE}) {
    my $sth = $self->{DBH}->prepare('select * from '. $self->{ROOT_TABLE_N_PK_TABLE});
    $sth->execute();
    my $row = $sth->fetch(); 
    $rt_n_pk = { root => $row->[1],  pk => $row->[0] }
      if ($row);    
  }
  else {
    use vars qw(*root_n_pk);
    *root_n_pk = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                 '!Table' => $self->{ROOT_TABLE_N_PK_TABLE}});
    my $root;                             
    $root = $root_n_pk[0] if (@root_n_pk);
    $rt_n_pk = { root => $root->{root}, pk => $root->{pk} } if ($root);
    DBIx::Recordset::Undef ('*root_n_pk');
  }
  return $rt_n_pk;
}

#
# Pulls out one_to_n data structures from the DB itself
#
sub get_one_to_n_db {
  my $self = shift;
  my %one_to_n;

  if ($self->{_SQLITE}) {
    my $sth = $self->{DBH}->prepare('select * from '. $self->{LINK_TABLE_NAMES_TABLE});
    $sth->execute();
    while (my $row = $sth->fetch()) {
       $one_to_n{$row->[0]}{$row->[1]} = 1;    
    }
  }
  else {
    use vars qw(*link_tables);
    *link_tables = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                 '!Table' => $self->{LINK_TABLE_NAMES_TABLE}});
    foreach my $links (@link_tables) {
        $one_to_n{$links->{one_table}}{$links->{many_table}} = 1;
    }
    #    *link_tables->Flush(); 
    DBIx::Recordset::Undef ('*link_tables');
  }
  return \%one_to_n;
}

sub get_real_element_names_db {
  my $self = shift;
  my $names;

  if ($self->{_SQLITE}) {
    my $sth = $self->{DBH}->prepare('select * from '. $self->{REAL_ELEMENT_NAME_TABLE});
    $sth->execute();
    while (my $row = $sth->fetch()) {
       $names->{$row->[0]} = $row->[1];    
    }
  }
  else {
    use vars qw(*set);
    *set = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                    '!Table' => $self->{REAL_ELEMENT_NAME_TABLE}});
      foreach my $n (@set) {
          $names->{$n->{db_name}} = $n->{xml_name};
      }
      #    *link_tables->Flush(); 
    DBIx::Recordset::Undef ('*set');
  }
  return $names;
}


#
# Get the corresponding 'xml_name' from this 'db_name'
#
#sub get_xml_name {
#  my($self, $db_name) = @_;
#    my @set = DBIx::Recordset->Search({
#        '!DataSource' => $self->{DBH},
#        '!Table' => $self->{REAL_ELEMENT_NAME_TABLE},
#        '$where' => 'db_name = ?',
#        '$values' => [ $db_name ],
#      });
#
#    $set[0]{xml_name};
#}

#
# Recursive routine to unpopulate DB into in-memory data structure
#
# Takes a table name, PK of a row, & a hash ref of where in this
#   giant monstrous data in-memory data-structure we've created to
#   stick this row's values
#

sub un_populate_table {
    my($self, $one_to_n, $table_name, $id, $put_it_here) = @_;
    my $match = "_" . $self->{PK_NAME};
    my(@stack, $schema_names, $jj, $other_table, $fk_field, $links, $kk, $i );
    use vars qw(*schema);   # DBIx::Recordset likes GLOBs, yummy

    TOP_TBL:
    ( $jj, $other_table, $fk_field, $links, $kk, $i ) = ();
            
    # This'll get the ball rolling...
    *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                       '!Table' => $table_name,
                                        $self->{PK_NAME} => $id
                                        });
    # Any column that ends in '_id' we gotta assume is a 1:1 map
    # Any column that ends in '_value' is text in this element
    # Any column that ends in '_attribute' is an attribute

    $schema_names = $schema->Names;

#    foreach my $col (@{$schema->Names}) {
    for ($jj = 0; scalar(@{$schema_names}) > $jj; $jj++) {
        my $col = $schema_names->[$jj];
        my $val = $schema[0]{$col};

        if ($col =~ /${match}$/o) {
            # 1:1
            next if (!$val);

            # Unpopulate sub table since this is a foreign key
            my $this_table;
            ($this_table = $col) =~ s/${match}$//;
#            $self->un_populate_table($one_to_n, $other_table, $val, \%{$put_it_here->{$other_table}});

            push(@stack, [ $table_name, $id, $put_it_here, $schema_names, $jj, 
                           $other_table, $fk_field, $links, $kk, $i ]);
            ($table_name, $id, $put_it_here ) = 
              ($this_table, $val, \%{$put_it_here->{$this_table}});
            goto TOP_TBL;
            TOPLESS_TBL_1to1:

            # Put the candle - back
            *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                               '!Table' => $table_name,
                                               $self->{PK_NAME} => $id});

        }
        elsif ($col =~ /_value$/o) {
            # text between tag
            $put_it_here->{value} = $val if (defined $val);
        }
        elsif ($col =~ /_attribute$/o) {
            # attribute
            $put_it_here->{attribute}{$col} = $val if (defined $val);
        }
        elsif ($col eq $self->{PK_NAME}) {
            # PK - don't do anything
        }
        elsif ($col =~ /_$self->{FK_NAME}$/o ) {
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

          $links = [ keys %{$one_to_n->{$table_name}} ];

          for ($kk = 0; scalar(@{$links}) > $kk; $kk++) {
            my $link = $links->[$kk];

            # Look up other PK via our PK (which is an FK in the sub_table)
            $other_table = $self->mtn($link);
    	    $fk_field = $table_name."_" . $self->{FK_NAME};

            # Look up matching row in other (linked) table
    	        # Get rows from other table with a $fk_field matching
    	        #	this one's
            *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
                                   '!Table' => $other_table,
                                    "$fk_field" => $id});

            $i = 0;
            while(my $other_pk = $schema[$i]{$self->{PK_NAME}}) {
                next if (!$other_pk);
                # use $i in name to keep 'em seperate
                #   & recursively unpopulate that other table
#                $self->un_populate_table($one_to_n, $other_table, $other_pk, \%{$put_it_here->{$i}{"${other_table}"}});

                push(@stack, [ $table_name, $id, $put_it_here, $schema_names, $jj, 
                               $other_table, $fk_field, $links, $kk, $i ]);
                ($table_name, $id, $put_it_here ) = 
                  ($other_table, $other_pk, \%{$put_it_here->{$i}{"${other_table}"}});
      
                goto TOP_TBL;
                TOPLESS_TBL_FK:

                # Put The Candle - Back
                *schema = DBIx::Recordset->Search({'!DataSource'=>$self->{DBH},
                                   '!Table' => $other_table,
                                    "$fk_field" => $id});
                $i++;
            }
        }
    }

  if (scalar(@stack) > 0) {
    ( $table_name, $id, $put_it_here, $schema_names, $jj,
      $other_table, $fk_field, $links, $kk, $i ) = @{pop(@stack)};
    unless ($other_table) {  goto TOPLESS_TBL_1to1;  }
                     else {  goto TOPLESS_TBL_FK;    }
  }

    DBIx::Recordset::Undef ('*schema');
}




#sub un_populate_table {
#    my($self, $one_to_n, $table_name, $id, $put_it_here) = @_;
#    use vars qw(*schema);   # DBIx::Recordset likes GLOBs, yummy
#
#    # This'll get the ball rolling...
#    *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
#                                       '!Table' => $table_name,
#                                        $self->{PK_NAME} => $id
#                                        });
#    # Any column that ends in '_id' we gotta assume is a 1:1 map
#    # Any column that ends in '_value' is text in this element
#    # Any column that ends in '_attribute' is an attribute
#    foreach my $col (@{$schema->Names}) {
#        my $val = $schema[0]{$col};
#        my $match = "_" . $self->{PK_NAME};
#
#        if ($col =~ /${match}$/) {
#            # 1:1
#            next if (!$val);
#
#            # Unpopulate sub table since this is a foreign key
#            my $other_table;
#            ($other_table = $col) =~ s/${match}$//;
#            $self->un_populate_table($one_to_n, $other_table, $val, \%{$put_it_here->{$other_table}});
#            # Put the candle - back
#            *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
#                                               '!Table' => $table_name,
#                                               $self->{PK_NAME} => $id});
#
#        }
#        elsif ($col =~ /_value$/) {
#            # text between tag
#            $put_it_here->{value} = $val if (defined $val);
#        }
#        elsif ($col =~ /_attribute$/) {
#            # attribute
#            $put_it_here->{attribute}{$col} = $val if (defined $val);
#        }
#        elsif ($col eq $self->{PK_NAME}) {
#            # PK - don't do anything
#        }
#        elsif ($col =~ /_$self->{FK_NAME}$/ ) {
#            # FK - don't do anything
#        }
#        else {
#            # Keep us honest
#            die "I don't know what to do with column name $col = $val!\n";
#        }
#    }
#
#    # Now get 1:N relationships
#    if ($one_to_n->{$table_name}) {
#        # Go thru each 'N' relationship table to this one
#        foreach my $link (keys %{$one_to_n->{$table_name}}) {
#            # Look up other PK via our PK (which is an FK in the sub_table)
#            my $other_table = $self->mtn($link);
#    	        my $fk_field = $table_name."_" . $self->{FK_NAME};
#
#            # Look up matching row in other (linked) table
#    	        # Get rows from other table with a $fk_field matching
#    	        #	this one's
#            *schema = DBIx::Recordset->Search({'!DataSource' => $self->{DBH},
#                                   '!Table' => $other_table,
#                                    "$fk_field" => $id});
#            my $i = 0;
#            while(my $other_pk = $schema[$i]{$self->{PK_NAME}}) {
#                next if (!$other_pk);
#                # use $i in name to keep 'em seperate
#                #   & recursively unpopulate that other table
#                $self->un_populate_table($one_to_n, $other_table, $other_pk, \%{$put_it_here->{$i}{"${other_table}"}});
#
#                # Put The Candle - Back
#                *schema = DBIx::Recordset->Search({'!DataSource'=>$self->{DBH},
#                                   '!Table' => $other_table,
#                                    "$fk_field" => $id});
#                $i++;
#            }
#        }
#    }
##    *schema->Flush(); 
#    DBIx::Recordset::Undef ('*schema');
#}

1;
__END__
=head1 NAME

XML::RDB - Perl extension to convert XML files into RDB schemas and 
populate, and unpopulate them.  Works with XML Schemas too.

=head1 SYNOPSIS

  use XML::RDB;

  # Give our DB's DSN & username/password
  my $rdb = new XML::RDB(config_file => 'db_config');

  # OR
  # supply new variables
  # my $rdb = new XML::RDB(DSN => 'dbi:SQLite:dbname=test',
  #                        DB_CATALOG => 0 );

  # Supply file or url
  #   Generate RDB Schema
  $rdb->make_tables("my_xml_file.xml", "db_schema_output_file");

  # Now load the generated 'db_schema_output_file' into your DB
  $rdb->create_tables("db_schema_output_file");

  # Now populate our RDB
  $rdb->populate_tables("my_xml_file.xml");

  # OR
  # undef when rdb has loaded the same XML file
  # $rdb->populate_tables();

  # Your XML file is now in your RDB!!!!  Play as desired & when ready:
  $rdb->unpopulate_tables('new_xml_file.xml'); 

  # OR
  # undef writes to STDOUT
  # $rdb->unpopulate_tables();

  #Or drop the tableset
  $tables = $rdb->drop_tables;
  print "dropped @{$tables} ...\n":

  # Disconnect DB, XML::DOM cleanup
  $rdb->done;

  +______________________________________________________+
  |                                                      |
  |  Table of configuration in 'new',                    |
  |   same list available by dsn config file.            |
  |                                                      |
  |  scalar              default value                   |
  |  ------------------  -------------                   |
  |  DSN                 undef                           |
  |  DB_USERNAME         ''                              |
  |  DB_PASSWORD         ''                              |
  |  DB_RAISEERROR       0                               |
  |  DB_PRINTERROR       0                               |
  |  DBIX_DEBUG          0                               |
  |  DBIX_FETCHSIZEWARN  0                               |
  |  DB_CATALOG          undef                           |
  |  TEXT_WIDTH          50                              |
  |  TAB                 2                               |
  |  PK_NAME             'id'                            |
  |  FK_NAME             'fk'                            |
  |  TABLE_PREFIX        'gen'                           |
  |  SQL_HEADERS         1                               |
  |  SQL_SELECTS         1                               |
  |                                                      |
  |              OR   ( specifing both, the config file  |
  |                     is read and available defaults   |
  |                     are supplied. )                  |
  |                                                      |
  |  config_file         'dsn config file'               |
  |                                                      |
  +______________________________________________________+


Re-vamped the above portion, again. A third improvement over 1.2 in speed and memory management on a couple routines.
  Replaced recursive sub calls with the beloved 'goto'.
  Added further flexibility to the interface 
  Added 2 new config vars, SQL_*
  Removed DBIx::Sequence and related work tables, dbix_*.
  Tested with  Postgreql 8.3, SQLite 3.6.16, and MySQL 5.0.51a. on perl 5.10

TODO : Recursive routines can be optimized (further).
       Move to LibXML
       Get XSD working, xml newb here.
       Fix the API, (think most of it works now) 
       Re-write this doc.

  XSD IS ON THE BENCH BROKE, interested if you have it working.
  p.s. the rest is good reading, inspiring.



  # That's all fine & dandy but what if you've got an XML Schema???
  #
  # the first 2 calls are the same:
  $rdb->make_tables("my_xsd_file.xsd", "db_schema_output_file");

  #
  # don't forget to put 'db_schema_output_file' into your DB!
  # then:
  my($root_table_name, $primary_key) = 
                        $rdb->populate_tables("my_xsd_file.xsd");

  # note we only need the primary key for this next call
  $rdb->unpopulate_schema($primary_key, 'fully_formed.xml'); 

  #
  # Now you've got 'fully_formed.xml' - pass THAT to make_tables 
  # & yer golden:
  #
  
  $rdb->make_tables("fully_formed.xml", "REAL_RDB_schema");

  #
  # Now insert REAL_RDB_schema into yer DB & now any XML documents 
  # conforming to your original XML Schema ('my_xsd_file.xsd') can be 
  # imported into your schema:
  my ($rt, $pk) =
    $rdb->populate_tables("xml_doc_conforming_to_my_xsd_file.xml");

  # See the 'README' file for a LOT more information...
  
=head1 ABSTRACT

XML::RDB - Perl extension to convert XML files into RDB schemas and 
populate, and unpopulate them.  Works with XML Schemas too.
Analyzes relationships within either an XML file or an XML Schema to 
create RDB tables to hold that document (or any XML document that 
conforms to the XML Schema).

=head1 DESCRIPTION

XML/RDB version 1.1
====================

A long-arse how-to & explanation:

    An XML document is an ideal transport for data between heterogeneous 
systems.  XML documents are also an ideal way to represent hierarchical 
data generically.  Yet when it comes time to store, query, compare, edit, 
delete, and even create these data-centric documents, few mature XML 
tools exist.
    Fortunately, there is an older technology that has been successfully
handling these tasks for years.  It also has (fairly) standard syntax
and a standard query language (in fact it has _the_ Standard Query 
Language (1)).  Everyone's got one - your pal and mine - the Relational 
Database Management System (RDBMS).  
    While native XML Databases are best suited for storing document-
centric data like XHTML files, data-centric documents, like a Juniper 
Network's(tm) router configuration, are best stored within a RDBMS, a 
system which is tuned for data storage and manipulation (2).
    By bringing these two technologies together, we can leverage each
system's strengths, minimize their weaknesses, and learn that by using 
Perl, two seemingly opposed technologies can become friends.
    An example of hierarchical data is a router's configuration.
Using a Perl module, an XML-ified version of a Juniper router's
configuration can be retrieved easily.  Almost any bit of router 
information can be requested and received in XML using Juniper 
Network's JUNOScript (3) technology.  Using a standard set of XML 
libraries, these XML documents are easily manipulated at a low level.  
Unfortunately, higher-level tools to manipulate XML are either immature, 
unproven, unknown, or simply non-existent. But by putting XML documents 
into a RDBMS we have access to all of the robust, mature data 
manipulation tools we need.
    The ability to map XML to RDBMSs (and then back into XML) plays to
both system's strengths:  XML provides self-describing data transport, 
and the RDBMS provides data managing and manipulating tools. 
    But how should we put an XML document into a RDBMS?  The quick and 
dirty answer is to store the entire XML document in a RDBMS as a Binary 
Large Object (BLOB) or Character Large Object (CLOB) - but these 
approaches solve very little and certainly do not take full advantage of 
the RDBMS.  Other existing tools force you to pre-create your RDBMS 
schema to match your XML Documents, or require you to create either an 
XML or proprietary template to define the mapping between your XML 
documents and your RDBMS table sets.  But I thought XML was 
self-describing - why should we have to describe our data twice?  
Fortunately we don't have to.  Using the self-describing nature of 
XML documents, and Perl, there is a better way.

Relationships

    The key to transforming XML into a RDBMS is analyzing the 
relationships in an XML document and then mapping those relationships 
into a RDBMS.
Let's examine the kinds of relationships utilized by a RDBMS - there 
are three:

    1. 1 to 1 relationship (1:1)
        We are only interested in the simplest case - the primary entity
        must participate in the relationship but the secondary entity may 
        not. e.g. I own 1 car but my 1 car does not own me (or does 
        it????) This relationship is modeled by storing the secondary 
        entity's primary key as a foreign key in the primary entity's 
        table.
    2. 1 to N relationship (1:N)
        There is only one case for our purposes - the primary entity may
        possess multiple secondary entities.
        e.g. I own zero or more books.
        This relationship is modeled by storing the primary entity's 
        (the '1') primary key as a foreign key in the secondary entity's 
        (the 'N') table.
    3. N to N relationship (N:N)
        For the purposes of transforming XML we do not need these!
        e.g. the relationship between students and classes - each 
        student can have multiple classes and each class can have 
        multiple students.
        This relationship is modeled by creating a new table whose rows 
        hold the primary key from each foreign table.

    XML documents can be distilled into just the first two kinds of 
    RDBMS relationships.  Let's look at some XML:

<address-book>
    <name>My Address Book</name>
    <entry>
        <name type="Person">Mark</name>
        <street>Perl Place</street>
    </entry>
    <entry>
        <name>Bob</name>
        <street>Heck Ave.</street>
        <state>FL</state>
    </entry>
</address-book>

    Here <address-book> is the 'root' entity in this XML fragment and has
two sub-entities, <name> and <entry>.  <address-book> and <name> form a
1:1 relationship and <address-book> and <entry> form a 1:N relationship.
Similarly there are 1:1 relationships between <entity> and <name>, 
<street>, and <state>.  That's all we need to know!
    Without further ado, let's put Perl to work.

Module #1 - MakeTables

    Our first Perl script does exactly what we just did - it analyzes the 
relationships between the entities in an XML document and outputs those 
relationships as a set of RDB tables.  It takes one required argument - 
the XML file you want to analyze.  Optionally a second parameter may be
passed containing a filename in which to write the RDB Schema, if not
passed then it's output to STDOUT.  Here's the generated table that 
corresponds to the <address-book> entity:

CREATE TABLE gen_address_book (
  gen_name_id integer NULL,
  id integer NOT NULL,
  PRIMARY KEY (id)
);

    Lots to note here - first, all table names are prefixed by a 
user-supplied string - in this case 'gen' (for 'generated').  Also, 
some characters that offend RDBMSs are transformed into underscores 
(don't worry, the real names are also stored in the database for 
exporting back to XML).  Finally, a generated primary key column is 
added to each table (named 'id').

    One to one relationships

    So what we've got is a table that contains a reference to a row in
the 'gen_name' table to model our 1:1 relationship between <address-book>
and <name>.  The primary key of a 'gen_name' row (the 'id' value) becomes 
a foreign key in a 'gen_address_book' row (the 'gen_name_id' value).

    One to many relationships

    But what about the 1:N relationship between <address-book> and 
<entry>? As good RDBMS design tells us, it is modeled by placing the 
primary key of the '1' part of the relationship as a foreign key in 
the 'N' part of the relationship.  Let's look at the table generated 
for the <entry> entity:

CREATE TABLE gen_entry (
  gen_address_book_fk integer NOT NULL,
  gen_name_id integer NULL,
  gen_state_id integer NULL,
  gen_street_id integer NULL,
  id integer NOT NULL,
  PRIMARY KEY (id)
);

    The interesting bit is the 'gen_address_book_fk' column.  This 
column will contain the primary key of a gen_address_book row that 
contains this <entry>.  The other columns you will recognize as parts 
of a 1:1 relationship between <entry> and <name>, <state>, and 
<street>.  And of course the generated primary key column 'id'.

    Plain old text

    Let's now look at the gen_name table:

CREATE TABLE gen_name (
  gen_name_type_attribute text NULL,
  gen_name_value text NULL,
  id integer NOT NULL,
  PRIMARY KEY (id)
);

    The column 'gen_name_value' holds the text associated with this 
entity. The column 'gen_name_type_attribute' holds the text associated 
with the attribute 'type' in the entity <name>.  Again, there is a 
generated table that contains the mappings between RDBMS column and 
table names and XML names.
    The other tables gen_state and gen_street simply consist of a 
'_value' column and a generated primary key.  Note we did not have to 
do anything to generate these tables!  We simply fed our XML document 
to MakeTables.

    Meta tables

    To help keep track of everything,  MakeTables creates four extra
tables to hold meta-information about this XML document.  These tables 
are only used internally, so you do not have to worry about them.  
    Two of the tables are used to create primary keys in a generic, 
database-independent fashion and are not very interesting for our 
purposes.  
    The table 'gen_element_names' contains the mappings between table 
and column names to XML names - this is table we alluded to earlier.  
It looks like this:

CREATE TABLE gen_element_names (
  db_name text NOT NULL  ,
  xml_name text NOT NULL  
);

    Every time MakeTables has to generate a RDBMS equivalent name for an 
XML tag (every tag and attribute name must be converted), another row 
gets added to this table.  Here are the rows that get inserted into 
this table from our example (generated by MakeTables of course):

INSERT INTO gen_element_names VALUES ('gen_street','street');
INSERT INTO gen_element_names VALUES ('gen_address_book','address-book');
INSERT INTO gen_element_names VALUES ('gen_name_type_attribute','type');
INSERT INTO gen_element_names VALUES ('gen_entry','entry');
INSERT INTO gen_element_names VALUES ('gen_name','name');
INSERT INTO gen_element_names VALUES ('gen_state','state');

    Using this table we can accurately re-create our XML document.  
    The final generated meta table is called 'gen_link_tables'.  This 
table contains a list of all of the 1:N relationships in the XML 
document.  Like the 'gen_element_names' table it is only used internally 
for bookkeeping.  Here's what it looks like:

CREATE TABLE gen_link_tables (
  one_table text NOT NULL  ,
  many_table text NOT NULL  
);
    
    And here's the row that gets inserted into it using our example:

INSERT INTO gen_link_tables VALUES ('gen_address_book','entry');

    There is only one 1:N relationship in our XML document, so there's 
only one row in this table.  This table is used by later scripts to 
populate and unpopulate the data into and out of our RDBMS.
    Now that our tables have been generated, it's time to import them 
into our database and populate them.  The output of MakeTables is a 
bunch of 'CREATE TABLE' and 'INSERT' statements.  Each RDBMS has its 
own way to import these statements - check your documentation.  Later 
we'll see an real live example using MySQL (10).

Module #2 - PopulateTables

    Once our tables exist in our database we need to actually pull the
data out of our XML document and put it into our RDBMS.  Remember, 
MakeTables only analyzes the relationships between elements in an XML
document - the actual data is ignored.  The actual data parsing is the
job of module #2, PopulateTables.  It takes only one argument,
the name of the XML document that was passed to MakeTables.
The data contained within that XML document will be transformed and 
stored into your RDBMS.  Let's take a look at our RDBMS after we've run
PopulateTables. (using MySQL) using our example:

mysql> select * from gen_address_book;
+-------------+----+
| gen_name_id | id |
+-------------+----+
|           1 |  1 |
+-------------+----+

    Ok, not too exciting.  Let's see the 'gen_name' table:

mysql> select * from gen_name;           
+-------------------------+-----------------+----+
| gen_name_type_attribute | gen_name_value  | id |
+-------------------------+-----------------+----+
| NULL                    | My Address Book |  1 |
| Person                  | Mark            |  2 |
| NULL                    | Bob             |  3 |
+-------------------------+-----------------+----+

    Now things get a little more interesting!  We see our 1:1 
relationship between <address-book> and <name> via the 'gen_name_id' 
in the gen_address_book table matching the 'id' in the gen_name table, 
and sure enough its value is our <address-book>'s name, 
'My Address Book'.  You'll notice that the 'gen_name_type_attribute' 
column is null for the two <name>'s that don't possess this attribute 
and is set to 'Person' for the <name> that does.  Let's see the 1:N 
relationships in the 'gen_entry' table:

mysql> select * from gen_entry;
+---------------------+-------------+--------------+---------------+----+
| gen_address_book_fk | gen_name_id | gen_state_id | gen_street_id | id |
+---------------------+-------------+--------------+---------------+----+
|                   1 |           2 |         NULL |             1 |  1 |
|                   1 |           3 |            1 |             2 |  2 |
+---------------------+-------------+--------------+---------------+----+

    The two <entry>'s associated with this <address-book> are linked by
the foreign key column.  The 'gen_address_book_fk' column matches the
'id' column in our gen_address_book row.  You can also see the 1:1 
relationship between each entry and its name (via the 'gen_name_id' 
column).  The state and street 1:1 relationships are similar.
 
    It's in!  We've transformed our XML document into our RDBMS.  At
this point we can take a break, sip some coffee, and rest assured that 
our RDBMS has our data under its watchful eye.  We can use any
of the mature RDBMS utilities and tools to massage, view, change, add, 
backup, and delete our information.  For some people this could indeed 
be the end of the line - but not for us!

Modules #3 - UnpopulateTables

    Our XML is in our RDBMS - now we want to get it out!  We've put 
our data through the RDBMS tool's ringer, doing all the zany things 
to it we wanted - but now we want our XML back.  Say hello to module 
#3, UnpopulateTables.  But before we get too acquainted there is one 
piece about script #2, PopulateTables that I have not yet mentioned, 
that makes our life easier.  
After PopulateTables finishes populating our tables, it returns a handy 2
element array containing the root table name & a primary key uniquely
identifying a row in that table that corresponds to the XML file we just
inserted into our DB.
    It has told us all we need to know to re-create the XML we just 
RDBMS-ized.  UnpopulateTables takes that very same two element array - 
the name of the 'root' table and the generated primary key for the row 
we're interested in.  I'll discuss what that second bit of output is 
later.  In our example the root table is 'gen_address_book', and since 
it's the first one we added to our database its primary key is one.  
This tells UnpopulateTables where to start unwinding from our RDBMS back 
into XML.  If you knew the table name and primary key of any other row 
you could create just a fragment of your XML by specifying those 
values to UnpopulateTables (all easily gleaned from your RDBMS).  
And out goes your XML.

Bonus Module #4 - UnpopulateSchema

    We've come full circle.  What a not-so-long-but-definitely strange 
trip it's been.  We've gone from an XML document into a RDBMS and back 
out again. Yet something is still missing.  The problem lies with 
not-fully-specified XML documents.  What if another <address-book> 
document had a <zip-code> tag within the <entry> tag?  Two different 
table sets would be generated.  That makes it impossible to put two 
different-yet-related XML documents into the same set of tables.  
What is needed, when generating RDBMS tables from MakeTables, is a 
'fully-specified' XML document containing all possible tags and 
attributes in all possible configurations.  Then all 1:1 and 1:N 
relationships could be correctly identified and all attributes could be
accounted for.  But how can we get a 'fully-specified' XML document?  
We can generate one using XML Schema (4).  Written in XML themselves, 
XML Schemas fully specify what may be contained within a conforming XML 
document.  The bonus fourth script - UnpopulateSchema - will 'unpopulate' 
an XML Schema stored in your RDBMS as a fully-specified XML document.  
This XML document can then be fed to MakeTables to generate 
fully-specified RDBMS tables.  
    Now that's quite a mouthful, but if you have an XML Schema for 
your documents, you can use that, and not a specific instantiation of
that Schema (which might not have all of the allowed entities in all 
possible configurations) to create your RDBMS tables.  Then all 
conforming XML documents can be fed to PopulateTables to populate 
your RDBMS without worrying about table mismatch.
    The secret is that XML Schemas are well-formed XML documents 
themselves.  Running MakeTables on your Schema itself and then 
importing those tables into your RDBMS gets the ball rolling.  
Then you populate your RDBMS the usual way by running PopulateTables 
with the XML Schema as the supplied XML Document.  Finally running 
UnpopulateSchema instead of UnpopulateTables against that data will 
output a fully-specified XML document, instead of just your XML Schema 
back again.  Since all XML Schemas must follow strict guidelines, 
UnpopulateSchema only needs to know the primary key of the XML Schema 
in your RDBMS.  This is the second bit of information output by 
PopulateTables.
    XML Schema is a very complicated specification.  Not all of the 
nooks and crannies of the specification are supported by 
UnpopulateSchema - which is by far the longest and most complicated 
for the four scripts.

    Here's what's supported - the numbers in parentheses correspond 
to sections in the XML Schema Primer (5): 

        Named Simple and Complex types (2.2 & 2.3)
        Simple type restrictions and enumerations (2.3)
        List types (2.3.1)
        Unions types (2.3.2)
        Anonymous Type Definitions and choices (2.4)
        Complex Types from Simple Types (simpleContent) (2.5.1)
        Mixed content (2.5.2)
        Empty content (2.5.3)
        Choice and Sequence groups (including xsd:group) (2.7)
        'All' group (2.7)
        Attribute groups (2.8)
        Nil Values (2.9)
        Deriving Types by Extension (4.2)
        Deriving Complex Types by Restriction (4.4)
        Abstract Elements & Types (partially) (4.7)

    Here's what's not:

        anyType (2.5.4) (not applicable)
        Target Namespaces & Unqualified locals (3.1)
        Qualified locals (3.2)
        Importing & Multiple documents (4.1)
        Redefining Types & Groups (4.5)
        Substitution Groups (4.6)
        Abstract Elements & Types (partially) (4.7)
        Controlling the Creation & Use of Derived Types (4.8) 
                                                    (not applicable)
        Specifying Uniqueness (5.1) (not applicable)
        Defining Keys & their References (5.2) (not applicable)
        Importing Types (5.4)
        Any Element, Any Attribute (5.5) (not applicable)
        Schema Location (5.6)

    The namespace and importing can be handled by collecting all 
referenced Schemas by hand and creating one large document from 
them.  This list is subject to change - especially the namespace 
and importing functions.

Now Things Get Interesting!

    Let your mind go!  Not only can _any_ XML document be stored 
in your RDBMS, but you don't even have to have a XML document to 
start with.  All you need is an XML Schema.  Use that to create 
your table set.  You don't have to use PopulateTables to populate 
the database - use whatever tool you want.  When you're ready, 
use UnpopulateTables and you've magically got well-formed, valid 
XML to pass on to whomever you choose.  Any XML document --
SOAP (6), SVG (7), XSLT (8), whatever, can easily be intelligently 
imported into your RDBMS.  Once XML Schema really gets going and 
all XML documents are defined using it, you've got a ready-made 
RDBMS system just waiting for conforming XML documents.

What You Need To Make It Work

  In your constructor call to XML::RDB you provide the path to 
your configuration file.  The format of the file is key/values 
pairs - one per line - delimited by '='.  See 'config.test' in 
the base directory for all of the options.

the most important (& only) variable you must set is 'DSN':

  DSN=DBI:mysql:database=TEST

    This is a MySQL DSN - alter it to fit your needs.  You can 

    The _only_ thing you need to change is the DSN, after that you 
are ready to rumble.  See the 'config.test' file in this directory 
for all the other options.

Module Dependencies

    As Sir Isaac Newton stood on the shoulders of giants, so have I.  
These scripts could not function without these great modules available 
from the CPAN (9):

    DBI and DBD::<your RDBMS>
        You need these to talk to your RDBMS at a low level.
    DBIx::Recordset
        The scripts use this awesome module to talk to your RDBMS as a
            higher level.
    DBIx::Sequence
        This module provides RDBMS-independent unique primary key 
          generation.
    DBIx::DBSchema
        This module provides MakeTables with a RDBMS-independent way to
            generate tables.
    XML::DOM
        The workhorse - parses all the XML so I don't have to!
    URI::Escape
        Only used by UnpopulateTables to keep the XML clean.

Tested platforms

    The scripts were developed using Perl 5.6.0 and also run under 5.6.1.  
There's no reason why the scripts should not run on any recent Perl5 
distribution.  Both MySQL and PostgreSQL(11) have been tested - MySQL on 
FreeBSD 4.2 and Linux (RedHat 7.1) and PostgreSQL on Linux (RedHat 7.1).  
Note column lengths can get long, and PostgreSQL is by default limited 
to 31-character long columns.  I had to recompile PostgreSQL with a 
more reasonable 64-character length limit to keep everything happy.

A Sample Run using MySQL
 
  use XML::RDB;

  # Give our DB's DSN & username/password
  my $rdb = new XML::RDB(config_file => 'db_config');

  # Generate RDB Schema
  $rdb->make_tables("my_xml_file.xml", "db_schema_output_file");

  #
  # Now import the generated 'db_schema_output_file' into your DB
  #   (see t/1.t for an automated way to do this)
  #
  
  # Now populate our RDB
  my($root_table_name, $primary_key) = 
    $rdb->populate_tables("my_xml_file.xml");

  #
  # Your XML file is now in your RDB!!!!  Play as desired & when ready:
  #
  $rdb->unpopulate_tables($root_table_name, $primary_key, 
    'new_xml_file.xml'); 


  #
  # That's all fine & dandy but what if you've got an XML Schema???
  #
  # the first 2 calls are the same:
  $rdb->make_tables("my_xsd_file.xsd", "db_schema_output_file");

  #
  # don't forget to put 'db_schema_output_file' into your DB!
  # then:
  my($root_table_name, $primary_key) = 
    $rdb->populate_tables("my_xsd_file.xsd");

  # note we only need the primary key for this next call
  $rdb->unpopulate_schema($primary_key, 'fully_formed.xml'); 

  #
  # Now you've got 'fully_formed.xml' - pass THAT to make_tables 
  # & yer golden:
  #
  
  $rdb->make_tables("fully_formed.xml", "REAL_RDB_schema");

  #
  # Now insert REAL_RDB_schema into yer DB & now any XML documents 
  # conforming to your original XML Schema ('my_xsd_file.xsd') can 
  # be imported into your schema:
  my ($rt, $pk) = 
    $rdb->populate_tables("xml_doc_conforming_to_my_xsd_file.xml");
   
Limitations and Future Directions

    There is a program written in Java that generates XML Schemas 
from DTDs. This provides a clear migration path.  However, DTDs do 
not provide as much information as XML Schemas do, so it would be 
wise not to count on automated tools to do the complete conversion 
for you.
    Also, once XML Schema parsers become readily available, 
UnpopulateSchema should take advantage of them, since the current 
'parsing' it does is pretty basic.  Finally, all XML Schemas must 
pass through your RDBMS, which is not optimal.
    Some XML documents rely on the order of the entities, but after 
under-going into an RDBMS and back out again the order is lost.  
A 'nice' way to preserve entity order would be a grand addition.
    Both UnpopulateTables and UnpopulateSchema utilize the same 
intermediary format from going from a RDBMS to XML.  The modularization 
of these modules allow XML stored in a RDBMS to be extracted to any 
other format, such as HTML.  Future work in this area will produce 
very interesting transformations.
Also, using something like XML::Writer (10) to output XML would probably 
be cleaner and lead to further benefits down the road.
    Finally, both MakeTables and PopulateTables use XML::DOM, which 
loads the entire XML document tree into memory.  Investigation into 
using the Simple API for XML (SAX) (12) to reduce memory consumption 
could prove very fruitful.  
Also both UnpopulateTables and UnpopulateSchema load the entire RDB 
into memory before outputting their transformations, so investigations 
into lowering the memory footprint of these scripts will yield beneficial 
results.

Acknowledgments

    Rob Enns and Phil Shafer for having the foresight to use XML in our 
routers that eventually led to these scripts, and Cynthia Tham, fellow
member of the Juniper JUNOScript team!

References

1.  Standard SQL ISO/IEC 9075:1992, "Information Technology --- Database Languages --- SQL" 
2. For a discussion of XML and RDBMSs see "XML Database Products" by Ronald Bourret, http://www.rpbourret.com/xml/XMLDatabaseProds.htm
3. JUNOScript Guide http://www.juniper.net/techpubs/software/junos44/junoscript44-guide/html/junoscript44-guideTOC.html
4. XML Schema http://www.w3.org/XML/Schema
5. XML Schema Primer http://www.w3.org/TR/xmlschema-0
6. SOAP http://www.w3.org/TR/soap12/
7. SVG http://www.w3.org/Graphics/SVG/Overview.htm8
8. XSL and XSLT http://www.w3.org/Style/XSL/
9. CPAN http://www.cpan.org
10. MySQL http://www.mysql.com
11. PostgreSQL http://www.postgresql.org/
12. SAX http://www.megginson.com/SAX/

Juniper Networks is a registered trademark of Juniper Networks, Inc. Internet Processor, Internet Processor II, JUNOS, JUNOScript, M5, M10, M20, M40, and M160 are trademarks of Juniper Networks, Inc. All other trademarks, service marks, registered trademarks, or registered service marks may be the property of their respective owners. All specifications are subject to change without notice.  Copyright © 2001, Juniper Networks, Inc.  All rights reserved.

=head1 SEE ALSO

XML Schema http://www.w3.org/XML/Schema

=head1 AUTHOR

Mark Trostler, E<lt>trostler@juniper.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
