use Test::More qw(no_plan);
use Text::Chump;


my $tc;

ok($tc = Text::Chump->new({ border => 1 }));


my $opt   = {};
my $count = 0;

while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	$out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in, $opt), $out);
	$opt->{border} = 0 if (++$count>5);
}


__END__
# images
+[http://thegestalt.org]
<img src='http://thegestalt.org' alt='http://thegestalt.org' title='http://thegestalt.org' border='1' />

+[http://thegestalt.org|foo]
<img src='http://thegestalt.org' alt='foo' title='foo' border='1' />

+[foo|http://thegestalt.org]
<img src='http://thegestalt.org' alt='foo' title='foo' border='1' />

+[http://thegestalt.org|bar|foo]
<img src='http://thegestalt.org' alt='foo' title='foo' border='1' />

+[http://thegestalt.org|http://foobar.com|foo]
<a href='http://foobar.com' ><img src='http://thegestalt.org' alt='foo' title='foo' border='1' /></a>

+[foo|http://foobar.com|http://thegestalt.org]
<a href='http://foobar.com' ><img src='http://thegestalt.org' alt='foo' title='foo' border='1' /></a>

+[http://thegestalt.org]
<img src='http://thegestalt.org' alt='http://thegestalt.org' title='http://thegestalt.org' border='0' />

+[http://thegestalt.org|foo]
<img src='http://thegestalt.org' alt='foo' title='foo' border='0' />

+[foo|http://thegestalt.org]
<img src='http://thegestalt.org' alt='foo' title='foo' border='0' />

+[http://thegestalt.org|bar|foo]
<img src='http://thegestalt.org' alt='foo' title='foo' border='0' />

+[http://thegestalt.org|http://foobar.com|foo]
<a href='http://foobar.com' ><img src='http://thegestalt.org' alt='foo' title='foo' border='0' /></a>

+[foo|http://foobar.com|http://thegestalt.org]
<a href='http://foobar.com' ><img src='http://thegestalt.org' alt='foo' title='foo' border='0' /></a>

