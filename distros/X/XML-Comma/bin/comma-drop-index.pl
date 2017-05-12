#!/usr/bin/perl -w

use strict;
use XML::Comma;
use XML::Comma::Util qw( dbg );

use Getopt::Long;
my ($doc_type, $index_name, $module); 
my %args = ( 'type=s', \$doc_type,
             'index=s', \$index_name,
             'module=s', \$module );
&GetOptions ( %args );

if ( $module ) {
  eval "use $module";
  if ( $@ ) { die "bad module load: $@\n" }
#  $module->new();
}

if ( ! $doc_type or ! $index_name ) {
  die "usage: comma-drop-index.pl [ -module <module to load> ] -type <document_type> -index <index_name>\n"
}

my $index = XML::Comma::Def->read(name=>$doc_type)->get_index($index_name);
my @tables;

push @tables, $index->data_table_name();
push @tables, $index->sql_get_sort_tables();
push @tables, $index->sql_get_bcollection_table();

foreach my $textsearch ( $index->elements('textsearch') ) {
  my $name = $textsearch->element('name')->get();
  print "dropping textsearch tables for '$name'\n";
  $index->sql_drop_textsearch_tables ( $name );
}

foreach ( @tables ) {
  print "dropping: $_\n";
  $index->drop_table ( $_ );
}


