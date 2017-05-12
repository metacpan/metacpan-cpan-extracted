#########################################################################################
# Package       Wx::PdfDocument::Loader
# Description:  Load wxPdfDocument
# Created       Mon Apr 30 18:42:52 2012
# SVN Id        $Id: Loader.pm 179 2012-06-01 15:43:38Z mark.dootson@gmail.com $
# Copyright:    Copyright (c) 2012  Mark Wardell
# Licence:      This program is free software; you can redistribute it 
#               and/or modify it under the same terms as Perl itself
#########################################################################################

package Wx::PdfDocument::Loader;

#########################################################################################

# This module / file contains necessary internal methods for loading the
# wxPdfDocument module and running ShowFont / MakeFont

use strict;
use warnings;

our $VERSION = '0.10';

package
  Wx::PdfDocument;

use strict;
use warnings;

use Wx::PdfDocument::Info;

our $_binpath;
our $_libpath;

require Wx::Mini;

sub _start {
    
    # set WXPDF_FONTPATH
    
    for my $incpath ( @INC ) {
        my $distpath = qq($incpath/auto/share/dist/Wx-PdfDocument);
        my $autopath = qq($incpath/auto/Wx/PdfDocument);
        if( -d $distpath && -d $autopath) {
            my $fontpath = qq($distpath/lib/fonts);
            $_binpath = qq($distpath/utils);
            $_libpath = qq($autopath);
            if( $^O =~ /^mswin/i ) {
                $fontpath =~ s/\//\\/g;
                $_binpath =~ s/\//\\/g;
                $_libpath =~ s/\//\\/g;
            }
            $ENV{WXPDF_FONTPATH} = $fontpath;
            last;
        }
    }
    
    # load wxPdfDocument dll using Wx::_load_plugin
    # we need this so that wxModule code is activated
    
    my $pdfmodulename = $Wx::PdfDocument::Info::buildconfig->{wxpdfdocdll};
    
    if( $^O =~ /^darwin/i ) {
        my $pathprefix = $_libpath;
        local $ENV{DYLD_LIBRARY_PATH} = ( defined($ENV{DYLD_LIBRARY_PATH} ))
            ? $pathprefix . ':' . $ENV{DYLD_LIBRARY_PATH} : $pathprefix;
        Wx::load_dll( 'adv' );
        Wx::load_dll( 'xml' );
        Wx::load_dll( 'html' );
        Wx::load_dll( 'richtext' );
        Wx::_load_plugin( qq($_libpath/$pdfmodulename) );
    } elsif( $^O =~ /^mswin/i ) {
        my $pathprefix = $_libpath . ';';
        $pathprefix .= $Wx::wx_path . ';' if -e $Wx::wx_path;
        local $ENV{PATH} = $pathprefix . $ENV{PATH};
        Wx::load_dll( 'adv' );
        Wx::load_dll( 'xml' );
        Wx::load_dll( 'html' );
        Wx::load_dll( 'richtext' );
        Wx::_load_plugin( $pdfmodulename );
    } else { # Linux etc
        # need to hack loading the XML library
        # perhaps we should rpath the dependencies
        for my $dllkey ( qw( adv xml html richtext) ) {
            my $file = ( $Wx::wx_path ) ? $Wx::wx_path . '/' . $Wx::dlls->{$dllkey} : $Wx::dlls->{$dllkey};
            if( $Wx::alien_key =~ /^gtk2_2_9_(\d+)/ ) {
                $file .= '.' . $1;
            } else {
                $file .= '.0';
            }
            if( -f $file ) {
                Wx::_load_plugin( $file );
            } else {
                Wx::load_dll( $dllkey );
            }
        }
        my $pathprefix = $_libpath;
        local $ENV{LD_LIBRARY_PATH} = ( defined($ENV{LD_LIBRARY_PATH} ))
                ? $pathprefix . ':' . $ENV{LD_LIBRARY_PATH} : $pathprefix;
        Wx::_load_plugin( qq($_libpath/$pdfmodulename) );
    }
}

sub _utilscmd {
    my ($command, $paramstring) = @_;
    
    my $status;
    my $stderr;
    my $stdout;
    
    if( $^O =~ /^mswin/i) {
        my $pathprefix = $_libpath . ';';
        $pathprefix .= $Wx::wx_path . ';' if -e $Wx::wx_path;
        $pathprefix =~ s/\//\\/g;
        local $ENV{PATH} = $pathprefix . $ENV{PATH};
        $command =~ s/\//\\/g;
        $command .= '.exe';
        ($status, $stdout, $stderr) = Wx::ExecuteStdoutStderr(qq($command $paramstring), &Wx::wxEXEC_SYNC);
        
    } elsif( $^O =~ /^darwin/i) {
        my $pathprefix = $_libpath;
        local $ENV{DYLD_LIBRARY_PATH} = ( defined($ENV{DYLD_LIBRARY_PATH} ))
            ? $pathprefix . ':' . $ENV{DYLD_LIBRARY_PATH} : $pathprefix;
        ($status, $stdout, $stderr) = Wx::ExecuteStdoutStderr(qq($command $paramstring), &Wx::wxEXEC_SYNC);
    } else { # *nix
        my $pathprefix = $_libpath . ':';
        $pathprefix .= $Wx::wx_path if -e $Wx::wx_path;
        local $ENV{LD_LIBRARY_PATH} = ( defined($ENV{LD_LIBRARY_PATH} ))
            ? $pathprefix . ':' . $ENV{LD_LIBRARY_PATH} : $pathprefix;
        ($status, $stdout, $stderr) = Wx::ExecuteStdoutStderr(qq($command $paramstring), &Wx::wxEXEC_SYNC);
    }
    return ( wantarray ) ? ($status, $stdout, $stderr) : $status;
}

1;
