#-*-perl-*-
#####################################################################
# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Uplug::IO::Any - virtual class for arbitrary streams
#
#
#####################################################################


=head1 NAME

Uplug::IO::Any - libraries for handling various kinds of input/output

=head1 SYNOPSIS

 use Uplug::IO::Any;
 use Uplug::Data;

  %InSpec = (
    format      => 'text',
    file        => $input_filename,
    access_mode => 'read',
    encoding    => 'iso-8859-1' );

  %OutSpec = (
    format      => 'xml',
    file        => $output_filename,
    access_mode => 'overwrite',
    root        => 's' );


 $input  = new Uplug::IO::Any( \%InSpec )
 $output = new Uplug::IO::Any( \%OutSpec )

 $data=Uplug::Data->new();

 while ($input->read($data)){
    # do somwthing with the data
    $output->write($data);
 }

 $input->close;
 $output->close;

=head1 DESCRIPTION

This is a class factory for creating data streams of various kinds. Supported sub-classes are:

 Uplug::IO::Text ........... plain text
 Uplug::IO::XML ............ generic XML class

 Uplug::IO::XCESAlign ...... XCES-based sentence alignment
 Uplug::IO::MosesWordAlign . word alignment in Moses format
 Uplug::IO::PlugXML ........ parallel corpus format (used in the project PLUG)
 Uplug::IO::LWA ............ format used by the Linköping Word Aligner (PLUG)
 Uplug::IO::LiuAlign ....... Linköping's parallel corpus format (PLUG)

 Uplug::IO::DBM ............ databases using AnyDBM
 Uplug::IO::Tab ............ tab-separated data
 Uplug::IO::Storable ....... storable objects
 Uplug::IO::Collection ..... generic class to combine several input streams

=cut


package Uplug::IO::Any;

use strict;
use vars qw(@ISA);
use vars qw($DefaultFormat);
use FindBin qw($Bin);

use IO::File;
use POSIX qw(tmpnam);

use autouse 'Uplug::Config';

use Uplug::IO;
use Uplug::IO::Text;
use Uplug::IO::XML;
use Uplug::IO::PlugXML;
use Uplug::IO::Tab;
use Uplug::IO::Collection;
use Uplug::IO::LiuAlign;
use Uplug::IO::DBM;
use Uplug::IO::XCESalign;
use Uplug::IO::LWA;
use Uplug::IO::Storable;
use Uplug::IO::MosesWordAlign;


@ISA = qw( Uplug::IO );


=head1 Methods

=head2 Constructor

 $handler = new Uplug::IO::Any( \%spec, $format );

Create a new I/O handler according to the specifications of C<%spec> and the optional format C<$format>. If C<%spec> includes the key C<stream name>: Try to load the specifications of a named stream (see L<Uplug::Config> for more information).

Accepted data formats:

 IO-class                    format parameter
 -----------------------------------------------
 Uplug::IO::Text ........... text
 Uplug::IO::XML ............ xml

 Uplug::IO::XCESAlign ...... align | xces
 Uplug::IO::MosesWordAlign . moses
 Uplug::IO::PlugXML ........ plug
 Uplug::IO::LWA ............ lwa
 Uplug::IO::LiuAlign ....... liu | koma

 Uplug::IO::DBM ............ dbm
 Uplug::IO::Tab ............ tab | uwa tab
 Uplug::IO::Storable ....... storable
 Uplug::IO::Collection ..... collection

If no format is given: Check file name extension:

 *.dbm ..................... Uplug::IO::DBM
 *.uwa ..................... Uplug::IO::Tab
 *.txt ..................... Uplug::IO::Text
 *.xml ..................... Uplug::IO::XML

=cut


sub new{
    my $class=shift;
    my ($stream,$format);
    if (ref($_[0]) eq 'HASH'){$stream = shift;}
    else{$stream={};$format = shift;}

    ## ---------------------------------
    ## 'stream name' => look for a 'named stream' and ignore all other settings

    if (defined $stream->{'stream name'}){
	$stream=&Uplug::Config::GetNamedIO($stream);
    }
    if ((not defined $format) and (defined $stream->{format})){
	$format=$stream->{format};
    }

    ##-----------------------------
    ## create data stream object according to format settings

    if ($format=~/^text$/i){return Uplug::IO::Text->new();}
    elsif ($format=~/^moses/i){return Uplug::IO::MosesWordAlign->new();}
    elsif ($format=~/^koma(\s|\Z)/i){return Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^align(\s|\Z)/i){return Uplug::IO::XCESalign->new();}
    elsif ($format=~/^liu\s*xml$/i){return Uplug::IO::LiuAlign->new();}
    elsif ($format=~/^xces(\s|\Z)/i){return Uplug::IO::XCESalign->new();}
    elsif ($format=~/^xml$/i){return Uplug::IO::XML->new();}
    elsif ($format=~/^plug$/i){return Uplug::IO::PlugXML->new();}
    elsif ($format=~/^lwa/i){return Uplug::IO::LWA->new();}
    elsif ($format=~/^tab$/i){return Uplug::IO::Tab->new();}
    elsif ($format=~/^uwa\s+tab$/i){return Uplug::IO::Tab->new();}
    elsif ($format=~/^collection$/i){return Uplug::IO::Collection->new();}
    elsif ($format=~/^dbm$/i){return Uplug::IO::DBM->new();}
    elsif ($format=~/^stor/i){return Uplug::IO::Storable->new();}

    ##-----------------------------
    ## try to find the appropriate format ...

    elsif (defined $stream->{file}){
	if ($format=&CheckExtender($stream->{file})){
	    $stream->{format}=$format;
	    return Uplug::IO::Any->new($stream);
	}
    }
    warn "# Uplug::IO::Any: no format specification found!\n";
    return undef;
}


sub CheckExtender{
    my $file=shift;

    if ($file=~/\.dbm$/){return 'dbm';}
    elsif ($file=~/\.uwa$/){return 'uwa tab';}
    elsif ($file=~/\.txt$/){return 'text';}
    elsif ($file=~/\.liu$/){return 'align';}
    elsif ($file=~/\.xml$/){return 'xml';}
    return undef;
}


sub GetTempFileName{
    my $fh;
    my $file;
    do {$file=tmpnam();}
    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
    $fh->close;
    return $file;
}

1;


__END__
