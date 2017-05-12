#!/usr/bin/perl -w
use strict;

use XML::Comma;
use Getopt::Long;

my ($file, $module); 

my %args = ( 'file=s', \$file,
             'module=s', \$module );
&GetOptions ( %args );

if ( $module ) {
  eval "use $module";
  if ( $@ ) { die "bad module load: $@\n" }
}

my $doc; 

if ( ! $file ) {
  my $key = shift();
  die "usage: comma-load-doc.pl [ -module <module to load> ] [-file <filename>] [doc-key]\n"
    if ! $key;
  $doc = XML::Comma::Doc->retrieve ( $key );
} else {
  $doc = XML::Comma::Doc->new ( file => $file );
}

if ( $doc ) {
  print "ok\n";
  exit ( 0 );
}
