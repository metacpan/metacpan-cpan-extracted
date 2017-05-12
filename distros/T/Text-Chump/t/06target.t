use Test::More qw(no_plan);
use Text::Chump;
use strict;

my $tc;

ok($tc = Text::Chump->new( { target => '_blank' } ));

my $opt = {};
my $count=0;

while (my $in = <DATA>) {
	next if $in =~ /^\s*$/;
	next if $in =~ /^#/;
	my $out = <DATA>;
	print "$in\n\n";
	chomp($in);
	chomp($out);
	is($tc->chump($in, $opt), $out);
	$opt->{target} = '_parent' if (++$count==2);
	
}


__END__
# urls
http://thegestalt.org
<a href='http://thegestalt.org/'  target='_blank'>http://thegestalt.org</a>

[http://thegestalt.org]
<a href='http://thegestalt.org'  target='_blank'>http://thegestalt.org</a>

http://thegestalt.org
<a href='http://thegestalt.org/'  target='_parent'>http://thegestalt.org</a>

[http://thegestalt.org]
<a href='http://thegestalt.org'  target='_parent'>http://thegestalt.org</a>


