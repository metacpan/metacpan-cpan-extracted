#!perl

my %i = (
	 Arrays => {
		    speed => 'fastest',
		    flex => 'so-so',
		    scales => 'not good',
		    memory => 'min',
		    order => 'yes',
		   },
	 Hashes => {
		    speed => 'fast',
		    flex => 'good',
		    scales => 'so-so',
		    memory => 'good',
		    order => 'no',
		   },
	 'B-Trees' => {
		    flex => 'silly',
		    scales => 'big',
		    speed => 'medium',
		    memory => 'good',
		    order => 'yes'
		   },
);

format STDOUT_TOP =
 TYPE       Speed       Flexibility  Scales     Memory   Keeps-Order
 ---------- ----------- ------------ ---------- -------- ------------
.
format STDOUT =
 @<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<  @<<<<<<<<  @<<<<<   @<<<<<<
$type,         $speed,    $flex,  $scale, $memory, $order
.

for my $t (qw/Arrays Hashes B-Trees/) {
    my $s = $i{$t};
    ($type,$flex,$memory,$order,$scale,$speed) = 
	($t, map { $s->{$_} } qw(flex memory order scales speed));
    write;
}
