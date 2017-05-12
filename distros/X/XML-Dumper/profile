#! /usr/local/bin/perl

use XML::Dumper;
use Benchmark qw( timeit timestr );

print
	"This is a test to see how quickly XML::Dumper runs on your system. \n",
	"This will take a few minutes\n\n";

my $count = 100;
my $data = [];
my $timemax = 0;
my $timemin = 100;

for my $size ( qw( 1 10 20 50 100 200 500 1000 ))  {
	my $perl = [ map {{ id => $_, data => rand( 1000 ), uncertainty => rand( 100 ) }} ( 0 .. $size ) ];

	print "Testing XML of size: $size...";
	my $t = timeit( $count, sub {
			$xml	= pl2xml( $perl );
			$pl		= xml2pl( $xml );
		}
	);
	my $time = int( timestr( $t ))/$count;

	print timestr( $t ), " ($time each)\n";
	
	$timemax = $time > $timemax ? $time : $timemax;
	$timemin = $time < $timemin ? $time : $timemin;

	push @$data, {
		size	=> $size,
		time	=> $time,
		count	=> $count
	};
}

print "\n\n";

($timemax, $timemin) = ( log10( $timemax ), log10( $timemin ) );

my $range = $timemax - $timemin;
my $v_size = $range/20;
my $v_span = $timemax;

print "time (log s)\n";
while( $v_span >= $timemin ) {
	printf( "%8.4f (%4.2f) |", $v_span, 10**$v_span );
	foreach( @$data ) {
		print log10( $_->{ time } ) >= $v_span ? "*    " : "     ";
	}
	print "\n";
	$v_span -= $v_size;
}
print '-' x 80, "\n";
print "                 ";
foreach( @$data ) {
	printf( "%-4d ", $_->{ size } );
}
print "\n\n";

my @stats = reverse @$data;
my $first = shift @stats;
my $sum = $first->{ time }/$first->{ size };
my $count = 1;

foreach( @stats ) { 
	$time = $_->{ time } / $_->{ size };

	# Skip outliers
	next if( $time <= $sum * 0.5 || $time >= $sum * 2 );

	$sum += $time;
	$count++;
}

printf( "%-02.6f seconds per XML record size.\n\n", $sum/$count );

sub log10 {
	my $num = shift;
	return -2 if $num == 0;
	return log($num)/log(10);
}

__END__

=head1 NAME

profile.pl - test how quickly XML::Dumper runs on your system

