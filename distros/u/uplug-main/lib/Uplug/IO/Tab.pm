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
# Uplug::IO::Tab - data records, row by row, 
#                separated by some delimiter symbol
#
#####################################################################
# $Author$
# $Id$

package Uplug::IO::Tab;

use strict;
use vars qw(@ISA $DefaultDelimiter);
use Uplug::IO::Text;

@ISA = qw( Uplug::IO::Text );

$DefaultDelimiter="\t";

#-------------------------------------------------------------------

sub read{
    my $self=shift;
    my ($data)=@_;
    $data->init;
    my $DataHash={};

    if (not $self->{StreamOptions}->{'field delimiter'}){
	$self->{StreamOptions}->{'field delimiter'}=
	    $Uplug::IO::Tab::DefaultDelimiter;
    }
    my $del=$self->{StreamOptions}->{'field delimiter'};

    my $fh=$self->{'FileHandle'};
    my $DataLine;
    while ($DataLine=$self->readFromHandle($fh)){

	if ($DataLine=~/^\# ([^:]+):\s*(\S.*)\s*$/){
	    my %HeaderHash=();
	    $HeaderHash{$1}=eval $2;
	    $self->addheader(\%HeaderHash);
	    next;
	}
	chop $DataLine;
	my @val=split(/$del/,$DataLine);
	my $c=$#val;
	if (not defined $self->{StreamOptions}->{'columns'}){
	    $self->{StreamOptions}->{'columns'} = [];
	}

	if (ref($self->{StreamOptions}->{'columns'}) ne 'ARRAY'){
	    my $columns=$self->{StreamOptions}->{'columns'};
	    $self->{StreamOptions}->{'columns'}=[];
	    if ($columns=~/\((.*)\)/){
		@{$self->{StreamOptions}->{'columns'}}=split(/\,/,$1);
	    }
	}

	for (0..$c){
	    if (not defined $self->{StreamOptions}->{'columns'}->[$_]){
		$self->{StreamOptions}->{'columns'}->[$_]="field $_";
	    }
	    $DataHash->{$self->{StreamOptions}->{'columns'}->[$_]}=$val[$_];
	}
	$data->setData($DataHash);
	return 1;
    }
    return 0;
}


sub write{
    my $self=shift;
    my ($TreeData)=@_;

    $self->Uplug::IO::write($TreeData);

    my $DataHash=$TreeData->data;

    if (not $self->{StreamOptions}->{'field delimiter'}){
	$self->{StreamOptions}->{'field delimiter'}=
	    $Uplug::IO::Tab::DefaultDelimiter;
    }
    my $del=$self->{StreamOptions}->{'field delimiter'};

    my %data=%{$DataHash};

    foreach (keys %data){
	$data{$_}=~s/\n/ /gs;
	$data{$_}=~s/$del/ /gs;
    }
    my $str;
    if ((not defined $self->{StreamOptions}->{'columns'}) or
	(ref($self->{StreamOptions}->{'columns'}) ne 'ARRAY')){
	$self->{StreamOptions}->{'columns'}=[];
	@{$self->{StreamOptions}->{'columns'}}=sort keys %data;
    }

    foreach (@{$self->{StreamOptions}->{'columns'}}){
	$str.=$data{$_}.$del;
	delete $data{$_};
    }
    if (keys %data){
	foreach (sort keys %data){
	    push (@{$self->{StreamOptions}->{'columns'}},$_);
	    $str.=$data{$_}.$del;
	    delete $data{$_};
	}
    }
	if (not defined $self->{StreamHeader}->{columns}){
	    @{$self->{StreamHeader}->{'columns'}}=
		@{$self->{StreamOptions}->{'columns'}};
	    $self->writeheader;
	}
    $str=~s/$del$//;
    my $fh=$self->{'FileHandle'};
    return $self->writeToHandle($fh,$str."\n");
}


sub addheader{
    my $self=shift;
    $self->SUPER::addheader(@_);
    my $header=$self->header;
    if (ref($header) eq 'HASH'){
	if (defined $header->{columns}){
	    $self->setOption('columns',$header->{columns});
	}
    }
}

