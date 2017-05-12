#!perl -w
use strict;
use Test::More tests => 6;

BEGIN { use_ok("Unicode::ICU::Collator", ":constants") }

{
  my @avail = Unicode::ICU::Collator->available;
  ok(@avail, "at least some are available");
  my ($en) = grep $_ eq "en", @avail;
  ok($en, "en is available");
}

{
  is(ULOC_ACTUAL_LOCALE, 0, "ULOC_ACTUAL_LOCALE");
  print "# ", ULOC_ACTUAL_LOCALE(), "\n";
  is(ULOC_VALID_LOCALE, 1, "ULOC_VALID_LOCALE");
}

{
  is(Unicode::ICU::Collator->getDisplayName("en", "en"), "English",
     "en is English");
}
