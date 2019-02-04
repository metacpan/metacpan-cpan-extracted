#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Win32::Backup::Robocopy;
#perl -E "map{ say $_.(/[^.]+\.{1}[^.]+/ || /[^.]+\.{3}/ ?' NO':' OK')}@ARGV" 
#"1,3..5,8....9" "1...3" "1.2" "1,3,5..8,9.70" "1..3" "1..3,4..6,8...10"

# invalid ranges - not permitted chars and sequences
foreach my $no ( 'x','3x','3-4', '1..3,4.4', '1..3,4...6','1.3','1...3'){
	dies_ok { Win32::Backup::Robocopy::_validrange($no) } "invalid range [$no]";
}

# invalid ranges - $1 > $2
foreach my $no2 ('3..1,7..9','1..4,7..5','3..4, 7..5','0..2,27..5'){
	dies_ok { Win32::Backup::Robocopy::_validrange($no2) } "invalid reverse range [$no2]";
}

# valid ranges
foreach my $ok ('1..3','1,3..5','1,3..5,7'){
	ok(Win32::Backup::Robocopy::_validrange($ok),"valid range string [$ok]");
}

# valid ranges array
# NO! _validrange ONLY ACCEPTS STRING! runjobs transform an
# eventual array into a string
# ok(Win32::Backup::Robocopy::_validrange(1..3),"valid range array (1..3)");
# ok(Win32::Backup::Robocopy::_validrange(1,2..4,9),"valid range array (1,2..4,9)");
# ok(Win32::Backup::Robocopy::_validrange(9,0..3),"valid range array (9,0..3)");

my %test = (
	'1,1..3'	=> [(1,2,3)],
	'1,2..5,4'	=> [(1,2,3,4,5)],
	'1..5,3'	=> [(1,2,3,4,5)],
	'8,9,1..2'	=> [(1,2,8,9)],
	# overlapped ranges silently corrected
	'1..3,3,5..7'	=> [(1,2,3,5,6,7)],
	'5..7,1..6'		=> [(1,2,3,4,5,6,7)],
	'0..5,3'		=> [(0,1,2,3,4,5)]
);

# ranges, even if overlapped, return the correct array
foreach my $range ( keys %test ){
	my @res = Win32::Backup::Robocopy::_validrange($range);
	is_deeply( $test{$range},\@res,
				"correct result for range [$range]"
	);
}
