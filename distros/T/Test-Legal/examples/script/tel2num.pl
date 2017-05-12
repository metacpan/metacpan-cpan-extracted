#!/usr/bin/env perl
# Copyright (C) 2011, Ioannis
use strict; use warnings;
use 5.010000;
use Scalar::Util qw/ looks_like_number /;
use Getopt::Compact;
use Data::Dumper;
use Telephone::Mnemonic::US qw/ to_num to_words printthem/ ;
use Tie::DictFile;


my $o = (new Getopt::Compact modes  => [qw( debug )],
	                         args   => 'number | word',
	                         struct => [ [ [qw(t timeout)], 'timeout',],
			])-> opts;

# Options
my $timeout = $o->{timeout} || 0;
my $input = shift || die "Usage: $0 -h";
#'202-468-8442';
exit unless $input;
#$input = '468-8442';
#$input = '724 4898';



given ($0) {
	when (/tel_mnemonic/)  { 
							  #die "\n" unless $input =~ /^ \d+ $/ox;
							  die "numbers containing 0's or 1's never map\n" if $input =~ /[01]/ox;
	                           my $res = to_words($input,$timeout) ;
                               printthem( $input, $res ) if $res;
	                       }
	when (/tel2num/)       { 
	                          my $res = to_num($input) || ''; 
							  say $input . ' -> '. $res ;
	                       }
	default:        warn "should not happen. check for proper filenames\n";
}

#say looks_like_number $input_tmp;
#my $res  =  looks_like_number($input_tmp) ? to_words($input) : to_num($input);



# to_num 
