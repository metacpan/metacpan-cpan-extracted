use Test;
BEGIN { plan tests => 4 }
use Pod::SAX;
use XML::Filter::EzPod;
use XML::SAX::Writer;

my $output = '';
my $p = Pod::SAX->new(
            Handler => XML::Filter::EzPod->new(
                Handler => XML::SAX::Writer->new(
                    Output => \$output
                )
            )
        );

ok($p);
my $str = join('', <DATA>);
ok($str, qr/=head1.*END/s, "Read DATA ok");
$p->parse_string($str);
ok($output);
print "$output\n";
ok($output, qr/<pod>.*<\/pod>/s, "Matches basic pod outline");

__DATA__

=head1 NAME

SomePod - Some Pod to parse

* A bullet
* Point
** With extra levels
   and continuation data
** Going
*** Up
** and
* Down with B<bold text> here.
** And up again

END
