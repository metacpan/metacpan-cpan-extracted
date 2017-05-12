use strict;
use warnings;
use Test::More;

use lib qw( ../lib );

my @modules = qw(
  Wcpancover
  Wcpancover::Admin
  Wcpancover::Front

  Wcpancover::DB::Schema

  Wcpancover::DB::Schema::Result::Package

  Wcpancover::I18N::de
  Wcpancover::I18N::en

);

eval "package Wcpancover::I18N; use base 'Locale::Maketext'; 1;";

for my $module (@modules) {
  use_ok($module);
}

done_testing;
