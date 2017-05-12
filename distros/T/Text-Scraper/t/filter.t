use Test;
use lib '../lib';

BEGIN { plan tests => 6 }

use Text::Scraper;
ok(1); 

my $tmpl = Text::Scraper->slurp(\*DATA);
my $src  = Text::Scraper->slurp("$0.html");
my $obj  = Text::Scraper->new(tmpl => $tmpl);
my $data = $obj->scrape($src);

ok(scalar(@$data) == 2);
ok($data->[0]{result} eq "HIT");
ok($data->[0]{email}  eq "asfasfsf");
ok($data->[1]{result} eq "HIT");
ok($data->[1]{email}  eq "12345678");

__DATA__

<tr>
    <td><?tmpl var result regex="(\w+)" ?></td><td><?tmpl var email regex="(?:([\w\d]+?)\@foo\.com)" ?></td>
</tr>
