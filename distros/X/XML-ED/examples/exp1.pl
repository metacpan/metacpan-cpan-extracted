use XML::ED;
use Data::Dumper;
my $ed = XML::ED->new();

my $xml = $ed->parse(text => <<XML);
<bib>
  <book>
    <title>TCP/IP Illustrated</title>
    <author>Stevens</author>
    <publisher>Addison-Wesley</publisher>
  </book>
  <book>
    <title>Advanced Programming in the Unix Environment</title>
    <author>Stevens</author>
    <publisher>Addison-Wesley</publisher>
  </book>
  <book>
    <title>Data on the Web</title>
    <author>Abiteboul</author>
    <author>Buneman</author>
    <author>Suciu</author>
  </book>
</bib>
XML

# for $a in fn:distinct-values(book/author)
# return (book/author[. = $a][1], book[author = $a]/title)

sub distinct_values {
    return @_;
};

foreach my $a (distinct_values($xml->child('book')->child('author'))) {
   print $a->to_string();
}
