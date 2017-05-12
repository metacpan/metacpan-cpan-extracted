#!perl

use Test::More tests => 7;

BEGIN {
	use_ok( 'WWW::Mechanize::Meta' );
	use_ok( 'Data::Dumper' );
}
my $mech=WWW::Mechanize::Meta->new();
$mech->get('http://search.cpan.org');
my @rss=$mech->link('alternate');
ok(@rss);
like($rss[0]->{href},qr~\Qhttp://search.cpan.org/\E~);
$mech->get('http://kostenko.name');
@rss = $mech->rss;
ok(scalar(@rss));
$mech->get('http://plod.popoever.com');
@rss=$mech->rss;
ok(@rss);
like($rss[0]->{href},qr~\Qhttp://feeds.feedburner.com/Plod\E~);
