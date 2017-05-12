#!/usr/bin/perl -w

use strict;

use Getopt::Long;

my $file;
my $module;
my %args = ( 'file=s', \$file,
             'module=s', \$module );
&GetOptions ( %args );

use XML::Comma;

if ( $module ) {
  eval "use $module";
  if ( $@ ) { die "bad module load: $@\n" }
}

my $doc;

my $key = shift;

die "usage: comma-load-and-store-doc.pl [-module <module to load>] <doc-key>\n"
  if ! $key;

$doc = XML::Comma::Doc->retrieve ( $key );
$doc->store();

print "ok\n";
exit ( 0 );

