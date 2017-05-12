# vim: set ft=perl :

use strict;
use Test::More tests => 6;
use Tie::Simple;

my $reader = "foo\nbar\nbaz\nqux\n";
open my $in, "<", \$reader or die $!;

my $writer = '';
open my $out, ">", \$writer or die $!;

tie *X, 'Tie::Simple', \$in,
	READ     => sub { 
		my $a = shift; 
		my $buf; 
		my (undef, $len, $off) = @_; 
		my $res = read $$a, $buf, $len, $off || 0;
   		$_[0] = $buf;
		return $res	
	},
	READLINE => sub { my $a = shift; readline $$a },
	GETC     => sub { my $a = shift; getc $$a },
	CLOSE    => sub { my $a = shift; close $$a };

tie *Y, 'Tie::Simple', \$out,
	WRITE  => sub { my ($a, $b, $l, $o) = @_; print $$a (substr $b, $o || 0, $l) },
	PRINT  => sub { my $a = shift; print $$a (@_) },
	PRINTF => sub { my $a = shift; printf $$a (@_) },
	CLOSE  => sub { my $a = shift; close $$a };

my $buf;
read X, $buf, 4;
is($buf, "foo\n", 'READ');
$buf = readline X;
is($buf, "bar\n", 'READLINE');
$buf = getc X;
is($buf, 'b', 'GETC');
ok(close X, 'CLOSE');

$buf = "foo\nbar\n";
syswrite Y, $buf, 4;
print Y "baz\n";
printf Y "%d %s\n", 10, 'qux';
ok(close Y, 'CLOSE');

is($writer, "foo\nbaz\n10 qux\n", 'WRITE/PRINT/PRINTF');
