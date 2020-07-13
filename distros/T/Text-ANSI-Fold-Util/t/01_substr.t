use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold::Util qw(ansi_substr);


$_ = "111222333";

my $s = ansi_substr($_, 3, 3);
is($s, "222", "ansi_substr");

my $s = Text::ANSI::Fold::Util::substr($_, 3, 3);
is($s, "222", "plain:");

my $s = Text::ANSI::Fold::Util::substr($_, 3);
is($s, "222333", "plain: no length");

my $s = Text::ANSI::Fold::Util::substr($_, -6, 3);
is($s, "222", "plain: negative offset");

my $s = Text::ANSI::Fold::Util::substr($_, -6);
is($s, "222333", "plain: negative offset, no length");

my $s = Text::ANSI::Fold::Util::substr($_, 3, 3, "000");
is($s, "111000333", "plain: replacement");


$_ = "\e[31m111222333\e[m";

my $s = Text::ANSI::Fold::Util::substr($_, 3, 3);
is($s, "\e[31m222\e[m", "color:");

my $s = Text::ANSI::Fold::Util::substr($_, -6, 3);
is($s, "\e[31m222\e[m", "color: negative offset");

my $s = Text::ANSI::Fold::Util::substr($_, -6);
is($s, "\e[31m222333\e[m", "color: negative offset, no length");

my $s = Text::ANSI::Fold::Util::substr($_, 3, 3, "000");
is($s, "\e[31m111\e[m000\e[31m333\e[m", "color: replacement");


$_ = "\e[31m111\e[m222\e[31m333\e[m";

my $s = Text::ANSI::Fold::Util::substr($_, 3, 3);
is($s, "222", "color: good break");


$_ = "\e[31m111\e[m222\e[31m333\e[m";

my $s = Text::ANSI::Fold::Util::substr($_, 2, 5);
is($s, "\e[31m1\e[m222\e[31m3\e[m", "color: good break");


done_testing;

