use Test::More tests => 57;
use Test::Exception;
use strict;
use warnings;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}

END {
}

my $m;
ok($m = $TL->newMail, 'newMail');
ok($m->get, 'get');
ok($m->set(q{日本語}), 'set');

ok($m->_encodeHeader(q{Subject: 日本語 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa}), '_encodeHeader');
ok($m->_encodeHeader(q{aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa}), '_encodeHeader');
ok($m->_encodeHeader(q{日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語}), '_encodeHeader');
ok($m->_encodeHeader(q{Subject: 日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語 日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語日本語}), '_encodeHeader');


ok($m->parse("From: =?ISO-2022-JP?B?GyRCOjk9UD9NGyhC?=\r\n".
               " =?ISO-2022-JP?B?IA==?=<null\@example.org>\r\n".
               "To: =?ISO-2022-JP?B?GyRCOjk9UD9NGyhC?=\r\n".
               " =?ISO-2022-JP?B?IA==?=<null\@example.org>\r\n".
               "Subject: =?ISO-2022-JP?B?GyRCJWEhPCVrN29MPhsoQg==?=\r\n".
               "\r\n".
               "mail body"), 'parse');

ok($m->set(q{Subject: 日本語ヘッダ
Content-Type: multipart/alternative; boundary="aaaa"
Content-Transfer-Encoding: quoted-printable

--aaaa
Content-Type: text/plain; charset=iso-2022-jp

--aaaa
Content-Type: text/html; charset=iso-2022-jp

--aaaa--
}), 'set');

ok($m->set(q{Subject: 日本語ヘッダ
Content-Type: multipart/alternative; boundary="aaaa"
Content-Transfer-Encoding: 7bit

--aaaa
Content-Type: text/plain; charset=iso-2022-jp

--aaaa
Content-Type: text/html; charset=iso-2022-jp

--aaaa--
}), 'set');

dies_ok {$m->set(q{Subject: 日本語ヘッダ
Content-Type: multipart/alternative; boundary="aaaa"

--bbbb
Content-Type: text/plain; charset=iso-2022-jp

--bbbb
Content-Type: text/html; charset=iso-2022-jp

--bbbb--
})} 'set die';

ok($m->set(q{Subject: 日本語ヘッダ

本文
}), 'set');

like($m->get, qr/Subject: 日本語ヘッダ/, 'get');
ok($m->get, 'get');


my %hash;
ok($m->setHeader(\%hash), 'setHeader');
dies_ok {$m->setHeader(\123)} 'setHeader die';
ok($m->setHeader(From => '日本語 <null@example.org>'), 'setHeader');

is($m->getHeader('Test'), undef, 'getHeader');
is($m->getHeader('From'), '日本語 <null@example.org>', 'getHeader');

$m->setHeader(Foo => 'テスト');
ok($m->deleteHeader('Foo'), 'deleteHeader [1]');
is($m->getHeader('Foo'), undef, 'deleteHeader [2]');

is($m->getBody, "本文\r\n", 'getBody');
ok($m->setBody("BODY"), 'setBody');
ok($m->toStr, 'toStr');


#dies_ok {$m->attach} 'attach die';
my $m2;
$m2 = $TL->newMail;

dies_ok {$m2->attach(
    type => undef,
   )} 'attach die';
dies_ok {$m2->attach(
    type => \123,
   )} 'attach die';
dies_ok {$m2->attach(
    type => 'text/plain',
    data => undef,
   )} 'attach die';
dies_ok {$m2->attach(
    type => 'text/plain',
    data => \123,
   )} 'attach die';

dies_ok {$m2->attach(
    part => \123,
   )} 'attach die';

ok($m2->attach(
    part => $TL->newMail,
   ), 'attach');

$m2->setHeader('Content-Type' => 'plain/text');
ok($m2->attach(
    part => $TL->newMail->setHeader('Content-Disposition' => 'inline'),
   ), 'attach');

ok($m2->attach(
    part => $TL->newMail,
   ), 'attach');

ok($m2->attach(
    type => 'text/html',
    data => 'MULTIPART',
   ), 'attach');

ok($m2->attach(
    type => 'application/xhtml+xml',
    data => 'MULTIPART',
   ), 'attach');

$m2->deleteHeader('Content-Type');
ok($m2->attach(
    type => 'text/html',
    data => 'MULTIPART',
   ), 'attach');

$m2->deleteHeader('Content-Type');
ok($m2->attach(
    type => 'application/xhtml+xml',
    data => 'MULTIPART',
    encoding => '7bit',
   ), 'attach');

ok($m2->attach(
    type => 'text/plain',
    data => 'MULTIPART',
    encoding => '7bit',
   ), 'attach');

ok($m2->attach(
    type => 'text/hdml',
    data => 'MULTIPART',
    filename => 'filename',
    id => 'content-id',
   ), 'attach');

ok($m2->attach(
    type => 'text/x-hdml',
    data => 'MULTIPART',
    encoding => 'base64',
   ), 'attach');

ok($m2->attach(
    type => 'etc',
    data => 'MULTIPART',
   ), 'attach');

ok($m2->attach(
    type => 'etc',
    data => 'MULTIPART',
    encoding => 'base64',
   ), 'attach');

ok($m->attach(
    type => 'text/plain',
    data => 'MULTIPART',
   ), 'attach');


is($m->countParts, 1, 'countParts');

my $child;
ok($child = $m->getPart(0), 'getPart');
dies_ok {$m->getPart} 'getPart die';
dies_ok {$m->getPart(\123)} 'getPart die';
dies_ok {$m->getPart(123)} 'getPart die';

is($child->getBody, 'MULTIPART', 'getBody(child)');

ok($m->deletePart(0), 'deletePart');
dies_ok {$m->deletePart} 'deletePart die';
dies_ok {$m->deletePart(\123)} 'deletePart die';
dies_ok {$m->deletePart(-1)} 'deletePart die';
dies_ok {$m->deletePart(500000)} 'deletePart die';

is($m->countParts, 0, 'countParts (after delete)');

my $filename_mail_str = q{Subject: This is a test mail...
To: null@example.org
From: null@example.org
Content-Type: multipart/alternative; boundary="----------=_1256691457-15882-0"
Date: Wed, 28 Oct 2009 09:57:37 +0900
Message-Id: <0.1256691457.15882.tmmlib7@rd8>
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit

This is a multi-part message in MIME format...

------------=_1256691457-15882-0
Content-Type: text/html;
 charset="ISO-2022-JP"
Content-Disposition:
 inline
Content-Transfer-Encoding: 7bit

1234567890
------------=_1256691457-15882-0
Content-Type: application/octet-stream;
 name="test.dat"
Content-Disposition: inline;
 filename="test.dat"
Content-Transfer-Encoding: base64

AAECAwQFBgcICQo=

------------=_1256691457-15882-0--

};
$filename_mail_str =~ s/\n/\r\n/g;

my $filename_mail = $TL->newMail->parse($filename_mail_str);
ok($filename_mail->countParts == 2, 'getFilename (1)');
ok(!defined($filename_mail->getPart(0)->getFilename), 'getFilename (1)');
ok($filename_mail->getPart(1)->getFilename eq 'test.dat', 'getFilename (2)');




