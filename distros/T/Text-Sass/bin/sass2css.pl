#!/usr/bin/env perl
#########
# Author:        rmp
# Last Modified: $Date: 2010-10-28 17:09:19 +0100 (Thu, 28 Oct 2010) $
# Id:            $Id: sass2css.pl 19 2010-10-28 16:09:19Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/bin/sass2css.pl $
#
use strict;
use warnings;
use lib qw(lib);
use Text::Sass;
use Carp;
use English qw(-no_match_vars);

our $VERSION = '1.00';

my $sass = Text::Sass->new();

if(!scalar @ARGV) {
  local $RS = undef;
  my $str   = <>;
  print $sass->sass2css($str) or croak $ERRNO;
}
