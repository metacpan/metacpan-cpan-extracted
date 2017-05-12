#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

BEGIN {
  ok(eval{require Wx});
  ok(eval{require wxPerl::Styles});
}

use wxPerl::Styles qw(style wxVal ID);

is(wxVal('align_right'), Wx::wxALIGN_RIGHT());
is(wxVal('ALIGN_RIGHT'), Wx::wxALIGN_RIGHT());

is(
  wxVal('align_right', te => 'multiline'),
  Wx::wxALIGN_RIGHT()|Wx::wxTE_MULTILINE()
);

is(
  wxVal('align_right', te => 'multiline|process_enter'),
  Wx::wxALIGN_RIGHT()|Wx::wxTE_MULTILINE()|Wx::wxTE_PROCESS_ENTER()
);

is_deeply(
  [style('align_right', te => 'multiline|process_enter')],
  [style => Wx::wxALIGN_RIGHT()|Wx::wxTE_MULTILINE()|Wx::wxTE_PROCESS_ENTER()],
);

is_deeply([ID('ok')], [id => Wx::wxID_OK()]);

# vim:ts=2:sw=2:et:sta
