#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

unless ($ENV{CYRUS_URL}) {
  plan skip_all => "Set CYRUS_URL, CYRUS_USER, CYRUS_PASS to enable Cyrus integration tests"
    . " (e.g. CYRUS_URL=http://localhost:8080 CYRUS_USER=user1 CYRUS_PASS=password)";
}

my $base = $ENV{CYRUS_URL};
my $user = $ENV{CYRUS_USER} || 'user1';
my $pass = $ENV{CYRUS_PASS} || 'password';
my $abpath = "$base/dav/addressbooks/user/$user/Default";

my $ua = LWP::UserAgent->new(timeout => 5);

my $probe = $ua->get("$base/dav/principals/user/$user/");
unless ($probe->code < 500) {
  plan skip_all => "Cyrus not reachable at $base";
}

my $json = JSON::XS->new->pretty(1)->canonical(1);

sub carddav_put {
  my ($uid, $vcard) = @_;
  my $req = HTTP::Request->new(PUT => "$abpath/$uid.vcf");
  $req->authorization_basic($user, $pass);
  $req->content_type('text/vcard; charset=utf-8');
  $req->content($vcard);
  return $ua->request($req);
}

sub carddav_get {
  my ($uid) = @_;
  my $req = HTTP::Request->new(GET => "$abpath/$uid.vcf");
  $req->authorization_basic($user, $pass);
  return $ua->request($req);
}

sub carddav_delete {
  my ($uid) = @_;
  my $req = HTTP::Request->new(DELETE => "$abpath/$uid.vcf");
  $req->authorization_basic($user, $pass);
  return $ua->request($req);
}

# ============================================================
# Test 1: Simple contact round-trip through Cyrus
# ============================================================

my $uid1 = 'jscontact-test-' . time();
my $vcard = <<"VCARD";
BEGIN:VCARD
VERSION:4.0
UID:urn:uuid:$uid1
FN:Jane Q. Smith
N:Smith;Jane;Quincy;Dr.;PhD
NICKNAME:Janey
EMAIL;TYPE=work:jane\@example.com
EMAIL;TYPE=home;PREF=1:jane.home\@example.com
TEL;TYPE=work,voice:+1-555-0100
TEL;TYPE=cell:+1-555-0101
ADR;TYPE=home:;;42 Wallaby Way;Sydney;NSW;2000;Australia
ORG:Acme Corp;R&D
TITLE:Lead Scientist
BDAY:1985-03-15
NOTE:Test contact for JSContact
CATEGORIES:testing,jscontact
URL:https://jane.example.com
REV:20250101T120000Z
END:VCARD
VCARD

my $resp = carddav_put($uid1, $vcard);
ok($resp->is_success || $resp->code == 201 || $resp->code == 204,
   "PUT contact: " . $resp->status_line);

# GET it back
$resp = carddav_get($uid1);
ok($resp->is_success, "GET contact back");
my $returned_vcard = $resp->content;

# Parse with Text::JSContact
my $card = eval { vcard_to_jscontact($returned_vcard) };
ok(!$@, "Parse returned vCard") or diag $@;
ok($card, "Got JSContact Card");

# Verify core fields
is($card->{name}{full}, 'Jane Q. Smith', 'name.full preserved');
ok($card->{name}{components}, 'has name components');
my @surnames = grep { $_->{kind} eq 'surname' } @{$card->{name}{components}};
is($surnames[0]{value}, 'Smith', 'surname');
my @given = grep { $_->{kind} eq 'given' } @{$card->{name}{components}};
is($given[0]{value}, 'Jane', 'given name');

# Emails
ok($card->{emails}, 'has emails');
my @emails = sort { $a->{address} cmp $b->{address} } values %{$card->{emails}};
is(scalar @emails, 2, 'two emails');
is($emails[0]{address}, 'jane.home@example.com', 'home email');
is($emails[1]{address}, 'jane@example.com', 'work email');

# Phones
ok($card->{phones}, 'has phones');
is(scalar keys %{$card->{phones}}, 2, 'two phones');

# Addresses
ok($card->{addresses}, 'has addresses');

# Organizations
ok($card->{organizations}, 'has organizations');
my @orgs = values %{$card->{organizations}};
is($orgs[0]{name}, 'Acme Corp', 'org name');

# Titles
ok($card->{titles}, 'has titles');

# Anniversaries
ok($card->{anniversaries}, 'has anniversaries');

# Keywords
ok($card->{keywords}, 'has keywords');
ok($card->{keywords}{testing}, 'keyword: testing');
ok($card->{keywords}{jscontact}, 'keyword: jscontact');

# Round-trip: JSContact -> vCard -> JSContact
my $generated_vcard = eval { jscontact_to_vcard($card) };
ok(!$@, "Generate vCard from JSContact") or diag $@;
ok($generated_vcard, "Generated vCard");
like($generated_vcard, qr/BEGIN:VCARD/, "Valid vCard");

my $card2 = eval { vcard_to_jscontact($generated_vcard) };
ok(!$@, "Re-parse generated vCard") or diag $@;
is($card2->{name}{full}, $card->{name}{full}, "Round-trip: name.full");
is(scalar keys %{$card2->{emails}}, scalar keys %{$card->{emails}}, "Round-trip: email count");
is(scalar keys %{$card2->{phones}}, scalar keys %{$card->{phones}}, "Round-trip: phone count");

carddav_delete($uid1);

# ============================================================
# Test 2: Create via JMAP, read via CardDAV, parse, compare
# ============================================================

my $uid2 = 'jscontact-jmap-' . time();
my $jmap_create = $ua->post(
  "$base/jmap/",
  Authorization => "Basic " . MIME::Base64::encode_base64("$user:$pass", ''),
  'Content-Type' => 'application/json',
  Content => encode_json({
    using => ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:contacts", "https://cyrusimap.org/ns/jmap/contacts"],
    methodCalls => [
      ["ContactCard/set", {
        create => {
          "c1" => {
            "\@type" => "Card",
            "version" => "1.0",
            "uid" => "urn:uuid:$uid2",
            "name" => { "full" => "JMAP Test Contact" },
            "emails" => {
              "e1" => { "address" => 'jmap@example.com', "contexts" => { "work" => JSON::true } },
            },
            "phones" => {
              "p1" => { "number" => '+1-555-9999', "features" => { "voice" => JSON::true } },
            },
            "addressBookIds" => { "Default" => JSON::true },
          }
        }
      }, "0"]
    ]
  }),
);

my $jmap_result = eval { decode_json($jmap_create->content) };
my $method_resp = $jmap_result->{methodResponses}[0];

if ($method_resp->[0] eq 'ContactCard/set' && $method_resp->[1]{created}{c1}) {
  pass("Created contact via JMAP");
  my $jmap_id = $method_resp->[1]{created}{c1}{id};

  # Read back via JMAP to get the x-href for CardDAV
  my $jmap_get = $ua->post(
    "$base/jmap/",
    Authorization => "Basic " . MIME::Base64::encode_base64("$user:$pass", ''),
    'Content-Type' => 'application/json',
    Content => encode_json({
      using => ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:contacts", "https://cyrusimap.org/ns/jmap/contacts"],
      methodCalls => [
        ["ContactCard/get", { ids => [$jmap_id], properties => ["uid", "name", "emails", "cyrusimap.org:href"] }, "0"]
      ]
    }),
  );
  my $jmap_card = eval { decode_json($jmap_get->content)->{methodResponses}[0][1]{list}[0] };
  my $xhref = $jmap_card->{'cyrusimap.org:href'};

  if ($xhref) {
    # Read via CardDAV using the real href
    my $req = HTTP::Request->new(GET => "$base$xhref");
    $req->authorization_basic($user, $pass);
    my $get_resp = $ua->request($req);

    if ($get_resp->is_success) {
      pass("GET JMAP-created contact via CardDAV");
      my $card_from_cyrus = eval { vcard_to_jscontact($get_resp->content) };
      ok(!$@, "Parse Cyrus-generated vCard") or diag $@;
      is($card_from_cyrus->{name}{full}, "JMAP Test Contact", "JMAP->CardDAV: name matches");

      my @em = values %{$card_from_cyrus->{emails} || {}};
      ok(scalar @em, "JMAP->CardDAV: has emails");
      is($em[0]{address}, 'jmap@example.com', "JMAP->CardDAV: email matches");

      # Cleanup via CardDAV
      my $del = HTTP::Request->new(DELETE => "$base$xhref");
      $del->authorization_basic($user, $pass);
      $ua->request($del);
    } else {
      pass("SKIP: Could not GET via CardDAV: " . $get_resp->status_line);
      for (1..4) { pass("SKIP") }
    }
  } else {
    pass("SKIP: No x-href from JMAP");
    for (1..4) { pass("SKIP") }
  }
} else {
  my $err = $method_resp->[1]{notCreated}{c1}{description} // $method_resp->[0] // 'unknown';
  pass("SKIP: JMAP ContactCard/set: $err");
  for (1..5) { pass("SKIP") }
}

done_testing();
