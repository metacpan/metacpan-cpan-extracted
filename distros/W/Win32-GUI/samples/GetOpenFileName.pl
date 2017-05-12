#!perl -w
use strict;
use warnings;
use Win32::GUI();

# This sample demonstrates GetOpenFileName

my $lastfile = 'foo.bar';

# single file with graphics file filters

{
my ( @file, $file );
my ( @parms );
push @parms,
  -filter =>
    [ 'TIF - Tagged Image Format', '*.tif',
      'BMP - Windows Bitmap', '*.bmp',
      'GIF - Graphics Interchange Format', '*.gif',
      'JPG - Joint Photographics Experts Group', '*.jpg',
      'All Files - *', '*'
    ],
  -directory => "c:\\program files",
  -title => 'Select a file';
push @parms, -file => $lastfile  if $lastfile;
@file = Win32::GUI::GetOpenFileName ( @parms );
print "$_\n" for @file;
print "index of null:", index( $file[ 0 ], "\0" ), "\n";
print "index of space:", index( $file[ 0 ], " " ), "\n";
}

# allow multiple files, only one filter
{
my ( @file, $file );
my ( @parms );
push @parms,
  -multisel => 10, # use 40000 byte buffer
  -filter =>
    [ 'All Files - *', '*'
    ],
  -directory => "c:\\program files",
  -title => 'Select a file';
push @parms, -file => $lastfile  if $lastfile;
@file = Win32::GUI::GetOpenFileName ( @parms );
print "$_\n" for @file;
print "index of null:", index( $file[ 0 ], "\0" ), "\n";
print "index of space:", index( $file[ 0 ], " " ), "\n";
}

# old style dialog, multiple file selection enabled, no filters.
# User has to type in a filter, to see anything.  Always good to have a
# filter.  But it isn't required....
{
my ( @file, $file );
my ( @parms );
push @parms, 
  -multisel => 1, # use 4000 byte buffer
  -explorer => 0,
  -directory => "c:\\program files",
  -title => 'Select a file';
push @parms, -file => $lastfile  if $lastfile;
@file = Win32::GUI::GetOpenFileName ( @parms );
print "$_\n" for @file;
print "index of null:", index( $file[ 0 ], "\0" ), "\n";
print "index of space:", index( $file[ 0 ], " " ), "\n";
}
