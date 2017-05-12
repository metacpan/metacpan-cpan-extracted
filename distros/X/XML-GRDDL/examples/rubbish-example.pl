use XML::GRDDL;
use LWP::Simple;
use RDF::TrineX::Functions -shortcuts;

my $grddl = XML::GRDDL->new();
my $data  = {};
foreach my $url (qw(http://localhost/test/grddl/document.html
	http://localhost/test/grddl/document2.html
	http://localhost/test/grddl/ease.html
	http://www.w3.org/TR/grddl-primer/hotel-data.html))
{
	print "#### URL: $url\n";
	my $r = $grddl->data(get($url), $url, force_rel=>1, metadata=>1);
	print rdf_string($r, 'nquads');
}
