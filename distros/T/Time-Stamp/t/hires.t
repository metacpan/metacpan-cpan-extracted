# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use ControlTime;

BEGIN {
  require Time::Stamp;
  my %args = (us => 1, format => 'easy');

  # tell TS that HiRes *is* available
  ControlTime->fake_have_hires(1);
  Time::Stamp->import(localstamp => { -as => 'localfrac', %args });

  # tell TS that HiRes is *not* available
  ControlTime->fake_have_hires(0);
  Time::Stamp->import(localstamp => { -as => 'localzero', %args });

  ControlTime->fraction(23456789);
}

sub frac_re { qr/^\d+-\d+-\d+ \d+:\d+:\d+\.($_[0])$/ }
*fstamp = \&localfrac;
*zstamp = \&localzero;

like localfrac(), qr/^\d+-\d+-\d+ \d+:\d+:\d+\.(234568)$/, 'local time with us';

# if fraction is specified it should be returned, even if we can't do better than zero
like localzero(), qr/^\d+-\d+-\d+ \d+:\d+:\d+\.(000000)$/,  'local time with whole number precision';

{
  my $t = ControlTime->new();

  like fstamp(), frac_re('234568'), 'time() overridden with stale value (plus fraction)';

  # 382 milliseconds
  $t->fraction(382);
  like fstamp(), frac_re('000382'), 'fraction has correct leading zeros';

  # if fraction is specified it should be returned, even if we can't do better than zero
  like zstamp(), frac_re('000000'), 'whole num precision has fraction of zeros';

  $t->fraction(43);
  like fstamp(), frac_re('000043'), 'fraction has correct leading zeros';

}

like fstamp('1356644666.345'),   frac_re('345000'), 'provided floating point retains precision';
like fstamp('1356644666.00345'), frac_re('003450'), 'provided floating point retains precision';

done_testing;
