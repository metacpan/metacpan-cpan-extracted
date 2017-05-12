# -*- Mode: CPerl -*-
# t/01_ini.t; just to load module(s) by using it (them)

use Test::More tests => 7;

BEGIN {
  my @modules = map {"Tie::File::Indexed".$_} ('',qw(::Utf8 ::JSON ::Storable ::StorableN ::Freeze ::FreezeN));
  use_ok($_) foreach (@modules);
}

# end of t/01_ini.t
