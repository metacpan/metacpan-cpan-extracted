use strict;
use warnings;

use Test::More tests => 256;

use_ok('XML::MinWriter');

{
    my ($w, undef, @xlines) = get_xml_list('XML::MinWriter', 'ZZ');

    is(scalar(@xlines),  73,                                                          'Test-ZZ-0010 - Number of elements is correct');
    is($w, q{},                                                                       'Test-ZZ-0015 - No warnings');

    is($xlines[  0], q{},                                                             'Test-ZZ-0020');
    is($xlines[  1], q{<?xml.version="1.0".encoding="iso-8859-1"?>},                  'Test-ZZ-0030');
    is($xlines[  2], q{%n},                                                           'Test-ZZ-0040');
    is($xlines[  3], q{<!DOCTYPE.delta.PUBLIC."public"."system">},                    'Test-ZZ-0050');
    is($xlines[  4], q{%n},                                                           'Test-ZZ-0060');
    is($xlines[  5], q{<delta>},                                                      'Test-ZZ-0070');
    is($xlines[  6], q{},                                                             'Test-ZZ-0080');
    is($xlines[  7], q{<dim.alter="511">},                                            'Test-ZZ-0090');
    is($xlines[  8], q{},                                                             'Test-ZZ-0100');
    is($xlines[  9], q{<gamma.parm1="abc".parm2="def">},                              'Test-ZZ-0110');
    is($xlines[ 10], q{},                                                             'Test-ZZ-0120');
    is($xlines[ 11], q{</gamma>},                                                     'Test-ZZ-0122');
    is($xlines[ 12], q{},                                                             'Test-ZZ-0125');
    is($xlines[ 13], q{<beta>},                                                       'Test-ZZ-0130');
    is($xlines[ 14], q{car},                                                          'Test-ZZ-0140');
    is($xlines[ 15], q{</beta>},                                                      'Test-ZZ-0150');
    is($xlines[ 16], q{},                                                             'Test-ZZ-0160');
    is($xlines[ 17], q{<alpha>},                                                      'Test-ZZ-0170');
    is($xlines[ 18], q{},                                                             'Test-ZZ-0180');
    is($xlines[ 19], q{<?tt.dat?>},                                                   'Test-ZZ-0190');
    is($xlines[ 20], q{},                                                             'Test-ZZ-0200');
    is($xlines[ 21], q{</alpha>},                                                     'Test-ZZ-0210');
    is($xlines[ 22], q{},                                                             'Test-ZZ-0220');
    is($xlines[ 23], q{<epsilon>},                                                    'Test-ZZ-0230');
    is($xlines[ 24], q{},                                                             'Test-ZZ-0240');
    is($xlines[ 25], q{<!--.remark.-->},                                              'Test-ZZ-0250');
    is($xlines[ 26], q{},                                                             'Test-ZZ-0260');
    is($xlines[ 27], q{</epsilon>},                                                   'Test-ZZ-0270');
    is($xlines[ 28], q{},                                                             'Test-ZZ-0280');
    is($xlines[ 29], q{<omega.type1="a".type2="b".type3="c">},                        'Test-ZZ-0290');
    is($xlines[ 30], q{fkfdsjhkjhkj},                                                 'Test-ZZ-0300');
    is($xlines[ 31], q{</omega>},                                                     'Test-ZZ-0310');
    is($xlines[ 32], q{},                                                             'Test-ZZ-0320');
    is($xlines[ 33], q{</dim>},                                                       'Test-ZZ-0330');
    is($xlines[ 34], q{},                                                             'Test-ZZ-0340');
    is($xlines[ 35], q{<kappa>},                                                      'Test-ZZ-0350');
    is($xlines[ 36], q{dsk\\njfh....yy},                                              'Test-ZZ-0360');
    is($xlines[ 37], q{</kappa>},                                                     'Test-ZZ-0370');
    is($xlines[ 38], q{},                                                             'Test-ZZ-0380');
    is($xlines[ 39], q{<test>},                                                       'Test-ZZ-0390');
    is($xlines[ 40], q{u.&amp;.&lt;.&gt;.&amp;amp;.&amp;gt;.&amp;lt;.Z},              'Test-ZZ-0400');
    is($xlines[ 41], q{</test>},                                                      'Test-ZZ-0410');
    is($xlines[ 42], q{},                                                             'Test-ZZ-0420');
    is($xlines[ 43], q{<test1>},                                                      'Test-ZZ-0430');
    is($xlines[ 44], q{},                                                             'Test-ZZ-0440');
    is($xlines[ 45], q{</test1>},                                                     'Test-ZZ-0450');
    is($xlines[ 46], q{},                                                             'Test-ZZ-0460');
    is($xlines[ 47], q{<one>},                                                        'Test-ZZ-0470');
    is($xlines[ 48], q{},                                                             'Test-ZZ-0480');
    is($xlines[ 49], q{<two>},                                                        'Test-ZZ-0490');
    is($xlines[ 50], q{},                                                             'Test-ZZ-0500');
    is($xlines[ 51], q{<three>},                                                      'Test-ZZ-0510');
    is($xlines[ 52], q{},                                                             'Test-ZZ-0520');
    is($xlines[ 53], q{<four>},                                                       'Test-ZZ-0530');
    is($xlines[ 54], q{},                                                             'Test-ZZ-0540');
    is($xlines[ 55], q{</four>},                                                      'Test-ZZ-0550');
    is($xlines[ 56], q{},                                                             'Test-ZZ-0560');
    is($xlines[ 57], q{</three>},                                                     'Test-ZZ-0570');
    is($xlines[ 58], q{},                                                             'Test-ZZ-0580');
    is($xlines[ 59], q{</two>},                                                       'Test-ZZ-0590');
    is($xlines[ 60], q{},                                                             'Test-ZZ-0600');
    is($xlines[ 61], q{<one-and-a-half.yo="man".ding="dong">},                        'Test-ZZ-0610');
    is($xlines[ 62], q{},                                                             'Test-ZZ-0620');
    is($xlines[ 63], q{</one-and-a-half>},                                            'Test-ZZ-0622');
    is($xlines[ 64], q{},                                                             'Test-ZZ-0625');
    is($xlines[ 65], q{</one>},                                                       'Test-ZZ-0630');
    is($xlines[ 66], q{},                                                             'Test-ZZ-0640');
    is($xlines[ 67], q{<root>},                                                       'Test-ZZ-0650');
    is($xlines[ 68], q{..test1.\\n.\\t.\\.\\\\.\\\\\\.a%tb...test2},                  'Test-ZZ-0660');
    is($xlines[ 69], q{</root>},                                                      'Test-ZZ-0670');
    is($xlines[ 70], q{},                                                             'Test-ZZ-0680');
    is($xlines[ 71], q{</delta>},                                                     'Test-ZZ-0690');
    is($xlines[ 72], q{%n},                                                           'Test-ZZ-0700');
}

{
    my ($w, undef, @xlines) = get_xml_list('XML::MinWriter', 'DM');

    is(scalar(@xlines),  73,                                                          'Test-DM-0010 - Number of elements is correct');
    is($w, q{},                                                                       'Test-DM-0015 - No warnings');

    is($xlines[  0], q{},                                                             'Test-DM-0020');
    is($xlines[  1], q{<?xml.version="1.0".encoding="iso-8859-1"?>},                  'Test-DM-0030');
    is($xlines[  2], q{%n},                                                           'Test-DM-0040');
    is($xlines[  3], q{<!DOCTYPE.delta.PUBLIC."public"."system">},                    'Test-DM-0050');
    is($xlines[  4], q{%n%n},                                                         'Test-DM-0060');
    is($xlines[  5], q{<delta>},                                                      'Test-DM-0070');
    is($xlines[  6], q{%n..},                                                         'Test-DM-0080');
    is($xlines[  7], q{<dim.alter="511">},                                            'Test-DM-0090');
    is($xlines[  8], q{%n....},                                                       'Test-DM-0100');
    is($xlines[  9], q{<gamma.parm1="abc".parm2="def">},                              'Test-DM-0110');
    is($xlines[ 10], q{},                                                             'Test-DM-0120');
    is($xlines[ 11], q{</gamma>},                                                     'Test-DM-0122');
    is($xlines[ 12], q{%n....},                                                       'Test-DM-0125');
    is($xlines[ 13], q{<beta>},                                                       'Test-DM-0130');
    is($xlines[ 14], q{car},                                                          'Test-DM-0140');
    is($xlines[ 15], q{</beta>},                                                      'Test-DM-0150');
    is($xlines[ 16], q{%n....},                                                       'Test-DM-0160');
    is($xlines[ 17], q{<alpha>},                                                      'Test-DM-0170');
    is($xlines[ 18], q{},                                                             'Test-DM-0180');
    is($xlines[ 19], q{<?tt.dat?>},                                                   'Test-DM-0190');
    is($xlines[ 20], q{},                                                             'Test-DM-0200');
    is($xlines[ 21], q{</alpha>},                                                     'Test-DM-0210');
    is($xlines[ 22], q{%n....},                                                       'Test-DM-0220');
    is($xlines[ 23], q{<epsilon>},                                                    'Test-DM-0230');
    is($xlines[ 24], q{%n......},                                                     'Test-DM-0240');
    is($xlines[ 25], q{<!--.remark.-->},                                              'Test-DM-0250');
    is($xlines[ 26], q{%n....},                                                       'Test-DM-0260');
    is($xlines[ 27], q{</epsilon>},                                                   'Test-DM-0270');
    is($xlines[ 28], q{%n....},                                                       'Test-DM-0280');
    is($xlines[ 29], q{<omega.type1="a".type2="b".type3="c">},                        'Test-DM-0290');
    is($xlines[ 30], q{fkfdsjhkjhkj},                                                 'Test-DM-0300');
    is($xlines[ 31], q{</omega>},                                                     'Test-DM-0310');
    is($xlines[ 32], q{%n..},                                                         'Test-DM-0320');
    is($xlines[ 33], q{</dim>},                                                       'Test-DM-0330');
    is($xlines[ 34], q{%n..},                                                         'Test-DM-0340');
    is($xlines[ 35], q{<kappa>},                                                      'Test-DM-0350');
    is($xlines[ 36], q{dsk\\njfh....yy},                                              'Test-DM-0360');
    is($xlines[ 37], q{</kappa>},                                                     'Test-DM-0370');
    is($xlines[ 38], q{%n..},                                                         'Test-DM-0380');
    is($xlines[ 39], q{<test>},                                                       'Test-DM-0390');
    is($xlines[ 40], q{u.&amp;.&lt;.&gt;.&amp;amp;.&amp;gt;.&amp;lt;.Z},              'Test-DM-0400');
    is($xlines[ 41], q{</test>},                                                      'Test-DM-0410');
    is($xlines[ 42], q{%n..},                                                         'Test-DM-0420');
    is($xlines[ 43], q{<test1>},                                                      'Test-DM-0430');
    is($xlines[ 44], q{},                                                             'Test-DM-0440');
    is($xlines[ 45], q{</test1>},                                                     'Test-DM-0450');
    is($xlines[ 46], q{%n..},                                                         'Test-DM-0460');
    is($xlines[ 47], q{<one>},                                                        'Test-DM-0470');
    is($xlines[ 48], q{%n....},                                                       'Test-DM-0480');
    is($xlines[ 49], q{<two>},                                                        'Test-DM-0490');
    is($xlines[ 50], q{%n......},                                                     'Test-DM-0500');
    is($xlines[ 51], q{<three>},                                                      'Test-DM-0510');
    is($xlines[ 52], q{%n........},                                                   'Test-DM-0520');
    is($xlines[ 53], q{<four>},                                                       'Test-DM-0530');
    is($xlines[ 54], q{},                                                             'Test-DM-0540');
    is($xlines[ 55], q{</four>},                                                      'Test-DM-0550');
    is($xlines[ 56], q{%n......},                                                     'Test-DM-0560');
    is($xlines[ 57], q{</three>},                                                     'Test-DM-0570');
    is($xlines[ 58], q{%n....},                                                       'Test-DM-0580');
    is($xlines[ 59], q{</two>},                                                       'Test-DM-0590');
    is($xlines[ 60], q{%n....},                                                       'Test-DM-0600');
    is($xlines[ 61], q{<one-and-a-half.yo="man".ding="dong">},                        'Test-DM-0610');
    is($xlines[ 62], q{},                                                             'Test-DM-0620');
    is($xlines[ 63], q{</one-and-a-half>},                                            'Test-DM-0622');
    is($xlines[ 64], q{%n..},                                                         'Test-DM-0625');
    is($xlines[ 65], q{</one>},                                                       'Test-DM-0630');
    is($xlines[ 66], q{%n..},                                                         'Test-DM-0640');
    is($xlines[ 67], q{<root>},                                                       'Test-DM-0650');
    is($xlines[ 68], q{..test1.\\n.\\t.\\.\\\\.\\\\\\.a%tb...test2},                  'Test-DM-0660');
    is($xlines[ 69], q{</root>},                                                      'Test-DM-0670');
    is($xlines[ 70], q{%n},                                                           'Test-DM-0680');
    is($xlines[ 71], q{</delta>},                                                     'Test-DM-0690');
    is($xlines[ 72], q{%n},                                                           'Test-DM-0700');
}

{
    my ($w, undef, @xlines) = get_xml_list('XML::MinWriter', 'NL');

    is(scalar(@xlines),  73,                                                          'Test-NL-0010 - Number of elements is correct');
    is($w, q{},                                                                       'Test-NL-0015 - No warnings');

    is($xlines[  0], q{},                                                             'Test-NL-0020');
    is($xlines[  1], q{<?xml.version="1.0".encoding="iso-8859-1"?>},                  'Test-NL-0030');
    is($xlines[  2], q{%n},                                                           'Test-NL-0040');
    is($xlines[  3], q{<!DOCTYPE.delta.PUBLIC."public"."system">},                    'Test-NL-0050');
    is($xlines[  4], q{%n},                                                           'Test-NL-0060');
    is($xlines[  5], q{<delta%n>},                                                    'Test-NL-0070');
    is($xlines[  6], q{},                                                             'Test-NL-0080');
    is($xlines[  7], q{<dim.alter="511"%n>},                                          'Test-NL-0090');
    is($xlines[  8], q{},                                                             'Test-NL-0100');
    is($xlines[  9], q{<gamma.parm1="abc".parm2="def"%n>},                            'Test-NL-0110');
    is($xlines[ 10], q{},                                                             'Test-NL-0120');
    is($xlines[ 11], q{</gamma%n>},                                                   'Test-NL-0122');
    is($xlines[ 12], q{},                                                             'Test-NL-0125');
    is($xlines[ 13], q{<beta%n>},                                                     'Test-NL-0130');
    is($xlines[ 14], q{car},                                                          'Test-NL-0140');
    is($xlines[ 15], q{</beta%n>},                                                    'Test-NL-0150');
    is($xlines[ 16], q{},                                                             'Test-NL-0160');
    is($xlines[ 17], q{<alpha%n>},                                                    'Test-NL-0170');
    is($xlines[ 18], q{},                                                             'Test-NL-0180');
    is($xlines[ 19], q{<?tt.dat?>},                                                   'Test-NL-0190');
    is($xlines[ 20], q{},                                                             'Test-NL-0200');
    is($xlines[ 21], q{</alpha%n>},                                                   'Test-NL-0210');
    is($xlines[ 22], q{},                                                             'Test-NL-0220');
    is($xlines[ 23], q{<epsilon%n>},                                                  'Test-NL-0230');
    is($xlines[ 24], q{},                                                             'Test-NL-0240');
    is($xlines[ 25], q{<!--.remark.-->},                                              'Test-NL-0250');
    is($xlines[ 26], q{},                                                             'Test-NL-0260');
    is($xlines[ 27], q{</epsilon%n>},                                                 'Test-NL-0270');
    is($xlines[ 28], q{},                                                             'Test-NL-0280');
    is($xlines[ 29], q{<omega.type1="a".type2="b".type3="c"%n>},                      'Test-NL-0290');
    is($xlines[ 30], q{fkfdsjhkjhkj},                                                 'Test-NL-0300');
    is($xlines[ 31], q{</omega%n>},                                                   'Test-NL-0310');
    is($xlines[ 32], q{},                                                             'Test-NL-0320');
    is($xlines[ 33], q{</dim%n>},                                                     'Test-NL-0330');
    is($xlines[ 34], q{},                                                             'Test-NL-0340');
    is($xlines[ 35], q{<kappa%n>},                                                    'Test-NL-0350');
    is($xlines[ 36], q{dsk\\njfh....yy},                                              'Test-NL-0360');
    is($xlines[ 37], q{</kappa%n>},                                                   'Test-NL-0370');
    is($xlines[ 38], q{},                                                             'Test-NL-0380');
    is($xlines[ 39], q{<test%n>},                                                     'Test-NL-0390');
    is($xlines[ 40], q{u.&amp;.&lt;.&gt;.&amp;amp;.&amp;gt;.&amp;lt;.Z},              'Test-NL-0400');
    is($xlines[ 41], q{</test%n>},                                                    'Test-NL-0410');
    is($xlines[ 42], q{},                                                             'Test-NL-0420');
    is($xlines[ 43], q{<test1%n>},                                                    'Test-NL-0430');
    is($xlines[ 44], q{},                                                             'Test-NL-0440');
    is($xlines[ 45], q{</test1%n>},                                                   'Test-NL-0450');
    is($xlines[ 46], q{},                                                             'Test-NL-0460');
    is($xlines[ 47], q{<one%n>},                                                      'Test-NL-0470');
    is($xlines[ 48], q{},                                                             'Test-NL-0480');
    is($xlines[ 49], q{<two%n>},                                                      'Test-NL-0490');
    is($xlines[ 50], q{},                                                             'Test-NL-0500');
    is($xlines[ 51], q{<three%n>},                                                    'Test-NL-0510');
    is($xlines[ 52], q{},                                                             'Test-NL-0520');
    is($xlines[ 53], q{<four%n>},                                                     'Test-NL-0530');
    is($xlines[ 54], q{},                                                             'Test-NL-0540');
    is($xlines[ 55], q{</four%n>},                                                    'Test-NL-0550');
    is($xlines[ 56], q{},                                                             'Test-NL-0560');
    is($xlines[ 57], q{</three%n>},                                                   'Test-NL-0570');
    is($xlines[ 58], q{},                                                             'Test-NL-0580');
    is($xlines[ 59], q{</two%n>},                                                     'Test-NL-0590');
    is($xlines[ 60], q{},                                                             'Test-NL-0600');
    is($xlines[ 61], q{<one-and-a-half.yo="man".ding="dong"%n>},                      'Test-NL-0610');
    is($xlines[ 62], q{},                                                             'Test-NL-0620');
    is($xlines[ 63], q{</one-and-a-half%n>},                                          'Test-NL-0622');
    is($xlines[ 64], q{},                                                             'Test-NL-0625');
    is($xlines[ 65], q{</one%n>},                                                     'Test-NL-0630');
    is($xlines[ 66], q{},                                                             'Test-NL-0640');
    is($xlines[ 67], q{<root%n>},                                                     'Test-NL-0650');
    is($xlines[ 68], q{..test1.\\n.\\t.\\.\\\\.\\\\\\.a%tb...test2},                  'Test-NL-0660');
    is($xlines[ 69], q{</root%n>},                                                    'Test-NL-0670');
    is($xlines[ 70], q{},                                                             'Test-NL-0680');
    is($xlines[ 71], q{</delta%n>},                                                   'Test-NL-0690');
    is($xlines[ 72], q{%n},                                                           'Test-NL-0700');
}

{
    open my $fh, '>', \my $xml or die "Error-0020: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('?xml version="1.0" encoding="iso-8859-1"');
        $wrt->write_pyx('(data');
        $wrt->write_pyx("(item\n\n\nAattr1 p1\nAattr2 p2\n-line", ")item\n(level");
        $wrt->write_pyx('#remark');
        $wrt->write_pyx(')level');
        $wrt->write_pyx(')data');
    }

    $wrt->end;
    close $fh;

    $xml =~ s{\n}"%n"xmsg;
    $xml =~ s{ [ ] }'.'xmsg;
    $xml =~ s{\t}"%t"xmsg;

    my @xlines = split m{(< [^>]* >)}xms, $xml;

    is(scalar(@xlines), 17,                                                     'Test-PYX1-0300: Number of lines in XML correct');
    is($wrn, q{},                                                               'Test-PYX1-0305: No Warning emitted');

    is($xlines[ 0], q{},                                                        'Test-PYX1-0310');
    is($xlines[ 1], q{<?xml.version="1.0".encoding="iso-8859-1"?>},             'Test-PYX1-0320');
    is($xlines[ 2], q{%n%n},                                                    'Test-PYX1-0330');
    is($xlines[ 3], q{<data>},                                                  'Test-PYX1-0340');
    is($xlines[ 4], q{%n..},                                                    'Test-PYX1-0350');
    is($xlines[ 5], q{<item.attr1="p1".attr2="p2">},                            'Test-PYX1-0360');
    is($xlines[ 6], q{line},                                                    'Test-PYX1-0370');
    is($xlines[ 7], q{</item>},                                                 'Test-PYX1-0380');
    is($xlines[ 8], q{%n..},                                                    'Test-PYX1-0390');
    is($xlines[ 9], q{<level>},                                                 'Test-PYX1-0400');
    is($xlines[10], q{%n....},                                                  'Test-PYX1-0410');
    is($xlines[11], q{<!--.remark.-->},                                         'Test-PYX1-0420');
    is($xlines[12], q{%n..},                                                    'Test-PYX1-0430');
    is($xlines[13], q{</level>},                                                'Test-PYX1-0440');
    is($xlines[14], q{%n},                                                      'Test-PYX1-0450');
    is($xlines[15], q{</data>},                                                 'Test-PYX1-0460');
    is($xlines[16], q{%n},                                                      'Test-PYX1-0470');
}

{
    open my $fh, '>', \my $xml or die "Error-0040: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    eval{
        $wrt->startTag('abc');
        $wrt->end;
    };

    like($@, qr{Document \s ended \s with \s unmatched \s start \s tag\(s\)}xms, 'Test-0700: end() fails ok');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0050: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    eval{
        $wrt->startTag('abc');
        $wrt->endTag('abc');
        $wrt->endTag('abc');
        $wrt->end;
    };

    like($@, qr{End \s tag \s "abc" \s does \s not \s close \s any \s open \s element}xms, 'Test-0710: endTag() fails ok');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0070: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->startTag('abc');
        $wrt->write_pyx('ZZZZ');
        $wrt->endTag('abc');
        $wrt->end;
    };

    like($wrn, qr{Invalid \s code \s = \s 'Z' \s in \s write_pyx}xms,           'Test-0730: warning Invalid code in write_pyx()');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0080: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('A');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s parse \s \(key, \s val\) \s \[code \s = \s 'A'\]}xms, 'Test-0740: Warning Can t parse A');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0090: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('?');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s parse \s \(intro, \s def\) \s \[code \s = \s '\?']}xms, 'Test-0750: Warning Can t parse ?');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0100: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('?xml test="a"');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Found \s invalid \s XML-Declaration}xms, 'Test-0760: Warning Invalid XML-Declaration');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0100: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('?xml version="2.0"');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Found \s version \s other \s than \s 1.0}xms, 'Test-0770: Warning Found version other than 1.0');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0110: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('!');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s parse \s \(intro, \s def\) \s \[code \s = \s '!'\]}xms, 'Test-0780: Warning Can t parse (intro, def) [code = "!"]');

    close $fh;
}


{
    open my $fh, '>', \my $xml or die "Error-0120: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('!test public def');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s parse \s DOCTYPE \s PUBLIC}xms, 'Test-0790: Warning Can t parse DOCTYPE PUBLIC');

    close $fh;
}

{
    open my $fh, '>', \my $xml or die "Error-0130: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('!test system def');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s parse \s DOCTYPE \s SYSTEM}xms, 'Test-0800: Warning Can t parse DOCTYPE SYSTEM');

    close $fh;
}


{
    open my $fh, '>', \my $xml or die "Error-0140: Can't open > xml because $!";
    my $wrt = XML::MinWriter->new(OUTPUT => $fh, NEWLINES => 1);

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('(abc');
        $wrt->write_pyx('!test iii');
        $wrt->write_pyx(')abc');
        $wrt->end;
    };

    like($wrn, qr{Can't \s find \s neither \s PUBLIC \s nor \s SYSTEM \s in \s DOCTYPE}xms, 'Test-0810: Warning Can t find neither PUBLIC nor SYSTEM');

    close $fh;
}

sub get_xml_list {
    my ($module, $mode) = @_;

    open my $fh, '>', \my $xml or die "Error-0010: Can't open > xml because $!";

    my $wrt;
    if ($mode eq 'DM') {
        $wrt = $module->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);
    }
    elsif ($mode eq 'NL') {
        $wrt = $module->new(OUTPUT => $fh, NEWLINES => 1);
    }
    elsif ($mode eq 'ZZ') {
        $wrt = $module->new(OUTPUT => $fh);
    }
    else {
        die "Error-0010: Can't identify mode '$mode'";
    }

    my $wrn = '';
    {
        local $SIG{__WARN__} = sub { $wrn .= $_[0]; };

        $wrt->write_pyx('?xml encoding="iso-8859-1"');      # xmlDecl('iso-8859-1');
        $wrt->write_pyx('!delta public "public" "system"'); # doctype('delta', 'public', 'system');
        $wrt->write_pyx('(delta');                          # startTag('delta');
        $wrt->write_pyx('(dim', 'Aalter 511');              # startTag('dim', alter => '511');
        $wrt->write_pyx('(gamma', 'Aparm1 abc','Aparm2 def', ')gamma');
                                                            # emptyTag('gamma', parm1 => 'abc', parm2 => 'def');
        $wrt->write_pyx('(beta');                           # startTag('beta');
        $wrt->write_pyx('-car');                            # characters('car');
        $wrt->write_pyx(')beta');                           # endTag('beta');
        $wrt->write_pyx('(alpha');                          # startTag('alpha');
        $wrt->write_pyx('?tt dat');                         # pi('tt', 'dat');
        $wrt->write_pyx(')alpha');                          # endTag('alpha');
        $wrt->write_pyx('(epsilon');                        # startTag('epsilon');
        $wrt->write_pyx('#remark');                         # comment('remark');
        $wrt->write_pyx(')epsilon');                        # endTag('epsilon');
        $wrt->write_pyx('(omega', 'Atype1 a', 'Atype2 b', 'Atype3 c', '-fkfdsjhkjhkj', ')omega');
                                                            # dataElement('omega', 'fkfdsjhkjhkj', type1 => 'a', type2 => 'b', type3 => 'c');
        $wrt->write_pyx(')dim');                            # endTag('dim');
        $wrt->write_pyx('(kappa');                          # startTag('kappa');
        $wrt->write_pyx('-dsk\\\\njfh  ');                  # characters('dsk\\njfh  ');
        $wrt->write_pyx('-  yy');                           # characters('  yy');
        $wrt->write_pyx(')kappa');                          # endTag('kappa');
        $wrt->write_pyx('(test');                           # startTag('test');
        $wrt->write_pyx('-u & < > &amp; &gt; &lt; Z');      # characters('u & < > &amp; &gt; &lt; Z');
        $wrt->write_pyx(')test');                           # endTag('test');
        $wrt->write_pyx('(test1');                          # startTag('test1');
        $wrt->write_pyx(')test1');                          # endTag('test1');
        $wrt->write_pyx('(one');                            # startTag('one');
        $wrt->write_pyx('(two');                            # startTag('two');
        $wrt->write_pyx('(three');                          # startTag('three');
        $wrt->write_pyx('(four');                           # startTag('four');
        $wrt->write_pyx(')four');                           # endTag('four');
        $wrt->write_pyx(')three');                          # endTag('three');
        $wrt->write_pyx(')two');                            # endTag('two');
        $wrt->write_pyx('(one-and-a-half', 'Ayo man', 'Ading dong', ')one-and-a-half');
                                                            # emptyTag('one-and-a-half', yo => 'man', ding => 'dong');
        $wrt->write_pyx(')one');                            # endTag('one');
        $wrt->write_pyx('(root');                           # startTag('root');
        $wrt->write_pyx('-  test1 \\\\n \\\\t \\ \\\\\\ \\\\\\\\\\ a\\tb ');
                                                            # characters("  test1 \\n \\t \\ \\\\ \\\\\\ a\tb ");
        $wrt->write_pyx('-  test2');                        # characters("  test2");
        $wrt->write_pyx(')root');                           # endTag('root');
        $wrt->write_pyx(')delta');                          # endTag('delta');
    }

    $wrt->end;
    close $fh;

    my $orig = $xml;

    $xml =~ s{\n}"%n"xmsg;
    $xml =~ s{ [ ] }'.'xmsg;
    $xml =~ s{\t}"%t"xmsg;

    return $wrn, $orig, split(m{(< [^>]* >)}xms, $xml);
}
