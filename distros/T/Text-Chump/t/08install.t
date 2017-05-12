use Test::More qw(no_plan);
use Text::Chump;

my $tc;

ok($tc = Text::Chump->new());


ok($tc->install('image',\&one));

ok($tc->install('link',\&two));

ok($tc->install('url',\&three));

ok($tc->install('link',\&four,'^\d+$'));

ok($tc->install('image',\&five,'simon wistow'));

ok($tc->install('url',\&six,'simon wistow'));

ok($tc->install('link',\&seven,'aaaa'));

ok($tc->install('link',\&eight,'aaaaa'));




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

sub one  {
	my ($opt, $url, $alt, $link) = @_;
	
	if (defined $link) {
		return "$alt = $link";
	} else {
		return "bar";
	}
}

sub two {
	my ($opt, $url, $text) = @_;
	return uc($url);
}

sub three {
	my ($opt, $text) = @_;
	$text =~ s/./a/g;
	
	return $text;
}

sub four {
	my ($opt, $match, $text) = @_;
	return "$text=blog.cgi?$match";

}

sub five {
	my ($opt, $match, $text) = @_;

	return sprintf "%s=%s",lc($text),uc($match);
}

sub six {
	my ($opt, $token) = @_;
		
	$token =~  s/simon wistow/muttley/;
		
	return $token;
}

sub seven {
	my ($opt, $match) = @_;
	return reverse $match;
}

sub eight {
	return "nation";
}

__END__
+[http://quirka.org]
bar

+[foo|http://foo.com|http://quirka.org]
foo = http://foo.com


[http://foo.com]
HTTP://FOO.COM

[foo|http://bar.com]
HTTP://BAR.COM


foo http://fleeg.gov noo
aaaaaaaaaaaaaaaaaaaaaaaa

[foo|4444]
foo=blog.cgi?4444

+[simon wistow|FOO]
foo=SIMON WISTOW


[test|other side aaaa foo]
oof aaaa edis rehto

[test|aaaaa quirk]
nation
