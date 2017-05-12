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
# Uplug::IO::PlugXML - bitext in PLUG XML
#
#####################################################################
# $Author$
# $Id$

package Uplug::IO::PlugXML;

use strict;
use vars qw(@ISA);
use vars qw(%StreamOptions);
use Uplug::IO::XML;
use Uplug::Data::Lang;
# use Uplug::IO::Any;

@ISA = qw( Uplug::IO::XML );

# stream options and their default values!!

%StreamOptions = ('DocRootTag' => 'PLUG',
		  'DocHeaderTag' => 'header',
		  'DocBodyTag' => 'corpus',
		  'root' => 'align',
		  'InternalEncoding' => 'iso-8859-1',
		  'DTDname' => 'PLUG',
		  'DTDsystemID' => 'plugXML.dtd',
		  'DefaultEncoding' => 'iso-8859-1',

#		  'encoding' => 'iso-8859-1',
#		  'DataStructure' => 'complex',
#		  'encoding' => $Uplug::IO::DEFAULTENCODING,
#		  'DTDpublicID' => '...'
		  );
$StreamOptions{DocRoot}{version}='1.0';

sub new{
    my $class=shift;
    my $self=$class->SUPER::new($class);
    &Uplug::IO::AddHash2Hash($self->{StreamOptions},\%StreamOptions);
    return $self;
}

sub read{
    my $self=shift;
    my ($data)=@_;

    if (not ref($data->{source})){$data->{source}=Uplug::Data::Lang->new();}
    if (not ref($data->{target})){$data->{target}=Uplug::Data::Lang->new();}

    if ($self->SUPER::read($data)){
	my @seg=$data->findNodes('seg');
	if (defined $seg[0]){
	    $seg[0]->setLabel('source');
	    $data->{source}->setRoot($seg[0]);
	}
	if (defined $seg[1]){
	    $seg[1]->setLabel('target');
	    $data->{target}->setRoot($seg[1]);
	}
	return 1;
    }
    return 0;
}

sub write{
    my $self=shift;
    my ($data)=@_;
    $self->Uplug::IO::write($data);
    my @seg=$data->getNodes('seg');
    if (not @seg){

	my ($source)=$data->getNodes('source');
	my ($target)=$data->getNodes('target');

	if (not ref($source)){return 0;}
	if (not ref($target)){return 0;}

	my $srcLang=$data->attribute($source,'lang');
	my $trgLang=$data->attribute($target,'lang');
	if (not $srcLang){$data->setAttribute($source,'lang','src');}
	if (not $trgLang){$data->setAttribute($target,'lang','trg');}

	$source->setTagName('seg');
	$target->setTagName('seg');

    }
    
    return $self->SUPER::write($data);
}


sub readFromHandle{
    my $self=shift;
    my $txt=$self->SUPER::readFromHandle(@_);
    if ($txt=~/\<align\s+id\=[^\"\']/){
	$txt=~s/(\<align\s+id\=)([^\"\'])/$1\'$2/;
    }
    if ($txt=~/\<\?xml/){
	if ($txt!~/encoding/){
	    $txt=~s/\?\>/ encoding=\"iso-8859-1\"\?\>/;
	}
    }
    my @ent=();
    while ($txt=~/\&([^\s\;]+)\;/g){
	if ($1 eq 'lt'){next;}
	if ($1 eq 'gt'){next;}
	if ($1 eq 'amp'){next;}
	push (@ent,$1);
    }
    foreach (@ent){
	print STDERR "replace \&$_\; with \[$_\]!\n";
	$txt=~s/\&$_\;/ [$_] /gs;
    }
    return $txt;
}
