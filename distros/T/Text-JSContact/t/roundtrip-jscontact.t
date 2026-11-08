#!/usr/bin/perl

# Write -> read: a hand-written JSContact Card, written as a vCard and read
# back, must be the Card we started from.  t/data/jscontact/full.json uses
# every property and parameter the module reads and writes; the other files
# isolate one known gap each (labels, phonetics, custom anniversary kinds,
# UTF-8, RFC 9553 forms the module does not support), so a TODO there does
# not hide a regression in full.json.
#
# jscontact_to_vcard returns characters; the vCard is UTF-8 encoded before
# it is read back, as it would be on the wire.

use strict;
use warnings;
use Test::More;
use JSON;
use Encode qw(encode_utf8);

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $DIR  = 't/data/jscontact';
my $JSON = JSON->new->utf8;

sub load {
  my ($file) = @_;
  open my $fh, '<:raw', "$DIR/$file" or die "$file: $!";
  local $/;
  return $JSON->decode(scalar <$fh>);
}

my $LABEL = 'label only written for emails and phones (_add_label: lib/Text/JSContact.pm:1161,1190)';

# "file key" => reason
my %TODO_KEY = (
  'full.json kind'                       => 'KIND:individual is not written (lib:986), so it does not come back',
  'labels.json addresses'                => $LABEL,
  'labels.json onlineServices'           => $LABEL,
  'labels.json media'                    => $LABEL,
  'labels.json links'                    => $LABEL,
  'labels.json calendars'                => $LABEL,
  'phonetic.json name'                   => 'phoneticComponents never written: _unconvert_name ignores them (lib:1088-1136)',
  'custom-anniversary.json anniversaries'=> 'an Anniversary kind other than birth/wedding/death is written as ANNIVERSARY (lib:1286), read back as wedding (lib:531)',
  'rfc9553-only.json addresses'     => 'AddressComponent kinds beyond the 7 ADR fields (number, ...) dropped (lib:1199-1202), and contexts other than private/work (billing) dropped (lib:1045-1052)',
  'rfc9553-only.json calendars'     => 'Calendar kind not read or written: CALURI gets no kind (lib:775), freeBusy is read from FBURL into links (lib:768), written as CALURI (lib:1388)',
  'rfc9553-only.json directories'   => 'Directory listAs (INDEX) neither read (lib:739-762) nor written (lib:1399-1413)',
  'rfc9553-only.json localizations' => 'localizations neither read nor written (no ALTID/LANGUAGE support)',
  'rfc9553-only.json name'          => 'Name isOrdered (and defaultSeparator, separator components) not written (lib:1088-1136)',
  'rfc9553-only.json phones'        => 'Phone feature main-number not mapped (lib:1170-1174, 344-348)',
);

# whole files that cannot work yet
my %TODO_FILE = (
  'rfc9553-dates.json' => 'Anniversary.date is a PartialDate or Timestamp object (RFC 9553 S2.8.1); the module assumes a string (lib:540, 1289) and the writer dies in Text::VCardFast on the hash',
);

for my $file (sort map { s{^\Q$DIR\E/}{}r } glob "$DIR/*.json") {
  my $card = load($file);
  local $TODO = $TODO_FILE{$file};

  my $written = eval { jscontact_to_vcard($card) };
  ok(defined $written, "$file: writes") or do { diag $@; next };

  my $again = vcard_to_jscontact(encode_utf8($written));
  ok($again, "$file: written vCard reads") or next;

  my %keys = map { $_ => 1 } keys %$card, keys %$again;
  my $any_todo = $TODO;
  for my $key (sort keys %keys) {
    local $TODO = $TODO // $TODO_KEY{"$file $key"};
    $any_todo ||= $TODO;
    is_deeply($again->{$key}, $card->{$key}, "$file: $key survives write-read");
  }
  local $TODO = $any_todo ? "see the $file property failures above" : undef;
  is_deeply($again, $card, "$file: whole Card survives write-read");
}

# full.json really does exercise every property: if the reader or writer
# learns a new one, add it to full.json
{
  my $full = load('full.json');
  my @expected = qw(
    @type addresses anniversaries calendars created cryptoKeys directories
    emails keywords kind language links media members name nicknames notes
    onlineServices organizations personalInfo phones preferredLanguages
    prodId relatedTo schedulingAddresses speakToAs titles uid updated version
  );
  is_deeply([sort keys %$full], [sort @expected], 'full.json covers every Card property the module maps');
}

# --- The written vCard, as another client reads it -------------------------

{
  my $full = load('full.json');
  my $v = jscontact_to_vcard($full);
  (my $unfolded = $v) =~ s/\r?\n[ \t]//g;

  like($unfolded, qr/^VERSION:4\.0$/m, 'wire: VERSION:4.0');
  like($unfolded, qr/^PHOTO;.*:data:image\/png;base64,iVBOR/m, 'wire: data: URI written raw');
  like($unfolded, qr/^NOTE;.*:Line one\\; with punctuation\\, commas\\nand a second line\\\\backslash\.$/m,
       'wire: TEXT escaped per RFC 6350 S3.4');

  like($unfolded, qr/^N[;:].*:Smith,Jones;/m, 'wire: N surname list is comma-separated, not escaped');
  like($unfolded, qr/^CATEGORIES:colleague,lab,sailing club$/m, 'wire: CATEGORIES is a list, not one escaped value');
}

{
  my $c = { '@type' => 'Card', version => '2.0', uid => 'x',
            addresses => { a => { '@type' => 'Address', components => [
              { kind => 'name', value => '1 Main St' }, { kind => 'name', value => 'Rear, Unit 2' },
              { kind => 'locality', value => 'Springfield' } ] } },
            keywords => { 'a,b' => JSON::true, c => JSON::true } };
  (my $v = jscontact_to_vcard($c)) =~ s/\r?\n[ \t]//g;
  like($v, qr/^ADR;.*:;;1 Main St,Rear\\, Unit 2;Springfield;;;$/m,
       'wire: ADR street list comma-separated, a comma inside one value escaped');
  like($v, qr/^CATEGORIES:a\\,b,c$/m, 'wire: a comma inside one keyword escaped');
}

{
  my $c = { '@type' => 'Card', version => '2.0', uid => 'x',
            phones => { p1 => { '@type' => 'Phone', number => 'tel:+1-555-555-5555;ext=5555' } } };
  (my $v = jscontact_to_vcard($c)) =~ s/\r?\n[ \t]//g;
  like($v, qr/^TEL;.*:tel:\+1-555-555-5555;ext=5555$/m, 'wire: tel: URI written unescaped');
  like($v, qr/^TEL;[^:]*VALUE=uri/m, 'wire: with VALUE=uri');
  is(vcard_to_jscontact(encode_utf8($v))->{phones}{p1}{number}, 'tel:+1-555-555-5555;ext=5555', 'tel: URI reads back');
  my $t = jscontact_to_vcard({ '@type' => 'Card', version => '2.0', uid => 'x',
            phones => { p1 => { '@type' => 'Phone', number => '+1 555 555 5555' } } });
  unlike($t, qr/^TEL;[^:]*VALUE=/m, 'wire: a plain number has no VALUE');
}

{
  my $c = { '@type' => 'Card', version => '2.0', uid => 'x',
            personalInfo => { h => { '@type' => 'PersonalInfo', kind => 'hobby', value => 'sailing', level => 'high' } } };
  my $v = jscontact_to_vcard($c);
  local $TODO = 'beginner/average/expert are EXPERTISE levels only (RFC 9555 S2.3.13); lib:1432 maps every kind';
  like($v, qr/^HOBBY;.*LEVEL=high/m, 'wire: HOBBY keeps LEVEL=high');
}

{
  my $c = { '@type' => 'Card', version => '2.0', uid => 'x',
            relatedTo => { 'Ask my deputy John' => { '@type' => 'Relation' } } };
  my $v = jscontact_to_vcard($c);
  like($v, qr/^RELATED;.*VALUE=text/mi, 'wire: free-text RELATED has VALUE=text');
  my $u = jscontact_to_vcard({ '@type' => 'Card', version => '2.0', uid => 'x',
            relatedTo => { 'urn:uuid:4e1a2b3c-0000-4000-8000-000000000001' => { '@type' => 'Relation' } } });
  unlike($u, qr/^RELATED;.*VALUE=/mi, 'wire: a URI RELATED has no VALUE');
  is(vcard_to_jscontact(encode_utf8($v))->{relatedTo}{'Ask my deputy John'}{'@type'}, 'Relation',
     'free-text RELATED reads back');
}

{
  my $c = { '@type' => 'Card', version => '2.0', uid => 'x',
            onlineServices => { s => { '@type' => 'OnlineService', service => 'Mastodon', uri => 'https://social.example/@a' } } };
  my $v = jscontact_to_vcard($c);
  local $TODO = 'every onlineService is written as IMPP (lib:1331); a profile URL is SOCIALPROFILE (RFC 9554 S3.6)';
  like($v, qr/^SOCIALPROFILE/m, 'wire: a web profile is SOCIALPROFILE');
}

done_testing;
