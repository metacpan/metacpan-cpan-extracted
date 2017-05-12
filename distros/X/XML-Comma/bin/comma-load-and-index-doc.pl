#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use XML::Comma;

my ($file, $module); 

my %args = ( 'file=s', \$file,
             'module=s', \$module );
&GetOptions ( %args );

if ( $module ) {
  eval "use $module";
  if ( $@ ) { die "bad module load: $@\n" }
}

my $doc; 

my $key = shift;
my $index_name = shift;

die "usage: comma-load-and-index-doc.pl [ -module <module to load> ] <doc-key> <index-name>\n"
  if ! ($key and $index_name);

$doc = XML::Comma::Doc->retrieve ( $key );
$doc->index_update( index=>$index_name );

print "ok\n";
exit ( 0 );

