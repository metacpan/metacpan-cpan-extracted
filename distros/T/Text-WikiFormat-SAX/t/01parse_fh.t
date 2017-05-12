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
$_ = <DATA>;
$p->parse_file(\*DATA);
ok($output);
print "$output\n";
ok($output, qr/<wiki>.*<\/wiki>/s, "Matches basic pod outline");

__DATA__

Some text.

Some more text and a LinkHere
