#!/usr/bin/perl

# jscontact_to_vcard($card, original => $vcard): write a Card as a patch
# of the vCard it was read from, without the caller keeping the old Card.

use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use Encode qw(decode encode_utf8);
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

my $DIR = 't/data/vcard';

sub slurp {
  my ($file) = @_;
  open my $fh, '<:raw', "$DIR/$file" or die "$file: $!";
  local $/;
  return scalar <$fh>;
}

for my $file (sort map { s{^\Q$DIR\E/}{}r } glob "$DIR/*.vcf") {
  my $raw  = slurp($file);
  my $card = vcard_to_jscontact($raw);
  my $out  = jscontact_to_vcard($card, original => $raw);
  is(encode_utf8($out), $raw, "$file: an unchanged Card gives the original back");
  my $json = JSON->new->utf8->canonical;
  is(encode_utf8(jscontact_to_vcard($json->decode($json->encode($card)), original => $raw)), $raw,
     "$file: also after a JSON round trip");
}

{
  my $raw  = slurp('apple-ios-person.vcf');
  my $card = vcard_to_jscontact($raw);
  my $old  = dclone($card);
  my ($id) = grep { $card->{emails}{$_}{address} eq 'jq@icloud.example' } keys %{$card->{emails}};
  $card->{emails}{$id}{address} = 'jq@icloud.example.net';

  my $out = jscontact_to_vcard($card, original => $raw);
  ok(utf8::is_utf8($out) || $out !~ /[^\x00-\x7f]/, 'returns characters, as without original');
  is(encode_utf8($out), patch_vcard($raw, $old, $card), 'the same as patch_vcard with the Card read from the original');
  like($out, qr/^VERSION:3\.0$/m, 'a vCard 3 stays vCard 3');

  # what the proxy does: the Card it saves is not the one it read
  my $mutated = dclone($card);
  $mutated->{CPath} = '/dav/addressbooks/user/x/Default/x.vcf';
  $mutated->{addressBookIds} = { Default => JSON::true };
  is(jscontact_to_vcard($mutated, original => $raw), $out,
     'keys that are not Card properties change nothing');
}

{
  # an original without UID: a uid the caller adds becomes a UID line
  my $raw = "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:No Uid\r\nX-KEEP:yes\r\nEND:VCARD\r\n";
  my $card = vcard_to_jscontact($raw);
  $card->{uid} = 'urn:uuid:0b5c7a2e-0000-4000-8000-000000000001';
  is(jscontact_to_vcard($card, original => $raw),
     "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:No Uid\r\nX-KEEP:yes\r\n"
   . "UID:urn:uuid:0b5c7a2e-0000-4000-8000-000000000001\r\nEND:VCARD\r\n",
     'a uid added to the Card is added to the vCard, everything else kept');
}

{
  # a vCard that cannot be parsed: the Card is written afresh
  my $card = { '@type' => 'Card', version => '2.0', uid => 'x', name => { full => 'Fresh' } };
  for my $bad ("not a vCard at all", "BEGIN:VCARD\r\nVERSION:4.0\r\nFN:x\r\n", '') {
    is(jscontact_to_vcard($card, original => $bad), jscontact_to_vcard($card),
       'an unparseable original: written as a new vCard (' . length($bad) . ' bytes)');
  }
  is(jscontact_to_vcard($card, original => undef), jscontact_to_vcard($card),
     'original => undef is no original');
}

{
  # characters in, characters out; the original may be either
  my $raw   = slurp('apple-company.vcf');
  my $chars = decode('UTF-8', $raw);
  my $card  = vcard_to_jscontact($raw);
  $card->{name}{full} = "Caf\x{e9} M\x{fc}ller AG";
  my $a = jscontact_to_vcard($card, original => $raw);
  my $b = jscontact_to_vcard($card, original => $chars);
  is($a, $b, 'bytes or characters, the same result');
  like($a, qr/^FN:Caf\x{e9} M\x{fc}ller AG$/m, 'the new FN');
  like($a, qr/^NOTE:\x{d6}ffnungszeiten: Mo\x{2013}Fr 8\x{2013}18 Uhr$/m, 'the untouched NOTE, decoded once');
}

done_testing;
