use Test;
BEGIN { plan tests => 3 }
use Text::WikiFormat::SAX;
use XML::SAX::Writer;

my $output = '';
my $p = Text::WikiFormat::SAX->new(
            Handler => XML::SAX::Writer->new(
                Output => \$output
                )
            );

ok($p);
$p->parse_uri("t/file.wiki");
ok($output);
print "$output\n";
ok($output, qr/<wiki>.*<\/wiki>/s, "Matches basic wiki outline");

