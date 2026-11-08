#!/usr/bin/perl

# RFC 6350 S3.4: only TEXT values are backslash-escaped; a URI value
# (PHOTO, URL, KEY, SOURCE, MEMBER, ...) is written as it is.

use strict;
use warnings;
use Test::More;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

my $png_b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEX/AAAZ4gk3'
            . 'AAAAAXRSTlN/gFy0ywAAAApJREFUeJxjYgAAAAYAAzY3fKgAAAAASUVORK5CYII=';
my $data_uri = "data:image/png;base64,$png_b64";

sub unfold { my $v = shift; $v =~ s/\r?\n[ \t]//g; return $v }

sub line_of {
  my ($vcf, $name) = @_;
  my @l = grep { /^\Q$name\E[;:]/i } split /\r?\n/, unfold($vcf);
  return wantarray ? @l : $l[0];
}

sub card {
  return {
    '@type' => 'Card', version => '1.0', uid => 'urn:uuid:uri-values-1',
    name => { full => 'Uri Test' },
    @_,
  };
}

subtest 'data: URI photo' => sub {
  my $vcf = jscontact_to_vcard(card(
    media => { m1 => { '@type' => 'Media', kind => 'photo', uri => $data_uri } },
  ));
  is(line_of($vcf, 'PHOTO'), "PHOTO;PROP-ID=m1:$data_uri", 'PHOTO written unescaped');
  unlike($vcf, qr/\\[;,]/, 'no backslash escapes anywhere');

  my $back = vcard_to_jscontact($vcf);
  is($back->{media}{m1}{uri}, $data_uri, 'uri round-trips');
  is($back->{media}{m1}{kind}, 'photo', 'kind round-trips');
};

subtest 'https URIs' => sub {
  my $url = 'https://example.com/a,b;c?x=1&y=2';
  my $vcf = jscontact_to_vcard(card(
    media => { m1 => { '@type' => 'Media', kind => 'logo', uri => $url, mediaType => 'image/png' } },
    links => { l1 => { '@type' => 'Link', uri => $url } },
    cryptoKeys  => { k1 => { '@type' => 'CryptoKey', uri => 'https://example.com/key;1' } },
    directories => { d1 => { '@type' => 'Directory', kind => 'entry', uri => 'https://example.com/dir,1' } },
    members     => { 'urn:uuid:a,b' => JSON::true },
  ));
  like(line_of($vcf, 'LOGO'), qr/^LOGO;[^:]*:\Q$url\E$/, 'LOGO unescaped');
  is(line_of($vcf, 'URL'), "URL;PROP-ID=l1:$url", 'URL unescaped');
  is(line_of($vcf, 'KEY'), "KEY;PROP-ID=k1:https://example.com/key;1", 'KEY unescaped');
  is(line_of($vcf, 'SOURCE'), "SOURCE;PROP-ID=d1:https://example.com/dir,1", 'SOURCE unescaped');
  is(line_of($vcf, 'MEMBER'), "MEMBER:urn:uuid:a,b", 'MEMBER unescaped');

  my $back = vcard_to_jscontact($vcf);
  is($back->{media}{m1}{uri}, $url, 'logo uri round-trips');
  is($back->{links}{l1}{uri}, $url, 'link uri round-trips');
  is($back->{cryptoKeys}{k1}{uri}, 'https://example.com/key;1', 'key uri round-trips');
  is($back->{directories}{d1}{uri}, 'https://example.com/dir,1', 'directory uri round-trips');
  ok($back->{members}{'urn:uuid:a,b'}, 'member round-trips');
};

subtest 'TEXT stays escaped' => sub {
  my $vcf = jscontact_to_vcard(card(
    notes => { n1 => { note => 'a,b;c\\d' } },
    # an IMPP with only a username is not a URI
    onlineServices => { o1 => { user => 'bob,smith' } },
  ));
  is(line_of($vcf, 'NOTE'), 'NOTE;PROP-ID=n1:a\\,b\\;c\\\\d', 'NOTE escaped');
  like(line_of($vcf, 'IMPP'), qr/:bob\\,smith$/, 'bare IMPP username escaped');
  my $back = vcard_to_jscontact($vcf);
  is($back->{notes}{n1}{note}, 'a,b;c\\d', 'note round-trips');
};

subtest 'a URI cannot end the line' => sub {
  my $vcf = jscontact_to_vcard(card(
    links => { l1 => { '@type' => 'Link', uri => "https://example.com/\\x\r\nX-INJECTED:1" } },
  ));
  is_deeply([ grep { /^X-INJECTED/i } split /\r?\n/, $vcf ], [], 'no injected line');
  is(line_of($vcf, 'URL'), 'URL;PROP-ID=l1:https://example.com/%5Cx%0AX-INJECTED:1',
     'backslash and newline percent-encoded');
};

subtest 'TEL;VALUE=uri preserved by patch_vcard' => sub {
  my $orig = "BEGIN:VCARD\r\nVERSION:4.0\r\nUID:urn:uuid:p1\r\nFN:P\r\n"
           . "TEL;VALUE=uri:tel:+1-555-0100;ext=1\r\nEND:VCARD\r\n";
  my $old = vcard_to_jscontact($orig);
  my $new = { %$old, media => { m1 => { '@type' => 'Media', kind => 'photo', uri => $data_uri } } };
  my $vcf = patch_vcard($orig, $old, $new);
  is(line_of($vcf, 'TEL'), 'TEL;VALUE=uri:tel:+1-555-0100;ext=1', 'TEL uri unescaped');
  is(line_of($vcf, 'PHOTO'), "PHOTO;PROP-ID=m1:$data_uri", 'patched PHOTO unescaped');
};

subtest 'legacy escaped URI still reads' => sub {
  my $card = vcard_to_jscontact("BEGIN:VCARD\r\nVERSION:4.0\r\nUID:x\r\nFN:L\r\n"
    . "PHOTO;PROP-ID=m1:data:image/png\\;base64\\,$png_b64\r\nEND:VCARD\r\n");
  is($card->{media}{m1}{uri}, $data_uri, 'escaped data: URI decoded');
};

subtest 'media with no uri' => sub {
  my $vcf = jscontact_to_vcard(card(
    media => { m1 => { '@type' => 'Media', kind => 'photo', blobId => 'Gabc', mediaType => 'image/png' } },
  ));
  is(scalar(() = line_of($vcf, 'PHOTO')), 0, 'no empty PHOTO written');
};

subtest 'vCard 3 inline photo' => sub {
  # how Cyrus stores a vCard 4 data: URI PHOTO
  my $card = vcard_to_jscontact("BEGIN:VCARD\r\nVERSION:3.0\r\nUID:x\r\nFN:V3\r\n"
    . "PHOTO;PROP-ID=m1;ENCODING=B;TYPE=PNG:$png_b64\r\nEND:VCARD\r\n");
  is($card->{media}{m1}{uri}, $data_uri, 'base64 kept as is, media type lower-cased');
  is($card->{media}{m1}{mediaType}, 'image/png', 'mediaType');
};

subtest 'vCard 3 inline photo with a TYPE list' => sub {
  # what Cyrus stores for a PHOTO that had both MEDIATYPE and a data: URI
  my $card = vcard_to_jscontact("BEGIN:VCARD\r\nVERSION:3.0\r\nUID:x\r\nFN:V3\r\n"
    . "PHOTO;PROP-ID=m1;TYPE=PNG,PNG;ENCODING=B:$png_b64\r\nEND:VCARD\r\n");
  is($card->{media}{m1}{uri}, $data_uri, 'one media type in the data: URI');
  is($card->{media}{m1}{mediaType}, 'image/png', 'mediaType is the first TYPE');
};

done_testing;
