#!/usr/bin/perl -w

# Copyright 2009, 2010, 2013 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use lib 'lib';
BEGIN {
  $ENV{'LANGUAGE'} = 'id:en_PIGLATIN:fr:pt_PT:en:sv';
}
use Time::Duration::Locale;


use I18N::LangTags;
use I18N::LangTags::Detect;

my @langs = I18N::LangTags::Detect::detect();
$, = "\n";
print @langs,'','';

@langs = I18N::LangTags::implicate_supers(@langs);
$, = "\n";
print @langs,'','';

@langs = I18N::LangTags::implicate_supers(qw(pt-br de-DE en-US fr pt-br-janeiro));
@langs = I18N::LangTags::implicate_supers_strictly(qw(pt-br de-DE en-US fr pt-br-janeiro));
@langs = I18N::LangTags::implicate_supers(qw(en-gb en-au));
$, = "\n";
print @langs,'','';
