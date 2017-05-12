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
my $str = join('', <DATA>);
$p->parse_string($str);
ok($output);
print "$output\n";
ok($output, qr/<wiki>.*<\/wiki>/s, "Matches basic wiki outline");

__DATA__

Some Wiki text.

With '' some quotes
