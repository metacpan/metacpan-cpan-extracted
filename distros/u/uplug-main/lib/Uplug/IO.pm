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
#####################################################################
#
#     access modes - read|write|overwrite|append
#
###########################################################################


package Uplug::IO;

require 5.004;

use vars qw($DEFAULTENCODING);
use strict;
use Uplug::Encoding;

$DEFAULTENCODING='utf-8';

my $PerlVersion=$];

sub new{
    my $class=shift;
    my $self={};
    bless $self,$class;
    $self->{StreamOptions}={} ;
    $self->{StreamOptions}->{encoding}=$DEFAULTENCODING;
    return $self;
}



sub init{
    my $self=shift;
    my $OptionHash=shift;
    &AddHash2Hash($self->{StreamOptions},$OptionHash);
    if ($self->{AccessMode} eq 'write'){
	if (defined $OptionHash->{'write_mode'}){
	    $self->{AccessMode}=$OptionHash->{'write_mode'};
	}
    }
    $self->{DATACOUNTER}=0;
    return 1;
}


sub open{

    my $self            = shift;
    $self->{AccessMode} = shift;
    my $OptionHash      = shift;

    if (not $self->{AccessMode}){$self->{AccessMode}='read';}

    my $ret;
    if ($ret=$self->init($OptionHash)){
	$self->{StreamStatus}='open';
	if ($self->{AccessMode} eq 'read'){
	    $self->readheader;
	}
	else{
	    if (defined $OptionHash->{'write_mode'}){
		$self->{AccessMode}=$OptionHash->{'write_mode'};
	    }
	    $self->writeheader;
	}
	return 1;
    }
    return 0;
}

sub reopen{
    my $self=shift;
    $self->close;
    return $self->open($self->{AccessMode});
}


sub close{

    my $self              = shift;
    my ($TailHash)      = @_;
    $self->{StreamStatus} = 'close';

    if ($self->{AccessMode} eq 'read'){
	$self->readtail;
    }
    else{
	$self->addtail($TailHash);
	$self->writetail($TailHash);
    }
    return 1;
}

#----------------------------------------------------------------

sub read{
    my $self = shift;
    $self->{DATACOUNTER}++;
    return 1;
}


sub write{
    my $self = shift;
    $self->{DATACOUNTER}++;
    return 1;
}

#----------------------------------------------------------------

sub select{
    my $self=shift;
    my ($data,
	$SelectPatternHash,
	$ListOfAttributes,
	$CmpOperator)=@_;

    while ($self->read($data)){

	if ($data->matchData($SelectPatternHash,$CmpOperator)){
	    if (ref($ListOfAttributes) eq 'ARRAY'){
		$data->keepAttributes($ListOfAttributes);
	    }
	    return 1;
	}
    }
    return 0;
}

#----------------------------------------------------------------
# update(oldData,newData,cmpOperator)

sub update{return;}

#----------------------------------------------------------------
# delete(dataPattern,cmpOperator)

sub delete{return;}

#----------------------------------------------------------------

sub count{
    my $self=shift;


    return $self->{DATACOUNTER} if (defined $self->{DATACOUNTER});

    if ($self->{AccessMode} eq 'read'){
	$self->init();
	$self->{DATACOUNTER}=0;
	while ($self->read){$self->{DATACOUNTER}++}
	return $self->{DATACOUNTER};
    }
}


#----------------------------------------------------------------

sub options{
    my $self=shift;
    return $self->{StreamOptions};
}

sub option{
    my $self=shift;
    if (ref($self->{StreamOptions}) eq 'HASH'){
	return $self->{StreamOptions}->{$_[0]};
    }
    return undef;
}

sub setOption{
    my $self=shift;
    while (@_){
	my $attr=shift;
	my $val=shift;
	$self->{StreamOptions}->{$attr}=$val;
    }
}

sub SetOption{
    my $self=shift;
    return $self->setOption(@_);
}

#----------------------------------------------------------------

sub header{
    my $self=shift;
    return $self->{StreamHeader};
}

sub tail{
    my $self=shift;
    return $self->{StreamTail};
}

#----------------------------------------------------------------

sub readheader{
    my $self=shift;
    if (not defined $self->{StreamHeader}){$self->{StreamHeader} = {};}
    return 0;
}

sub addheader{
    my $self=shift;
    my $HeaderHash=shift;

    if (not defined $self->{StreamHeader}){$self->{StreamHeader}={};}
    if (not defined $self->{StreamOptions}){$self->{StreamOptions}={};}

    &AddHash2Hash($self->{StreamHeader},$HeaderHash);   # stream options can
    &AddHash2Hash($self->{StreamOptions},$HeaderHash);  # be stored in header!
}

#----------------------------------------------------------------

sub writeheader{
    my $self=shift;
    return 0;
}

#----------------------------------------------------------------

sub readtail{
    my $self=shift;
    $self->{'StreamTail'} = {};
    return 0;
}

sub addtail{
    my $self=shift;
    my $TailHash=shift;
    &AddHash2Hash($self->{StreamTail},$TailHash);
}

#----------------------------------------------------------------

sub writetail{
    my $self=shift;
    return 0;
}

sub files{return undef;}



######################################################################
#
# encoding determines the EXTERNAL encoding of data streams
# internal encoding is somewhat depreciated with perl >= 5.8
#

sub getEncoding{
    my $self=shift;
    if (ref($self->{StreamOptions}) eq 'HASH'){
	if (defined $self->{StreamOptions}->{encoding}){
	    return $self->{StreamOptions}->{encoding};
	}
    }
    if (ref($self->{StreamHeader}) eq 'HASH'){
	if (defined $self->{StreamHeader}->{encoding}){
	    return $self->{StreamHeader}->{encoding};
	}
    }
    return $DEFAULTENCODING;
}

sub getInternalEncoding{return $DEFAULTENCODING;}     # internal encoding
sub getExternalEncoding{return $_[0]->getEncoding();} # external encoding

######################################################################
#----------------------------------------------------------------

sub readFromHandle{
    my $self=shift;
    my ($fh,$encoding)=@_;
    if (defined $self->{READBUFFER}){         # check if there's
	my $content=$self->{READBUFFER};      # something in the buffer
	delete $self->{READBUFFER};
	return $content;
    }
    if (not defined $encoding){
	$encoding=$self->getEncoding;
    }
    my $content=<$fh>;                        # otherwise: read from handle
    if (not $content){return $content;}
    if ($PerlVersion<5.008){
	if ($encoding ne $DEFAULTENCODING){
	    $content=Uplug::Encoding::decode($content,$DEFAULTENCODING,
					     $encoding);
#	    $content=$self->decode($content,$encoding,$DEFAULTENCODING);
	}
    }
    return $content;
}

#----------------------------------------------------------------

sub writeToHandle{
    my $self=shift;
    my ($fh,$content,$encoding)=@_;
    if (not defined $encoding){
	$encoding=$self->getEncoding;
    }
    if ($PerlVersion<5.008){
	if ($encoding ne $DEFAULTENCODING){
	    $content=$self->encode($content,$DEFAULTENCODING,$encoding);
	}
    }
    print $fh $content;
}


#----------------------------------------------------------------



sub AddHash2Hash{
    my $base=shift;
    my $hash=shift;
    if (ref($base) ne 'HASH'){return;}
    foreach (keys %{$hash}){
	eval {$base->{$_}=$hash->{$_} };
    }
}



#-------------------------------------------------------------------------

sub encode{
    my $self=shift;
    return &Uplug::Encoding::encode(@_);
}


#-------------------------------------------------------------------------
# return a true value
# 


1;
