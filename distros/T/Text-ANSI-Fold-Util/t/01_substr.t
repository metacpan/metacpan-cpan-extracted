use strict;
use Test::More 0.98;
use utf8;
use charnames ':full';

use Text::ANSI::Fold::Util qw(ansi_substr);


$_ = "111222333";

my $s = ansi_substr($_, 30, 30);
is($s, undef, "undef");

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

my $s = Text::ANSI::Fold::Util::substr($_, 9, 0, "000");
is($s, "111222333000", "plain: replacement (unmatch)");

{
local $TODO = "shoud be error";
my $s = Text::ANSI::Fold::Util::substr($_, 10, 0, "000");
is($s, undef, "plain: replacement for unmatched substr");
}

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

$_ = "\e[31m111222\e[m";

my $s = Text::ANSI::Fold::Util::substr($_, 3, 6);
is($s, "\e[31m222\e[m", "color: no-padding");

Text::ANSI::Fold->configure(padding => 1);
my $s = Text::ANSI::Fold::Util::substr($_, 3, 6);
is($s, "\e[31m222\e[m   ", "color: padding");


# crackwide

$_ = "\e[31m赤赤\e[m赤";
Text::ANSI::Fold->configure(crackwide => 1);
my $s = Text::ANSI::Fold::Util::substr($_, 1, 4);
my $nbp = "\N{NO-BREAK SPACE}";
is($s, "\e[31m${nbp}赤\e[m${nbp}", "color: crackwide");

done_testing;

