#-*-perl-*-
###########################################################################
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
# simple text stream (reading line by line)
# (derived from Uplug::IO)
#
# TextStream::open($AccessMode,\%OptionHash)
#        $AccessMode - read|write|overwrite|append
#        %OptionHash - FileName            => '/path/to/file'    (required)
#                      pipe command        => pipe_command       (optional)
#                      input pipe command  => input_pipe         (optional)
#                      output pipe command => output_pipe        (optional)
#
###########################################################################


package Uplug::IO::Text;

# use bytes;    #### ????????? Do WE NEED THIS ?????????????
use strict;
use vars qw(@ISA $COMPRESS $DECOMPRESS);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use File::Basename;
use FileHandle;

use Uplug::IO;

@ISA = qw( Uplug::IO );

$COMPRESS='gzip -c';
$DECOMPRESS='gzip -cd';


sub init{
    my $self    = shift;
    my $OptionHash = shift;

    $self->SUPER::init($OptionHash);

    if ((not defined $self->{StreamOptions}->{FileName}) and
	(defined $self->{StreamOptions}->{file})){
	$self->{StreamOptions}->{FileName}=$self->{StreamOptions}->{file};
    }
    $self->{FileName}=$self->{StreamOptions}->{FileName};
    $self->{StreamOptions}->{file}=$self->{StreamOptions}->{FileName};

    my $ret;
    if (not defined $self->{FileName}){
	if (not defined $self->{FileHandle}){
	    if ($self->{AccessMode} eq 'read'){
		$self->{FileHandle}=*STDIN;
	    }
	    else{
		$self->{FileHandle}=*STDOUT;
	    }
	}
	$ret=1;
    }
    else{
	$ret=$self->{'FileHandle'}=&OpenStreamFile($self->{FileName},
						   $self->{AccessMode},
						   $OptionHash);
    }
    if ($]>=5.008){                                   # for Perl version >= 5.8
	binmode($self->{FileHandle},                  # set PerlIO layer
		':encoding('.$self->getEncoding.')'); # according to char enc.
    }
    return $ret;
}

sub close{
    my $self=shift;
    return $self->SUPER::close;
    if (defined $self->{'FileHandle'}){
	$self->{'FileHandle'}->close;
    }
}

sub getFileHandle{return $_[0]->{FileHandle};}       # return file-handle!


sub read{
    my $self=shift;
    my $data=shift;
    if (not ref($data)){return 0;}
    $data->init;

    my $fh=$self->{'FileHandle'};
#    my $content=<$fh>;
    my $content=$self->readFromHandle($fh);
    chomp $content;
    $data->setContent($content);
    $self->SUPER::read($data);
    return (defined $content);
}


sub write{
    my $self=shift;
    my ($data)=@_;
    my $content=$data;
    if (ref($data)){
	$self->SUPER::write($data);
	$content=$data->content;
    }
    my $fh=$self->{'FileHandle'};
    $self->writeToHandle($fh,$content."\n");
    return 1;
}




sub readheader{
    my $self=shift;
    $self->SUPER::readheader;
    my $fh=$self->{'FileHandle'};
#    print STDERR "---$fh--\n";
    if ($fh=~/STDIN/){return;}
    my $CurrentPos;
    my %HeaderHash=();
    my $DataLine;
    do {
	$CurrentPos=tell $fh;
	if (not $DataLine=$self->readFromHandle($fh)){
	    $self->addheader(\%HeaderHash);
	    return 0;
	}
	chomp $DataLine;
	if ($DataLine=~/^\# ([^:]+):\s*(\S.*)\s*$/){
	    $HeaderHash{$1}=eval $2;
#	    $HeaderHash{$1}=$2;
	}
    }
    until ($DataLine!~/^\#/);
    seek $fh,$CurrentPos,0;
    if (tell $fh != $CurrentPos){$self->{READBUFFER}=$DataLine;}
    $self->addheader(\%HeaderHash);
}



sub writeheader{
    my $self=shift;
    if (ref($self->{StreamHeader}) eq 'HASH'){
	my $fh=$self->{'FileHandle'};
	foreach my $k (sort keys %{$self->{StreamHeader}}){

	    $Data::Dumper::Terse = 1;
	    $Data::Dumper::Indent = 0;
	    $Data::Dumper::Purity=1;
	    my $string=Dumper($self->{StreamHeader}->{$k});
	    $self->writeToHandle($fh,"# $k: $string\n");
	}
    }
}


sub files{
    my $self=shift;
    if (defined $self->{file}){
	return wantarray ? ($self->{file}) : $self->{file};
    }
    if (defined $self->{FileName}){
	return wantarray ? ($self->{FileName}) : $self->{FileName};
    }
}

sub delete{
    my $self=shift;
    my $file;
    if (defined $self->{file}){$file=$self->{file};}
    if (defined $self->{FileName}){$file=$self->{FileName};}
    if (-e $file){
	print STDERR "# LiuStream.pm: remove file $file!\n";
	unlink $file;
    }
}







##########################################################################


sub OpenStreamFile{

    my $FileName=shift;
    my $AccessMode=shift;
    my $OptionHash=shift;

    print STDERR "open $FileName ($AccessMode)\n";

    my $fh = new FileHandle;

#---------------------------------------------------------------------------
# initialize pipe command according to the access mode
#---------------------------------------------------------------------------

    if ($AccessMode eq 'read'){
	$FileName=&FindDataFile($FileName);
	if (defined $$OptionHash{'input pipe command'}){
	    $$OptionHash{'pipe command'}=$$OptionHash{'input pipe command'};
	}
    }
    if ($AccessMode ne 'read'){
	if (defined $$OptionHash{'output pipe command'}){
	    $$OptionHash{'pipe command'}=$$OptionHash{'output pipe command'};
	}
    }

#---------------------------------------------------------------------------
# gzipped files: add gzip command in pipe
#---------------------------------------------------------------------------

    if ($FileName=~/\.gz$/){
	my $compress;
	if ($AccessMode eq 'read'){
	    $compress=$Uplug::IO::Text::DECOMPRESS;
	}
	else{
	    $compress=$Uplug::IO::Text::COMPRESS;
	}
	if (not defined $$OptionHash{'pipe command'}){
	    $$OptionHash{'pipe command'}=$compress;
	}
	else{
	    if ($$OptionHash{'pipe command'}!~/$compress/){
		if ($AccessMode eq 'read'){
		    $$OptionHash{'pipe command'}=
			"$compress | $$OptionHash{'pipe command'}";
		}
		else{
		    $$OptionHash{'pipe command'}=
			"$$OptionHash{'pipe command'} | $compress";
		}
	    }
	}
    }

#---------------------------------------------------------------------------
# access_mode == read --> open files for reading
#---------------------------------------------------------------------------

    if ($AccessMode eq 'read'){
	if (-e $FileName){                   # if file exists
	    my $str="<$FileName";
	    if ($$OptionHash{'pipe command'}){
		$str="$$OptionHash{'pipe command'} $str |";
	    }
	    if (not $fh->open($str)){
		warn "failed to open $FileName";
		return 0;
	    }
	}
    }

#---------------------------------------------------------------------------
# access_mode <> read --> open files for writing
#---------------------------------------------------------------------------

    if ($AccessMode ne 'read'){
	my $f;
	my $pipe='';
	if ($$OptionHash{'pipe command'}){
	    $pipe="| $$OptionHash{'pipe command'} ";
	}

#---------------------------------------------------------------------------
# ... file exists and is non-empty
#---------------------------------------------------------------------------

	if ((-s $FileName) and 
	    ($AccessMode eq 'write')){
	    warn "failed to open $FileName, data exist!";
	    return 0;
	}

#---------------------------------------------------------------------------
# ... file exists and access_mode is 'overwrite'
#---------------------------------------------------------------------------

	elsif ((-e $FileName) and
	       ($AccessMode eq 'overwrite')){
#	    print STDERR "# Uplug::IO::Text.pm: Data exist in $FileName! (overwriting!)\n";

	    if (not $fh->open("$pipe>$FileName")){
		warn "failed to open $FileName";
		return 0;
	    }
	}

#---------------------------------------------------------------------------
# ... access_mode is 'append'
#---------------------------------------------------------------------------

	elsif ($AccessMode eq 'append'){
	    if (not $fh->open("$pipe>>$FileName")){
		warn "failed to open $FileName";
		return 0;
	    }
	}

#---------------------------------------------------------------------------
# ... (file is empty or does not exist) and (access_mode is not 'append')
#---------------------------------------------------------------------------

	else{
	    if (not $fh->open("$pipe>$FileName")){
		warn "failed to open $FileName in $$OptionHash{'id'}!";
		return 0;
	    }
	}
    }
#    binmode($fh);
    return $fh;
}


############################################################################

sub FindDataFile{
    my ($file)=@_;
    if (-f $file){return $file;}
    if ($file!~/\.gz$/){
      my $new=&FindDataFile("$file.gz");
      if (-f $new){return $new;}
    }
    if (-f "data/$file"){return "data/$file";}
    if (-f "$ENV{UPLUGHOME}/$file"){return "$ENV{UPLUGHOME}/$file";}
    $file=basename($file);
    if (-f "data/$file"){return "data/$file";}
    if (-f "$ENV{UPLUGHOME}/$file"){return "$ENV{UPLUGHOME}/$file";}
    return $file;
}
