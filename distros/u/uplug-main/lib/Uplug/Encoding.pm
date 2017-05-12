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
# $Author$
# $Id$


package Uplug::Encoding;

# use lib '/home/staff/joerg/user_local/lib/perl5/site_perl/5.8.0/i386-linux-thread-multi/';
# use Unicode::String;

use strict;
use vars qw( @ISA @EXPORT @DefinedEncodings %EncodingSubs %EncodingAlias);
use vars qw( $DEFAULTENCODING );

@ISA = qw( Exporter);
@EXPORT = qw( &convert &encodeArray );

$DEFAULTENCODING='utf-8';

@DefinedEncodings = ('ucs4','utf16','utf8','utf7','hex','iso-8859-1');
%EncodingAlias = ('utf-8' => 'utf8',
		  'latin1' => 'iso-8859-1',
		  'latin-1' => 'iso-8859-1',
		  'iso8859-1' => 'iso-8859-1',
		  'iso88591' => 'iso-8859-1'
		  );



my $PerlVersion=$];
if ($PerlVersion<5.008){
#    my $mod=qw( Unicode::String );
    my $mod='Unicode/String.pm';
    eval "require('$mod')";
    if ($@){warn $@;exit;}
}
else{
    my $mod=qw( Encode );
    eval "require $mod";
    if ($@){warn $@;exit;}
    @DefinedEncodings=Encode->encodings(":all");
    foreach (@DefinedEncodings){
	$EncodingAlias{lc($_)}=$_;
    }
}


%EncodingSubs = ('ucs4'      => 'ucs4',        # this is for perl < 5.8
		 'utf16'     => 'utf16',
		 'utf8'      => 'utf8',
		 'utf7'      => 'utf7',
		 'hex'        => 'hex',
		 'iso-8859-1' => 'latin1',
		 );

1;

sub convert{
    my $data=shift;
    my $from=shift;
    my $to=shift;

    #---------
    # perl >= 5.8 takes care of character encodings when opening files
    #            (using PerlIO ...)
    if ($PerlVersion>=5.008){return $data}

    $from=~tr/A-Z/a-z/;
    $to=~tr/A-Z/a-z/;
    if (defined $EncodingAlias{$from}){$from=$EncodingAlias{$from};}
    if (defined $EncodingAlias{$to}){$to=$EncodingAlias{$to};}
    if ($from eq $to){return $data;}

    if (not grep (/^$from$/,@DefinedEncodings)){
#	warn "# Uplug::Encoding: character encoding $from is not defined!";
	return $data;
    }
    if (not grep (/^$to$/,@DefinedEncodings)){
#	warn "# Uplug::Encoding: character encoding $to is not defined!";
	return $data;
    }

#    if ($PerlVersion<5.008){
	my $DecodingSub=$EncodingSubs{$from};
	my $EncodingSub=$EncodingSubs{$to};
	my $u;
	eval "\$u=Unicode::String::$DecodingSub(\$data);";
	eval "\$data=\$u->$EncodingSub;";
	if ($@){warn "# Uplug::Encoding: conversion failed!";}
	return $data;
#    }
#    else{
##	Encode::from_to($data,$from,$to);
##	Encode::decode($from,$data,$from);
##	Encode::decode($to,$data);
#	return Encode::encode($to,$data);
##	return $data;
#    }
#    return $data;
}

#sub convertString{
#    my $string=shift;
#    my $from=shift;
#    my $to=shift;
#    if ($PerlVersion<5.008){return &convert($string,$from,$to);}
#    return &decode($string,$to);
#}

sub encode{
    my $data=shift;
    my $from=shift;
    my $to=shift;
    if ($from eq $to){return $data;}
    if ($PerlVersion<5.008){
	return &convert($data,$from,$to);
    }
    return Encode::encode($from,$data);
}



sub decode{
    my $data=shift;
    my $to=shift;
    my $from=shift;
    if ($PerlVersion<5.008){
	return &convert($data,$from,$to);
    }
    return Encode::decode($to,$data);
}

######################################################################

sub encodeArray{
    my ($arr,$oldCode,$newCode)=@_;
    if (ref($arr) eq 'HASH'){
	foreach (keys %{$arr}){
	    $arr->{$_}=&encode($arr->{$_},$oldCode,$newCode);
	}
    }
    elsif (ref($arr) eq 'ARRAY'){
	foreach (0..$#{$arr}){
	    $arr->[$_]=&encode($arr->[$_],$oldCode,$newCode);
	}
    }
}

1;

