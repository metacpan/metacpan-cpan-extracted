#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

# Test Apple iOS-style vCard with all extensions
my $apple_vcard = <<'VCARD';
BEGIN:VCARD
VERSION:3.0
PRODID:-//Apple Inc.//iOS 8.1.1//EN
N:Smith;Jane;Marie;Dr.;PhD
FN:Dr. Jane Marie Smith PhD
NICKNAME:Janey
X-PHONETIC-FIRST-NAME:Jeyn
X-PHONETIC-LAST-NAME:Smith
ORG:SuperCorp;Engineering
TITLE:CTO
EMAIL;type=INTERNET;type=HOME;type=pref:jane@home.example
item1.EMAIL;type=INTERNET:jane@icloud.example
item1.X-ABLabel:iCloud
item2.EMAIL;type=INTERNET:jane@custom.example
item2.X-ABLabel:Customemail
TEL;type=HOME;type=VOICE;type=pref:+1-555-0100
item3.TEL:+1-555-0199
item3.X-ABLabel:Customphone
item4.ADR;type=HOME;type=pref:;;42 Wallaby Way;Sydney;NSW;2000;Australia
item4.X-ABADR:au
BDAY:1985-03-15
item5.X-ABDATE;type=pref:2010-06-20
item5.X-ABLabel:_$!<Anniversary>!$_
item6.X-ABDATE:2020-01-01
item6.X-ABLabel:Customdate
item7.X-ABRELATEDNAMES;type=pref:John Smith
item7.X-ABLabel:_$!<Spouse>!$_
item8.X-ABRELATEDNAMES:Bob Smith
item8.X-ABLabel:_$!<Father>!$_
item9.X-ABRELATEDNAMES:Alice Smith
item9.X-ABLabel:_$!<Friend>!$_
X-SOCIALPROFILE;type=twitter;x-user=janesmith:http://twitter.com/janesmith
X-SOCIALPROFILE;type=linkedin;x-user=janesmith:http://www.linkedin.com/in/janesmith
item10.IMPP;X-SERVICE-TYPE=Skype;type=pref:skype:janeskype
item10.X-ABLabel:Skype
X-AIM:janeaim
X-JABBER:jane@jabber.example
URL;type=HOME:https://jane.example.com
NOTE:Apple test contact
END:VCARD
VCARD

my $card = vcard_to_jscontact($apple_vcard);
ok($card, 'parsed Apple vCard');

# Name
is($card->{name}{full}, 'Dr. Jane Marie Smith PhD', 'full name');

# Phonetic names
ok($card->{name}{phoneticComponents}, 'has phonetic components');
my @phon_given = grep { $_->{kind} eq 'given' } @{$card->{name}{phoneticComponents}};
is($phon_given[0]{value}, 'Jeyn', 'phonetic first name');
my @phon_surname = grep { $_->{kind} eq 'surname' } @{$card->{name}{phoneticComponents}};
is($phon_surname[0]{value}, 'Smith', 'phonetic last name');

# Emails with X-ABLabel
ok($card->{emails}, 'has emails');
my @emails = values %{$card->{emails}};
my ($icloud_email) = grep { ($_->{address} // '') eq 'jane@icloud.example' } @emails;
ok($icloud_email, 'found iCloud email');
is($icloud_email->{label}, 'iCloud', 'iCloud label preserved');
my ($custom_email) = grep { ($_->{address} // '') eq 'jane@custom.example' } @emails;
ok($custom_email, 'found custom email');
is($custom_email->{label}, 'Customemail', 'custom email label preserved');

# Phones with X-ABLabel
ok($card->{phones}, 'has phones');
my @phones = values %{$card->{phones}};
my ($custom_phone) = grep { ($_->{label} // '') eq 'Customphone' } @phones;
ok($custom_phone, 'found custom-labeled phone');

# Address with X-ABADR country code
ok($card->{addresses}, 'has addresses');
my @addrs = values %{$card->{addresses}};
is($addrs[0]{countryCode}, 'au', 'X-ABADR country code');

# Anniversaries from BDAY + X-ABDATE
ok($card->{anniversaries}, 'has anniversaries');
my @anns = values %{$card->{anniversaries}};
my ($bday) = grep { $_->{kind} eq 'birth' } @anns;
ok($bday, 'has birthday');
is($bday->{date}, '1985-03-15', 'birthday date');
my ($wedding) = grep { $_->{kind} eq 'wedding' } @anns;
ok($wedding, 'X-ABDATE Anniversary -> wedding');
is($wedding->{date}, '2010-06-20', 'anniversary date');
my ($custom_date) = grep { ($_->{kind} // '') eq 'customdate' } @anns;
ok($custom_date, 'X-ABDATE custom date');

# Related from X-ABRELATEDNAMES
ok($card->{relatedTo}, 'has relatedTo');
my $spouse_rel = $card->{relatedTo}{'John Smith'};
ok($spouse_rel, 'found spouse relation');
ok($spouse_rel->{relation}{spouse}, 'spouse relation type');
my $father_rel = $card->{relatedTo}{'Bob Smith'};
ok($father_rel, 'found father relation');
ok($father_rel->{relation}{parent}, 'father -> parent relation type');
my $friend_rel = $card->{relatedTo}{'Alice Smith'};
ok($friend_rel, 'found friend relation');
ok($friend_rel->{relation}{friend}, 'friend relation type');

# Online services from X-SOCIALPROFILE + IMPP + legacy X-properties
ok($card->{onlineServices}, 'has onlineServices');
my @services = values %{$card->{onlineServices}};
my ($twitter) = grep { ($_->{service} // '') =~ /twitter/i } @services;
ok($twitter, 'found twitter');
is($twitter->{user}, 'janesmith', 'twitter username');
my ($skype) = grep { ($_->{service} // '') =~ /skype/i } @services;
ok($skype, 'found skype');
my ($aim) = grep { ($_->{service} // '') eq 'AIM' } @services;
ok($aim, 'found AIM from X-AIM');
is($aim->{user}, 'janeaim', 'AIM username');
my ($jabber) = grep { ($_->{service} // '') eq 'Jabber' } @services;
ok($jabber, 'found Jabber from X-JABBER');

# Test X-ABLabel round-trip on output
my $vcard_out = jscontact_to_vcard($card);
ok($vcard_out, 'generated vCard from JSContact');
like($vcard_out, qr/X-ABLabel/i, 'output contains X-ABLabel');

# Re-parse and verify labels survive
my $card2 = vcard_to_jscontact($vcard_out);
my @emails2 = values %{$card2->{emails}};
my ($icloud2) = grep { ($_->{label} // '') eq 'iCloud' } @emails2;
ok($icloud2, 'iCloud label survives round-trip');

# Apple group contact
my $group_vcard = <<'VCARD';
BEGIN:VCARD
VERSION:3.0
X-ADDRESSBOOKSERVER-KIND:group
N:Family
FN:Family
X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:member-1
X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:member-2
X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:member-3
END:VCARD
VCARD

my $group = vcard_to_jscontact($group_vcard);
ok($group, 'parsed Apple group vCard');
is($group->{kind}, 'group', 'kind is group');
ok($group->{members}, 'has members');
ok($group->{members}{'urn:uuid:member-1'}, 'member 1');
ok($group->{members}{'urn:uuid:member-2'}, 'member 2');
ok($group->{members}{'urn:uuid:member-3'}, 'member 3');
is(scalar keys %{$group->{members}}, 3, 'three members');

done_testing();
