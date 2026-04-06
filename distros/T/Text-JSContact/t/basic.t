#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $j = JSON->new->utf8->canonical->pretty;

# Basic vCard 4.0
my $vcard = <<'VCARD';
BEGIN:VCARD
VERSION:4.0
UID:urn:uuid:1234-5678
FN:John Q. Doe
N:Doe;John;Quincy;Mr.;Jr.
NICKNAME:Johnny
EMAIL;TYPE=work:john@example.com
EMAIL;TYPE=home;PREF=1:john@home.example
TEL;TYPE=work,voice:+1-555-1234
TEL;TYPE=cell:+1-555-5678
ADR;TYPE=home:;;123 Main St;Anytown;CA;90210;USA
ORG:Acme Corp;Engineering
TITLE:Senior Engineer
ROLE:Lead Developer
BDAY:1990-05-15
NOTE:A test contact
URL:https://example.com
CATEGORIES:friends,work
PHOTO;MEDIATYPE=image/jpeg:https://example.com/photo.jpg
KEY:https://example.com/key.asc
REV:20230101T120000Z
PRODID:-//Test//Test//EN
END:VCARD
VCARD

# Test vCard -> JSContact
my $card = vcard_to_jscontact($vcard);
ok($card, 'parsed vCard to JSContact');
is($card->{'@type'}, 'Card', '@type is Card');
is($card->{version}, '1.0', 'version is 1.0');
is($card->{uid}, 'urn:uuid:1234-5678', 'uid preserved');

# Name
ok($card->{name}, 'has name');
is($card->{name}{full}, 'John Q. Doe', 'full name');
ok($card->{name}{components}, 'has name components');
my @surnames = grep { $_->{kind} eq 'surname' } @{$card->{name}{components}};
is($surnames[0]{value}, 'Doe', 'surname is Doe');
my @given = grep { $_->{kind} eq 'given' } @{$card->{name}{components}};
is($given[0]{value}, 'John', 'given name is John');
my @given2 = grep { $_->{kind} eq 'given2' } @{$card->{name}{components}};
is($given2[0]{value}, 'Quincy', 'given2 is Quincy');
my @titles = grep { $_->{kind} eq 'title' } @{$card->{name}{components}};
is($titles[0]{value}, 'Mr.', 'title is Mr.');
my @creds = grep { $_->{kind} eq 'credential' } @{$card->{name}{components}};
is($creds[0]{value}, 'Jr.', 'credential is Jr.');

# Nicknames
ok($card->{nicknames}, 'has nicknames');
my @nn = values %{$card->{nicknames}};
is($nn[0]{name}, 'Johnny', 'nickname is Johnny');

# Emails
ok($card->{emails}, 'has emails');
my @emails = sort { $a->{address} cmp $b->{address} } values %{$card->{emails}};
is(scalar @emails, 2, 'two emails');
is($emails[0]{address}, 'john@example.com', 'work email');
ok($emails[0]{contexts}{work}, 'work context');
is($emails[1]{address}, 'john@home.example', 'home email');
ok($emails[1]{contexts}{private}, 'home -> private context');
is($emails[1]{pref}, 1, 'pref=1');

# Phones
ok($card->{phones}, 'has phones');
my @phones = sort { $a->{number} cmp $b->{number} } values %{$card->{phones}};
is(scalar @phones, 2, 'two phones');
is($phones[0]{number}, '+1-555-1234', 'work phone');
ok($phones[0]{contexts}{work}, 'work context on phone');
ok($phones[0]{features}{voice}, 'voice feature');
is($phones[1]{number}, '+1-555-5678', 'cell phone');
ok($phones[1]{features}{mobile}, 'cell -> mobile feature');

# Addresses
ok($card->{addresses}, 'has addresses');
my @addrs = values %{$card->{addresses}};
is(scalar @addrs, 1, 'one address');
ok($addrs[0]{contexts}{private}, 'home -> private context');
my @locality = grep { $_->{kind} eq 'locality' } @{$addrs[0]{components}};
is($locality[0]{value}, 'Anytown', 'locality');
my @region = grep { $_->{kind} eq 'region' } @{$addrs[0]{components}};
is($region[0]{value}, 'CA', 'region');
my @postcode = grep { $_->{kind} eq 'postcode' } @{$addrs[0]{components}};
is($postcode[0]{value}, '90210', 'postcode');

# Organizations
ok($card->{organizations}, 'has organizations');
my @orgs = values %{$card->{organizations}};
is($orgs[0]{name}, 'Acme Corp', 'org name');
is($orgs[0]{units}[0]{name}, 'Engineering', 'org unit');

# Titles
ok($card->{titles}, 'has titles');
my @t = sort { $a->{kind} cmp $b->{kind} } values %{$card->{titles}};
is(scalar @t, 2, 'title and role');
my ($role_t) = grep { $_->{kind} eq 'role' } @t;
my ($title_t) = grep { $_->{kind} eq 'title' } @t;
is($role_t->{name}, 'Lead Developer', 'role');
is($title_t->{name}, 'Senior Engineer', 'title');

# Anniversaries
ok($card->{anniversaries}, 'has anniversaries');
my @ann = values %{$card->{anniversaries}};
is($ann[0]{kind}, 'birth', 'birthday');
is($ann[0]{date}, '1990-05-15', 'birthday date');

# Notes
ok($card->{notes}, 'has notes');
my @notes = values %{$card->{notes}};
is($notes[0]{note}, 'A test contact', 'note text');

# Keywords
ok($card->{keywords}, 'has keywords');
ok($card->{keywords}{friends}, 'friends keyword');
ok($card->{keywords}{work}, 'work keyword');

# Links
ok($card->{links}, 'has links');
my @links = values %{$card->{links}};
is($links[0]{uri}, 'https://example.com', 'url');

# Media
ok($card->{media}, 'has media');
my @media = values %{$card->{media}};
is($media[0]{kind}, 'photo', 'photo kind');
is($media[0]{uri}, 'https://example.com/photo.jpg', 'photo uri');

# Crypto Keys
ok($card->{cryptoKeys}, 'has cryptoKeys');
my @keys = values %{$card->{cryptoKeys}};
is($keys[0]{uri}, 'https://example.com/key.asc', 'key uri');

# Metadata
is($card->{updated}, '2023-01-01T12:00:00Z', 'updated');
is($card->{prodId}, '-//Test//Test//EN', 'prodId');

# Test round-trip: JSContact -> vCard -> JSContact
my $vcard_out = jscontact_to_vcard($card);
ok($vcard_out, 'generated vCard from JSContact');
like($vcard_out, qr/BEGIN:VCARD/, 'has BEGIN');
like($vcard_out, qr/VERSION:4\.0/, 'version 4.0');
like($vcard_out, qr/FN:John Q\. Doe/, 'has FN');
like($vcard_out, qr/UID:urn:uuid:1234-5678/, 'has UID');

my $card2 = vcard_to_jscontact($vcard_out);
ok($card2, 'parsed round-tripped vCard');
is($card2->{uid}, $card->{uid}, 'uid round-trips');
is($card2->{name}{full}, $card->{name}{full}, 'name round-trips');
is(scalar keys %{$card2->{emails}}, scalar keys %{$card->{emails}}, 'email count round-trips');
is(scalar keys %{$card2->{phones}}, scalar keys %{$card->{phones}}, 'phone count round-trips');

done_testing();
