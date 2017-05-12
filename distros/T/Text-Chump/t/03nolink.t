use Test::More qw(no_plan);
use Text::Chump;


my $tc;

ok($tc = Text::Chump->new({ links => 0 }));


my $opt   = {};

while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	$out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in, $opt), $out);
	$opt->{links} = 1;
}


__END__
# images
[http://thegestalt.org]
[http://thegestalt.org]

[http://thegestalt.org]
<a href='http://thegestalt.org' >http://thegestalt.org</a>

