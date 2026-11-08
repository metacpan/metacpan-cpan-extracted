#!/usr/bin/perl

# Round trip of a corpus of real-world vCards: read -> write -> read must give
# back the first Card, and the written vCard must still carry every property
# of the original.  This is the safety net for moving reader, writer and
# patch_vcard onto one mapping table: every known failure is a TODO with the
# reason, so `prove` stays green but the gap stays visible, and a TODO that
# starts passing shows up as "unexpectedly succeeded".
#
# The corpus is t/data/vcard/*.vcf.  vcard_to_jscontact takes the bytes of a
# vCard (as read from a CardDAV server), jscontact_to_vcard returns a
# character string, so the written vCard is UTF-8 encoded before it is read
# back, as it would be on the wire.

use strict;
use warnings;
use Test::More;
use Encode qw(encode_utf8);
use Text::VCardFast qw(vcard2hash);

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $DIR = 't/data/vcard';

sub slurp {
  my ($file) = @_;
  open my $fh, '<:raw', $file or die "$file: $!";
  local $/;
  return scalar <$fh>;
}

# Reasons shared by several files
my $LABEL  = 'X-ABLabel only written for emails and phones (_add_label: lib/Text/JSContact.pm:1161,1190)';
my $ABDATE = 'custom X-ABDATE label read as an Anniversary kind (lib:558), written as ANNIVERSARY (lib:1286), read back as wedding (lib:531)';
my $KIND   = 'KIND:individual is not written (lib:986), so it does not come back';
my $PHON   = 'phoneticComponents never written: _unconvert_name ignores them (lib:1088-1136)';

# "file key" => reason: a top-level Card property that does not survive
# read -> write -> read
my %TODO_KEY = (
  'apple-ios-person.vcf anniversaries'  => $ABDATE,
  'apple-ios-person.vcf links'          => $LABEL,
  'apple-ios-person.vcf name'           => $PHON,
  'apple-ios-person.vcf onlineServices' => $LABEL,
  'apple-company.vcf addresses'         => $LABEL,
  'google-export.vcf anniversaries'     => $ABDATE,
  'google-export.vcf links'             => $LABEL,
  'google-export.vcf onlineServices'    => $LABEL,
  'cyrus-carddav-v4.vcf kind'           => $KIND,
  'rfc9555-examples.vcf kind'           => $KIND,
);

# A property of the original vCard is kept if the written vCard has one of
# these (the writer may use the vCard 4 name for an Apple one)
my %KEPT_AS = (
  'x-addressbookserver-kind'   => [qw(kind x-addressbookserver-kind)],
  'x-addressbookserver-member' => [qw(member x-addressbookserver-member)],
  'x-abdate'                   => [qw(anniversary x-abdate)],
  'x-abrelatednames'           => [qw(related x-abrelatednames)],
  'x-abadr'                    => [qw(adr x-abadr)],
  'x-socialprofile'            => [qw(socialprofile x-socialprofile)],
  'x-aim'                      => [qw(impp x-aim)],
);

my $DROP    = 'property with no JSContact mapping is dropped: the reader has no catch-all (vcard_to_jscontact, lib:168-225), RFC 9555 S2.15 maps it to vCardProps';
my $SOCIAL  = 'every onlineService is written as IMPP (lib:1331), SOCIALPROFILE/X-SOCIALPROFILE are lost';
my $PHONW   = 'X-PHONETIC-* is read into phoneticComponents (lib:280-289) but never written';
my $GEOTZ   = 'ungrouped GEO/TZ is only read when it shares an ADR group (lib:386-391), otherwise dropped';

# "file prop" => reason: a property of the original missing from the
# written vCard
my %TODO_PROP = (
  (map { ("apple-ios-person.vcf $_" => $DROP) }
     qw(x-abshowas x-abuid x-shared-photo-display-pref x-imagetype x-imagehash)),
  (map { ("apple-ios-person.vcf $_" => $PHONW) }
     qw(x-phonetic-first-name x-phonetic-middle-name x-phonetic-last-name)),
  'apple-ios-person.vcf x-socialprofile' => $SOCIAL,
  'apple-company.vcf x-abshowas'         => $DROP,
  'google-export.vcf x-google-etag'      => $DROP,
  'cyrus-carddav-v4.vcf gender'          => $DROP,
  'cyrus-carddav-v4.vcf x-cyrus-special' => $DROP,
  'cyrus-carddav-v4.vcf jsprop'          => $DROP,
  'cyrus-carddav-v4.vcf socialprofile'   => $SOCIAL,
  'rfc6350-s8.vcf gender'                => $DROP,
  'rfc6350-s8.vcf geo'                   => $GEOTZ,
  'rfc6350-s8.vcf tz'                    => $GEOTZ,
  'rfc6350-altid.vcf clientpidmap'       => $DROP,
  'rfc9555-examples.vcf birthplace'      => $DROP,
  'rfc9555-examples.vcf deathplace'      => $DROP,
  'rfc9555-examples.vcf socialprofile'   => $SOCIAL,
  'cyrus-carddav-v4.vcf kind'            => $KIND,
  'rfc9555-examples.vcf kind'            => $KIND,
);

my @files = sort map { s{^\Q$DIR\E/}{}r } glob "$DIR/*.vcf";
ok(@files >= 10, 'corpus has at least ten vCards');

for my $file (@files) {
  my $raw = slurp("$DIR/$file");

  my $card = vcard_to_jscontact($raw);
  ok($card, "$file: reads") or next;

  my $written = eval { jscontact_to_vcard($card) };
  ok(defined $written, "$file: writes") or do { diag $@; next };

  my $again = vcard_to_jscontact(encode_utf8($written));
  ok($again, "$file: written vCard reads") or next;

  # read -> write -> read, one top-level property at a time so a failure
  # names what was lost
  my %keys = map { $_ => 1 } keys %$card, keys %$again;
  my $any_todo;
  for my $key (sort keys %keys) {
    local $TODO = $TODO_KEY{"$file $key"};
    $any_todo ||= $TODO;
    is_deeply($again->{$key}, $card->{$key}, "$file: $key survives read-write-read");
  }
  {
    local $TODO = $any_todo ? "see the $file property failures above" : undef;
    is_deeply($again, $card, "$file: whole Card survives read-write-read");
  }

  # the written vCard keeps every property of the original
  my $in  = vcard2hash($raw, multival => [qw(n adr org)])->{objects}[0]{properties};
  my $out = vcard2hash(encode_utf8($written))->{objects}[0]{properties};
  for my $prop (sort keys %$in) {
    # an empty property (Apple writes N:;;;; for a company) carries nothing
    next unless grep { length } map { ref $_ ? @$_ : $_ } map { $_->{value} // (), @{$_->{values} // []} } @{$in->{$prop}};
    my @as = @{$KEPT_AS{$prop} // [$prop]};
    local $TODO = $TODO_PROP{"$file $prop"};
    ok((grep { $out->{$_} && @{$out->{$_}} } @as),
       "$file: \U$prop\E is still in the written vCard");
  }

  # writing the same Card twice gives the same bytes (a CardDAV ETag, or a
  # diff of two versions, depends on it)
  {
    my %seen;
    $seen{jscontact_to_vcard($card)}++ for 1..5;
    is(scalar(keys %seen), 1, "$file: writing is deterministic");
  }
}

# --- What the first read must get right --------------------------------

my $apple = vcard_to_jscontact(slurp("$DIR/apple-ios-person.vcf"));
{
  my %by_addr = map { $_->{address} => $_ } values %{$apple->{emails}};
  is($by_addr{'jq@icloud.example'}{label}, 'iCloud', 'Apple: X-ABLabel on a grouped EMAIL');
  is_deeply($by_addr{'johnny@home.example'}{contexts}, { private => JSON::true },
            'Apple: type=HOME is the private context');
  is($by_addr{'johnny@home.example'}{pref}, 1, 'Apple: type=pref is pref 1');
  my ($photo) = values %{$apple->{media}};
  like($photo->{uri}, qr{^data:image/png;base64,iVBORw0KGgo}, 'Apple: inline base64 PHOTO becomes a data: URI');
  my %rel = map { $_ => $apple->{relatedTo}{$_}{relation} } keys %{$apple->{relatedTo}};
  is_deeply($rel{'Jane Appleseed'}, { spouse => JSON::true }, 'Apple: X-ABRELATEDNAMES with _$!<Spouse>!$_');
  my ($custom) = grep { $_->{date} eq '2019-02-01' } values %{$apple->{anniversaries}};
  local $TODO = 'a custom X-ABDATE label becomes the Anniversary kind (lib:558); RFC 9553 kinds are birth/death/wedding, the label belongs in a label or vCardProps';
  ok($custom && $custom->{kind} =~ /^(birth|death|wedding)$/, 'Apple: custom X-ABDATE gets a valid Anniversary kind');
}

my $group = vcard_to_jscontact(slurp("$DIR/apple-group.vcf"));
is($group->{kind}, 'group', 'Apple group: X-ADDRESSBOOKSERVER-KIND');
is(scalar keys %{$group->{members}}, 3, 'Apple group: X-ADDRESSBOOKSERVER-MEMBER');

my $cyrus = vcard_to_jscontact(slurp("$DIR/cyrus-carddav-v4.vcf"));
is_deeply([sort keys %{$cyrus->{emails}}], [qw(e1 e2)], 'Cyrus: PROP-ID gives the map key');
like(jscontact_to_vcard($cyrus), qr/^EMAIL;.*PROP-ID=e1/m, 'Cyrus: map key written back as PROP-ID');

{
  # Text::VCardFast hands back the raw bytes; RFC 6350 vCards are UTF-8
  my $co = vcard_to_jscontact(slurp("$DIR/apple-company.vcf"));
  my ($org) = values %{$co->{organizations}};
  my ($em)  = values %{$co->{emails}};
  is($co->{name}{full}, "Caf\x{e9} M\x{fc}ller GmbH", 'UTF-8: FN decoded');
  is($org->{units}[0]{name}, "K\x{fc}che", 'UTF-8: ORG unit decoded');
  is($org->{name}, "Caf\x{e9} M\x{fc}ller GmbH", 'UTF-8: ORG name decoded');
  is($em->{address}, "k\x{fc}che\@caf\x{e9}.example", 'UTF-8: EMAIL decoded');
}

{
  # an explicit PROP-ID and an allocated id must not collide
  my $c = vcard_to_jscontact("BEGIN:VCARD\r\nVERSION:4.0\r\nFN:X\r\n"
    . "EMAIL;PROP-ID=1:a\@example.com\r\nEMAIL:b\@example.com\r\nEND:VCARD\r\n");
  is(scalar keys %{$c->{emails} // {}}, 2, 'PROP-ID=1 and an unlabelled EMAIL are both kept');
}

{
  # ALTID/LANGUAGE (RFC 9555 S2.3.1, S2.3.11): one property plus localizations
  my $alt = vcard_to_jscontact(slurp("$DIR/rfc6350-altid.vcf"));
  local $TODO = 'ALTID/LANGUAGE are ignored: alternates become separate entries (lib:508-523, 573-600) or are dropped (FN, _first_value lib:236); no localizations';
  is(scalar keys %{$alt->{titles}}, 1, 'ALTID: TITLE alternates are one Title');
  is(scalar keys %{$alt->{notes}}, 1, 'ALTID: NOTE alternates are one Note');
  ok($alt->{localizations} && $alt->{localizations}{fr}, 'ALTID: the fr alternates are a localization');
  like(jscontact_to_vcard($alt), qr/^TITLE;.*LANGUAGE=fr.*:Patron/m, 'ALTID: written back with LANGUAGE=fr');
}

{
  my $ph = vcard_to_jscontact(slurp("$DIR/rfc9555-phonetic.vcf"));
  local $TODO = 'only the first N is read (_first_prop lib:239); PHONETIC/SCRIPT (RFC 9555 S2.3.15) are ignored';
  ok($ph->{localizations} && $ph->{localizations}{yue}, 'PHONETIC: N;PHONETIC=jyut is a yue localization');
}

{
  my $ex = vcard_to_jscontact(slurp("$DIR/rfc9555-examples.vcf"));
  my ($adr) = values %{$ex->{addresses}};
  local $TODO = 'RFC 9554 ADR components 8-18 are ignored (lib:400-419)';
  ok((grep { $_->{kind} eq 'number' } @{$adr->{components}}), 'RFC 9554 ADR: number component');
}

done_testing;
