###################################################
## Interval.pm		(Time::Interval)
## Andrew N. Hicox	<andrew@hicox.com>
## http://www.hicox.com
##
## a module for dealing with time intervals
###################################################


## Global Stuff ###################################
package	Time::Interval;
use	strict;
require	Exporter;

#class global vars ...
use vars qw($VERSION @EXPORT @ISA %intervals);
@ISA 		= qw(Exporter);
@EXPORT		= qw(&parseInterval &convertInterval &getInterval &coalesce);
$VERSION	= 1.233;
#what everything is worth in seconds
%intervals 	= (
	'days'		=> ((60**2) * 24),
	'hours'		=> (60 **2),
	'minutes'	=> 60,
	'seconds'	=> 1
);


## getInterval ####################################
sub getInterval {
	my $date1 = shift();
	my $date2 = shift();
	my $string = shift() || "";
	if ( (! $date1) || (! $date2) ){
		warn ("two dates are required for the getInterval method");
		return (undef);
	}
	require Date::Parse;
	foreach ($date1, $date2){
		$_ = Date::Parse::str2time($_) || do {
			warn ("failed to parse date: $!\n");
			return (undef);
		};
	}
	
	my %args = ( seconds => abs($date1 - $date2) );
	if ($string =~/^small/i){
		$args{'Small'} = 1;
	}elsif($string !~/^\s*$/){
		$args{'String'} = 1;
	}
	my $data = parseInterval(%args);
	return ($data);
}


## convertInterval ################################
#'days'		=> $num,
#'hours'	=> $num,
#'minutes'	=> $num,
#'seconds'	=> $num,
#'ConvertTo'	=> 'days'|'hours'|'minutes'|'seconds'
sub convertInterval {
	my %p = @_;
	#ConvertTo, default is seconds
	exists($p{'ConvertTo'}) || do {
		$p{'ConvertTo'} = "seconds";
		warn ("convertInterval: using default ConvertTo (seconds)") if $p{'Debug'};
	};
	#convert everything to seconds
	my $seconds = 0;
	foreach ("days","hours","minutes","seconds"){
		
		#new 1.233 hotness: quantize seconds.
		if ($_ eq "seconds"){ $p{$_} = int($p{$_}); }
		
		#as it were
		if (exists($p{$_})){ $seconds += ($intervals{$_} * $p{$_}); }
	}
	#send it back out into the desired output
	return (($seconds/$intervals{$p{'ConvertTo'}}));
}


## parseInterval ##################################
#'days'		=> $num,
#'hours'	=> $num,
#'minutes'	=> $num,
#'seconds'	=> $num,
sub parseInterval {
	my %p = @_;
	#convert everything to seconds
	my $seconds = convertInterval(%p);
	
	#new 1.233 hotness: quantize seconds.
	$seconds = int($seconds);
	
	#do the thang
	my %time = (
		'days'		=> 0,
		'hours'		=> 0,
		'minutes'	=> 0,
		'seconds'	=> 0
	);
	while ($seconds > 0){
		foreach ("days","hours","minutes","seconds"){
			if ($seconds >= $intervals{$_}){
				$time{$_} ++;
				$seconds  -= $intervals{$_};
				last;
			}
		}
	}
	#return data
        if ($p{'Small'} && $p{'Small'} != 0) {
		#return a string?
		my @temp = ();
		foreach ("days","hours","minutes","seconds"){
			if ($time{$_} > 0){
				push (@temp, "$time{$_}".substr($_,0,1));
			}
		}
        return join (" ", @temp) || "0s";
	}elsif ($p{'String'} && $p{'String'} != 0){
		#return a string?
		my @temp = ();
		foreach ("days","hours","minutes","seconds"){
			if ($time{$_} > 0){
                          if ($time{$_} == 1) {
				push (@temp, "$time{$_} ".substr($_,0,-1));
                              } else {
				push (@temp, "$time{$_} $_");
                              }
			}
		}
		return (join (", ", @temp)) || "0 seconds";
	}else{
		#return a data structure
		return (\%time);
	}	
}


## coalesce #######################################
#coalesce([ [$start1, $end1], [$start2, $end2] ... ])
sub coalesce {
	require Date::Parse;
	my $intervals = shift() || [];
	my %epoch_map = ();
	my ($flag, $repeat) = (0,1);
	
	#convert each start / end to an epoch pair and stash 'em in epoch_map
	foreach my $int (@{$intervals}) {
		foreach (@{$int}){
			
			## only convert if it's not already epoch time
			my $epoch = "";
			if ($_ =~/^(\d{10})$/){
				$epoch = $1;
			}else{
				my $epoch = Date::Parse::str2time($_);
			}
			$epoch_map{$epoch} = $_;
			$_ = $epoch;
		}
	}

	#sort 'em by start time
	@{$intervals} = sort { $a->[0] <=> $b->[0] } @{$intervals};
	
	#flatten 'em
	while ($repeat == 1) {
		@{$intervals} = sort {
			#if it's not an array ref, it's been destructo'd
			if ( (ref($a) eq "ARRAY") && (ref($b) eq "ARRAY") ){
			
				#if b is inside a
				if (($b->[0] >= $a->[0]) && ($b->[0] <= $a->[1])){
					#if b's end time is greater than a's, update a's end time
					if ($b->[1] > $a->[1]){ $a->[1] = $b->[1]; }
					#destructo b
					$b = ();
					$flag = 1;
					return (1);
				#if a is inside b
				}elsif (($a->[0] >= $b->[0]) && ($a->[0] <= $b->[1])){
					#if a's end time is greater than b's, update b's end time
					if ($a->[1] > $b->[1]){ $b->[1] = $a->[1]; }
					#destructo a
					$a = ();
					$flag = 1;
					return (0);
				}else{
					return (0);
				}
		
			}else{
				return (1);
			}
	
		} @{$intervals};
	
		#weed out null elements
		my $i = 0;
		foreach (@{$intervals}){
			if ( ref($_) ne "ARRAY" ){ splice (@{$intervals}, $i, 1); }
			$i ++;
		}
		
		#decide wether or not to repeat
		if ($flag == 1){ 
			$repeat = 1;  
			$flag = 0;
		}else{ 
			$repeat = 0;
		}
	}
	
	#replace the epoch's with their time string equivalents
	foreach my $pair (@{$intervals}){
		if ( ref($pair) eq "ARRAY"){
			foreach (@{$pair}){ $_ = $epoch_map{$_}; }
		}
	}
	
	#weed out any remaining bum elements
	my $i = 0;
	foreach (@{$intervals}){
		unless (ref($_) eq "ARRAY"){ splice (@{$intervals}, $i, 1); }
		$i ++;
	}
	return ($intervals);
}
