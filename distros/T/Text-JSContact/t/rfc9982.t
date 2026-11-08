#!/usr/bin/perl
# RFC 9982: JSContact version 2.0, in which uid is optional.
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $with = vcard_to_jscontact("BEGIN:VCARD\nVERSION:4.0\nUID:urn:uuid:a1\nFN:Ann\nEND:VCARD\n");
is($with->{version}, '2.0', 'S3: a Card is created as version "2.0"');
is($with->{uid}, 'urn:uuid:a1', 'a vCard UID becomes the uid');

# S5: converting a vCard without UID to version 2.0 MUST NOT generate one
my $without = vcard_to_jscontact("BEGIN:VCARD\nVERSION:4.0\nFN:Bob\nEND:VCARD\n");
is($without->{version}, '2.0', 'version "2.0"');
ok(!exists $without->{uid}, 'S5: no UID in the vCard, no uid in the Card');
is_deeply(vcard_to_jscontact("BEGIN:VCARD\nVERSION:4.0\nFN:Bob\nEND:VCARD\n"), $without,
          'so the same vCard converts to the same Card every time');

# S3: a Card without uid is valid, and converts to a vCard without UID
my $vcf = jscontact_to_vcard({ '@type' => 'Card', version => '2.0', name => { full => 'Cy' } });
like($vcf, qr/^FN:Cy\r?$/m, 'a Card without uid converts');
unlike($vcf, qr/^UID/m, 'and the vCard has no UID');

# a version 1.0 Card (which always has a uid) still converts
like(jscontact_to_vcard({ '@type' => 'Card', version => '1.0', uid => 'urn:uuid:d1', name => { full => 'Di' } }),
     qr/^UID:urn:uuid:d1\r?$/m, 'a version "1.0" Card keeps its UID');

done_testing;
