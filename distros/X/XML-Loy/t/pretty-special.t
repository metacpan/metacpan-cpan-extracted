#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 24;

my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('test'), 'Constructor String');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test />
PP


ok($xml = XML::Loy->new('feed'), 'New constructor');

ok(my $html = $xml->add('html' => { -type => 'escape' }), 'Encoded html');
ok($html->add(h1 => { style => 'color: red' } => 'I start blogging!'), 'Add html');
ok($html->add(p => 'What a great idea!')->comment('First post'), 'Add html');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<feed>
  <html>
    &lt;h1 style=&quot;color: red&quot;&gt;I start blogging!&lt;/h1&gt;

    &lt;!-- First post --&gt;
    &lt;p&gt;What a great idea!&lt;/p&gt;
  </html>
</feed>
PP

ok($xml = XML::Loy->new('entry'), 'New constructor');
ok($xml->add('text' => '><><'), 'Encoded html');
ok($xml->add('text' => { -type => 'escape' } => '><><'), 'Encoded html');

ok($html = $xml->add('text' => { -type => 'escape' } => '><><'),
   'Encoded html');

ok($html->add('Inner'), 'Added tag');

my $string = $xml->to_pretty_xml;
$string =~ s/\s//g;

is("$string\n", <<'PP', 'Pretty Print');
<?xmlversion="1.0"encoding="UTF-8"standalone="yes"?><entry><text>&gt;&lt;&gt;&lt;</text><text>&gt;&lt;&gt;&lt;</text><text>&amp;gt;&amp;lt;&amp;gt;&amp;lt;&lt;Inner/&gt;</text></entry>
PP

ok(my $plain = XML::Loy->new(<<'PLAIN'), 'Plain');
<entry>There is <b>no</b> pretty printing</entry>
PLAIN

ok($xml = XML::Loy->new('entry'), 'Constructor');
ok(my $text = $xml->add('text' => { -type => 'raw' }), 'Add raw');
ok($text->add($plain), 'Add Plain');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<entry>
  <text><entry>There is <b>no</b> pretty printing</entry>
</text>
</entry>
PP

ok($xml = XML::Loy->new('entry'), 'Constructor');
ok(my $data =
     $xml->add(
       data => {
	 type  => 'text/plain',
	 -type => 'armour:30'
       } => <<'B64'), 'Add base64');
    VGhpcyBpcyBqdXN0IGEgdGVzdCBzdHJpbmcgZm
    9yIHRoZSBhcm1vdXIgdHlwZS4gSXQncyBwcmV0
    dHkgbG9uZyBmb3IgZXhhbXBsZSBpc3N1ZXMu
B64

ok($data->comment('This is base64 data!'), 'Comment');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<entry>

  <!-- This is base64 data! -->
  <data type="text/plain">
    VGhpcyBpcyBqdXN0IGEgdGVzdCBzdH
    JpbmcgZm9yIHRoZSBhcm1vdXIgdHlw
    ZS4gSXQncyBwcmV0dHkgbG9uZyBmb3
    IgZXhhbXBsZSBpc3N1ZXMu
  </data>
</entry>
PP

is($xml->to_pretty_xml(2), <<'PP', 'Pretty Print');
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <entry>

      <!-- This is base64 data! -->
      <data type="text/plain">
        VGhpcyBpcyBqdXN0IGEgdGVzdCBzdH
        JpbmcgZm9yIHRoZSBhcm1vdXIgdHlw
        ZS4gSXQncyBwcmV0dHkgbG9uZyBmb3
        IgZXhhbXBsZSBpc3N1ZXMu
      </data>
    </entry>
PP
