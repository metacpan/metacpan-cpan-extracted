#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Text::YAWikiFormater' ) || print "Bail out!\n";
}

my $wiki = Text::YAWikiFormater->new(
		body	=> <<EoB,
{{toc}}

!! Internal Links

Link to page: [[Test]]

[[Link Title|LinkPage]]

Category Link: [[>MainCateg>Categ>Page]]

[[Page on Categ|>MainCateg>Categ>Page]]

SubCategory Link: [[Categ>Page]]

!! NameSpace Links

Wikipedia Link: [[wp:WikipediaPage]]

Wikipedia Portal: [[wp:Portal>Arts]]

!! External Links

[[Perl|http://www.perl.org]] is the best

See http://www.perl.org

EoB
	);

%links = $wiki->urls;

my $urls = scalar keys %links;

is($urls, 9, 'number of found URLs');

my $lnk = $links{'[[Test]]'};
is($lnk->{href}, 'test', 'link for page');
is($lnk->{title}, 'Test', 'title for page');

$lnk = $links{'[[Link Title|LinkPage]]'};
is($lnk->{href},'linkpage','link for page with title');
is($lnk->{title},'Link Title','Title for page with Title');

$lnk = $links{'[[Page on Categ|>MainCateg>Categ>Page]]'};
is($lnk->{href},'/maincateg/categ/page','Internal link from root with title');
is($lnk->{title},'Page on Categ','Title on link from root with Title');

$lnk = $links{'[[>MainCateg>Categ>Page]]'};
is($lnk->{href},'/maincateg/categ/page','Internal link from root, no title');
is($lnk->{title},'Page','Title on link from root, no Title');

$lnk = $links{'[[Categ>Page]]'};
is($lnk->{href},'categ/page','link to subcateg, no title');
is($lnk->{title},'Page','Title on link to subcateg, no Title');

# Wikipedia Links (Namespace)
$lnk = $links{'[[wp:WikipediaPage]]'};
is($lnk->{href},
		'http://en.wikipedia.org/WikipediaPage',
		'link to WikipediaPage');
is($lnk->{title},'WikipediaPage','Title on link to WikipediaPage');

$lnk = $links{'[[wp:Portal>Arts]]'};
is($lnk->{href},
		'http://en.wikipedia.org/Portal:Arts',
		'link to wikipedia portal, no title');
is($lnk->{title},'Arts','Title on link to wikipedia portal, no Title');

# Links to Perl
$lnk = $links{'[[Perl|http://www.perl.org]]'};
is($lnk->{href},'http://www.perl.org','link to perl.org with title');
is($lnk->{title},'Perl','Title on link to perl.org with title');

$lnk = $links{'http://www.perl.org'};
is($lnk->{href},'http://www.perl.org','link to perl.org no []');
is($lnk->{title},'http://www.perl.org','Title on link to perl.org no []');


done_testing();
