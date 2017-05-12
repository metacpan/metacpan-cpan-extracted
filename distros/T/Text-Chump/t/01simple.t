use Test::More qw(no_plan);
use Text::Chump;


my $tc;

ok($tc = Text::Chump->new());

while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	$out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in), $out);
}


__END__
# urls
http://thegestalt.org
<a href='http://thegestalt.org/' >http://thegestalt.org</a>

foo
foo

# links
[http://thegestalt.org]
<a href='http://thegestalt.org' >http://thegestalt.org</a>


[gestalt|http://thegestalt.org]
<a href='http://thegestalt.org' >gestalt</a>

[http://thegestalt.org|gestalt]
<a href='http://thegestalt.org' >gestalt</a>


[[hello]|http://thegestalt.org]
<a href='http://thegestalt.org' >[hello]</a>

# pathological links
[foo|bar]
[foo|bar]

[foo]
[foo]

# images
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

# pathological images
+[foo|bar]
+[foo|bar]

+[foo]
+[foo]

+[foo|bar|quux]
+[foo|bar|quux]

# compound
hello there http://foobar.com [foo|http://bar.com]
hello there <a href='http://foobar.com/' >http://foobar.com</a> <a href='http://bar.com' >foo</a>


hello there http://foobar.com +[foo|http://bar.com]
hello there <a href='http://foobar.com/' >http://foobar.com</a> <img src='http://bar.com' alt='foo' title='foo' border='0' />

hello there http://foobar.com [foo|http://bar.com] quux +[foo|http://quux.org|http://bar.com] fleeg
hello there <a href='http://foobar.com/' >http://foobar.com</a> <a href='http://bar.com' >foo</a> quux <a href='http://quux.org' ><img src='http://bar.com' alt='foo' title='foo' border='0' /></a> fleeg



