use Test::More qw(no_plan);
use Text::Chump;


my $tc;

ok($tc = Text::Chump->new({urls=>0, images=>0, links=>0, borders=>0}));

my $opt = {};
while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	$out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in, $opt), $out);
	$opt = {urls=>1, images=>1, links=>1, border=>1};
}


__END__
hello there http://foobar.com [foo|http://bar.com] quux +[foo|http://quux.org|http://bar.com] fleeg
hello there http://foobar.com [foo|http://bar.com] quux +[foo|http://quux.org|http://bar.com] fleeg


hello there http://foobar.com [foo|http://bar.com] quux +[foo|http://quux.org|http://bar.com] fleeg
hello there <a href='http://foobar.com/' >http://foobar.com</a> <a href='http://bar.com' >foo</a> quux <a href='http://quux.org' ><img src='http://bar.com' alt='foo' title='foo' border='1' /></a> fleeg



