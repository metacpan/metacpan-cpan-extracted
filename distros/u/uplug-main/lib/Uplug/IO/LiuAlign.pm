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

#####################################################################
#
# LiuStream - 
#
#####################################################################
# $Author$
# $Id$


package Uplug::IO::LiuAlign;

use strict;
use vars qw(@ISA);
use vars qw(%StreamOptions);
use Uplug::IO::XML;
use Uplug::IO::Any;
use Uplug::Data;
# use IO::File;
# use POSIX qw(tmpnam);

@ISA = qw( Uplug::IO::XML );

# stream options and their default values!!

%StreamOptions = ('DocRootTag' => 'liuAlign',
		  'DocHeaderTag' => 'liuHeader',
		  'DocBodyTag' => 'linkList',
		  'root' => 'sentLink',
#		  'encoding' => $Uplug::IO::DEFAULTENCODING,
		  'DataStructure' => 'complex',
		  'SkipDataHeader' => 1,
		  'DTDname' => 'liuAlign',
		  'DTDsystemID' => 'liu-align.dtd',
#		  'DTDpublicID' => '...'
		  );
$StreamOptions{DocRoot}{version}='1.0';

sub new{
    my $class=shift;
    my $self=$class->SUPER::new($class);
    &Uplug::IO::AddHash2Hash($self->{StreamOptions},\%StreamOptions);
    return $self;
}

sub init{
    my $self            = shift;
    my $options         = $_[0];
    if (ref $options){
	$self->{DocRoot}->{fromDoc}=$options->{fromDoc};
	$self->{DocRoot}->{toDoc}=$options->{toDoc};
    }
    return $self->SUPER::init($options);
}

sub initFromDoc{
    my $self=shift;

    if (defined $self->{StreamOptions}->{fromDoc}){
	$self->{StreamOptions}->{DocRoot}->{fromDoc}=
	    $self->{StreamOptions}->{fromDoc};
    }
    elsif ((ref($self->{StreamHeader}->{DocRoot}) eq 'HASH') and
	   (defined $self->{StreamHeader}->{DocRoot}->{fromDoc})){
	$self->{StreamOptions}->{DocRoot}->{fromDoc}=
	    $self->{StreamHeader}->{DocRoot}->{fromDoc};
    }
    elsif (not defined $self->{StreamOptions}->{DocRoot}->{fromDoc}){
	if (defined $self->{StreamOptions}->{file}){
	    $self->{StreamOptions}->{DocRoot}->{fromDoc}=
		$self->{StreamOptions}->{file}.'.src';
	}
	else{
	    $self->{StreamOptions}->{DocRoot}->{fromDoc}=
		&Uplug::IO::Any::GetTempFileName.'.src';
	}
    }
    $self->{StreamOptions}->{DocRoot}->{fromDoc}=
	$self->FindDataFile($self->{StreamOptions}->{DocRoot}->{fromDoc});
}



sub initToDoc{
    my $self=shift;

    if (defined $self->{StreamOptions}->{toDoc}){
	$self->{StreamOptions}->{DocRoot}->{toDoc}=
	    $self->{StreamOptions}->{toDoc};
    }
    elsif ((ref($self->{StreamHeader}->{DocRoot}) eq 'HASH') and
	   (defined $self->{StreamHeader}->{DocRoot}->{toDoc})){
	$self->{StreamOptions}->{DocRoot}->{toDoc}=
	    $self->{StreamHeader}->{DocRoot}->{toDoc};
    }
    elsif (not defined $self->{StreamOptions}->{DocRoot}->{toDoc}){
	if (defined $self->{StreamOptions}->{file}){
	    $self->{StreamOptions}->{DocRoot}->{toDoc}=
		$self->{StreamOptions}->{file}.'.trg';
	}
	else{
	    $self->{StreamOptions}->{DocRoot}->{toDoc}=
		&Uplug::IO::Any::GetTempFileName.'.trg';
	}
    }
    $self->{StreamOptions}->{DocRoot}->{toDoc}=
	$self->FindDataFile($self->{StreamOptions}->{DocRoot}->{toDoc});
}

sub init{
    my $self=shift;
    my $ret=$self->SUPER::init(@_);
    $self->initFromDoc;
    $self->initToDoc;
    return $ret;
}

sub open{
    my $self            = shift;
    $self->{AccessMode} = shift;
    my $OptionHash      = $_[0];

    &Uplug::IO::AddHash2Hash($self->{StreamOptions},\%StreamOptions);
    my $ret=$self->SUPER::open($self->{AccessMode},$OptionHash);
    $self->initFromDoc;
    $self->initToDoc;


    if (($self->{AccessMode} ne 'read') and 
	(-s $self->{StreamOptions}->{DocRoot}->{fromDoc})){
	$self->{fromDoc}='exists';
    }
    else{
	my %SrcStream=('file' => $self->{StreamOptions}->{DocRoot}->{fromDoc},
		       'format' => 'XML',
#		       'DocRootTag' => 'cesDoc',
		       'root' => 's');
	if ($self->{AccessMode} ne 'read'){$SrcStream{DocRootTag}='document';}
	$self->{source}=Uplug::IO::Any->new(\%SrcStream);
	my $r;
	if (not $r=$self->{source}->open($self->{AccessMode},\%SrcStream)){
	    $self->{fromDoc}='exists';
	}
    }


    if (($self->{AccessMode} ne 'read') and 
	(-s $self->{StreamOptions}->{DocRoot}->{toDoc})){
	$self->{toDoc}='exists';
    }
    else{
	my %TrgStream=('file' => $self->{StreamOptions}->{DocRoot}->{toDoc},
		       'format' => 'XML',
#		       'DocRootTag' => 'cesDoc',
		       'root' => 's');
	if ($self->{AccessMode} ne 'read'){$TrgStream{DocRootTag}='document';}
	$self->{target}=Uplug::IO::Any->new(\%TrgStream);
	my $r;
	if (not $r=$self->{target}->open($self->{AccessMode},\%TrgStream)){
	    $self->{toDoc}='exists';
	}
    }
#    if ($self->{AccessMode} eq 'read'){
#	if ($self->{toDoc} eq 'exists'){return 0;}
#	if ($self->{fromDoc} eq 'exists'){return 0;}
#    }
    return $ret;
}

sub close{
    my $self=shift;
    $self->SUPER::close();
    if (defined $self->{source}){
	$self->{source}->close;
    }
    if (defined $self->{target}){
	$self->{target}->close;
    }
}

sub write{
    my $self=shift;
    my ($data)=@_;

    $self->Uplug::IO::write($data);

    my $ret;
    my $source=Uplug::Data->new;
    $data->subData($source,'source');
    my $target=Uplug::Data->new;
    $data->subData($target,'target');
    if (ref($data->{link})){
	my $rootTag=$self->option('root');                     # should be this
	my $linkTag=$data->{link}->getRootNode->getNodeName(); # but is this
	if (($rootTag ne $linkTag) and                         # different tags
	    ($data->{link}->getRootNode->getNodeType==1)){     # (element node)
	    $data->{link}->getRootNode->setTagName($rootTag);  # change name!!
	}
	$ret=$self->SUPER::write($data->{link});
    }
    elsif (defined $data->attribute('xtargets')){
	$ret=$self->SUPER::write($data);
    }
    else{
	my $tag=$self->option('root');
	my $link=Uplug::Data->new($tag);
	my @src=$source->findNodes('s');
	my @srcID=$source->attribute(\@src,'id');
	foreach (0..$#src){
	    if (not defined $srcID[$_]){
		$self->{srcID}++;
		$srcID[$_]=$self->{srcID};
		$source->setAttribute($src[$_],'id',$srcID[$_]);
	    }
	    $self->{srcID}=$srcID[$_];
	}

	my @trg=$target->findNodes('s');
	my @trgID=$target->attribute(\@trg,'id');
	foreach (0..$#trg){
	    if (not defined $trgID[$_]){
		$self->{trgID}++;
		$trgID[$_]=$self->{trgID};
		$target->setAttribute($trg[$_],'id',$trgID[$_]);
	    }
	    $self->{trgID}=$trgID[$_];
	}
	my $s=join('+',@srcID);
	my $t=join('+',@trgID);
	$link->setAttribute('xtargets',"$s\;$t",$tag);

	my $id=$data->attribute('id');
	if (not defined $id){
	    $self->{alignID}++;
	    $id=$self->{alignID};
	}
	$link->setAttribute('id',$id);
	$ret=$self->SUPER::write($link);
    }
    if ($self->{fromDoc} ne 'exists'){
#	$source->moveAttribute('s','seg');
	$self->{source}->write($source);
    }
    if ($self->{toDoc} ne 'exists'){
#	$target->moveAttribute('s','seg');
	$self->{target}->write($target);
    }
    return $ret;
}

sub read{
    my $self=shift;
    my ($data)=@_;

    $data->init;
    $data->addChild('align');
    $data->{link}=Uplug::Data->new;
    my $ret=$self->SUPER::read($data->{link});
    my ($src,$trg);

    my $xtargets=$data->{link}->attribute('xtargets');
    if (defined $xtargets){
	($src,$trg)=split(/\;/,$xtargets);
    }
    else{return 0;}


    my @srcID=split(/[\+\s]/,$src);
    my @trgID=split(/[\+\s]/,$trg);

    my $elem=0;
    if (ref($data->{link}->{content}) eq 'ARRAY'){
	$elem=@{$data->{link}->{content}};
    }

#----------- sentences ------------------------------

    &ReadSegments($self->{source},$data,\@srcID,'source');
    &ReadSegments($self->{target},$data,\@trgID,'target');

    $self->Uplug::IO::read($data);

    return $ret;

}


sub ReadSegments{

    my ($stream,$data,$IDs,$lang)=@_;

    if (not @{$IDs}){return;}
    my $i=0;
    my $parent=$data->addChild($lang);
#    my $dom=$data->getDOM();
    my $sent=Uplug::Data->new();

    my $fail=0;
    while ($stream->read($sent)){
	my $id=$sent->attribute('id');
#	if (not grep(@{$IDs},$id)){
	if (not grep ($_ eq $id,@{$IDs})){
	    if ($id<$IDs->[0]){next;}
	    else{
		$fail++;
		if ($fail>1){
		    last;
		}                # fail only once!!!
#		$stream->close;            # takes too much time!
#		$stream->open('read');     # ... ignore it for now ...
		next;
	    }
	}
	my $node=$sent->getRootNode();
#	$sent->{dom}->removeChild($node);
#	$node->setOwnerDocument($dom);
	$data->addChild($node,$parent);
	if ($id eq $IDs->[-1]){last;}
	$i++;
    }
    $sent->dispose();
#    $sent->{dom}->dispose();
}









#sub readheader{
#    my $self            = shift;
#    $self->SUPER::readheader(@_);
#}

#sub writeheader{
#    my $self=shift;
#    $self->SUPER::writeheader(@_);
#}

sub ReadSegmentsOld{

    my ($stream,$data,$IDs,$lang)=@_;

    if (not @{$IDs}){return;}
    my $i=0;
    my $parent=$data->addChild($lang);
    my $dom=$data->getDOM();
    my $sent=Uplug::Data->new();

    my $fail=0;
    while ($stream->read($sent)){
	my $id=$sent->attribute('id');
#	if (not grep(@{$IDs},$id)){
	if (not grep ($_ eq $id,@{$IDs})){
	    if ($id<$IDs->[0]){next;}
	    else{
		$fail++;
		if ($fail>1){
		    last;
		}                # fail only once!!!
#		$stream->close;           # takes too much time
#		$stream->open('read');    # ... should do something here ...
		next;
	    }
	}
	my $node=$sent->getRootNode();
	$sent->{dom}->removeChild($node);
	$node->setOwnerDocument($dom);
	$data->addChild($node,$parent);
	if ($id eq $IDs->[-1]){last;}
	$i++;
    }
    $sent->{dom}->dispose();
}

#sub GetTempFileName{
#    my $fh;
#    my $file;
#    do {$file=tmpnam();}
#    until ($fh=IO::File->new($file,O_RDWR|O_CREAT|O_EXCL));
#    $fh->close;
#    return $file;
#}




sub files{
    my $self=shift;
    my @files=$self->SUPER::files;
    my $file=$self->{StreamOptions}->{file};
    my $from=$self->{StreamOptions}->{DocRoot}->{fromDoc};
    my $to=$self->{StreamOptions}->{DocRoot}->{toDoc};
    if ($from eq $file.'.src'){
	push(@files,$from);
    }
    if ($to eq $file.'.src'){
	push(@files,$to);
    }
    return @files;
}

sub delete{
    my $self=shift;
    return $self->SUPER::delete;
    my $file=$self->{StreamOptions}->{file};
    my $from=$self->{StreamOptions}->{DocRoot}->{fromDoc};
    my $to=$self->{StreamOptions}->{DocRoot}->{toDoc};
    if ($from eq $file.'.src'){
	if (-e $from){
	    print STDERR "# LiuStream.pm: remove file $from!\n";
	    unlink $from;
	}
    }
    if ($to eq $file.'.trg'){
	if (-e $to){
	    print STDERR "# LiuStream.pm: remove file $to!\n";
	    unlink $to;
	}
    }
}

sub FindDataFile{
    my $self=shift;
    my ($file)=@_;

    if (-e $file){
	return $file;
    }

    #-------------------------------------
    # if AccessMode is 'read' and the file is not found:
    #    check if the file
    #    1) is in the same dir as the alignment file
    #    2) exists relativ to the alignment file directory

    if ($self->{AccessMode} eq 'read'){
	my $AlignFile=$self->{StreamOptions}->{file};
	my $AlignDir='';
	if ($AlignFile=~/^(.*[\\\/])([^\\\/]+)$/){
	    $AlignDir=$1;
	    $AlignFile=$2;
	}
	my $dir='';
	if ($file=~/^(.*[\\\/])([^\\\/]+)$/){
	    $dir=$1;
	    $file=$2;
	}
	if (-e "$AlignDir$file"){
	    return "$AlignDir$file";
	}
	if (-e "$AlignDir$dir$file"){
	    return "$AlignDir$dir$file";
	}
	if (not -e $file.'gz'){
	    return $file.'.gz';
	}
    }
    return $file;
}

