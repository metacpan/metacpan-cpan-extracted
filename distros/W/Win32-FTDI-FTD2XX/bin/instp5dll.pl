#!perl
# $Id: instp5dll.pl,v 1.2 2008/11/10 17:58:14 395502 Exp $
# Installs P5FTD2XX.DLL into {C:\Windows}\System32
# alongside FTD2XX.DLL 
#
use strict;
use File::Copy;

my $dest = "$ENV{SystemRoot}\\System32";
#$dest =~ s|\\|/|g;
printf( STDERR "Installing $ARGV[0] to $dest\n" );
copy( $ARGV[0], $dest ) or die( "Error copying $ARGV[0] to $dest: $!\n" );
exit( 0 );
