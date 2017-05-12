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
}

if ( ! $doc_type or ! $index_name ) {
  die "usage: comma-rebuild-index.pl [ -module <module to load> ] -type <document_type> -index <index_name>\n"
}

my $index = XML::Comma::Def->read(name=>$doc_type)->get_index($index_name);
$index->rebuild( verbose=> 1, workers=> 1 );
