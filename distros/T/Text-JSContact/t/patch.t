#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

# Original vCard with Apple extensions and custom X-properties
my $original = <<'VCARD';
BEGIN:VCARD
VERSION:3.0
PRODID:-//Apple Inc.//iOS 17//EN
UID:urn:uuid:patch-test-001
N:Smith;Jane;;;
FN:Jane Smith
EMAIL;type=HOME:jane@home.example
item1.EMAIL;type=INTERNET:jane@work.example
item1.X-ABLabel:Work Email
TEL;type=CELL:+1-555-0100
ADR;type=HOME:;;42 Wallaby Way;Sydney;NSW;2000;Australia
ORG:Acme Corp
NOTE:Original note
X-CUSTOM-PROP:this should be preserved
X-ANOTHER-CUSTOM:also preserved
item2.X-ABRELATEDNAMES:John Smith
item2.X-ABLabel:_$!<Spouse>!$_
BDAY:1985-03-15
END:VCARD
VCARD

# Parse the original
my $old_card = vcard_to_jscontact($original);
ok($old_card, 'parsed original');

# ============================================================
# Test 1: Change only the name, everything else preserved
# ============================================================

my $new_card = { %$old_card };
$new_card->{name} = { %{$old_card->{name}}, full => 'Jane Q. Smith' };

my $patched = patch_vcard($original, $old_card, $new_card);
ok($patched, 'patch_vcard returned result');

# Custom properties should be preserved
like($patched, qr/X-CUSTOM-PROP:this should be preserved/, 'X-CUSTOM-PROP preserved');
like($patched, qr/X-ANOTHER-CUSTOM:also preserved/, 'X-ANOTHER-CUSTOM preserved');

# Name should be updated
like($patched, qr/FN:Jane Q\. Smith/, 'FN updated');

# Other properties should still be there
like($patched, qr/jane\@home\.example/, 'home email preserved');
like($patched, qr/\+1-555-0100/, 'phone preserved');
like($patched, qr/Acme Corp/, 'org preserved');

# Re-parse and verify
my $reparsed = vcard_to_jscontact($patched);
is($reparsed->{name}{full}, 'Jane Q. Smith', 'name updated after reparsing');
is(scalar keys %{$reparsed->{emails}}, 2, 'email count unchanged');

# ============================================================
# Test 2: Add a new email, keep everything else
# ============================================================

my $new_card2 = { %$old_card };
my %new_emails = %{$old_card->{emails}};
$new_emails{new1} = { address => 'jane@new.example', contexts => { work => JSON::true } };
$new_card2->{emails} = \%new_emails;

my $patched2 = patch_vcard($original, $old_card, $new_card2);
ok($patched2, 'patch with new email');
like($patched2, qr/X-CUSTOM-PROP/, 'custom props still preserved');
like($patched2, qr/jane\@new\.example/, 'new email present');

my $reparsed2 = vcard_to_jscontact($patched2);
is(scalar keys %{$reparsed2->{emails}}, 3, 'now three emails');

# ============================================================
# Test 3: Change nothing -> original preserved exactly
# ============================================================

my $patched3 = patch_vcard($original, $old_card, $old_card);
is($patched3, $original, 'no changes -> original returned verbatim');

# ============================================================
# Test 4: Update phone number, verify labels on other props survive
# ============================================================

my $new_card4 = { %$old_card };
my %new_phones = %{$old_card->{phones}};
my ($phone_id) = keys %new_phones;
$new_phones{$phone_id} = { %{$new_phones{$phone_id}}, number => '+1-555-9999' };
$new_card4->{phones} = \%new_phones;

my $patched4 = patch_vcard($original, $old_card, $new_card4);
ok($patched4, 'patch with changed phone');
like($patched4, qr/\+1-555-9999/, 'new phone number present');
# Email label should still be there
like($patched4, qr/Work Email/, 'email X-ABLabel preserved');
like($patched4, qr/X-CUSTOM-PROP/, 'custom props preserved');

# ============================================================
# Test 5: Delete a property
# ============================================================

my $new_card5 = { %$old_card };
delete $new_card5->{notes};

my $patched5 = patch_vcard($original, $old_card, $new_card5);
ok($patched5, 'patch with deleted notes');
unlike($patched5, qr/NOTE:/, 'NOTE removed');
like($patched5, qr/X-CUSTOM-PROP/, 'custom props still preserved');
like($patched5, qr/jane\@home\.example/, 'emails still there');

# ============================================================
# Test 6: Patch Apple group - adding member uses X-ADDRESSBOOKSERVER-MEMBER
# ============================================================

my $apple_group = <<'VCARD';
BEGIN:VCARD
VERSION:3.0
X-ADDRESSBOOKSERVER-KIND:group
N:Family
FN:Family
X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:member-1
X-ADDRESSBOOKSERVER-MEMBER:urn:uuid:member-2
X-CUSTOM-GROUP-PROP:keep me
END:VCARD
VCARD

my $old_group = vcard_to_jscontact($apple_group);
ok($old_group, 'parsed Apple group');

# Add a new member
my $new_group = { %$old_group };
my %new_members = %{$old_group->{members}};
$new_members{'urn:uuid:member-3'} = JSON::true;
$new_group->{members} = \%new_members;

my $patched_group = patch_vcard($apple_group, $old_group, $new_group);
ok($patched_group, 'patched Apple group');

# Should use X-ADDRESSBOOKSERVER-MEMBER, NOT standard MEMBER
like($patched_group, qr/X-ADDRESSBOOKSERVER-MEMBER/, 'uses Apple member property');
unlike($patched_group, qr/^MEMBER:/m, 'does NOT use standard MEMBER');
like($patched_group, qr/member-3/, 'new member present');
like($patched_group, qr/member-1/, 'old member-1 preserved');
like($patched_group, qr/member-2/, 'old member-2 preserved');

# Should use X-ADDRESSBOOKSERVER-KIND, NOT standard KIND
like($patched_group, qr/X-ADDRESSBOOKSERVER-KIND:group/, 'uses Apple kind property');
unlike($patched_group, qr/^KIND:/m, 'does NOT use standard KIND');

# Custom properties preserved
like($patched_group, qr/X-CUSTOM-GROUP-PROP:keep me/, 'custom group prop preserved');

# Re-parse to verify
my $reparsed_group = vcard_to_jscontact($patched_group);
is($reparsed_group->{kind}, 'group', 'kind still group');
is(scalar keys %{$reparsed_group->{members}}, 3, 'now three members');

done_testing();
