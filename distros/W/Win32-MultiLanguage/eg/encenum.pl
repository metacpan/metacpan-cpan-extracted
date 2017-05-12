#!/usr/bin/perl
use strict;
use warnings;
use Win32::MultiLanguage;

print "Encodings supported on this system:\n";

foreach my $info (Win32::MultiLanguage::EnumCodePages()) {
  printf "%s (%s)\n", $info->{WebCharset}, $info->{Description};
}