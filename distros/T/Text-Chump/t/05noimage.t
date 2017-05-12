use Test::More qw(no_plan);
use Text::Chump;


my $tc;

ok($tc = Text::Chump->new({images => 0 }));

my $opt = {};

while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	$out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in, $opt), $out);
	$opt->{images} = 1;
}


__END__
+[http://thegestalt.org|http://foobar.com|foo]
+[http://thegestalt.org|http://foobar.com|foo]

+[http://thegestalt.org|http://foobar.com|foo]
<a href='http://foobar.com' ><img src='http://thegestalt.org' alt='foo' title='foo' border='0' /></a>

