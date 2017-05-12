#
# Copyright (c) 2001, 2002
# Giulio Motta, Ivo Marino All rights reserved.
# http://www-sms.sourceforge.net/
# 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 

package Telephone::Number;

use strict;
use Carp;

use vars qw($VERSION %DATA);

$VERSION = '0.09';

%DATA = (
    #Bulgaria
    359 => [88, 87],
    #Finland
    358 => [40, 50, 41],
    #France
    33  => [6],
    #Germany
    49  => [151, 160, 162, 152, 1520, 170..180, 163],
    #Italy
    39  => [330, 333..340, 360, 368, 340, 347..349, 328, 329, 380, 388, 389],
    #Russia
    7   => [901..903, 910],
    #Spain
    34  => [600, 605..610, 615..620, 626, 627, 629, 630, 636, 637, 639,
            646, 647, 649..662, 666, 667, 669, 670, 676..680, 686, 687,
            689, 690, 696, 697, 699],
    #United Kingdom
    44  => [qw/370 374 378 385 401 402 403 410 411 421 441 467 468 498 585 
            589 772 780 798 802 831 836 850 860 966 973 976 4481 4624 7000 
            7002 7074 7624 7730 7765 7771 7781 7787 7866 7939 7941 7956 7957 
            7958 7961 7967 7970 7977 7979 8700 9797/]
);  

sub new {
	my $class = shift;
	croak "Wrong number of parameters" unless (grep {$_ == @_} (1, 3));
	my $self;
	$_ = shift;
	s/^\+// unless (ref);
	($_, @_) = &parse_number($_) if (@_ == 0);
	$self = bless {
			intpref => $_,
			prefix => shift,
			telnum => shift,
		} , $class;
	$self;
}

sub fits {
	my ($tn, $setn) = @_;
	for (keys %{$tn}) {
		next unless (defined $setn->{$_});
		return 0 unless (
			is_in($tn->{$_}, (
					  ref $setn->{$_} 
					  ? @{$setn->{$_}} 
					  : $setn->{$_}
					 ) 
			     )
		);
	}
	1;
}

sub whole_number {
	my $tn = shift;
	return $tn->{intpref} . $tn->{prefix} . $tn->{telnum};
}

sub parse_number {
	my $tn = shift;
	my ($intpref, $prefix, $telnum);

    for (sort {length($b) <=> length($a)} keys %DATA) {
        $intpref = $_ and last if $tn =~ /^$_/;
    }
    
	unless ($intpref) {
		carp "No matching international prefix found";
		return (undef, undef, $tn);
	}
	
	$tn = substr($tn, length $intpref);

	for (sort { length($b) <=> length($a) } @{ $DATA{$intpref} }) {
		if ($tn =~ /^$_/) {
			$prefix = $_;
			$telnum = substr($tn, length);
			last;
		}
	}
	
	unless ($prefix) {
		carp "No matching mobile phone provider found";
		$telnum = $tn;
	}

	return ($intpref, $prefix, $telnum);
}

sub is_in {
	$_ = shift;
	for my $regexp (@_) {
		return 1 if (/^$regexp$/); 
	}
	return 0;
}


1;
