use 5.014;

use strict;
use warnings;

use Test::More tests => 50;
use Test::LongString;

use_ok('XML::Parsepp::Testgen', qw(test_2_xml xml_2_test));

my $data_r01_src_ori_xml =
  qq|#! Testdata for XML::Parsepp\n|.
  qq|#! Ver 0.01\n|.
  qq|<?xml version="1.0" encoding="ISO-8859-1"?>\n|.
  qq|<!DOCTYPE dialogue [\n|.
  qq|  <!ENTITY nom0 "<data>y<item>y &nom1; zz</data>">\n|.
  qq|  <!ENTITY nom1 "<abc>def</abc></item>">\n|.
  qq|]>\n|.
  qq|<root>&nom0;</root>\n|.
  qq|#! ===\n|.
  qq|<?xml version="1.0" encoding="ISO-8859-1"?>\n|.
  qq|<!DOCTYPE dialogue\n|.
  qq|[\n|.
  qq|  <!ENTITY nom1 "aa &nom2; tt &nom4; bb">\n|.
  qq|  <!ENTITY nom2 "c <xx>abba</xx> c tx <ab> &nom3; dd">\n|.
  qq|  <!ENTITY nom3 "dd </ab> <yy>&nom4;</yy> ee">\n|.
  qq|  <!ENTITY nom4 "gg">\n|.
  qq|]>\n|.
  qq|<root>hh &nom1; ii</root>\n|;

my $data_r02_src_ori_prl =
  qq|use 5.014;\n|.
  qq|use warnings;\n|.
  qq|# Generate Tests for XML::Parsepp\n|.
  qq|# No of get_result is 2\n|.
  qq|get_result(\$XmlParser,\n|.
  qq|           q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\\n},\n|.
  qq|           q{<!DOCTYPE dialogue [}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom0 "<data>y<item>y &nom1; zz</data>">}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom1 "<abc>def</abc></item>">}.qq{\\n},\n|.
  qq|           q{]>}.qq{\\n},\n|.
  qq|           q{<root>&nom0;</root>}.qq{\\n},\n|.
  qq|);\n|.
  qq|get_result(\$XmlParser,\n|.
  qq|           q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\\n},\n|.
  qq|           q{<!DOCTYPE dialogue}.qq{\\n},\n|.
  qq|           q{[}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom1 "aa &nom2; tt &nom4; bb">}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom2 "c <xx>abba</xx> c tx <ab> &nom3; dd">}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom3 "dd </ab> <yy>&nom4;</yy> ee">}.qq{\\n},\n|.
  qq|           q{  <!ENTITY nom4 "gg">}.qq{\\n},\n|.
  qq|           q{]>}.qq{\\n},\n|.
  qq|           q{<root>hh &nom1; ii</root>}.qq{\\n},\n|.
  qq|);\n|.
  qq|\n|.
  qq|sub get_result {\n|.
  qq|}\n|;

{
    my ($temp_r01_clc_ori_prl, $temp_r01_clc_ori_err) = runtest('xml_2_test', \$data_r01_src_ori_xml);
    my ($temp_r02_clc_ori_xml, $temp_r02_clc_ori_err) = runtest('test_2_xml', \$data_r02_src_ori_prl);

    my $temp_r01_clc_res_prl = make_res($temp_r01_clc_ori_prl);
    my $temp_r02_src_res_prl = make_res($data_r02_src_ori_prl);

    is($temp_r01_clc_ori_err, '',                           'test-001: no error from xml_2_test(data_r01_src_ori_xml)');
    is_string($temp_r01_clc_res_prl, $temp_r02_src_res_prl, 'test-002: good result from xml_2_test(data_r01_src_ori_xml)');

    is($temp_r02_clc_ori_err, '',                           'test-003: no error from test_2_xml(data_r02_src_ori_prl)');
    is_string($temp_r02_clc_ori_xml, $data_r01_src_ori_xml, 'test-004: good result from test_2_xml(data_r02_src_ori_prl)');
}

{
    my ($temp_prl, $temp_err) = runtest('xml_2_test', \$data_r01_src_ori_xml);
    is($temp_err, '',                                       'test-005: no error from xml_2_test(data_r01_src_ori_xml)');

    my @temp_exp = $temp_prl =~ m{my \s+ \@expected \s+ = \s+ \( (.*?) \);}xmsg;
    my @temp_msg = $temp_prl =~ m/like\(\$err, \s+ qr\{ (\N*) \}xms/xmsg;

    is(scalar(@temp_exp), 2,                                'test-006: no of elements found when searching for expected');
    is(scalar(@temp_msg), 2,                                'test-007: no of elements found when searching for messages');

    is_string_nows($temp_exp[0],
      q!q{INIT},!.
      q!q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom0], Val=[<data>y<item>y &nom1; zz</data>], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom1], Val=[<abc>def</abc></item>], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DOCF},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{STRT Ele=[root], Att=[]},!.
      q!q{STRT Ele=[data], Att=[]},!.
      q!q{CHAR Str=[y]},!.
      q!q{STRT Ele=[item], Att=[]},!.
      q!q{CHAR Str=[y ]},!.
      q!q{STRT Ele=[abc], Att=[]},!.
      q!q{CHAR Str=[def]},!.
      q!q{ENDL Ele=[abc]},!,                               'test-008: content of first expected');

    is($temp_msg[0], 'asynchronous \s+ entity',            'test-009: content of first message');

    is_string_nows($temp_exp[1],
      q!q{INIT},!.
      q!q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom1], Val=[aa &nom2; tt &nom4; bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom2], Val=[c <xx>abba</xx> c tx <ab> &nom3; dd], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom3], Val=[dd </ab> <yy>&nom4;</yy> ee], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DEFT Str=[  ]},!.
      q!q{ENTT Nam=[nom4], Val=[gg], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{DOCF},!.
      q!q{DEFT Str=[&<0a>]},!.
      q!q{STRT Ele=[root], Att=[]},!.
      q!q{CHAR Str=[hh ]},!.
      q!q{CHAR Str=[aa ]},!.
      q!q{CHAR Str=[c ]},!.
      q!q{STRT Ele=[xx], Att=[]},!.
      q!q{CHAR Str=[abba]},!.
      q!q{ENDL Ele=[xx]},!.
      q!q{CHAR Str=[ c tx ]},!.
      q!q{STRT Ele=[ab], Att=[]},!.
      q!q{CHAR Str=[ ]},!.
      q!q{CHAR Str=[dd ]},!,                               'test-010: content of second expected');

    is($temp_msg[1], 'asynchronous \s+ entity',            'test-011: content of second message');
}

{
    # round trip test

    my ($temp_stage01_prl, $temp_stage01_err) = runtest('xml_2_test', \$data_r01_src_ori_xml);
    my ($temp_stage02_xml, $temp_stage02_err) = runtest('test_2_xml', \$temp_stage01_prl);

    my ($temp_stage03_prl, $temp_stage03_err) = runtest('xml_2_test', \$temp_stage02_xml);
    my ($temp_stage04_xml, $temp_stage04_err) = runtest('test_2_xml', \$temp_stage03_prl);

    is($temp_stage01_err, '',                             'test-012: test message 1 for round-trip');
    is($temp_stage02_err, '',                             'test-013: test message 2 for round-trip');
    is($temp_stage03_err, '',                             'test-014: test message 3 for round-trip');
    is($temp_stage04_err, '',                             'test-015: test message 4 for round-trip');

    is_string($temp_stage01_prl, $temp_stage03_prl,       'test-016: identical round-trip for perl');
    is_string($temp_stage02_xml, $temp_stage04_xml,       'test-017: identical round-trip for xml');
}

{
    # test the different formats with which xml_2_test and test_2_xml can be called...

    my $fname01_xml = 'test01-xml.dat';
    my $fname02_prl = 'test02-perl.dat';

    END {
        unlink $fname01_xml if defined $fname01_xml;
        unlink $fname02_prl if defined $fname02_prl;
    }

    open my $of1, '>', $fname01_xml or die "Error-0010: Can't open > '$fname01_xml' because $!";
    print {$of1} $data_r01_src_ori_xml;
    close $of1;

    open my $of2, '>', $fname02_prl or die "Error-0020: Can't open > '$fname02_prl' because $!";
    print {$of2} $data_r02_src_ori_prl;
    close $of2;

    open my $fh_xml, '<', $fname01_xml or die "Error-0030: Can't open < '$fname01_xml' because $!";
    open my $fh_prl, '<', $fname02_prl or die "Error-0040: Can't open < '$fname02_prl' because $!";

    my ($temp_mode01_prl_res, $temp_mode01_prl_err) = runtest('xml_2_test', \$data_r01_src_ori_xml);
    my ($temp_mode01_xml_res, $temp_mode01_xml_err) = runtest('test_2_xml', \$data_r02_src_ori_prl);

    my ($temp_mode02_prl_res, $temp_mode02_prl_err) = runtest('xml_2_test', $fname01_xml);
    my ($temp_mode02_xml_res, $temp_mode02_xml_err) = runtest('test_2_xml', $fname02_prl);

    my ($temp_mode03_prl_res, $temp_mode03_prl_err) = runtest('xml_2_test', $fh_xml);
    my ($temp_mode03_xml_res, $temp_mode03_xml_err) = runtest('test_2_xml', $fh_prl);

    close $fh_xml;
    close $fh_prl;

    is($temp_mode01_prl_err, '',                          'test-018: test message mode-01 for perl');
    is($temp_mode01_xml_err, '',                          'test-019: test message mode-01 for xml');

    is($temp_mode02_prl_err, '',                          'test-020: test message mode-02 for perl');
    is($temp_mode02_xml_err, '',                          'test-021: test message mode-02 for xml');

    is($temp_mode03_prl_err, '',                          'test-022: test message mode-03 for perl');
    is($temp_mode03_xml_err, '',                          'test-023: test message mode-03 for xml');

    is_string($temp_mode01_prl_res, $temp_mode02_prl_res, 'test-024: identical result for perl mode-01-02');
    is_string($temp_mode02_prl_res, $temp_mode03_prl_res, 'test-025: identical result for perl mode-02-03');

    is_string($temp_mode01_xml_res, $temp_mode02_xml_res, 'test-026: identical result for xml mode-01-02');
    is_string($temp_mode02_xml_res, $temp_mode03_xml_res, 'test-027: identical result for xml mode-02-03');
}

# provoke the different errors...

{
    my $temp_data = # xml is correct and does not provoke any error...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc</data>\n}.
      qq{#! ===\n}.
      qq{<root>def</root>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{\A \z}xms, 'test-028: Test error-message');
}

{
    my $temp_data = # xml without newlines...
      qq{#! Testdata for XML::Parsepp}.
      qq{#! Ver 0.01}.
      qq{<data>abc</data>}.
      qq{#! ===}.
      qq{<root>def</root>};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{Error-0010: \s Can't \s extract \s xml_defs}xms,  'test-029: Test error-message');
}

{
    my $temp_data = # the first line contains zz at the end...
      qq{#! Testdata for XML::Parsepp zz\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc</data>\n}.
      qq{#! ===\n}.
      qq{<root>def</root>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{Error-0020: \s Expected \s xml_def1 \s to \s be}xms, 'test-030: Test error-message');
}

{
    my $temp_data = # the second line contains zz at the end...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01 zz\n}.
      qq{<data>abc</data>\n}.
      qq{#! ===\n}.
      qq{<root>def</root>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{Error-0030: \s Expected \s xml_def2 \s to \s be}xms, 'test-031: Test error-message');
}

# This should never happen: like($temp_msg, qr{Error-0040: \s Can't \s eval \s 'sub}xms,                               'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0050: \s Expected \s ref\(handler\) \s = \s 'CODE'}xms,           'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0060: \s Can't \s create \s XML::Parser \s -> \s new}xms,         'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0070: \s Can't \s create \s XML::Parser \s -> \s parse_start}xms, 'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0080: \s Can't \s decompose \s error-line}xms,                    'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0090: \s Can't \s open \s > \s '\\\$result'}xms,                  'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0100: \s Can't \s parse \s %include}xms,                          'test-000: Test error-message');

{
    my $temp_data = # invalid characters ( \ { } ) inside <data>...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc \\ \{ \} </data>\n}.
      qq{#! ===\n}.
      qq{<root>def</root>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{Error-0110: \s Found \s invalid \s character \s in \s xml}xms, 'test-032: Test error-message');
}

{
    my $temp_data = # one invalid character ( \ ) coded by "...&#92;..." inside <data>...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc &#92; </data>\n}.
      qq{#! ===\n}.
      qq{<root>def</root>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{Error-0120: \s Found \s invalid \s character \s in \s result}xms, 'test-033: Test error-message');
}

# This should never happen: like($temp_msg, qr{Error-0130: \s Can't \s parse \s message \s from \s ecode}xms,          'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0140: \s Found \s invalid \s character \s in \s message}xms,      'test-000: Test error-message');
# This should never happen: like($temp_msg, qr{Error-0150: \s Found \s invalid \s %include \s subject}xms,             'test-000: Test error-message');

{
    my $temp_data = # perl-code is correct and does not provoke any error...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{\A \z}xms, 'test-034: Test error-message');
}

{
    my $temp_data = # perl-code without newlines...
      qq{use 5.014;}.
      qq{use warnings;}.
      qq{# Generate Tests for XML::Parsepp}.
      qq{# No of get_result is 2}.
      qq{get_result(\$XmlParser,}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},}.
      qq{);}.
      qq{get_result(\$XmlParser,}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},}.
      qq{);};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0160: \s Can't \s extract \s use-statements}xms, 'test-035: Test error-message');
}

{
    my $temp_data = # the first line contains zz at the end...
      qq{use 5.014; zz\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0170: \s Expected \s def1 \s to \s be \s 'use \s 5\.014;'}xms, 'test-036: Test error-message');
}

{
    my $temp_data = # the second line contains zz at the end...
      qq{use 5.014;\n}.
      qq{use warnings; zz\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0180: \s Expected \s def2 \s to \s be \s 'use \s warnings;'}xms, 'test-037: Test error-message');
}

{
    my $temp_data = # the third line contains zz at the end...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp zz\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0190: \s Expected \s def3 \s to \s be \s'\# \s Generate \s Tests \s for \s XML::Parsepp'}xms, 'test-038: Test error-message');
}

{
    my $temp_data = # the line 'No of get_result' contains zz at the end...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2 zz\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0200: \s Can't \s find \s 'No \s of \s get_result\.\.\.'}xms, 'test-039: Test error-message');
}

{
    my $temp_data = # the line 'No of get_result' contains 1 instead of 2...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 1\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0210: \s Found \s \d+ \s get_result, \s but \s expected \s \d+}xms, 'test-040: Test error-message');
}

# This should never happen: like($temp_msg, qr{Error-0220: \s Can't \s open \s > \s '\\\$result'}xms,                  'test-000: Test error-message');

{
    my $temp_data = # the first get_result() is empty...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result();\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0230: \s Too \s few \s elements \s in \s lines}xms, 'test-041: Test error-message');
}

{
    my $temp_data = # the first line $XmlParser, ends with zz...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser, zz\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\},\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0240: \s found \s first \s line}xms, 'test-042: Test error-message');
}

{
    my $temp_data = # the first line q{<data>abc</data>} ends with zz...
      qq{use 5.014;\n}.
      qq{use warnings;\n}.
      qq{# Generate Tests for XML::Parsepp\n}.
      qq{# No of get_result is 2\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<data>abc</data>\}.qq\{\\n\}, zz\n}.
      qq{);\n}.
      qq{get_result(\$XmlParser,\n}.
      qq{         q\{<root>def</root>\}.qq\{\\n\},\n}.
      qq{);\n};

    my ($temp_result, $temp_msg) = runtest('test_2_xml', \$temp_data);
    like($temp_msg, qr{Error-0250: \s Can't \s parse \s fragment}xms, 'test-043: Test error-message');
}

# Test the option {chkpos => 1} in xml_2_test...

{
    my $temp_data = # There is not an error as such, but the XML does not close properly and chkpos is => 1...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc</dat1>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data, {chkpos => 1});
    like($temp_msg, qr{\A \z}xms, 'test-044: Test error-message');
    like($temp_result, qr{is\(\$e_line,}xms, 'test-045: check for e_line exists (XML does not close properly and chkpos is => 1...)');
}

{
    my $temp_data = # The XML closes properly and chkpos is => 1...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc</data>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data, {chkpos => 1});
    like($temp_msg, qr{\A \z}xms, 'test-046: Test error-message');
    unlike($temp_result, qr{is\(\$e_line,}xms, 'test-047: check for e_line does not exist (XML closes properly and chkpos is => 1...)');
}

{
    my $temp_data = # There is not an error as such, but the XML does not close properly and chkpos is => 0...
      qq{#! Testdata for XML::Parsepp\n}.
      qq{#! Ver 0.01\n}.
      qq{<data>abc</dat1>\n};

    my ($temp_result, $temp_msg) = runtest('xml_2_test', \$temp_data);
    like($temp_msg, qr{\A \z}xms, 'test-048: Test error-message');
    unlike($temp_result, qr{is\(\$e_line,}xms, 'test-049: check for e_line does not exist (XML does not close properly and chkpos is => 0...)');
}

sub runtest {
    my ($fcode, @param) = @_;

    my ($res, $err);
    if ($fcode eq 'test_2_xml') {
        $res = eval{ test_2_xml(@param) };
        $err = $@;
    }
    elsif ($fcode eq 'xml_2_test') {
        $res = eval{ xml_2_test(@param) };
        $err = $@;
    }
    else {
        $res = '';
        $err = "** invalid fcode = '$fcode' **";
    }

    $res //= '';
    $err //= '';

    return ($res, $err);
}

sub make_res {
    my @getres = $_[0] =~ m{(get_result \( [^\)]* \);)}xmsg;
    my $newres = join("\n", @getres)."\n";
    $newres =~ s{^[ ]+}''xmsg;

    return $newres;
}
