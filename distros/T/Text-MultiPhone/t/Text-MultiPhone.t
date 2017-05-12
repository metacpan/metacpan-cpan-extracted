# -*- Perl -*-

use Test::More tests => 6;

BEGIN {
    use_ok(Text::MultiPhone);
    use_ok(Text::MultiPhone::de);
    use_ok(Text::MultiPhone::no);
}

my $de = Text::MultiPhone::de;
my $no = Text::MultiPhone::no;

isnt(($de->multiphone("Alphabet"))[0], "alphabet");
is(($de->multiphone("Alphabet"))[0], "alfabet");
is(($no->multiphone("kjenning"))[0], "sjening");
