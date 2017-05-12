####################################################################
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
# Uplug::IO::DBM
#
# simple module for storing uplug-data in DBM-files
#
#####################################################################
# $Author$
# $Id$



package Uplug::IO::DBM;

# use utf8;
# use bytes;
use strict;
use vars qw(@ISA $DEFAULTMODE $DEFAULTCACHESIZE);
use Uplug::IO;
use Uplug::Data;
use Uplug::Encoding;
use Data::Dumper;

@ISA = qw( Uplug::IO );

BEGIN { @AnyDBM_File::ISA=qw(DB_File GDBM_File SDBM_File NDBM_File ODBM_File) }
# BEGIN { @AnyDBM_File::ISA=qw(SDBM_File GDBM_File_ NDBM_File ODBM_File) }
use AnyDBM_File;
use POSIX;

#---------------------------------------------------------------------------
# simple caching: the first selected items get chached
# nothing will be added if the cache is full until the DBM is opened again

$DEFAULTCACHESIZE=200000;       # max number of items cached by GetKeyData
#$DEFAULTCACHESIZE=0;
$DEFAULTMODE=0644;                # default file mode for tie



sub open{
    my $self            = shift;
    $self->{AccessMode} = shift;
    my $HeaderHash      = $_[0];
    if (not $self->{AccessMode}){$self->{AccessMode}='read';}
    if ($self->{AccessMode} eq 'write'){
	if (defined $HeaderHash->{'write_mode'}){
	    $self->{AccessMode}=$HeaderHash->{'write_mode'};
	}
    }

    $self->{CACHED}=0;
    $self->{CACHESIZE}=$DEFAULTCACHESIZE;
    $self->SUPER::init($HeaderHash);

    if ((not defined $self->{StreamOptions}->{FileName}) and
	(defined $self->{StreamOptions}->{file})){
	$self->{StreamOptions}->{FileName}=$self->{StreamOptions}->{file};
    }
    $self->{FileName}=$self->{StreamOptions}->{FileName};
    $self->{StreamOptions}->{file}=$self->{StreamOptions}->{FileName};


    if (defined $self->{FileName}){
	$self->{DBMhash}={};
	if (not defined $self->{StreamOptions}->{'file mode'}){
	    $self->{StreamOptions}->{'file mode'}=$Uplug::IO::DBM::DEFAULTMODE;
	}
	if (-e $self->{'FileName'}){
	    if ($self->{AccessMode} eq 'write'){
		warn "Cannot open $self->{'FileName'} for writing!";
		return 0;
	    }
	    if ($self->{AccessMode} eq 'overwrite'){
		unlink $self->{'FileName'};
	    }
	}
	if ($self->{AccessMode} eq 'read'){
	    if (not $self->{DBH}=tie %{$self->{DBMhash}},
		'AnyDBM_File',
		$self->{'FileName'},
		O_RDONLY,
		$self->{StreamOptions}->{'file mode'}){
		return 0;
	    }
	}
	elsif (not $self->{DBH}=tie %{$self->{DBMhash}},
	    'AnyDBM_File',
	    $self->{'FileName'},
	    O_RDWR|O_CREAT,
	    $self->{StreamOptions}->{'file mode'}){
	    return 0;
	}


	## JT 2005-03-14:
	
	if ($]>=5.006){
	    my $mod=qw( Encode );
	    eval "require $mod";
	    if ($@){warn $@;exit;}
# 	    $self->{DBH}->filter_store_key(sub {Encode::_utf8_off($_)});
#	    $self->{DBH}->filter_store_value(sub{Encode::_utf8_off($_)});
#	    $self->{DBH}->filter_fetch_key(sub{Encode::_utf8_off($_)});
#	    $self->{DBH}->filter_fetch_value(sub {Encode::_utf8_off($_)});
 	    $self->{DBH}->filter_store_key(sub {$_=Encode::encode('utf8',$_)});
	    $self->{DBH}->filter_store_value(sub{$_=Encode::encode('utf8',$_)});
	    $self->{DBH}->filter_fetch_key(sub{$_=Encode::decode('utf8',$_)});
	    $self->{DBH}->filter_fetch_value(sub {$_=Encode::decode('utf8',$_)});
	}
    }
    if (defined $HeaderHash->{'key'}){
	if (ref($HeaderHash->{'key'}) eq 'ARRAY'){
	    my @arr=@{$HeaderHash->{'key'}};
	    $self->{'key'}=[];
	    @{$self->{'key'}}=@arr;
	}
	else{
	    if ($HeaderHash->{'key'}=~/^\((.*)\)$/){
		my @arr=split(/\s*,\s*/,$1);
		$self->{'key'}=[];
		@{$self->{'key'}}=@arr;
	    }
	    else{
		$self->{'key'}=[];
		@{$self->{'key'}}=($HeaderHash->{'key'});
	    }
	}
    }
    my %HeaderOptions=('FileName' => $self->{FileName}.'.head');
    $self->{HeaderStream}=Uplug::IO::Text->new;
    $self->{HeaderStream}->open($self->{AccessMode},\%HeaderOptions);
    $self->addheader($self->{HeaderStream}->header);
    return $self->SUPER::open($self->{AccessMode},$HeaderHash);
}



sub close{
    my $self=shift;
    $self->{HeaderStream}->close;
    untie %{$self->{DBMhash}};
    return 1;
}


sub read{
    my ($self,$TreeData)=@_;

    $TreeData->init;

    my $data={};
    my ($key,$val)=each %{$self->{DBMhash}};

    if ((not defined $key) and (not defined $val)){
	return 0;
    }

    my @keyval=split(/\x00/,$key);
    %{$data}=split(/\x00/,$val);
    if ($val=~/\|/){
	foreach (keys %{$data}){
	    if ($data->{$_}=~/\|/){
		my @arr=split(/\|/,$data->{$_});
		$data->{$_}=undef;
		@{$data->{$_}}=@arr;
	    }
	}
    }
    if (defined $self->{key}){
	foreach (@{$self->{'key'}}){
	    $data->{$_}=shift(@keyval);
	}
    }
    %{$data}=&expandData($data);
    $TreeData->setData($data);
    return 1;
}



sub write{
    my ($self,$TreeData)=@_;

    $self->SUPER::write($TreeData);
    my $data=$TreeData->data;
    if (ref($data) ne 'HASH'){return;}

    my %dat=%{$data};
    my $key;
    my @fields=();
    if (defined $self->{key}){
	foreach (@{$self->{'key'}}){
	    push (@fields,$dat{$_});
	    delete $dat{$_};
	}
    }
    $key=join ("\x00",@fields);
    if (not $key){
	$self->{'LastNr'}++;
	$key=$self->{'LastNr'};
    }

    my %TmpData=$self->GetKeyValue($key);
    if (keys %TmpData){
	my $NewData=&JoinComplexHashs(\%TmpData,\%dat);
	%dat=%{$NewData};
    }
    foreach (keys %dat){if ($dat{$_} eq ''){$dat{$_}=' ';}}

    %dat=&dumpData(\%dat);
    my $d=join ("\x00",%dat);

    eval { $self->{DBMhash}->{$key}=$d; };
    return 1;
}


sub count{
    my $self=shift;
    my $records=keys %{$self->{DBMhash}};
    return $records;
}



#-----------------------------------------------------------------------------

sub select{
    my $self=shift;
    my ($data,
	$Query,
	$ListOfAttr,
	$CmpOperator)=@_;

    if (not ref($data)){return;}                  # no return data object found
    if (ref($Query) ne 'HASH'){return;}           # query pattern is no hash
    my %Pattern=%{$Query};                        # save query in a new hash

    my @keys;
    if (defined $self->{'key'}){                  # hash-key fields
	@keys=@{$self->{'key'}};
    }
    if (not @keys){                               # if no hash keys specified:
	return $self->SUPER::select($data,        # use standard select
				    $Query,       # (read sequentially through
				    $ListOfAttr,  #  the database --> slow!)
				    $CmpOperator);
    }
    my $key;
    my $keycomplete=1;                            # hash-key is complete
    my @fields=();
    foreach my $k (@keys){                        # check all key-fields
	if (not defined $Pattern{$k}){            # if one of them is not
	    $keycomplete=0;                       # specified --> reset flag
	    push (@fields,'.*');                  # and create a wild-card-key
	}
	else{
	    push(@fields,$Pattern{$k});           # otherwise: save key-field
	    delete $Pattern{$k};                  # and delete pattern
	}
    }
    $key=join ("\x00",@fields);                   # join all keys together

    #-------------------------------------------------------------------------
    my %hash=();
    if ($keycomplete){                            # if the key is complete:
	%hash=$self->GetKeyData($key);            # * get data from hash
    }
    else{                                         # key is not complete!
	$key=qr/^$key\$/;                         # make regular expression
	my ($k,$v);
	while (($k,$v)=$self->getNext()){         # run through all keys
	    if ($k=~/$key/){                      # and try to match the key!
		%hash=$self->GetKeyData($k);      #   - get the data
	    }
	    if (keys %hash){last;}
	}
    }
    #-------------------------------------------------------------------------
    if (not keys %hash){return 0;}                #   - key not found -> return
    if (not &MatchQuery(\%Pattern,\%hash)){       #   - other attr don't match
	return 0;
    }
    $data->setData(\%hash);
    return 1;
}

#-----------------------------------------------------------------------------


sub getNext{
    my $self=shift;
    return each %{$self->{DBMhash}};
}

sub getValue{
    return $_[0]->{DBMhash}->{$_[1]};
}

#-------------------------------------------------------------------
# match a query pattern with a data structure
# ... this is much too simple ... 
# ... should be improved in many ways
#

sub MatchQuery{
    my ($query,$data)=@_;

    if (ref($query) ne ref($data)){return 0;}
    if (not ref($query)){
	return $data=~/^$query$/;
    }
    if (ref($query) eq 'ARRAY'){
	foreach my $a (@{$query}){
	    if (not &MatchQuery($query->[$a],$data->[$a])){
		return 0;
	    }
	}
    }
    foreach my $a (keys %{$query}){
	if (not &MatchQuery($query->{$a},$data->{$a})){
	    return 0;
	}
    }
    return 1;
}


sub readheader{
    my $self=shift;
    $self->{HeaderStream}->readheader;
    $self->addheader($self->{HeaderStream}->header);
}

sub writeheader{
    my $self=shift;
    $self->{HeaderStream}->addheader($self->header);
    $self->{HeaderStream}->writeheader;
}




sub GetKeyData{
    my ($self,$key)=@_;

    #-----------------------------------------------
    if (defined $self->{DBMcache}->{$key}){
#	print STDERR "found $key in cache ($self->{CACHED})!\n";
	return %{$self->{DBMcache}->{$key}};
    }
    #-----------------------------------------------

    if (defined $self->{DBMhash}->{$key}){
	my $dat=$self->{DBMhash}->{$key};
	my @keyval=split(/\x00/,$key);
	my %FoundData=split(/\x00/,$dat);
	&expandData(\%FoundData);
	foreach (@{$self->{'key'}}){
	    $FoundData{$_}=shift(@keyval);
	}
	#-----------------------------------------------
	if ($self->{CACHED}<$self->{CACHESIZE}){
	    %{$self->{DBMcache}->{$key}}=%FoundData;
	    $self->{CACHED}++;
	}
	#-----------------------------------------------
	return %FoundData;
    }
    #-----------------------------------------------
    # JT 14-11-2004: cache even not-found keys
    if ($self->{CACHED}<$self->{CACHESIZE}){
	%{$self->{DBMcache}->{$key}}=();
	$self->{CACHED}++;
    }
    #-----------------------------------------------
    return ();
}

sub GetKeyValue{
    my ($self,$key)=@_;
    if (defined $self->{DBMhash}->{$key}){
	my $dat=$self->{DBMhash}->{$key};
	my %FoundData=split(/\x00/,$dat);
	&expandData(\%FoundData);
	return %FoundData;
    }
    return ();
}



####################################################
# put 2 hash-structures together

sub JoinComplexHashs{

    my ($data1,$data2)=@_;
    if (not defined $data2->{freq}){$data2->{freq}=1;}
    if (not defined $data1->{freq}){$data1->{freq}=1;}
    $data1->{freq}+=$data2->{freq};
    foreach my $key (keys %{$data2}){
	if ($key eq 'freq'){next;}
	if (defined $data1->{$key}){
	    if ((not ref($data2->{$key})) and 
		($data1->{$key} eq $data2->{$key})){
		next;
	    }
	    if (not ref($data1->{$key})){
		my $old=$data1->{$key};
		$data1->{$key}=[];
		$data1->{$key}->[0]=$old;
	    }
	    if (not ref($data2->{$key})){
		my $old=$data2->{$key};
		$data2->{$key}=[];
		$data2->{$key}->[0]=$old;
	    }
#	    if (ref($data1->{$key}) ne ref($data2->{$key})){
#		my $old=$data1->{$key};
#		my $new=$data2->{$key};
#		$data1->{$key}=[];
#		$data1->{$key}->[0]=$old;
#		$Data::Dumper::Terse=1;
#		$Data::Dumper::Purity=1;
#		my $ValString=Dumper($data2->{$key});
#		$data1->{$key}->[1]=$ValString;
#		return;
#	    }
	    if (ref($data2->{$key}) eq 'ARRAY'){
		push (@{$data1->{$key}},@{$data2->{$key}});
	    }
	    if (ref($data2->{$key}) eq 'HASH'){
		foreach (keys %{$data2->{$key}}){
		    $data1->{$key}->{$_}=$data2->{$key}->{$_};
		}
	    }
#	    $Data::Dumper::Terse=1;
#	    $Data::Dumper::Purity=1;
#	    my $DataString=Dumper($data1->{$key});
#	    delete $data1->{$key};
#	    $data1->{$key}=eval $DataString;
	}
	else{
	    if (ref($data2->{$key})){
		$Data::Dumper::Terse=1;
		$Data::Dumper::Purity=1;
		my $ValString=Dumper($data2->{$key});
		$data1->{$key}=eval $ValString;
	    }
	    else{
		$data1->{$key}=$data2->{$key};
	    }
	}
    }
    return $data1;
}


#######################################

sub expandData{
    my ($data)=@_;
    my %FlatHash=%{$data};
    my $VAR1;
    foreach (keys %FlatHash){
	if ($FlatHash{$_}=~/^\s*\$VAR1\s*\=/){
	    $data->{$_}=eval $FlatHash{$_};
	}
    }
    return %{$data};
}

sub dumpData{
    my ($data)=@_;
    my %FlatHash;
    my $VAR1;
    foreach (keys %{$data}){
	if (ref($data->{$_})){
	    $Data::Dumper::Indent=0;
	    $Data::Dumper::Terse=0;
	    $Data::Dumper::Purity=1;
	    $FlatHash{$_}=Dumper($data->{$_});
	}
	else{
	    $FlatHash{$_}=$data->{$_};
	}
    }
    return %FlatHash;
}


#######################################

1;
