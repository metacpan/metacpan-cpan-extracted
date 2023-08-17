use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Tk::CodeText::Theme') };

my $theme = Tk::CodeText::Theme->new;
ok((defined $theme), "Theme object defined");

