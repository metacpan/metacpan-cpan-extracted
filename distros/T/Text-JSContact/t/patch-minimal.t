#!/usr/bin/perl

# patch_vcard must change only what the Card change asks for: a vCard from
# Apple or Google carries grouped lines, labels, X- properties and vendor
# parameters that JSContact cannot represent, and a client that saves one
# edited email must not lose or rewrite them.

use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON;
use Encode ();
use Text::VCardFast qw(vcard2hash);

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

my $DIR = 't/data/vcard';

sub slurp {
  my ($file) = @_;
  open my $fh, '<:raw', "$DIR/$file" or die "$file: $!";
  local $/;
  return scalar <$fh>;
}

# content lines, unfolded, without line endings
sub lines {
  my ($v) = @_;
  $v =~ s/\r?\n[ \t]//g;
  return grep { length } split /\r?\n/, $v;
}

# a property as Text::VCardFast parses it, comparable regardless of the case
# of names and of parameter order
my $CANON = JSON->new->canonical;
sub props {
  my ($v) = @_;
  my $p = vcard2hash($v, multival => [qw(n adr org)])->{objects}[0]{properties};
  my @out;
  for my $name (sort keys %$p) {
    for my $item (@{$p->{$name}}) {
      push @out, {
        name   => $name,
        group  => lc($item->{group} // ''),
        params => $item->{params} // {},
        value  => $item->{values} // $item->{value},
        key    => $CANON->encode([$name, lc($item->{group} // ''), $item->{params} // {}, $item->{values} // $item->{value}]),
      };
    }
  }
  return @out;
}

sub find_id {
  my ($map, $field, $value) = @_;
  my ($id) = grep { ($map->{$_}{$field} // '') eq $value } keys %$map;
  return $id;
}


# a map of objects as a sorted list, to compare without the ids
sub by_value {
  my ($v) = @_;
  return $v unless ref $v eq 'HASH' && !grep { ref $_ ne 'HASH' } values %$v;
  return [ sort map { $CANON->encode($_) } values %$v ];
}

# --- No change: the original, byte for byte ------------------------------

for my $file (sort map { s{^\Q$DIR\E/}{}r } glob "$DIR/*.vcf") {
  my $raw  = slurp($file);
  my $card = vcard_to_jscontact($raw);
  is(patch_vcard($raw, $card, dclone($card)), $raw, "$file: no change returns the original bytes");
  # as a JMAP client sends it back: through JSON
  my $json = JSON->new->utf8->canonical;
  my $back = $json->decode($json->encode($card));
  is(patch_vcard($raw, $card, $back), $raw, "$file: no change after a JSON round trip returns the original bytes");
}

# --- Apple vCard 3.0: change one email ---------------------------------

{
  my $raw  = slurp('apple-ios-person.vcf');
  my $old  = vcard_to_jscontact($raw);
  my $new  = dclone($old);
  my $id   = find_id($new->{emails}, address => 'j.appleseed@orchard.example');
  ok($id, 'Apple: found the work email');
  $new->{emails}{$id}{address} = 'johnny@orchard.example';

  my $patched = patch_vcard($raw, $old, $new);
  like($patched, qr/johnny\@orchard\.example/, 'Apple: new address written');
  unlike($patched, qr/j\.appleseed\@orchard\.example/, 'Apple: old address gone');

  # the email lines and their labels are the only ones allowed to change
  my %email_groups = map { lc($_->{group}) => 1 } grep { $_->{name} eq 'email' && $_->{group} } props($raw);
  my $is_email = sub {
    my $l = shift;
    return 1 if $l =~ /^(?:[\w-]+\.)?EMAIL[;:]/i;
    return 1 if $l =~ /^([\w-]+)\.X-ABLABEL[;:]/i && $email_groups{lc $1};
    return 0;
  };

  is_deeply([grep { !$is_email->($_) } lines($patched)],
            [grep { !$is_email->($_) } lines($raw)],
            'Apple: every other line is byte-identical and in the same order');

  # semantically: every other property, with its group, params and value
  my %after = map { $_->{key} => 1 } props($patched);
  my @missing = map { "$_->{group}.$_->{name}" }
                grep { !$after{$_->{key}} }
                grep { $_->{name} ne 'email' && !($_->{name} eq 'x-ablabel' && $email_groups{$_->{group}}) }
                props($raw);
  is_deeply(\@missing, [], 'Apple: every other property kept, with its group, parameters and value');

  my $reread = vcard_to_jscontact($patched);
  my %by = map { $_->{address} => $_ } values %{$reread->{emails}};
  is($by{'jq@icloud.example'}{label}, 'iCloud', 'Apple: the label of an untouched email survives');
  is_deeply([sort keys %by], [sort map { $_->{address} } values %{$new->{emails}}], 'Apple: the emails are the new ones');
  my @others = sort grep { $_ ne 'emails' } keys %$new;
  for my $key (@others) {
    is_deeply(by_value($reread->{$key}), by_value($new->{$key}), "Apple: $key unchanged after patching an email (ignoring ids)");
  }
  {
    is_deeply({ map { ($_ => $reread->{$_}) } @others }, { map { ($_ => $new->{$_}) } @others },
              'Apple: every other property unchanged, ids included');
  }

  like($patched, qr/^VERSION:3\.0\r?$/m, 'Apple: still VERSION:3.0');
  my @v4 = grep { /;(?:PROP-ID|PREF)=/i } lines($patched);
  is_deeply(\@v4, [], 'Apple: no vCard 4 parameters (PROP-ID, PREF) in a 3.0 card');
  my ($work) = grep { /johnny\@orchard/ } lines($patched);
  like($work // '', qr/^item2\.EMAIL;type=INTERNET;type=WORK:/,
       'Apple: the changed email keeps its group and its 3.0 parameters');
}

# --- A new label must not take a group the original uses ----------------

{
  my $raw = slurp('google-export.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  my $id  = find_id($new->{emails}, address => 'alice@corp.example');
  $new->{emails}{$id}{label} = 'Office';
  my $reread = vcard_to_jscontact(patch_vcard($raw, $old, $new));
  is(($reread->{emails}{$id} // {})->{label}, 'Office', 'Google: new email label written');
  my $ph = find_id($reread->{phones}, number => '+1 650-555-0100');
  is(($reread->{phones}{$ph // ''} // {})->{label}, "Grandma's house",
     'Google: item1 phone keeps its own label');
}

# --- Ids: the untouched properties keep theirs --------------------------

{
  my $raw = slurp('google-export.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  my $id  = find_id($new->{emails}, address => 'alice@corp.example');
  $new->{emails}{$id}{address} = 'alice@newcorp.example';
  my $reread = vcard_to_jscontact(patch_vcard($raw, $old, $new));
  is_deeply([sort keys %{$reread->{emails}}], [sort keys %{$new->{emails}}], 'ids: patched emails keep their ids (written as PROP-ID)');
  is_deeply([sort keys %{$reread->{phones}}], [sort keys %{$old->{phones}}], 'ids: untouched phones keep their ids');
}

# --- Patching a property keeps what JSContact cannot say about it ---------

{
  my $raw = slurp('apple-ios-person.vcf');
  my $old = vcard_to_jscontact($raw);

  {
    my $new = dclone($old);
    $new->{name}{full} = 'Johnny Q. Appleseed';
    my $reread = vcard_to_jscontact(patch_vcard($raw, $old, $new));
    is($reread->{name}{full}, 'Johnny Q. Appleseed', 'Apple name: FN changed');
    is_deeply($reread->{name}{phoneticComponents}, $old->{name}{phoneticComponents}, 'Apple name: phonetic names kept');
  }

  {
    my $new = dclone($old);
    my $id  = find_id($new->{links}, uri => 'https://orchard.example/team/johnny');
    $new->{links}{$id}{uri} = 'https://orchard.example/people/johnny';
    my $reread = vcard_to_jscontact(patch_vcard($raw, $old, $new));
    my $home = find_id($reread->{links}, uri => 'https://johnny.example/');
    is(($reread->{links}{$home // ''} // {})->{label}, 'HomePage', 'Apple links: untouched URL keeps its label');
  }

  {
    my $new = dclone($old);
    my $bday = find_id($new->{anniversaries}, kind => 'birth');
    $new->{anniversaries}{$bday}{date} = '0000-07-05';
    my $patched = patch_vcard($raw, $old, $new);
    like($patched, qr/^item\d+\.X-ABDATE[;:].*2019-02-01/mi, 'Apple anniversaries: custom X-ABDATE kept');
  }
}

# --- Cyrus vCard 4.0: unknown properties and vendor parameters ------------

{
  my $raw = slurp('cyrus-carddav-v4.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{emails}{e1}{address} = 'jane@new-work.example';
  my $patched = patch_vcard($raw, $old, $new);
  my @after = lines($patched);
  ok((grep { /^X-CYRUS-SPECIAL;X-VENDOR-PARAM=keep:opaque value$/i } @after), 'Cyrus: X- property with vendor parameter kept');
  ok((grep { /^JSPROP;JSPTR="example\.com:foo":"bar"$/i } @after), 'Cyrus: JSPROP kept');
  ok((grep { /^GENDER:F$/ } @after), 'Cyrus: GENDER kept');
  ok((grep { /^EMAIL;.*PROP-ID=e1.*:jane\@new-work\.example$/ } @after), 'Cyrus: patched email keeps its PROP-ID');
  is_deeply([grep { !/^EMAIL[;:]/ } @after], [grep { !/^EMAIL[;:]/ } lines($raw)],
            'Cyrus: every other line is byte-identical and in the same order');
}

# --- UTF-8: a patched vCard is still UTF-8 ---------------------------------

{
  my $raw = slurp('apple-company.vcf');
  my $old = vcard_to_jscontact($raw);
  for my $addr ("bestellung\@caf\x{e9}.example", "\x{6ce8}\x{6587}\@example.jp") {
    my $what = $addr =~ /[^\x00-\xff]/ ? 'a character above U+00FF' : 'a Latin-1 character';
    my $new = dclone($old);
    my ($id) = keys %{$new->{emails}};
    $new->{emails}{$id}{address} = $addr;
    my $patched = patch_vcard($raw, $old, $new);
    my $bytes = utf8::is_utf8($patched) ? undef : $patched;
    ok(defined $bytes && eval { Encode::decode('UTF-8', my $copy = $bytes, Encode::FB_CROAK); 1 },
       "UTF-8: patching in $what gives a vCard of UTF-8 bytes");
    like(Encode::decode('UTF-8', $bytes // ''), qr/^FN:Caf\x{e9} M\x{fc}ller GmbH\r?$/m, "UTF-8: after patching in $what, the untouched FN still reads as UTF-8");
  }
}

# --- Apple group: members stay in Apple's form ----------------------------

{
  my $raw = slurp('apple-group.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{members}{'urn:uuid:11111111-2222-4333-8444-555555555555'} = JSON::true;
  my $patched = patch_vcard($raw, $old, $new);
  like($patched, qr/^X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:11111111-2222-4333-8444-555555555555\r?$/m,
       'Apple group: new member as X-ADDRESSBOOKSERVER-MEMBER');
  unlike($patched, qr/^MEMBER:/m, 'Apple group: no vCard 4 MEMBER');
  like($patched, qr/^X-ADDRESSBOOKSERVER-KIND:group\r?$/m, 'Apple group: kind untouched');
  is(scalar keys %{vcard_to_jscontact($patched)->{members}}, 4, 'Apple group: four members');
}

# --- Untouched lines keep their folding and line endings ------------------

{
  my $raw = slurp('apple-ios-person.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{name}{full} = 'Johnny Appleseed';
  my $patched = patch_vcard($raw, $old, $new);
  my ($photo) = $raw =~ /^(PHOTO;.*?\n(?: .*?\n)*)/m;
  ok($photo && index($patched, $photo) >= 0, 'Apple: the folded PHOTO keeps its folding');
  (my $crlf = $raw) =~ s/\r?\n/\r\n/g;
  my $p2 = patch_vcard($crlf, vcard_to_jscontact($crlf), $new);
  unlike($p2, qr/(?<!\r)\n/, 'CRLF original: every line, patched or not, ends in CRLF');
  like($p2, qr/^FN:Johnny Appleseed\r$/m, 'CRLF original: patched FN');
}

# --- vCard 3: what is patched in is vCard 3 -------------------------------

{
  my $raw = slurp('apple-ios-person.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{emails}{added} = { '@type' => 'EmailAddress', address => 'new@orchard.example',
                            contexts => { work => JSON::true }, pref => 1, label => 'Orchard' };
  my ($m) = keys %{$new->{media}};
  $new->{media}{$m}{uri} = 'data:image/jpeg;base64,/9j/4AAQ';
  my ($us) = grep { $new->{addresses}{$_}{countryCode} eq 'us' } keys %{$new->{addresses}};
  $new->{addresses}{$us}{countryCode} = 'ca';
  my $patched = patch_vcard($raw, $old, $new);
  my @l = lines($patched);
  my ($email) = grep { /new\@orchard/ } @l;
  like($email // '', qr/^(item\d+)\.EMAIL;TYPE=WORK;TYPE=PREF:new\@orchard\.example$/,
       'v3: a new email has TYPE=pref, no PROP-ID or PREF, and a new group');
  my ($g) = ($email // '') =~ /^(item\d+)\./;
  ok($g && !grep({ /^\Q$g\E\./ } lines($raw)), 'v3: the new group is not one the original uses');
  ok((grep { /^\Q$g\E\.X-ABLabel:Orchard$/ } @l), 'v3: the label is in that group');
  ok((grep { $_ eq 'PHOTO;ENCODING=b;TYPE=JPEG:/9j/4AAQ' } @l), 'v3: an inline photo is ENCODING=b with the format as TYPE');
  ok((grep { $_ eq 'item5.X-ABADR:ca' } @l), 'v3: the Apple country code line is updated');
  ok((grep { /^item5\.ADR;type=HOME;type=pref:/ } @l), 'v3: and the address line itself is untouched');
  my $reread = vcard_to_jscontact($patched);
  # (by value: without PROP-IDs, the new email moves the later ids on)
  ok((grep { ($_->{countryCode} // '') eq 'ca' } values %{$reread->{addresses}}), 'v3: the country code reads back');
  my ($back) = grep { $_->{address} eq 'new@orchard.example' } values %{$reread->{emails}};
  is_deeply([ @{$back // {}}{qw(label pref)} ], ['Orchard', 1], 'v3: the new email reads back with its label and pref');
}

{
  my $raw = slurp('google-export.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{phones}{ext} = { '@type' => 'Phone', number => 'tel:+1-650-555-0177;ext=7' };
  $new->{relatedTo}{'Carol Example'} = { '@type' => 'Relation' };
  my @l = lines(patch_vcard($raw, $old, $new));
  ok((grep { $_ eq 'TEL:+1-650-555-0177\\;ext=7' } @l), 'v3: a tel: URI is written as a vCard 3 phone number');
  ok((grep { $_ eq 'RELATED:Carol Example' } @l), 'v3: free text RELATED needs no VALUE=text');
}

# --- Removing an entry removes its group -----------------------------------

{
  my $raw = slurp('apple-ios-person.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  my ($au) = grep { $new->{addresses}{$_}{countryCode} eq 'au' } keys %{$new->{addresses}};
  delete $new->{addresses}{$au};
  my ($icloud) = grep { $new->{emails}{$_}{address} eq 'jq@icloud.example' } keys %{$new->{emails}};
  delete $new->{emails}{$icloud};
  my @l = lines(patch_vcard($raw, $old, $new));
  is_deeply([ grep { /^item[36]\./ } @l ], [], 'a removed entry takes its label and X-ABADR with it');
  is(scalar(@l), scalar(lines($raw)) - 4, 'and nothing else');
}

# --- Apple relations live in the label -----------------------------------

{
  my $raw = slurp('apple-ios-person.vcf');
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{relatedTo}{'Granny Smith'}{relation} = { friend => JSON::true };
  my @l = lines(patch_vcard($raw, $old, $new));
  ok((grep { $_ eq 'item12.X-ABRELATEDNAMES:Granny Smith' } @l), 'relation change: X-ABRELATEDNAMES untouched');
  ok((grep { $_ eq 'item12.X-ABLabel:_$!<Friend>!$_' } @l), 'relation change: written as the X-ABLabel');
}

# --- A vCard 4 property keeps its unknown parameters ------------------------

{
  my $raw = "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:A\r\n"
          . "EMAIL;PROP-ID=e1;X-VENDOR=\"keep, me\";TYPE=work,x-custom;PREF=1:a\@example.com\r\n"
          . "TEL;PROP-ID=t1:+1 555\r\nEND:VCARD\r\n";
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{emails}{e1}{address} = 'b@example.com';
  $new->{emails}{e1}{contexts} = { private => JSON::true };
  delete $new->{emails}{e1}{pref};
  is(patch_vcard($raw, $old, $new),
     "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:A\r\n"
   . "EMAIL;PROP-ID=e1;X-VENDOR=\"keep, me\";TYPE=x-custom;TYPE=home:b\@example.com\r\n"
   . "TEL;PROP-ID=t1:+1 555\r\nEND:VCARD\r\n",
     'v4: unknown parameters and TYPE values kept, known ones rewritten');
}

# --- Characters in, characters out ---------------------------------------

{
  my $raw = Encode::decode('UTF-8', slurp('apple-company.vcf'));
  my $old = vcard_to_jscontact($raw);
  my $new = dclone($old);
  $new->{name}{full} = "Caf\x{e9} M\x{fc}ller AG";
  my $patched = patch_vcard($raw, $old, $new);
  ok(utf8::is_utf8($patched), 'an original given as characters is patched as characters');
  like($patched, qr/^FN:Caf\x{e9} M\x{fc}ller AG$/m, 'with the new FN');
  like($patched, qr/^ORG:Caf\x{e9} M\x{fc}ller GmbH;K\x{fc}che$/m, 'and the untouched ORG');
}

done_testing;
