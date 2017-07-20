# -*- cperl -*-
use strict;
use vars qw($DEBUG);
use IO::Handle;
use Test::More tests=>27;
use utf8;
use Encode 'decode';
use Unicode::Normalize;

use Cwd;
my $common = getcwd()."/t/common.pl";
require $common;


use Text::BibTeX qw(:nameparts :joinmethods);


$DEBUG = 1;

{
    # tests 1..3
    # Get a name to work with (and just a quick check that the Name class
    # is in working order)
    my $name = Text::BibTeX::Name->new
      ("Charles Louis Xavier Joseph de la Vall{\\'e}e Poussin");

    my @first = $name->part('first');
    my @von   = $name->part('von');
    my @last  = $name->part('last');

    is_deeply \@first, [qw(Charles Louis Xavier Joseph)],
      "First name is 'Charles Louis Xavier Joseph'";
    is_deeply \@von,   [qw(de la)],
      "von part is 'de la'";
    is_deeply \@last,  ["Vall{\\'e}e", 'Poussin'],
      "Last name is 'Vall{\\'e}e Poussin'";
}

{
    # tests 4..5..
    my $name1   = Text::BibTeX::Name->new('{John Henry} Ford');
    my $format1 = Text::BibTeX::NameFormat->new('f', 1);
    is $format1->apply($name1), 'J.', "first name is abbreviated correctly [1]";

    my $name2   = Text::BibTeX::Name->new('{John} Ford');
    my $format2 = Text::BibTeX::NameFormat->new('f', 1);
    is $format2->apply($name2), 'J.', "first name is abbreviated correctly [2]";
}

{
    # tests 6..
    my $name3   = Text::BibTeX::Name->new
      ('{U.S. Department of Health and Human Services, National Institute of Mental Health,'.
       'National Heart, Lung and Blood Institute}');

    my $format3 = Text::BibTeX::NameFormat->new('l', 1);

    $format3->set_text(BTN_LAST, undef, undef, undef, '.');
    $format3->set_options(BTN_LAST, 1, BTJ_NOTHING, BTJ_NOTHING);

    is $format3->apply($name3), 'U.', 'big institution';
}

{
    # tests 7..8..
    my $name4   = Text::BibTeX::Name->new("{\\'E}mile Zola");
    my $format4 = Text::BibTeX::NameFormat->new('f', 1);
    is $format4->apply($name4), "{\\'E}.", "accented first letter";

    my $name5   = Text::BibTeX::Name->new('St John-Mollusc, Oliver');
    my $format5 = Text::BibTeX::NameFormat->new('l', 1);

    $format5->set_text(BTN_LAST, undef, undef, undef, '.');
    $format5->set_options(BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);

    is $format5->apply($name5), 'S.~J.-M.', "abbreviated surname";
}

{
    # tests 9..
    my $name6   = Text::BibTeX::Name->new("St John-{\\'E}mile Mollusc, Oliver");
    my $format6 = Text::BibTeX::NameFormat->new('l', 1);

    $format6->set_text (BTN_LAST, undef, undef, undef, '.');
    $format6->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);

    is $format6->apply($name6), "S.~J.-{\\'E}.~M.", "Abbreviated accented surname";
}

{
    # test 10...
    my $name7   = Text::BibTeX::Name->new('St {John-Mollusc}, Oliver');
    my $format7 = Text::BibTeX::NameFormat->new('l', 1);

    $format7->set_text (BTN_LAST, undef, undef, undef, '.');
    $format7->set_options (BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);

    is $format7->apply($name7), 'S.~J.';
}

{
    # test 11... to 16

    ## This in raw mode
    my $name8     = Text::BibTeX::Name->new('Šomeone Smith');
    my $formatter = Text::BibTeX::NameFormat->new('f', 1);
    is NFC(decode('UTF-8',$formatter->apply($name8))), 'Š.', "raw test 1";

    my $name9   = Text::BibTeX::Name->new('Šomeone-Šomething Smith');
    is NFC(decode('UTF-8',$formatter->apply($name9))), 'Š.-Š.', "raw test 2";

    $formatter = Text::BibTeX::NameFormat->new('f', 1);
    my $name10   = Text::BibTeX::Name->new({binmode=>'utf-8'},'{Šomeone-Šomething} Smith');
    is $formatter->apply($name10), 'Š.', "utf-8 [1]";

    # Initial is 2 bytes long in UTF8
    my $formatterlast = Text::BibTeX::NameFormat->new('f', 1);
    my $name11   = Text::BibTeX::Name->new({binmode=>'utf-8'},'Żaa Smith');
    is $formatterlast->apply($name11), 'Ż.', "utf-8 [2]";

    # Initial is 3 bytes long in UTF8 (Z + 2 byte combining mark)
    $formatterlast = Text::BibTeX::NameFormat->new('f', 1);
    my $name12   = Text::BibTeX::Name->new({binmode=>'utf-8'},'Z̃ Smith');
    is $formatterlast->apply($name12), 'Z̃.', "utf-8 [3]";

    # Initial is 7 bytes long in UTF8 (A + 3 * 2 byte combining marks)
    $formatterlast = Text::BibTeX::NameFormat->new('f', 1);
    my $name13   = Text::BibTeX::Name->new({binmode=>'utf-8'},'A̧̦̓ Smith');
    is $formatterlast->apply($name13), 'A̧̦̓.', "utf-8 [3]";

}

{
    # test 17... and 18
    my $name14   = Text::BibTeX::Name->new('Harold {K}ent-{B}arrow');
    my $format11 = Text::BibTeX::NameFormat->new('l', 1);

    $format11->set_text(BTN_LAST, undef, undef, undef, '.');
    $format11->set_options(BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);

    is $format11->apply($name14), 'K.-B.';

    my $name15   = Text::BibTeX::Name->new('Mirian Neuser-Hoffman');
    my $format12 = Text::BibTeX::NameFormat->new('l', 1);

    $format12->set_text(BTN_LAST, undef, undef, undef, '');
    $format12->set_options(BTN_LAST, 1, BTJ_MAYTIE, BTJ_NOTHING);

    is $format12->apply($name15), 'N-H';
}

{
    # test 19 to 26

    my $name = Text::BibTeX::Name->new
      ("Charles Louis Xavier Joseph de la Vall{\\'e}e Poussin");

    # Start with a basic "von last, jr, first" formatter
    my $format = Text::BibTeX::NameFormat->new('vljf', 1);

    is $format->apply($name), "de~la Vall{\\'e}e~Poussin, C.~L. X.~J.";
    is $format->apply($name), $name->format($format);

    # Tweak options: force ties between tokens of the first name
    $format->set_options(BTN_FIRST, 1, BTJ_FORCETIE, BTJ_NOTHING);
    is $format->apply($name), "de~la Vall{\\'e}e~Poussin, C.~L.~X.~J.";

    # And no ties in the "von" part
    $format->set_options(BTN_VON, 0, BTJ_SPACE, BTJ_SPACE);
    is $format->apply($name), "de la Vall{\\'e}e~Poussin, C.~L.~X.~J.";

    # No punctuation in the first name
    $format->set_text(BTN_FIRST, undef, undef, undef, '');
    is $format->apply($name), "de la Vall{\\'e}e~Poussin, C~L~X~J";

    # And drop the first name inter-token separation entirely
    $format->set_options(BTN_FIRST, 1, BTJ_NOTHING, BTJ_NOTHING);
    is $format->apply($name), "de la Vall{\\'e}e~Poussin, CLXJ";

    # Now we get silly: keep the first name tokens jammed together, but
    # don't abbreviate them any more
    $format->set_options(BTN_FIRST, 0, BTJ_NOTHING, BTJ_NOTHING);
    is $format->apply($name), "de la Vall{\\'e}e~Poussin, CharlesLouisXavierJoseph";

    # OK, but spaces back in to the first name
    $format->set_options (BTN_FIRST, 0, BTJ_SPACE, BTJ_NOTHING);
    is $format->apply($name), "de la Vall{\\'e}e~Poussin, Charles Louis Xavier Joseph";
}

{
    # test 27
    my $entry = new Text::BibTeX::Entry;
    $entry->parse_s('@' . "article{key,\n author = {Firstlastname Secondlastname, Firstname and others},\n}");
    my @authors = $entry->names("author");
    my $format = new Text::BibTeX::NameFormat("vl");
    is $format->apply($authors[0]), "Firstlastname~Secondlastname";
}
