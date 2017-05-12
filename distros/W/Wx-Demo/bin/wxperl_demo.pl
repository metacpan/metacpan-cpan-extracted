#!/usr/bin/perl -w
#############################################################################
## Name:        bin/wxperl_demo.pl
## Purpose:     main wxPerl demo driver script
## Author:      Mattia Barbon
## Modified by:
## Created:     14/08/2006
## RCS-ID:      $Id: wxperl_demo.pl 3450 2013-03-30 04:03:16Z mdootson $
## Copyright:   (c) 2006-2008 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;
use Wx;

# Demonstrate switching off Ubuntu Scrollbars
BEGIN { $ENV{LIBOVERLAY_SCROLLBAR} = 0 if $^O =~ /^linux/i ; }

# wxPerl exec only needed on Mac OS X pre Wx 0.98

if( $Wx::VERSION lt '0.98' && $^O eq 'darwin' && $^X !~ m{/wxPerl\.app/} ) {
    print "On Mac OS X please run the demo with 'wxPerl wxperl_demo.pl' or update to Wx >= 0.98.\n";
    exit 0;
}

use Wx::Demo;
use Getopt::Long;


GetOptions( 'show=s'   => \( my $module ),
            'help'     => \( my $help ),
            'list'     => \( my $list ),
            ) or usage();
usage() if $help;

my $app    = Wx::SimpleApp->new;
my $locale = Wx::Locale->new( Wx::Locale::GetSystemLanguage );
my $demo   = Wx::Demo->new;

$demo->activate_module( $module ) if $module;
if ($list) {
    print join "\n",
          sort
          map $_->title, 
          grep $_->can( 'title' ),
          $demo->plugins;

   exit 0;
}

$app->MainLoop;

exit 0;

sub usage {
    die <<"END_USAGE";
Version: $Wx::Demo::VERSION

Usage: $0
           --help        this help
           --show ???    showing the particular Demo
           --list        list all available modules
END_USAGE

}
