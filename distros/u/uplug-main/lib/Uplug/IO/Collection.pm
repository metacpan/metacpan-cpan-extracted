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
# StreamCollection - 
#
#
#####################################################################
# $Author$
# $Id$


package Uplug::IO::Collection;

use strict;
use vars qw(@ISA);
use Uplug::IO;
use Uplug::IO::Any;

@ISA = qw( Uplug::IO );


sub new{
    my $class=shift;
    my $options=shift;
    my $self=$class->SUPER::new($options);
    $self->{StreamHandles}=[];
    $self->{StreamID}={};
    return $self;
}

sub open{
    my $self            = shift;
    $self->{AccessMode} = shift;
    my $HeaderHash      = $_[0];

    $self->SUPER::open($self->{AccessMode},$HeaderHash);

    $self->AddStream($self->{StreamOptions});

    if ($#{$self->{StreamHandles}}){
	if (not defined $self->{CurrentStreamID}){
	    $self->{CurrentStreamID}=0;
	    $self->{CurrentStream}=$self->{StreamHandles}->[0];
	}
	return $self->{CurrentStream}->open($self->{AccessMode},$HeaderHash);
    }
}

sub AddStream{
    my $self            = shift;
    my $OptionHash      = $_[0];

    if (ref($OptionHash) ne 'HASH'){return 0;}
    my @streams=();
    if (ref($OptionHash->{'stream names'}) eq 'ARRAY'){
	@streams=@{$OptionHash->{'stream names'}};
    }
    if (ref($OptionHash->{'streams'}) eq 'ARRAY'){
	@streams=@{$OptionHash->{'streams'}};
    }
    if (@streams){
	foreach (@streams){
	    my %options=(format => $_);
	    $self->AddStream(\%options);
	}
	return 1;
    }
    
    my $StreamID=scalar @{$self->{StreamHandles}};
    $self->{StreamHandles}->[$StreamID]=Uplug::IO::Any->new($OptionHash);
    if (not defined $OptionHash->{'stream name'}){
	$OptionHash->{'stream name'}="stream $StreamID";
    }
    &Uplug::IO::AddHash2Hash($self->{StreamHandles}->[$StreamID]->{StreamOptions},$OptionHash);
    $self->{StreamID}->{$OptionHash->{'stream name'}}=$StreamID;
}

sub close{
    my $self=shift;
    return $self->SUPER::close;
#    return $self->{CurrentStream}->close;
}


sub read{
    my $self=shift;
    my $data=shift;
    my $doc='';
    while (not $self->{CurrentStream}->read($data)){
	if (not $self->NextStream){
	    delete $self->{openDoc};
	    return 0;
	}
	else{                       # save the doc-name of a new stream

	    if (defined $self->{CurrentStream}->{StreamOptions}->{FileName}){
		$doc=$self->{CurrentStream}->{StreamOptions}->{FileName};
	    }
	    elsif (defined $self->{CurrentStream}->{StreamOptions}->{file}){
		$doc=$self->{CurrentStream}->{StreamOptions}->{file};
	    }
	    elsif (defined 
		$self->{CurrentStream}->{StreamOptions}->{'stream name'}){
		$doc=$self->{CurrentStream}->{StreamOptions}->{'stream name'};
	    }
	}
    }
#     $data->addHeader($doc);        # add the document name to the data header
    if ($doc){
	if ($self->{openDoc}){
	    $data->addHeader("\n</text>\n");
	}
	$self->{openDoc}=$doc;
	$data->addHeader("\n<text file=\"$doc\">\n");
    }

    return 1;
}

sub write{
    my $self=shift;
    my $data=shift;
    return $self->{CurrentStream}->write($data);
}


sub select{
    my $self=shift;
    my ($PatternHash,
	$ListOfAttr,
	$CmpOperator)=@_;
    my $data;
    while (not ($data=$self->{CurrentStream}->select($PatternHash,
						     $ListOfAttr,
						     $CmpOperator))){
	if (not $self->NextStream){
	    return undef;
	}
    }
    return $data;
}


sub NextStream{

    my $self=shift;
    $self->{CurrentStream}->close;
    while (1) {
	if ($self->{CurrentStreamID}<$#{$self->{StreamHandles}}){
	    $self->{CurrentStreamID}++;
	    my $streamID=$self->{CurrentStreamID};
	    $self->{CurrentStream}=
		$self->{StreamHandles}->[$self->{CurrentStreamID}];
	    if ($self->{CurrentStream}->open($self->{AccessMode})){
		return 1;
	    }
	}
	else{
	    $self->{CurrentStreamID}=-1;
	    $self->{CurrentStream}=undef;
	    return 0;
	}
    }
    return 1;
}


sub GotoStream{

    my $self=shift;
    my $StreamName=shift;

    my $StreamID;
    if (not defined $self->{StreamID}->{$StreamName}){
	if ($StreamName=~/^[0-9]+$/){
	    $StreamID=$StreamName;
	}
	else{return 0;}
    }
    else{
	$StreamID=$self->{StreamID}->{$StreamName};
    }

    $self->{CurrentStream}->close;
    $self->{CurrentStreamID}=$StreamID;
    $self->{CurrentStream}=
	$self->{StreamHandles}->[$self->{CurrentStreamID}];
    if ($self->{CurrentStream}->open($self->{AccessMode})){
	return 1;
    }
    else{
	return 0;
    }
}


1;

