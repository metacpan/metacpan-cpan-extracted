#!/usr/bin/perl
# Hostile input: refused, never a crash.
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact);

my $n = 60000;
is(vcard_to_jscontact(("BEGIN:VCARD\r\n" x $n) . ("END:VCARD\r\n" x $n)), undef,
   'vCards nested 60000 deep: refused, not a crash in Text::VCardFast');
ok(vcard_to_jscontact("BEGIN:VCARD\r\nVERSION:4.0\r\nFN:Ann\r\nEND:VCARD\r\n"), 'an ordinary vCard still converts');

# a trailing backslash in a parameter value no longer breaks the card
{
  use Text::JSContact qw(jscontact_to_vcard);
  my $v = jscontact_to_vcard({ '@type' => 'Card', version => '2.0', uid => 'u',
                               name => { full => 'A', sortAs => { surname => "a \\" } } });
  ok(vcard_to_jscontact($v), 'a backslash in SORT-AS: the card still reads back');
}

done_testing;
