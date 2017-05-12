#! /usr/bin/perl

# WWW::NicoVideo example
# usage: perl -Ilib examples/ritsuko.pl your-mail@ritsuko.org your-password

use utf8;
use strict;
use warnings;
use YAML;
use WWW::NicoVideo;

binmode STDOUT, ":encoding(euc-jp)";

MAIN: {
  my $mail = shift || die "mail required";
  my $passwd = shift || die "passwd required";

  my $nv = new WWW::NicoVideo();
  $nv->mail($mail);
  $nv->passwd($passwd);

  $nv->login or die "login failed";

  print Dump($nv->getEntriesByTagNames(keys => ["アイマス", "律子"]));
  print "\n====\n";
  print Dump($nv->getEntriesByKeywords(key => "リッチャンハ、カワイイデスヨ"));
}
