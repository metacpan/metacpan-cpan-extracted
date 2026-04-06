#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use JSON;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard);

my $j = JSON->new->utf8->canonical;

# Helper to test a single property conversion from a vCard snippet
sub test_vcard {
  my ($label, $vcard_body, $tests) = @_;

  my $fn = $vcard_body =~ /^FN[;:]/m ? '' : "FN:Test\n";
  my $vcard = "BEGIN:VCARD\nVERSION:4.0\nUID:urn:uuid:test\n${fn}${vcard_body}END:VCARD\n";
  my $card = vcard_to_jscontact($vcard);
  ok($card, "$label: parsed");
  $tests->($card) if $card;
}

# RFC 9555 Figure 7: KIND
test_vcard('KIND', "KIND:individual\n", sub {
  is($_[0]->{kind}, 'individual', 'kind=individual');
});

# RFC 9555 Figure 8: SOURCE
test_vcard('SOURCE', "SOURCE:https://dir.example.com/addrbook/jdoe/Jean%20Dupont.vcf\n", sub {
  ok($_[0]->{directories}, 'has directories');
  my @dirs = values %{$_[0]->{directories}};
  is($dirs[0]{kind}, 'entry', 'kind=entry');
  is($dirs[0]{uri}, 'https://dir.example.com/addrbook/jdoe/Jean%20Dupont.vcf', 'uri');
});

# RFC 9555 Figure 10: FN
test_vcard('FN', "FN:John Q. Public\\, Esq.\n", sub {
  is($_[0]->{name}{full}, 'John Q. Public, Esq.', 'full name with comma');
});

# RFC 9555 Figure 11: GRAMGENDER + PRONOUNS
test_vcard('GRAMGENDER+PRONOUNS',
  "GRAMGENDER:NEUTER\nPRONOUNS;PREF=2:they/them\nPRONOUNS;PREF=1:xe/xir\n", sub {
  my $sta = $_[0]->{speakToAs};
  ok($sta, 'has speakToAs');
  is($sta->{grammaticalGender}, 'neuter', 'grammaticalGender');
  ok($sta->{pronouns}, 'has pronouns');
  my @p = sort { $a->{pref} <=> $b->{pref} } values %{$sta->{pronouns}};
  is($p[0]{pronouns}, 'xe/xir', 'first pronoun by pref');
  is($p[0]{pref}, 1, 'pref=1');
  is($p[1]{pronouns}, 'they/them', 'second pronoun by pref');
  is($p[1]{pref}, 2, 'pref=2');
});

# RFC 9555 Figure 12: N with SORT-AS and multiple values
test_vcard('N-complex',
  "N;SORT-AS=\"Stevenson,John Philip\":Stevenson;John;Philip,Paul;Dr.;Jr.,M.D.,A.C.P.;;Jr.\n", sub {
  my $name = $_[0]->{name};
  ok($name->{components}, 'has components');

  my @surnames = grep { $_->{kind} eq 'surname' } @{$name->{components}};
  is($surnames[0]{value}, 'Stevenson', 'surname');

  my @given = grep { $_->{kind} eq 'given' } @{$name->{components}};
  is($given[0]{value}, 'John', 'given');

  my @given2 = grep { $_->{kind} eq 'given2' } @{$name->{components}};
  is(scalar @given2, 2, 'two given2 values');
  is($given2[0]{value}, 'Philip', 'given2[0]');
  is($given2[1]{value}, 'Paul', 'given2[1]');

  my @title = grep { $_->{kind} eq 'title' } @{$name->{components}};
  is($title[0]{value}, 'Dr.', 'title prefix');

  my @cred = grep { $_->{kind} eq 'credential' } @{$name->{components}};
  ok(scalar @cred >= 2, 'has credentials');

  my @gen = grep { $_->{kind} eq 'generation' } @{$name->{components}};
  is($gen[0]{value}, 'Jr.', 'generation');

  is($name->{sortAs}{surname}, 'Stevenson', 'sortAs surname');
  is($name->{sortAs}{given}, 'John Philip', 'sortAs given');
});

# RFC 9555 Figure 13: NICKNAME
test_vcard('NICKNAME', "NICKNAME:Johnny\n", sub {
  ok($_[0]->{nicknames}, 'has nicknames');
  my @nn = values %{$_[0]->{nicknames}};
  is($nn[0]{name}, 'Johnny', 'nickname');
});

# RFC 9555 Figure 14: PHOTO
test_vcard('PHOTO', "PHOTO:https://www.example.com/pub/photos/jqpublic.gif\n", sub {
  ok($_[0]->{media}, 'has media');
  my @m = values %{$_[0]->{media}};
  is($m[0]{kind}, 'photo', 'photo kind');
  is($m[0]{uri}, 'https://www.example.com/pub/photos/jqpublic.gif', 'photo uri');
});

# RFC 9555 Figure 16: EMAIL
test_vcard('EMAIL',
  "EMAIL;TYPE=work:jqpublic\@xyz.example.com\nEMAIL;PREF=1:jane_doe\@example.com\n", sub {
  ok($_[0]->{emails}, 'has emails');
  my @em = sort { $a->{address} cmp $b->{address} } values %{$_[0]->{emails}};
  is(scalar @em, 2, 'two emails');
  is($em[1]{address}, 'jqpublic@xyz.example.com', 'work email');
  ok($em[1]{contexts}{work}, 'work context');
  is($em[0]{address}, 'jane_doe@example.com', 'personal email');
  is($em[0]{pref}, 1, 'pref=1');
});

# RFC 9555 Figure 17: IMPP
test_vcard('IMPP', "IMPP;PREF=1:xmpp:alice\@example.com\n", sub {
  ok($_[0]->{onlineServices}, 'has onlineServices');
  my @os = values %{$_[0]->{onlineServices}};
  is($os[0]{uri}, 'xmpp:alice@example.com', 'impp uri');
  is($os[0]{pref}, 1, 'pref=1');
});

# RFC 9555 Figure 18: LANG
test_vcard('LANG',
  "LANG;TYPE=work;PREF=1:en\nLANG;TYPE=work;PREF=2:fr\nLANG;TYPE=home:fr\n", sub {
  ok($_[0]->{preferredLanguages}, 'has preferredLanguages');
  my @langs = sort { ($a->{pref}//99) <=> ($b->{pref}//99) } values %{$_[0]->{preferredLanguages}};
  is(scalar @langs, 3, 'three language prefs');
  is($langs[0]{language}, 'en', 'first lang');
  is($langs[0]{pref}, 1, 'pref=1');
  ok($langs[0]{contexts}{work}, 'work context');
});

# RFC 9555 Figure 19: LANGUAGE
test_vcard('LANGUAGE', "LANGUAGE:de-AT\n", sub {
  is($_[0]->{language}, 'de-AT', 'language');
});

# RFC 9555 Figure 20: SOCIALPROFILE
test_vcard('SOCIALPROFILE',
  "SOCIALPROFILE;SERVICE-TYPE=Mastodon:https://example.com/\@foo\n", sub {
  ok($_[0]->{onlineServices}, 'has onlineServices');
  my @os = values %{$_[0]->{onlineServices}};
  is($os[0]{service}, 'Mastodon', 'service');
  is($os[0]{uri}, 'https://example.com/@foo', 'uri');
});

# RFC 9555 Figure 21: TEL with multiple types
test_vcard('TEL',
  "TEL;VALUE=uri;PREF=1;TYPE=\"voice,home\":tel:+1-555-555-5555;ext=5555\nTEL;VALUE=uri;TYPE=home:tel:+33-01-23-45-67\n", sub {
  ok($_[0]->{phones}, 'has phones');
  my @ph = sort { ($a->{pref}//99) <=> ($b->{pref}//99) } values %{$_[0]->{phones}};
  is(scalar @ph, 2, 'two phones');
  is($ph[0]{number}, 'tel:+1-555-555-5555;ext=5555', 'first phone number');
  ok($ph[0]{contexts}{private}, 'home -> private');
  ok($ph[0]{features}{voice}, 'voice feature');
  is($ph[0]{pref}, 1, 'pref=1');
});

# RFC 9555 Figure 25: ORG with SORT-AS
test_vcard('ORG',
  "ORG;SORT-AS=\"ABC\":ABC\\, Inc.;North American Division;Marketing\n", sub {
  ok($_[0]->{organizations}, 'has organizations');
  my @orgs = values %{$_[0]->{organizations}};
  is($orgs[0]{name}, 'ABC, Inc.', 'org name');
  is(scalar @{$orgs[0]{units}}, 2, 'two units');
  is($orgs[0]{units}[0]{name}, 'North American Division', 'first unit');
  is($orgs[0]{units}[1]{name}, 'Marketing', 'second unit');
  is($orgs[0]{sortAs}, 'ABC', 'sortAs');
});

# RFC 9555 Figure 26: RELATED
test_vcard('RELATED',
  "RELATED;TYPE=friend:urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6\nRELATED;TYPE=contact:https://example.com/directory/john.vcf\n", sub {
  ok($_[0]->{relatedTo}, 'has relatedTo');
  my $r1 = $_[0]->{relatedTo}{'urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6'};
  ok($r1, 'related friend');
  ok($r1->{relation}{friend}, 'friend relation');
  my $r2 = $_[0]->{relatedTo}{'https://example.com/directory/john.vcf'};
  ok($r2, 'related contact');
  ok($r2->{relation}{contact}, 'contact relation');
});

# RFC 9555 Figure 28: EXPERTISE
test_vcard('EXPERTISE',
  "EXPERTISE;LEVEL=beginner;INDEX=2:Chinese literature\nEXPERTISE;INDEX=1;LEVEL=expert:chemistry\n", sub {
  ok($_[0]->{personalInfo}, 'has personalInfo');
  my @pi = sort { ($a->{listAs}//0) <=> ($b->{listAs}//0) } values %{$_[0]->{personalInfo}};
  is($pi[0]{kind}, 'expertise', 'expertise kind');
  is($pi[0]{value}, 'chemistry', 'chemistry');
  is($pi[0]{level}, 'high', 'expert -> high');
  is($pi[0]{listAs}, 1, 'listAs=1');
  is($pi[1]{value}, 'Chinese literature', 'Chinese literature');
  is($pi[1]{level}, 'low', 'beginner -> low');
  is($pi[1]{listAs}, 2, 'listAs=2');
});

# RFC 9555 Figure 32: CATEGORIES
test_vcard('CATEGORIES',
  "CATEGORIES:internet,IETF,Industry,Information Technology\n", sub {
  ok($_[0]->{keywords}, 'has keywords');
  ok($_[0]->{keywords}{internet}, 'internet');
  ok($_[0]->{keywords}{IETF}, 'IETF');
  ok($_[0]->{keywords}{Industry}, 'Industry');
  ok($_[0]->{keywords}{'Information Technology'}, 'Information Technology');
});

# RFC 9555 Figure 33: CREATED
test_vcard('CREATED', "CREATED:19940930T143510Z\n", sub {
  is($_[0]->{created}, '1994-09-30T14:35:10Z', 'created normalized');
});

# RFC 9555 Figure 34: NOTE with author and created
test_vcard('NOTE',
  "NOTE;CREATED=20221123T150132Z;AUTHOR-NAME=\"John\":Office hours are from 0800 to 1715 EST\\, Mon-Fri.\n", sub {
  ok($_[0]->{notes}, 'has notes');
  my @n = values %{$_[0]->{notes}};
  is($n[0]{note}, 'Office hours are from 0800 to 1715 EST, Mon-Fri.', 'note text');
  is($n[0]{created}, '2022-11-23T15:01:32Z', 'note created');
  is($n[0]{author}{name}, 'John', 'note author name');
});

# RFC 9555 Figure 35: PRODID
test_vcard('PRODID', "PRODID:ACME Contacts App version 1.23.5\n", sub {
  is($_[0]->{prodId}, 'ACME Contacts App version 1.23.5', 'prodId');
});

# RFC 9555 Figure 36: REV
test_vcard('REV', "REV:19951031T222710Z\n", sub {
  is($_[0]->{updated}, '1995-10-31T22:27:10Z', 'updated normalized');
});

# RFC 9555 Figure 24: MEMBER (group)
test_vcard('GROUP',
  "KIND:group\nMEMBER:urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af\nMEMBER:urn:uuid:b8767877-b4a1-4c70-9acc-505d3819e519\n", sub {
  is($_[0]->{kind}, 'group', 'kind=group');
  ok($_[0]->{members}, 'has members');
  ok($_[0]->{members}{'urn:uuid:03a0e51f-d1aa-4385-8a53-e29025acd8af'}, 'member 1');
  ok($_[0]->{members}{'urn:uuid:b8767877-b4a1-4c70-9acc-505d3819e519'}, 'member 2');
});

# RFC 9555 Figure 9: BDAY + ANNIVERSARY + DEATHDATE
test_vcard('ANNIVERSARIES',
  "BDAY:19531015\nANNIVERSARY:19860201\n", sub {
  ok($_[0]->{anniversaries}, 'has anniversaries');
  my @anns = values %{$_[0]->{anniversaries}};
  my ($bday) = grep { $_->{kind} eq 'birth' } @anns;
  my ($wedding) = grep { $_->{kind} eq 'wedding' } @anns;
  ok($bday, 'has birthday');
  is($bday->{date}, '1953-10-15', 'birthday date');
  ok($wedding, 'has wedding');
  is($wedding->{date}, '1986-02-01', 'wedding date');
});

# RFC 9555 Figure 22: CONTACT-URI
test_vcard('CONTACT-URI', "CONTACT-URI;PREF=1:mailto:contact\@example.com\n", sub {
  ok($_[0]->{links}, 'has links');
  my @l = values %{$_[0]->{links}};
  is($l[0]{kind}, 'contact', 'kind=contact');
  is($l[0]{uri}, 'mailto:contact@example.com', 'uri');
  is($l[0]{pref}, 1, 'pref=1');
});

# RFC 9555 Figure 23: LOGO
test_vcard('LOGO', "LOGO:https://www.example.com/pub/logos/abccorp.jpg\n", sub {
  ok($_[0]->{media}, 'has media');
  my @m = values %{$_[0]->{media}};
  is($m[0]{kind}, 'logo', 'logo kind');
  is($m[0]{uri}, 'https://www.example.com/pub/logos/abccorp.jpg', 'logo uri');
});

done_testing();
