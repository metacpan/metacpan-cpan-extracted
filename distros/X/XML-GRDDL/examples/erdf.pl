use XML::GRDDL;
use LWP::Simple;
use RDF::TrineX::Functions -shortcuts;

my $grddl = XML::GRDDL->new();
my $url   = 'http://example.com/document.html';
my $html  = <<'HTML';
<html xmlns="http://www.w3.org/1999/xhtml">
  <head profile="http://purl.org/NET/erdf/profile">
    <title>Homepage</title>
    <base href="http://example.org/about" />
    <link rel="schema.foaf" href="http://xmlns.com/foaf/0.1/" />
  </head>
  <body>
    <p id="ian"><a rel="foaf.homepage" href="http://example.org/home">my home page</a></p>
  </body>
</html>
HTML

my $r = $grddl->data($html, $url, force_rel=>1, metadata=>1);
print rdf_string($r, 'nquads');
