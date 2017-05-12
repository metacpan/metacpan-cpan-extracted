use strict;
use warnings;

package XML::Reader::Testcases;
$XML::Reader::Testcases::VERSION = '0.65';
require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( all => [ qw(Get_TestCntr Get_TestProg) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

our %TestProg;

$TestProg{'0010_test_Module.t'} = [67, sub {
    my ($XML_Reader_Any) = @_;

    Test::More::use_ok($XML_Reader_Any);

    {
        my $line = '';
        $line .= '<data>' for 1..10;
        $line .= '<item name="abc" id="123">xyz</item>';
        $line .= '</data>' for 1..10;

        {
            my $count = 0;
            my $rdr = $XML_Reader_Any->new(\$line, {filter => 2});
            while ($rdr->iterate) { $count++; }
            Test::More::is($count, 23, 'counting values {filter => 2}');
        }
    }

    {
        my $line = q{<data><dummy></dummy>a      <!-- b -->    c</data>};
        my $out = '';
        my $rdr = $XML_Reader_Any->new(\$line);
        while ($rdr->iterate) { $out .= '['.$rdr->tag.'='.$rdr->value.']'; }
        Test::More::is($out, '[data=][dummy=][data=a c]', 'defaults are ok {strip => 1, filter => 2}');
    }

    {
        my $line = q{<data><dummy><!-- test --></dummy></data>};
        my $out = '';
        my $rdr = $XML_Reader_Any->new(\$line, {parse_ct => 1});
        while ($rdr->iterate) { $out .= '['.$rdr->path.'='.$rdr->comment.']'; }
        Test::More::is($out, '[/data=][/data/dummy=][/data/dummy=test][/data=]', 'comment is produced');
    }

    {
        my $line = q{<data>     a        b c             </data>};
        my $out = '';
        my $rdr = $XML_Reader_Any->new(\$line, {strip => 1});
        while ($rdr->iterate) { $out .= '['.$rdr->type.'='.$rdr->value.']'; }
        Test::More::is($out, '[T=a b c]', 'field is stripped of spaces');
    }

    {
        my $line = q{<data>     a        b c             </data>};
        my $out = '';
        my $rdr = $XML_Reader_Any->new(\$line, {strip => 0});
        while ($rdr->iterate) { $out .= '['.$rdr->type.'='.$rdr->value.']'; }
        Test::More::is($out, '[T=     a        b c             ]', 'field is not stripped of spaces');
    }

    {
        my $line = q{
          <data>
            <item>abc</item>
            <item>
              <dummy/>
              fgh
              <inner name="ttt" id="fff">
                o <!-- comment --> p <!-- comment2 --> q
              </inner>
            </item>
          </data>
          };

        {
            my $start_seq = '';
            my $end_seq   = '';
            my $lvl_seq   = '';

            my $rdr = $XML_Reader_Any->new(\$line);
            while ($rdr->iterate) {
                $start_seq .= $rdr->is_start;
                $end_seq   .= $rdr->is_end;
                $lvl_seq   .= '['.$rdr->level.']';
            }

            Test::More::is($start_seq, '11011000100', 'sequence of start-tags (with new)');
            Test::More::is($end_seq,   '01001000111', 'sequence of end-tags (with new)');
            Test::More::is($lvl_seq,   '[1][2][1][2][3][2][4][4][3][2][1]', 'sequence of level information (with new)');
        }
    }

    {
        my $line = q{<a><b><c><d></d></c></b></a>};

        {
            my $info = '';

            my $rdr = $XML_Reader_Any->new(\$line);
            while ($rdr->iterate) {
                $info .= '['.$rdr->path.'='.$rdr->value.']';
            }
            Test::More::is($info, '[/a=][/a/b=][/a/b/c=][/a/b/c/d=][/a/b/c=][/a/b=][/a=]', 'an empty, 4-level deep, nested XML (with new)');
        }
    }

    {
        my $line = q{
          <data>
            ooo <!-- hello --> ppp
          </data>
          };

        {
            my $data    = '';
            my $comment = '';

            my $rdr = $XML_Reader_Any->new(\$line, {parse_ct => 1});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                $comment = $rdr->comment if $i == 2;
                $data    = $rdr->value   if $i == 2;
            }
            Test::More::is($comment, 'hello', 'comment is correctly recognised');
            Test::More::is($data,    'ppp', 'data is broken up by comments');
        }

        {
            my $data    = '';
            my $comment = '';

            my $rdr = $XML_Reader_Any->new(\$line, {parse_ct => 1});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                $comment .= $rdr->comment if $rdr->type eq 'T';
                $data    .= $rdr->value   if $rdr->type eq 'T';
            }
            Test::More::is($i,       2, 'only one line is produced (with new)');
            Test::More::is($comment, 'hello', 'comment is found to be correct (with new)');
            Test::More::is($data,    'oooppp', 'data is not empty (with new)');
        }
        {
            my $data    = '';
            my $comment = '';

            my $rdr = $XML_Reader_Any->new(\$line, {parse_ct => 1});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                $comment .= $rdr->comment if $rdr->type eq 'T';
                $data    .= $rdr->value   if $rdr->type eq 'T';
            }
            Test::More::is($i,       2, 'only one line is produced (with new)');
            Test::More::is($comment, 'hello', 'comment is found to be correct (with new)');
            Test::More::is($data,    'oooppp', 'data is not empty (with new)');
        }
    }

    {
        my $line = q{
          <data>
            <item>abc</item>
            <item>
              <dummy/>
              fgh
              <inner name="ttt" id="fff">
                ooo <!-- comment --> ppp
              </inner>
            </item>
            <btem>
              <record id="77" used="no">Player 1</record>
              <record id="88" used="no">Player 2</record>
              <user>
                <level>
                  <agreement>
                    <line water="abc" ice="iii">jump</line>
                    <line water="def" ice="jjj">go</line>
                    <line water="ghi" ice="kkk">crawl</line>
                  </agreement>
                </level>
              </user>
              <record id="99" used="no">Player 3</record>
            </btem>
            <item>
              <alpha name="lll" type="qqq" age="999" />
              <beta test="successful">
                <gamma>
                  <delta number="undef">
                    letter
                  </delta>
                </gamma>
                <test>number one</test>
                <test>number two</test>
                <test>number three</test>
              </beta>
            </item>
          </data>
        };

        {
            my $att_seq = '';

            my $rdr = $XML_Reader_Any->new(\$line, {filter => 3, using => ['/data/item/alpha', '/data/item/beta']});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                my %at = %{$rdr->att_hash};
                $att_seq .= '['.join(' ', map {qq($_="$at{$_}")} sort keys %at).']';
            }
            Test::More::is($att_seq, '[age="999" name="lll" type="qqq"][test="successful"][][number="undef"][][][][][][][][]',
              'check $rdr->att_hash {filter => 3}');
        }

        {
            my $point_01 = '';
            my $point_09 = '';
            my $point_10 = '';
            my $point_25 = '';
            my $point_26 = '';
            my $point_38 = '';
            my $point_48 = '';

            my $rdr = $XML_Reader_Any->new(\$line, {using => ['/data/item', '/data/btem/user/level/agreement']});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                my $point = '['.$rdr->prefix.']['.$rdr->path.']['.$rdr->is_start.']['.$rdr->is_end.']['.$rdr->level.']';
                if    ($i ==  1) { $point_01 = $point; }
                elsif ($i ==  9) { $point_09 = $point; }
                elsif ($i == 10) { $point_10 = $point; }
                elsif ($i == 25) { $point_25 = $point; }
                elsif ($i == 26) { $point_26 = $point; }
                elsif ($i == 38) { $point_38 = $point; }
                elsif ($i == 48) { $point_48 = $point; }
            }
            Test::More::is($point_01, '[/data/item][/][1][1][0]',                               'check using at data point 01 (using)');
            Test::More::is($point_09, '[/data/btem/user/level/agreement][/][1][0][0]',          'check using at data point 09 (using)');
            Test::More::is($point_10, '[/data/btem/user/level/agreement][/line/@ice][0][0][2]', 'check using at data point 10 (using)');
            Test::More::is($point_25, '[/data/item][/alpha/@type][0][0][2]',                    'check using at data point 25 (using)');
            Test::More::is($point_26, '[/data/item][/alpha][1][1][1]',                          'check using at data point 26 (using)');
            Test::More::is($point_38, '[/data/item][/beta][0][0][1]',                           'check using at data point 38 (using)');
            Test::More::is($point_48, '',                                                       'check using at data point 48 (using)');
        }

        {
            my $point_01 = '';
            my $point_07 = '';
            my $point_08 = '';
            my $point_09 = '';
            my $point_15 = '';
            my $point_18 = '';
            my $point_19 = '';
            my $point_30 = '';
            my $point_41 = '';

            my $rdr = $XML_Reader_Any->new(\$line, {using => ['/data/item', '/data/btem/user/level/agreement']});
            my $i = 0;
            while ($rdr->iterate) { $i++;
                my $point = '['.$rdr->prefix.']['.$rdr->path.']['.$rdr->is_start.$rdr->is_end.']['.$rdr->level.']';
                if    ($i ==  1) { $point_01 = $point; }
                elsif ($i ==  7) { $point_07 = $point; }
                elsif ($i ==  8) { $point_08 = $point; }
                elsif ($i ==  9) { $point_09 = $point; }
                elsif ($i == 15) { $point_15 = $point; }
                elsif ($i == 18) { $point_18 = $point; }
                elsif ($i == 19) { $point_19 = $point; }
                elsif ($i == 30) { $point_30 = $point; }
                elsif ($i == 41) { $point_41 = $point; }
            }
            Test::More::is($point_01, '[/data/item][/][11][0]',                                 'check using at data point 01 {filter => 2}');
            Test::More::is($point_07, '[/data/item][/inner][11][1]',                            'check using at data point 07 {filter => 2}');
            Test::More::is($point_08, '[/data/item][/][01][0]',                                 'check using at data point 08 {filter => 2}');
            Test::More::is($point_09, '[/data/btem/user/level/agreement][/][10][0]',            'check using at data point 09 {filter => 2}');
            Test::More::is($point_15, '[/data/btem/user/level/agreement][/line/@water][00][2]', 'check using at data point 15 {filter => 2}');
            Test::More::is($point_18, '[/data/btem/user/level/agreement][/line/@ice][00][2]',   'check using at data point 18 {filter => 2}');
            Test::More::is($point_19, '[/data/btem/user/level/agreement][/line/@water][00][2]', 'check using at data point 19 {filter => 2}');
            Test::More::is($point_30, '[/data/item][/beta/gamma][10][2]',                       'check using at data point 30 {filter => 2}');
            Test::More::is($point_41, '[/data/item][/][01][0]',                                 'check using at data point 41 {filter => 2}');
        }
    }

    {
        my $line = q{<data />};

        my $output = '';

        my $rdr = $XML_Reader_Any->new(\$line);
        my $i = 0;
        while ($rdr->iterate) { $i++;
            $output .= '['.$rdr->path.'-'.$rdr->value.']['.$rdr->is_start.$rdr->is_end.']['.$rdr->level.']';
        }
        Test::More::is($output, '[/data-][11][1]', 'the simplest XML possible');
    }

    {
        my $line = q{<data id="z" />};

        my $output = '';

        my $rdr = $XML_Reader_Any->new(\$line);
        my $i = 0;
        while ($rdr->iterate) { $i++;
            $output .= '['.$rdr->path.'-'.$rdr->value.']['.$rdr->is_start.$rdr->is_end.']['.$rdr->level.']';
        }
        Test::More::is($output, '[/data/@id-z][00][2][/data-][11][1]', 'a simple XML with attribute');
    }

    {
        my $line = q{<apple orange="banana" />};

        my $tag  = '';
        my $attr = '';

        my $rdr = $XML_Reader_Any->new(\$line);
        my $i = 0;
        while ($rdr->iterate) { $i++;
            $tag  .= '['.$rdr->tag.']';
            $attr .= '['.$rdr->attr.']';
        }
        Test::More::is($tag,  '[@orange][apple]', 'verify tags');
        Test::More::is($attr, '[orange][]', 'verify attributes');
    }

    {
        my $line = q{<data>abc<![CDATA[  x    y  z >  <  &  ]]>def</data>};

        my $output = '';

        my $rdr = $XML_Reader_Any->new(\$line);
        my $i = 0;
        while ($rdr->iterate) { $i++;
            $output .= '['.$rdr->value.']';
        }
        Test::More::is($output, '[abc x y z > < & def]', 'CDATA is processed correctly');
    }

    {
        my $line = q{<root><id order='desc' nb='no' screen='color'>show
        <data name='abc' addr='def'>definition</data>text</id></root>};

        my $rdr = $XML_Reader_Any->new(\$line);

        my $output = '';

        my $i = 0;
        while ($rdr->iterate) { $i++;
            $output .= '['.$rdr->is_start.$rdr->is_end.']';
        }
        Test::More::is($output, '[10][00][00][00][10][00][00][11][01][01]',
           'filter => 2 for is_start, is_end');
    }

    {
        my $line = q{
          <data>
            <item>abc</item>
            <item>
              <dummy/>
              fgh
              <inner name="ttt" id="fff">
                o <!-- comment --> p
              </inner>
            </item>
            <btem>
              <record id="77" used="no">Player 1</record>
              <record id="88" used="no">Player 2</record>
              <user>
                <lvl>
                  <a>
                    <line water="abc" ice="iii">jump</line>
                    <line water="def" ice="jjj">go</line>
                    <line water="ghi" ice="kkk">crawl</line>
                  </a>
                </lvl>
              </user>
              <record id="99" used="no">Player 3</record>
            </btem>
            <item ts="vy">
              <alpha name="lll" type="qqq" age="999" />
              <beta test="sful">
                <gamma>
                  <d num="undef">
                    letter
                  </d>
                </gamma>
                <test>one</test>
                <test>t         o</test>
                <test>three</test>
              </beta>
            </item>
          </data>
        };

        my $point_01 = '';
        my $point_05 = '';
        my $point_08 = '';
        my $point_14 = '';
        my $point_15 = '';
        my $point_16 = '';
        my $point_22 = '';
        my $point_38 = '';
        my $point_42 = '';

        my $rdr = $XML_Reader_Any->new(\$line, {using => ['/data/item', '/data/btem/user/lvl/a']});

        my $i = 0;
        while ($rdr->iterate) { $i++;
            my $point = '['.$rdr->prefix.']['.$rdr->path.']['.$rdr->value.']['.$rdr->type.
                        ']['.$rdr->is_start.$rdr->is_end.']['.$rdr->tag.']['.$rdr->attr.']';

            if    ($i ==  1) { $point_01 = $point; }
            elsif ($i ==  5) { $point_05 = $point; }
            elsif ($i ==  8) { $point_08 = $point; }
            elsif ($i == 14) { $point_14 = $point; }
            elsif ($i == 15) { $point_15 = $point; }
            elsif ($i == 16) { $point_16 = $point; }
            elsif ($i == 22) { $point_22 = $point; }
            elsif ($i == 38) { $point_38 = $point; }
            elsif ($i == 42) { $point_42 = $point; }
        }
        Test::More::is($point_01, '[/data/item][/][abc][T][11][][]',                                  'check filter=>2 at data point 01');
        Test::More::is($point_05, '[/data/item][/inner/@id][fff][@][00][@id][id]',                    'check filter=>2 at data point 05');
        Test::More::is($point_08, '[/data/item][/][][T][01][][]',                                     'check filter=>2 at data point 08');
        Test::More::is($point_14, '[/data/btem/user/lvl/a][/line/@ice][jjj][@][00][@ice][ice]',       'check filter=>2 at data point 14');
        Test::More::is($point_15, '[/data/btem/user/lvl/a][/line/@water][def][@][00][@water][water]', 'check filter=>2 at data point 15');
        Test::More::is($point_16, '[/data/btem/user/lvl/a][/line][go][T][11][line][]',                'check filter=>2 at data point 16');
        Test::More::is($point_22, '[/data/item][/@ts][vy][@][00][@ts][ts]',                           'check filter=>2 at data point 22');
        Test::More::is($point_38, '[/data/item][/beta/test][t o][T][11][test][]',                     'check filter=>2 at data point 38');
        Test::More::is($point_42, '[/data/item][/][][T][01][][]',                                     'check filter=>2 at data point 42');
    }

    {
        my $line = qq{<root>\n}.
                   qq{  test1 \\n \\t \\ \\\\ \\\\\\ \t \n}.
                   qq{  test2\n}.
                   qq{\t<item />\n}.
                   qq{</root>};
        my $out = '';
        my $rdr = $XML_Reader_Any->new(\$line, {filter => 4, strip => 0});
        while ($rdr->iterate) { $out .= '['.$rdr->pyx.']'; }
        Test::More::is($out, '[(root][-\\n  test1 \\\\n \\\\t \\\\ \\\\\\\\ \\\\\\\\\\\\ \\t \\n  test2\\n\\t][(item][)item][-\\n][)root]', 'PYX escapes work as expected');
    }

    # stress tests

    {
        my $len = 10000;

        my $c_tag     = 'ab'.('c' x $len).'de';
        my $c_attr    = 'fg'.('h' x $len).'ij';
        my $c_value   = 'kl'.('m' x $len).'no';
        my $c_text    = 'pq'.('r' x $len).'st';
        my $c_comment = 'uv'.('w' x $len).'xy';
        my $c_pi1     = 'z0'.('1' x $len).'23';
        my $c_pi2     = '45'.('6' x $len).'78';

        my $v_starttag = '?';
        my $v_endtag   = '?';
        my $v_attr     = '?';
        my $v_value    = '?';
        my $v_text     = '?';
        my $v_comment  = '?';
        my $v_pi1      = '?';
        my $v_pi2      = '?';

        my $line = qq{<$c_tag $c_attr='$c_value'> $c_text <?$c_pi1 $c_pi2?> <!-- $c_comment --> </$c_tag>};

        my $rdr = $XML_Reader_Any->new(\$line, {filter => 4, parse_pi => 1, parse_ct => 1});

        while ($rdr->iterate) {
            if    ($rdr->is_start)   { $v_starttag = $rdr->tag; }
            elsif ($rdr->is_end)     { $v_endtag   = $rdr->tag; }
            elsif ($rdr->is_proc)    { $v_pi1      = $rdr->proc_tgt;
                                       $v_pi2      = $rdr->proc_data; }
            elsif ($rdr->is_comment) { $v_comment  = $rdr->comment; }
            elsif ($rdr->is_attr)    { $v_attr     = $rdr->attr;
                                       $v_value    = $rdr->value; }
            elsif ($rdr->is_text)    { $v_text     = $rdr->value; }
      }

        Test::More::is(length($v_starttag), $len + 4, 'length of variable $v_starttag');
        Test::More::is(length($v_endtag),   $len + 4, 'length of variable $v_endtag');
        Test::More::is(length($v_attr),     $len + 4, 'length of variable $v_attr');
        Test::More::is(length($v_value),    $len + 4, 'length of variable $v_value');
        Test::More::is(length($v_text),     $len + 4, 'length of variable $v_text');
        Test::More::is(length($v_comment),  $len + 4, 'length of variable $v_comment');
        Test::More::is(length($v_pi1),      $len + 4, 'length of variable $v_pi1');
        Test::More::is(length($v_pi2),      $len + 4, 'length of variable $v_pi2');

        Test::More::is(substr($v_starttag, 0, 3).'...'.substr($v_starttag, -3), 'abc...cde', 'content of variable $v_starttag');
        Test::More::is(substr($v_endtag,   0, 3).'...'.substr($v_endtag,   -3), 'abc...cde', 'content of variable $v_endtag');
        Test::More::is(substr($v_attr,     0, 3).'...'.substr($v_attr,     -3), 'fgh...hij', 'content of variable $v_attr');
        Test::More::is(substr($v_value,    0, 3).'...'.substr($v_value,    -3), 'klm...mno', 'content of variable $v_value');
        Test::More::is(substr($v_text,     0, 3).'...'.substr($v_text,     -3), 'pqr...rst', 'content of variable $v_text');
        Test::More::is(substr($v_comment,  0, 3).'...'.substr($v_comment,  -3), 'uvw...wxy', 'content of variable $v_comment');
        Test::More::is(substr($v_pi1,      0, 3).'...'.substr($v_pi1,      -3), 'z01...123', 'content of variable $v_pi1');
        Test::More::is(substr($v_pi2,      0, 3).'...'.substr($v_pi2,      -3), '456...678', 'content of variable $v_pi2');
    }
}];

$TestProg{'0020_test_Module.t'} = [281, sub {
    my ($XML_Reader_Any) = @_;

    Test::More::use_ok($XML_Reader_Any, qw(slurp_xml));

    {
        my $text = q{<init>n <?test pi?> t<page node="400">m <!-- remark --> r</page></init>};
        my @lines;
        my $rdr = $XML_Reader_Any->new(\$text);
        while ($rdr->iterate) {
            push @lines, sprintf("Path: %-19s, Value: %s", $rdr->path, $rdr->value);
        }

        Test::More::is(scalar(@lines), 4,                                  'Pod-Test case no  1: number of output lines');
        Test::More::is($lines[0], 'Path: /init              , Value: n t', 'Pod-Test case no  1: output line  0');
        Test::More::is($lines[1], 'Path: /init/page/@node   , Value: 400', 'Pod-Test case no  1: output line  1');
        Test::More::is($lines[2], 'Path: /init/page         , Value: m r', 'Pod-Test case no  1: output line  2');
        Test::More::is($lines[3], 'Path: /init              , Value: ',    'Pod-Test case no  1: output line  3');
    }

    {
      my $line1 =
        q{<?xml version="1.0" encoding="ISO-8859-1"?>
          <data>
            <item>abc</item>
            <item><!-- c1 -->
              <dummy/>
              fgh
              <inner name="ttt" id="fff">
                ooo <!-- c2 --> ppp
              </inner>
            </item>
          </data>
        };

        {
            my $rdr = $XML_Reader_Any->new(\$line1);
            my $i = 0;
            my @lines;
            while ($rdr->iterate) { $i++;
                push @lines, sprintf("%3d. pat=%-22s, val=%-9s, s=%-1s, e=%-1s, tag=%-6s, atr=%-6s, t=%-1s, lvl=%2d, c=%s",
                 $i, $rdr->path, $rdr->value, $rdr->is_start,
                 $rdr->is_end, $rdr->tag, $rdr->attr, $rdr->type, $rdr->level, $rdr->comment);
            }

            Test::More::is(scalar(@lines), 11,                                                                                                     'Pod-Test case no  2: number of output lines');
            Test::More::is($lines[ 0], '  1. pat=/data                 , val=         , s=1, e=0, tag=data  , atr=      , t=T, lvl= 1, c=',   'Pod-Test case no  2: output line  0');
            Test::More::is($lines[ 1], '  2. pat=/data/item            , val=abc      , s=1, e=1, tag=item  , atr=      , t=T, lvl= 2, c=',   'Pod-Test case no  2: output line  1');
            Test::More::is($lines[ 2], '  3. pat=/data                 , val=         , s=0, e=0, tag=data  , atr=      , t=T, lvl= 1, c=',   'Pod-Test case no  2: output line  2');
            Test::More::is($lines[ 3], '  4. pat=/data/item            , val=         , s=1, e=0, tag=item  , atr=      , t=T, lvl= 2, c=',   'Pod-Test case no  2: output line  3');
            Test::More::is($lines[ 4], '  5. pat=/data/item/dummy      , val=         , s=1, e=1, tag=dummy , atr=      , t=T, lvl= 3, c=',   'Pod-Test case no  2: output line  4');
            Test::More::is($lines[ 5], '  6. pat=/data/item            , val=fgh      , s=0, e=0, tag=item  , atr=      , t=T, lvl= 2, c=',   'Pod-Test case no  2: output line  5');
            Test::More::is($lines[ 6], '  7. pat=/data/item/inner/@id  , val=fff      , s=0, e=0, tag=@id   , atr=id    , t=@, lvl= 4, c=',   'Pod-Test case no  2: output line  6');
            Test::More::is($lines[ 7], '  8. pat=/data/item/inner/@name, val=ttt      , s=0, e=0, tag=@name , atr=name  , t=@, lvl= 4, c=',   'Pod-Test case no  2: output line  7');
            Test::More::is($lines[ 8], '  9. pat=/data/item/inner      , val=ooo ppp  , s=1, e=1, tag=inner , atr=      , t=T, lvl= 3, c=',   'Pod-Test case no  2: output line  8');
            Test::More::is($lines[ 9], ' 10. pat=/data/item            , val=         , s=0, e=1, tag=item  , atr=      , t=T, lvl= 2, c=',   'Pod-Test case no  2: output line  9');
            Test::More::is($lines[10], ' 11. pat=/data                 , val=         , s=0, e=1, tag=data  , atr=      , t=T, lvl= 1, c=',   'Pod-Test case no  2: output line 10');
        }
    }

    {
      my $line2 = q{
        <data>
          <order>
            <database>
              <customer name="aaa" />
              <customer name="bbb" />
              <customer name="ccc" />
              <customer name="ddd" />
            </database>
          </order>
          <dummy value="ttt">test</dummy>
          <supplier>hhh</supplier>
          <supplier>iii</supplier>
          <supplier>jjj</supplier>
        </data>
        };

        {
            my $rdr = $XML_Reader_Any->new(\$line2,
              {using => ['/data/order/database/customer', '/data/supplier']});
            my $i = 0;
            my @lines;
            while ($rdr->iterate) { $i++;
                push @lines, sprintf("%3d. prf=%-29s, pat=%-7s, val=%-3s, tag=%-6s, t=%-1s, lvl=%2d",
                  $i, $rdr->prefix, $rdr->path, $rdr->value, $rdr->tag, $rdr->type, $rdr->level);
            }

            Test::More::is(scalar(@lines), 11,                                                                                  'Pod-Test case no  4: number of output lines');
            Test::More::is($lines[ 0], '  1. prf=/data/order/database/customer, pat=/@name , val=aaa, tag=@name , t=@, lvl= 1', 'Pod-Test case no  4: output line  0');
            Test::More::is($lines[ 1], '  2. prf=/data/order/database/customer, pat=/      , val=   , tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  1');
            Test::More::is($lines[ 2], '  3. prf=/data/order/database/customer, pat=/@name , val=bbb, tag=@name , t=@, lvl= 1', 'Pod-Test case no  4: output line  2');
            Test::More::is($lines[ 3], '  4. prf=/data/order/database/customer, pat=/      , val=   , tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  3');
            Test::More::is($lines[ 4], '  5. prf=/data/order/database/customer, pat=/@name , val=ccc, tag=@name , t=@, lvl= 1', 'Pod-Test case no  4: output line  4');
            Test::More::is($lines[ 5], '  6. prf=/data/order/database/customer, pat=/      , val=   , tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  5');
            Test::More::is($lines[ 6], '  7. prf=/data/order/database/customer, pat=/@name , val=ddd, tag=@name , t=@, lvl= 1', 'Pod-Test case no  4: output line  6');
            Test::More::is($lines[ 7], '  8. prf=/data/order/database/customer, pat=/      , val=   , tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  7');
            Test::More::is($lines[ 8], '  9. prf=/data/supplier               , pat=/      , val=hhh, tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  8');
            Test::More::is($lines[ 9], ' 10. prf=/data/supplier               , pat=/      , val=iii, tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line  9');
            Test::More::is($lines[10], ' 11. prf=/data/supplier               , pat=/      , val=jjj, tag=      , t=T, lvl= 0', 'Pod-Test case no  4: output line 10');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$line2);
            my $i = 0;
            my @lines;
            while ($rdr->iterate) { $i++;
                push @lines, sprintf("%3d. prf=%-1s, pat=%-37s, val=%-6s, tag=%-11s, t=%-1s, lvl=%2d",
                  $i, $rdr->prefix, $rdr->path, $rdr->value, $rdr->tag, $rdr->type, $rdr->level);
            }

            Test::More::is(scalar(@lines), 26,                                                                                            'Pod-Test case no  5: number of output lines');
            Test::More::is($lines[ 0], '  1. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line  0');
            Test::More::is($lines[ 1], '  2. prf= , pat=/data/order                          , val=      , tag=order      , t=T, lvl= 2', 'Pod-Test case no  5: output line  1');
            Test::More::is($lines[ 2], '  3. prf= , pat=/data/order/database                 , val=      , tag=database   , t=T, lvl= 3', 'Pod-Test case no  5: output line  2');
            Test::More::is($lines[ 3], '  4. prf= , pat=/data/order/database/customer/@name  , val=aaa   , tag=@name      , t=@, lvl= 5', 'Pod-Test case no  5: output line  3');
            Test::More::is($lines[ 4], '  5. prf= , pat=/data/order/database/customer        , val=      , tag=customer   , t=T, lvl= 4', 'Pod-Test case no  5: output line  4');
            Test::More::is($lines[ 5], '  6. prf= , pat=/data/order/database                 , val=      , tag=database   , t=T, lvl= 3', 'Pod-Test case no  5: output line  5');
            Test::More::is($lines[ 6], '  7. prf= , pat=/data/order/database/customer/@name  , val=bbb   , tag=@name      , t=@, lvl= 5', 'Pod-Test case no  5: output line  6');
            Test::More::is($lines[ 7], '  8. prf= , pat=/data/order/database/customer        , val=      , tag=customer   , t=T, lvl= 4', 'Pod-Test case no  5: output line  7');
            Test::More::is($lines[ 8], '  9. prf= , pat=/data/order/database                 , val=      , tag=database   , t=T, lvl= 3', 'Pod-Test case no  5: output line  8');
            Test::More::is($lines[ 9], ' 10. prf= , pat=/data/order/database/customer/@name  , val=ccc   , tag=@name      , t=@, lvl= 5', 'Pod-Test case no  5: output line  9');
            Test::More::is($lines[10], ' 11. prf= , pat=/data/order/database/customer        , val=      , tag=customer   , t=T, lvl= 4', 'Pod-Test case no  5: output line 10');
            Test::More::is($lines[11], ' 12. prf= , pat=/data/order/database                 , val=      , tag=database   , t=T, lvl= 3', 'Pod-Test case no  5: output line 11');
            Test::More::is($lines[12], ' 13. prf= , pat=/data/order/database/customer/@name  , val=ddd   , tag=@name      , t=@, lvl= 5', 'Pod-Test case no  5: output line 12');
            Test::More::is($lines[13], ' 14. prf= , pat=/data/order/database/customer        , val=      , tag=customer   , t=T, lvl= 4', 'Pod-Test case no  5: output line 13');
            Test::More::is($lines[14], ' 15. prf= , pat=/data/order/database                 , val=      , tag=database   , t=T, lvl= 3', 'Pod-Test case no  5: output line 14');
            Test::More::is($lines[15], ' 16. prf= , pat=/data/order                          , val=      , tag=order      , t=T, lvl= 2', 'Pod-Test case no  5: output line 15');
            Test::More::is($lines[16], ' 17. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line 16');
            Test::More::is($lines[17], ' 18. prf= , pat=/data/dummy/@value                   , val=ttt   , tag=@value     , t=@, lvl= 3', 'Pod-Test case no  5: output line 17');
            Test::More::is($lines[18], ' 19. prf= , pat=/data/dummy                          , val=test  , tag=dummy      , t=T, lvl= 2', 'Pod-Test case no  5: output line 18');
            Test::More::is($lines[19], ' 20. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line 19');
            Test::More::is($lines[20], ' 21. prf= , pat=/data/supplier                       , val=hhh   , tag=supplier   , t=T, lvl= 2', 'Pod-Test case no  5: output line 20');
            Test::More::is($lines[21], ' 22. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line 21');
            Test::More::is($lines[22], ' 23. prf= , pat=/data/supplier                       , val=iii   , tag=supplier   , t=T, lvl= 2', 'Pod-Test case no  5: output line 22');
            Test::More::is($lines[23], ' 24. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line 23');
            Test::More::is($lines[24], ' 25. prf= , pat=/data/supplier                       , val=jjj   , tag=supplier   , t=T, lvl= 2', 'Pod-Test case no  5: output line 24');
            Test::More::is($lines[25], ' 26. prf= , pat=/data                                , val=      , tag=data       , t=T, lvl= 1', 'Pod-Test case no  5: output line 25');
        }
    }

    {
        my $text = q{<root><test param="v"><a><b>e<data id="z">g</data>f</b></a></test>x <!-- remark --> yz</root>};

        my $rdr = $XML_Reader_Any->new(\$text);
        my @lines;
        while ($rdr->iterate) {
            push @lines, sprintf("Path: %-24s, Value: %s", $rdr->path, $rdr->value);
        }

        Test::More::is(scalar(@lines), 11,                                        'Pod-Test case no  6: number of output lines');
        Test::More::is($lines[ 0], 'Path: /root                   , Value: ',     'Pod-Test case no  6: output line  0');
        Test::More::is($lines[ 1], 'Path: /root/test/@param       , Value: v',    'Pod-Test case no  6: output line  1');
        Test::More::is($lines[ 2], 'Path: /root/test              , Value: ',     'Pod-Test case no  6: output line  2');
        Test::More::is($lines[ 3], 'Path: /root/test/a            , Value: ',     'Pod-Test case no  6: output line  3');
        Test::More::is($lines[ 4], 'Path: /root/test/a/b          , Value: e',    'Pod-Test case no  6: output line  4');
        Test::More::is($lines[ 5], 'Path: /root/test/a/b/data/@id , Value: z',    'Pod-Test case no  6: output line  5');
        Test::More::is($lines[ 6], 'Path: /root/test/a/b/data     , Value: g',    'Pod-Test case no  6: output line  6');
        Test::More::is($lines[ 7], 'Path: /root/test/a/b          , Value: f',    'Pod-Test case no  6: output line  7');
        Test::More::is($lines[ 8], 'Path: /root/test/a            , Value: ',     'Pod-Test case no  6: output line  8');
        Test::More::is($lines[ 9], 'Path: /root/test              , Value: ',     'Pod-Test case no  6: output line  9');
        Test::More::is($lines[10], 'Path: /root                   , Value: x yz', 'Pod-Test case no  6: output line 10');
    }

    {
        my $text = q{<?xml version="1.0"?><dummy>xyz <!-- remark --> stu <?ab cde?> test</dummy>};

        {
            my $rdr = $XML_Reader_Any->new(\$text);
            my @lines;
            while ($rdr->iterate) {
                if ($rdr->is_decl)    { my %h = %{$rdr->dec_hash};
                                        push @lines, "Found decl     ".join('', map{" $_='$h{$_}'"} sort keys %h); }
                if ($rdr->is_proc)    { push @lines, "Found proc      "."t=".$rdr->proc_tgt.", d=". $rdr->proc_data; }
                if ($rdr->is_comment) { push @lines, "Found comment   ".$rdr->comment; }
                push @lines, "Text '".$rdr->value."'" unless $rdr->is_decl;
            }

            Test::More::is(scalar(@lines),  1,                'Pod-Test case no  7: number of output lines');
            Test::More::is($lines[ 0], "Text 'xyz stu test'", 'Pod-Test case no  7: output line  0');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text, {parse_ct => 1});
            my @lines;
            while ($rdr->iterate) {
                if ($rdr->is_decl)    { my %h = %{$rdr->dec_hash};
                                        push @lines, "Found decl     ".join('', map{" $_='$h{$_}'"} sort keys %h); }
                if ($rdr->is_proc)    { push @lines, "Found proc      "."t=".$rdr->proc_tgt.", d=". $rdr->proc_data; }
                if ($rdr->is_comment) { push @lines, "Found comment   ".$rdr->comment; }
                push @lines, "Text '".$rdr->value."'" unless $rdr->is_decl;
            }

            Test::More::is(scalar(@lines),  3,                   'Pod-Test case no  8: number of output lines');
            Test::More::is($lines[ 0], "Text 'xyz'",             'Pod-Test case no  8: output line  0');
            Test::More::is($lines[ 1], "Found comment   remark", 'Pod-Test case no  8: output line  1');
            Test::More::is($lines[ 2], "Text 'stu test'",        'Pod-Test case no  8: output line  2');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text, {parse_ct => 1, parse_pi => 1});
            my @lines;
            while ($rdr->iterate) {
                if ($rdr->is_decl)    { my %h = %{$rdr->dec_hash};
                                        push @lines, "Found decl     ".join('', map{" $_='$h{$_}'"} sort keys %h); }
                if ($rdr->is_proc)    { push @lines, "Found proc      "."t=".$rdr->proc_tgt.", d=". $rdr->proc_data; }
                if ($rdr->is_comment) { push @lines, "Found comment   ".$rdr->comment; }
                push @lines, "Text '".$rdr->value."'" unless $rdr->is_decl;
            }

            Test::More::is(scalar(@lines),  6,                          'Pod-Test case no  9: number of output lines');
            Test::More::is($lines[ 0], "Found decl      version='1.0'", 'Pod-Test case no  9: output line  0');
            Test::More::is($lines[ 1], "Text 'xyz'",                    'Pod-Test case no  9: output line  1');
            Test::More::is($lines[ 2], "Found comment   remark",        'Pod-Test case no  9: output line  2');
            Test::More::is($lines[ 3], "Text 'stu'",                    'Pod-Test case no  9: output line  3');
            Test::More::is($lines[ 4], "Found proc      t=ab, d=cde",   'Pod-Test case no  9: output line  4');
            Test::More::is($lines[ 5], "Text 'test'",                   'Pod-Test case no  9: output line  5');
        }
    }

    {
        my $text = q{<root><test param="v"><a><b>e<data id="z">g</data>f</b></a></test>x <!-- remark --> yz</root>};

        {
            my $rdr = $XML_Reader_Any->new(\$text, {filter => 2});
            my @lines;
            while ($rdr->iterate) {
                push @lines, sprintf "Path: %-24s, Value: %s", $rdr->path, $rdr->value;
            }

            Test::More::is(scalar(@lines), 11,                                        'Pod-Test case no 10: number of output lines');
            Test::More::is($lines[ 0], 'Path: /root                   , Value: ',     'Pod-Test case no 10: output line  0');
            Test::More::is($lines[ 1], 'Path: /root/test/@param       , Value: v',    'Pod-Test case no 10: output line  1');
            Test::More::is($lines[ 2], 'Path: /root/test              , Value: ',     'Pod-Test case no 10: output line  2');
            Test::More::is($lines[ 3], 'Path: /root/test/a            , Value: ',     'Pod-Test case no 10: output line  3');
            Test::More::is($lines[ 4], 'Path: /root/test/a/b          , Value: e',    'Pod-Test case no 10: output line  4');
            Test::More::is($lines[ 5], 'Path: /root/test/a/b/data/@id , Value: z',    'Pod-Test case no 10: output line  5');
            Test::More::is($lines[ 6], 'Path: /root/test/a/b/data     , Value: g',    'Pod-Test case no 10: output line  6');
            Test::More::is($lines[ 7], 'Path: /root/test/a/b          , Value: f',    'Pod-Test case no 10: output line  7');
            Test::More::is($lines[ 8], 'Path: /root/test/a            , Value: ',     'Pod-Test case no 10: output line  8');
            Test::More::is($lines[ 9], 'Path: /root/test              , Value: ',     'Pod-Test case no 10: output line  9');
            Test::More::is($lines[10], 'Path: /root                   , Value: x yz', 'Pod-Test case no 10: output line 10');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text, {filter => 2});
            my @lines;
            my %at;
            while ($rdr->iterate) {
                my $indentation = '  ' x ($rdr->level - 1);

                if ($rdr->type eq '@')  { $at{$rdr->attr} = $rdr->value; }

                if ($rdr->is_start) {
                    push @lines, $indentation.'<'.$rdr->tag.join('', map{" $_='$at{$_}'"} sort keys %at).'>';
                }

                if ($rdr->type eq 'T' and $rdr->value ne '') {
                    push @lines, $indentation.'  '.$rdr->value;
                }

                unless ($rdr->type eq '@') { %at  = (); }

                if ($rdr->is_end) {
                    push @lines, $indentation.'</'.$rdr->tag.'>';
                }
            }

            Test::More::is(scalar(@lines), 14,                   'Pod-Test case no 11: number of output lines');
            Test::More::is($lines[ 0], q{<root>},                'Pod-Test case no 11: output line  0');
            Test::More::is($lines[ 1], q{  <test param='v'>},    'Pod-Test case no 11: output line  1');
            Test::More::is($lines[ 2], q{    <a>},               'Pod-Test case no 11: output line  2');
            Test::More::is($lines[ 3], q{      <b>},             'Pod-Test case no 11: output line  3');
            Test::More::is($lines[ 4], q{        e},             'Pod-Test case no 11: output line  4');
            Test::More::is($lines[ 5], q{        <data id='z'>}, 'Pod-Test case no 11: output line  5');
            Test::More::is($lines[ 6], q{          g},           'Pod-Test case no 11: output line  6');
            Test::More::is($lines[ 7], q{        </data>},       'Pod-Test case no 11: output line  7');
            Test::More::is($lines[ 8], q{        f},             'Pod-Test case no 11: output line  8');
            Test::More::is($lines[ 9], q{      </b>},            'Pod-Test case no 11: output line  9');
            Test::More::is($lines[10], q{    </a>},              'Pod-Test case no 11: output line 10');
            Test::More::is($lines[11], q{  </test>},             'Pod-Test case no 11: output line 11');
            Test::More::is($lines[12], q{  x yz},                'Pod-Test case no 11: output line 12');
            Test::More::is($lines[13], q{</root>},               'Pod-Test case no 11: output line 13');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text, {filter => 3});
            my @lines;
            while ($rdr->iterate) {
                my $indentation = '  ' x ($rdr->level - 1);

                if ($rdr->is_start) {
                    push @lines, $indentation.'<'.$rdr->tag.
                      join('', map{" $_='".$rdr->att_hash->{$_}."'"} sort keys %{$rdr->att_hash}).'>';
                }

                if ($rdr->type eq 'T' and $rdr->value ne '') {
                    push @lines, $indentation.'  '.$rdr->value;
                }

                if ($rdr->is_end) {
                    push @lines, $indentation.'</'.$rdr->tag.'>';
                }
            }

            Test::More::is(scalar(@lines), 14,                   'Pod-Test case no 12: number of output lines');
            Test::More::is($lines[ 0], q{<root>},                'Pod-Test case no 12: output line  0');
            Test::More::is($lines[ 1], q{  <test param='v'>},    'Pod-Test case no 12: output line  1');
            Test::More::is($lines[ 2], q{    <a>},               'Pod-Test case no 12: output line  2');
            Test::More::is($lines[ 3], q{      <b>},             'Pod-Test case no 12: output line  3');
            Test::More::is($lines[ 4], q{        e},             'Pod-Test case no 12: output line  4');
            Test::More::is($lines[ 5], q{        <data id='z'>}, 'Pod-Test case no 12: output line  5');
            Test::More::is($lines[ 6], q{          g},           'Pod-Test case no 12: output line  6');
            Test::More::is($lines[ 7], q{        </data>},       'Pod-Test case no 12: output line  7');
            Test::More::is($lines[ 8], q{        f},             'Pod-Test case no 12: output line  8');
            Test::More::is($lines[ 9], q{      </b>},            'Pod-Test case no 12: output line  9');
            Test::More::is($lines[10], q{    </a>},              'Pod-Test case no 12: output line 10');
            Test::More::is($lines[11], q{  </test>},             'Pod-Test case no 12: output line 11');
            Test::More::is($lines[12], q{  x yz},                'Pod-Test case no 12: output line 12');
            Test::More::is($lines[13], q{</root>},               'Pod-Test case no 12: output line 13');
        }
    }

    {
        my $text = q{<?xml version="1.0" encoding="ISO-8859-1"?>
          <delta>
            <dim alter="511">
              <gamma />
              <beta>
                car <?tt dat?>
              </beta>
            </dim>
            dskjfh <!-- remark --> uuu
          </delta>};

        my $rdr = $XML_Reader_Any->new(\$text, {filter => 4, parse_pi => 1});
        my @lines;
        while ($rdr->iterate) {
            push @lines, sprintf "Type = %1s, pyx = %s", $rdr->type, $rdr->pyx;
        }

        Test::More::is(scalar(@lines), 13,                                                     'Pod-Test case no 13: number of output lines');
        Test::More::is($lines[ 0], "Type = D, pyx = ?xml version='1.0' encoding='ISO-8859-1'", 'Pod-Test case no 13: output line  0');
        Test::More::is($lines[ 1], "Type = S, pyx = (delta",                                   'Pod-Test case no 13: output line  1');
        Test::More::is($lines[ 2], "Type = S, pyx = (dim",                                     'Pod-Test case no 13: output line  2');
        Test::More::is($lines[ 3], "Type = @, pyx = Aalter 511",                               'Pod-Test case no 13: output line  3');
        Test::More::is($lines[ 4], "Type = S, pyx = (gamma",                                   'Pod-Test case no 13: output line  4');
        Test::More::is($lines[ 5], "Type = E, pyx = )gamma",                                   'Pod-Test case no 13: output line  5');
        Test::More::is($lines[ 6], "Type = S, pyx = (beta",                                    'Pod-Test case no 13: output line  6');
        Test::More::is($lines[ 7], "Type = T, pyx = -car",                                     'Pod-Test case no 13: output line  7');
        Test::More::is($lines[ 8], "Type = ?, pyx = ?tt dat",                                  'Pod-Test case no 13: output line  8');
        Test::More::is($lines[ 9], "Type = E, pyx = )beta",                                    'Pod-Test case no 13: output line  9');
        Test::More::is($lines[10], "Type = E, pyx = )dim",                                     'Pod-Test case no 13: output line 10');
        Test::More::is($lines[11], "Type = T, pyx = -dskjfh uuu",                              'Pod-Test case no 13: output line 11');
        Test::More::is($lines[12], "Type = E, pyx = )delta",                                   'Pod-Test case no 13: output line 12');
    }

    {
        my $text = q{
          <delta>
            <!-- remark -->
          </delta>};

        my $rdr = $XML_Reader_Any->new(\$text, {filter => 4, parse_ct => 1});
        my @lines;
        while ($rdr->iterate) {
            push @lines, sprintf "Type = %1s, pyx = %s", $rdr->type, $rdr->pyx;
        }

        Test::More::is(scalar(@lines),  3,                    'Pod-Test case no 14: number of output lines');
        Test::More::is($lines[ 0], "Type = S, pyx = (delta",  'Pod-Test case no 14: output line  0');
        Test::More::is($lines[ 1], "Type = #, pyx = #remark", 'Pod-Test case no 14: output line  1');
        Test::More::is($lines[ 2], "Type = E, pyx = )delta",  'Pod-Test case no 14: output line  2');
    }

    {
        my $text = q{<?xml version="1.0"?>
          <parent abc="def"> <?pt hmf?>
            dskjfh <!-- remark -->
            <child>ghi</child>
          </parent>};

        my $rdr = $XML_Reader_Any->new(\$text, {filter => 4, parse_pi => 1, parse_ct => 1});
        my @lines;
        while ($rdr->iterate) {
            my $txt = sprintf "Path %-15s v=%s ", $rdr->path, $rdr->is_value;

            if    ($rdr->is_start)   { push @lines, $txt."Found start tag ".$rdr->tag; }
            elsif ($rdr->is_end)     { push @lines, $txt."Found end tag   ".$rdr->tag; }
            elsif ($rdr->is_decl)    { my %h = %{$rdr->dec_hash};
                                       push @lines, $txt."Found decl     ".join('', map{" $_='$h{$_}'"} sort keys %h); }
            elsif ($rdr->is_proc)    { push @lines, $txt."Found proc      "."t=".$rdr->proc_tgt.", d=".$rdr->proc_data; }
            elsif ($rdr->is_comment) { push @lines, $txt."Found comment   ".$rdr->comment; }
            elsif ($rdr->is_attr)    { push @lines, $txt."Found attribute ".$rdr->attr."='".$rdr->value."'"; }
            elsif ($rdr->is_text)    { push @lines, $txt."Found text      ".$rdr->value; }
        }

        Test::More::is(scalar(@lines),  10,                                                       'Pod-Test case no 15: number of output lines');
        Test::More::is($lines[ 0], "Path /               " ."v=0 Found decl      version='1.0'",  'Pod-Test case no 15: output line  0');
        Test::More::is($lines[ 1], "Path /parent         " ."v=0 Found start tag parent",         'Pod-Test case no 15: output line  1');
        Test::More::is($lines[ 2], "Path /parent/\@abc    "."v=1 Found attribute abc='def'",      'Pod-Test case no 15: output line  2');
        Test::More::is($lines[ 3], "Path /parent         " ."v=0 Found proc      t=pt, d=hmf",    'Pod-Test case no 15: output line  3');
        Test::More::is($lines[ 4], "Path /parent         " ."v=1 Found text      dskjfh",         'Pod-Test case no 15: output line  4');
        Test::More::is($lines[ 5], "Path /parent         " ."v=0 Found comment   remark",         'Pod-Test case no 15: output line  5');
        Test::More::is($lines[ 6], "Path /parent/child   " ."v=0 Found start tag child",          'Pod-Test case no 15: output line  6');
        Test::More::is($lines[ 7], "Path /parent/child   " ."v=1 Found text      ghi",            'Pod-Test case no 15: output line  7');
        Test::More::is($lines[ 8], "Path /parent/child   " ."v=0 Found end tag   child",          'Pod-Test case no 15: output line  8');
        Test::More::is($lines[ 9], "Path /parent         " ."v=0 Found end tag   parent",         'Pod-Test case no 15: output line  9');
    }

    {
        my $text = q{
          <start>
            <param>
              <data>
                <item p1="a" p2="b" p3="c">start1 <inner p1="p">i1</inner> end1</item>
                <item p1="d" p2="e" p3="f">start2 <inner p1="q">i2</inner> end2</item>
                <item p1="g" p2="h" p3="i">start3 <inner p1="r">i3</inner> end3</item>
              </data>
              <dataz>
                <item p1="j" p2="k" p3="l">start9 <inner p1="s">i9</inner> end9</item>
              </dataz>
              <data>
                <item p1="m" p2="n" p3="o">start4 <inner p1="t">i4</inner> end4</item>
              </data>
            </param>
          </start>};

        {
            my $rdr = $XML_Reader_Any->new(\$text,
              {filter => 2, using => '/start/param/data/item'});
            my @lines;

            my ($p1, $p3);

            while ($rdr->iterate) {
                if    ($rdr->path eq '/@p1') { $p1 = $rdr->value; }
                elsif ($rdr->path eq '/@p3') { $p3 = $rdr->value; }
                elsif ($rdr->path eq '/' and $rdr->is_start) {
                    push @lines, sprintf("item = '%s', p1 = '%s', p3 = '%s'",
                      $rdr->value, $p1, $p3);
                }
                unless ($rdr->is_attr) { $p1 = undef; $p3 = undef; }
            }

            Test::More::is(scalar(@lines),   4,                               'Pod-Test case no 16: number of output lines');
            Test::More::is($lines[ 0], "item = 'start1', p1 = 'a', p3 = 'c'", 'Pod-Test case no 16: output line  0');
            Test::More::is($lines[ 1], "item = 'start2', p1 = 'd', p3 = 'f'", 'Pod-Test case no 16: output line  1');
            Test::More::is($lines[ 2], "item = 'start3', p1 = 'g', p3 = 'i'", 'Pod-Test case no 16: output line  2');
            Test::More::is($lines[ 3], "item = 'start4', p1 = 'm', p3 = 'o'", 'Pod-Test case no 16: output line  3');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text,
              {filter => 3, using => '/start/param/data/item'});
            my @lines;

            while ($rdr->iterate) {
                if ($rdr->path eq '/' and $rdr->is_start) {
                    push @lines, sprintf("item = '%s', p1 = '%s', p3 = '%s'",
                      $rdr->value, $rdr->att_hash->{p1}, $rdr->att_hash->{p3});
                }
            }

            Test::More::is(scalar(@lines),   4,                               'Pod-Test case no 17: number of output lines');
            Test::More::is($lines[ 0], "item = 'start1', p1 = 'a', p3 = 'c'", 'Pod-Test case no 17: output line  0');
            Test::More::is($lines[ 1], "item = 'start2', p1 = 'd', p3 = 'f'", 'Pod-Test case no 17: output line  1');
            Test::More::is($lines[ 2], "item = 'start3', p1 = 'g', p3 = 'i'", 'Pod-Test case no 17: output line  2');
            Test::More::is($lines[ 3], "item = 'start4', p1 = 'm', p3 = 'o'", 'Pod-Test case no 17: output line  3');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$text,
              {filter => 4, using => '/start/param/data/item'});
            my @lines;

            my ($count, $p1, $p3);

            while ($rdr->iterate) {
                if    ($rdr->path eq '/@p1') { $p1 = $rdr->value; }
                elsif ($rdr->path eq '/@p3') { $p3 = $rdr->value; }
                elsif ($rdr->path eq '/') {
                    if    ($rdr->is_start) { $count = 0; $p1 = undef; $p3 = undef; }
                    elsif ($rdr->is_text) {
                        $count++;
                        if ($count == 1) {
                            push @lines, sprintf("item = '%s', p1 = '%s', p3 = '%s'",
                              $rdr->value, $p1, $p3);
                        }
                    }
                }
            }

            Test::More::is(scalar(@lines),   4,                               'Pod-Test case no 18: number of output lines');
            Test::More::is($lines[ 0], "item = 'start1', p1 = 'a', p3 = 'c'", 'Pod-Test case no 18: output line  0');
            Test::More::is($lines[ 1], "item = 'start2', p1 = 'd', p3 = 'f'", 'Pod-Test case no 18: output line  1');
            Test::More::is($lines[ 2], "item = 'start3', p1 = 'g', p3 = 'i'", 'Pod-Test case no 18: output line  2');
            Test::More::is($lines[ 3], "item = 'start4', p1 = 'm', p3 = 'o'", 'Pod-Test case no 18: output line  3');
        }
    }

    {
        my $line2 = q{
        <data>
          aa
          <supplier>ggg</supplier>
          <supplier>hhh</supplier>
          <order>
            cc
            <database>
              <customer name="smith" id="652">
                <street>high street</street>
                <city>boston</city>
              </customer>
              <customer name="jones" id="184">
                <street>maple street</street>
                <city>new york</city>
              </customer>
              <customer name="stewart" id="520">
                <street>ring road</street>
                <city>dallas</city>
              </customer>
            </database>
            dd
          </order>
          <dummy value="ttt">test</dummy>
          <supplier>iii</supplier>
          <supplier>jjj</supplier>
          bb
        </data>
        };

        my $aref = slurp_xml(\$line2,
          { root => '/data/order/database/customer', branch => ['/@name', '/street', '/city'] },
          { root => '/data/supplier',                branch => ['/']                          },
          { root => '/',                             branch => ['/data']                      },
          { root => '/',                             branch => ['/data/order']                },
          { root => '/',                             branch => ['data/order']                 },
        );

        my @lines;

        for (@{$aref->[0]}) {
            push @lines, sprintf("Cust: Name = %-7s Street = %-12s City = %s", $_->[0], $_->[1], $_->[2]);
        }

        for (@{$aref->[1]}) {
            push @lines, sprintf("Supp: Name = %s", $_->[0]);
        }

        for (@{$aref->[2]}) {
            push @lines, sprintf("Root: Data = %s", $_->[0]);
        }

        for (@{$aref->[3]}) {
            push @lines, sprintf("Root: Ordr = %s", $_->[0]);
        }

        for (@{$aref->[4]}) {
            push @lines, sprintf("Root: Ord2 = %s", $_->[0]);
        }

        Test::More::is(scalar(@lines),  10,                                                      'Pod-Test case no 19: number of output lines');
        Test::More::is($lines[ 0], "Cust: Name = smith   Street = high street  City = boston",   'Pod-Test case no 19: output line  0');
        Test::More::is($lines[ 1], "Cust: Name = jones   Street = maple street City = new york", 'Pod-Test case no 19: output line  1');
        Test::More::is($lines[ 2], "Cust: Name = stewart Street = ring road    City = dallas",   'Pod-Test case no 19: output line  2');
        Test::More::is($lines[ 3], "Supp: Name = ggg",                                           'Pod-Test case no 19: output line  3');
        Test::More::is($lines[ 4], "Supp: Name = hhh",                                           'Pod-Test case no 19: output line  4');
        Test::More::is($lines[ 5], "Supp: Name = iii",                                           'Pod-Test case no 19: output line  5');
        Test::More::is($lines[ 6], "Supp: Name = jjj",                                           'Pod-Test case no 19: output line  6');
        Test::More::is($lines[ 7], "Root: Data = aabb",                                          'Pod-Test case no 19: output line  7');
        Test::More::is($lines[ 8], "Root: Ordr = ccdd",                                          'Pod-Test case no 19: output line  8');
        Test::More::is($lines[ 9], "Root: Ord2 = ccdd",                                          'Pod-Test case no 19: output line  9');
    }

    {
        my $line2 = q{
        <data>
          aa
          <supplier>ggg</supplier>
          <supplier>hhh</supplier>
          <order no="A">
            cc
            <database loc='alpha'>
              <item>
                <customer name="smith" id="652">
                  <street>high street</street>
                  <city>boston</city>
                </customer>
                <customer name="jones" id="184">
                  <street>maple street</street>
                  <city>new york</city>
                </customer>
                <customer name="stewart" id="520">
                  <street>ring road</street>
                  <city>dallas</city>
                </customer>
              </item>
              <item>
                <customer name="smith" id="444">
                  <street>upton way</street>
                  <city>motown</city>
                </customer>
                <customer name="gates" id="959">
                  <street>leave me thhis way</street>
                  <city>cambridge</city>
                </customer>
                <customer name="stewart" id="914">
                  <street>impossible way</street>
                  <city>chicago</city>
                </customer>
              </item>
            </database>
            <database loc='beta'>
              <item>
                <customer name="smith" id="211">
                  <street>place republique</street>
                  <city>paris</city>
                </customer>
                <customer name="smith" id="123">
                  <street>test drive</street>
                  <city>Moscow</city>
                </customer>
                <customer name="stewart" id="999">
                  <street>subway</street>
                  <city>london</city>
                </customer>
              </item>
            </database>
          </order>
          <dummy value="ttt">test</dummy>
          <supplier>iii</supplier>
          <supplier>jjj</supplier>
          bb
        </data>
        };

        my $aref = slurp_xml(\$line2,
          { root => '/data/order/database[@loc="alpha"]/item', branch => [
            'customer[@name="smith"]/street',
            'customer[@name="stewart"]/street',
          ] },
        );

        my @lines;

        for (@{$aref->[0]}) {
            push @lines, sprintf("Test2: smith = %-15s stewart = %s", $_->[0], $_->[1]);
        }

        Test::More::is(scalar(@lines),   2,                                                      'Pod-Test case no 19a: number of output lines');
        Test::More::is($lines[ 0], "Test2: smith = high street     stewart = ring road",         'Pod-Test case no 19a: output line  0');
        Test::More::is($lines[ 1], "Test2: smith = upton way       stewart = impossible way",    'Pod-Test case no 19a: output line  1');
    }

    {
        my $line2 = q{
          <data>
            <database loc="alpha">
              <item>
                <customer name="smith" id="652">
                  <street>high street</street>
                  <city>rio</city>
                </customer>
                <customer name="jones" id="184">
                  <street>maple street</street>
                  <city>new york</city>
                </customer>
                <customer name="gates" id="520">
                  <street>ring road</street>
                  <city>dallas</city>
                </customer>
                <customer name="smith" id="800">
                  <street>which way</street>
                  <city>ny</city>
                </customer>
              </item>
            </database>
            <database loc="beta">
              <item>
                <customer name="smith" id="001">
                  <street>nowhere</street>
                  <city>st malo</city>
                </customer>
                <customer name="jones" id="002">
                  <street>all the way</street>
                  <city>leeds</city>
                </customer>
                <customer name="gates" id="003">
                  <street>bypass</street>
                  <city>rome</city>
                </customer>
              </item>
            </database>
            <database loc="alpha">
              <item>
                <customer name="peter" id="444">
                  <street>upton way</street>
                  <city>motown</city>
                </customer>
                <customer name="gates" id="959">
                  <street>don't leave me this way</street>
                  <city>cambridge</city>
                </customer>
              </item>
            </database>
            <database loc="alpha">
              <item>
                <customer name="smith" id="881">
                  <street>anyway</street>
                  <city>big apple</city>
                </customer>
                <customer name="thatcher" id="504">
                  <street>baker street</street>
                  <city>oxford</city>
                </customer>
              </item>
            </database>
          </data>
        };

        my @lines;

        my $rdr = $XML_Reader_Any->new(\$line2, { mode => 'branches', sepchar => '|' }, {
          root   => '/data/database[@loc="alpha"]',
          branch => [
            'item/customer[@name="smith"]/city',
            'item/customer[@name="gates"]/city',
        ]});

        while ($rdr->iterate) {
            my ($smith, $gates) = $rdr->value;

            $smith = defined($smith) ? "($smith)" : 'undef';
            $gates = defined($gates) ? "($gates)" : 'undef';

            push @lines, sprintf("smith = %-12s, gates = %s", $smith, $gates);
        }

        Test::More::is(scalar(@lines),   3,                                                      'Pod-Test case no 19b: number of output lines');
        Test::More::is($lines[ 0], "smith = (rio|ny)    , gates = (dallas)",                     'Pod-Test case no 19b: output line  0');
        Test::More::is($lines[ 1], "smith = undef       , gates = (cambridge)",                  'Pod-Test case no 19b: output line  1');
        Test::More::is($lines[ 2], "smith = (big apple) , gates = undef",                        'Pod-Test case no 19b: output line  2');
    }

    {
        my $line2 = q{
        <data>
          <supplier>ggg</supplier>
          <supplier>hhh</supplier>
          <order>
            <database>
              <customer name="smith" id="652">
                <street>high street</street>
                <city>boston</city>
              </customer>
              <customer name="jones" id="184">
                <street>maple street</street>
                <city>new york</city>
              </customer>
              <customer name="stewart" id="520">
                <street>ring road</street>
                <city>dallas</city>
              </customer>
            </database>
          </order>
          <dummy value="ttt">test</dummy>
          <supplier>iii</supplier>
          <supplier>jjj</supplier>
        </data>
        };

        my $rdr = $XML_Reader_Any->new(\$line2, {filter => 5},
          { root => '/data/order/database/customer', branch => ['/@name', '/street', '/city'] },
          { root => '/data/supplier',                branch => ['/']                          },
        );

        my @lines;

        while ($rdr->iterate) {
            if ($rdr->rx == 0) {
                for ($rdr->rvalue) {
                    push @lines, sprintf("Cust: Name = %-7s Street = %-12s City = %s", $_->[0], $_->[1], $_->[2]);
                }
            }
            elsif ($rdr->rx == 1) {
                for ($rdr->rvalue) {
                    push @lines, sprintf("Supp: Name = %s", $_->[0]);
                }
            }
        }

        Test::More::is(scalar(@lines),   7,                                                      'Pod-Test case no 20: number of output lines');
        Test::More::is($lines[ 0], "Supp: Name = ggg",                                           'Pod-Test case no 20: output line  0');
        Test::More::is($lines[ 1], "Supp: Name = hhh",                                           'Pod-Test case no 20: output line  1');
        Test::More::is($lines[ 2], "Cust: Name = smith   Street = high street  City = boston",   'Pod-Test case no 20: output line  2');
        Test::More::is($lines[ 3], "Cust: Name = jones   Street = maple street City = new york", 'Pod-Test case no 20: output line  3');
        Test::More::is($lines[ 4], "Cust: Name = stewart Street = ring road    City = dallas",   'Pod-Test case no 20: output line  4');
        Test::More::is($lines[ 5], "Supp: Name = iii",                                           'Pod-Test case no 20: output line  5');
        Test::More::is($lines[ 6], "Supp: Name = jjj",                                           'Pod-Test case no 20: output line  6');
    }

    # Pod-Test case no 21: for XML-Reader ver 0.33 (25 Apr 2010), test for {filter => 5}:
    #   - you can now have duplicate roots (which was not possible before)
    #   - allow branch => '*' which will effectively collect all events and construct a sub-tree in XML format
    #   - allow relative roots, such as 'tag1/tag2' or '//tag1/tag2'
    #     that XML-format has the correct translations
    #       + < into &lt;
    #       + > into &gt;
    #       + & into &amp;
    #       + ' into &apos;
    #       + " into &quot;

    {
        my $line2 = q{
        <data>
          <supplier>ggg</supplier>
          <customer name="o'rob" id="444">
            <street>pod alley</street>
            <city>no city</city>
          </customer>
          <zcustomer name="ggg" id="842">
            <street>uuu</street>
            <city>rrr</city>
          </zcustomer>
          <customerz name="nnn" id="88">
            <street>oo</street>
            <city>yy</city>
          </customerz>
          <section>
            <tcustomer name="troy">
              <street>on</street>
              <city>rr</city>
            </tcustomer>
            <tcustomer id="44">
              <street></street>
              <city> </city>
            </tcustomer>
          </section>
          <section9>
            <tcustomer>
              <d1>f</d1>
              <d2>g</d2>
            </tcustomer>
            <tcustomer z="">
              <d1></d1>
              <d2> </d2>
            </tcustomer>
          </section9>
          <section>
            <tcustomer name="" />
            <tcustomer name="nb" id5="33">
              <street>aw</street>
              <city>ac</city>
            </tcustomer>
            <tcustomer name="john" id5="33">
              <city>abc</city>
            </tcustomer>
            <tcustomer name="bob" id1="22">
              <street>sn</street>
            </tcustomer>
          </section>
          <supplier>hhh</supplier>
          <zzz>
            <customer name='"sue"' id="111">
              <street>baker street</street>
              <city>sidney</city>
            </customer>
          </zzz>
          <order>
            <database>
              <customer name="&lt;smith&gt;" id="652">
                <street>high street</street>
                <city>boston</city>
              </customer>
              <customer name="&amp;jones" id="184">
                <street>maple street</street>
                <city>new york</city>
              </customer>
              <customer name="stewart" id="520">
                <street>  ring   road   </street>
                <city>  "'&amp;&lt;&#65;&gt;'"  </city>
              </customer>
            </database>
          </order>
          <dummy value="ttt">test</dummy>
          <supplier>iii</supplier>
          <supplier>jjj</supplier>
        </data>
        };

        {
            my $rdr = $XML_Reader_Any->new(\$line2, {filter => 5},
              { root => 'customer',       branch => ['/@name', '/street', '/city'] },
              { root => '/data/supplier', branch => ['/']                          },
              { root => '//customer',     branch => '*' },
              { root => '//customer',     branch => '**' },
              { root => '//customer',     branch => '+' },
            );

            my @stm0;
            my @stm1;
            my @stm2;

            my @lin0;
            my @lin1;
            my @lin2;
            my @lin3;
            my @lin4;

            my @lrv0;
            my @lrv2;

            while ($rdr->iterate) {
                if ($rdr->rx == 0) {
                    push @stm0, $rdr->path;
                    for ($rdr->rvalue) {
                         push @lin0, sprintf("Cust: Name = %-7s Street = %-12s City = %s", $_->[0], $_->[1], $_->[2]);
                    }
                    my @rv = $rdr->value;
                    push @lrv0, sprintf("C-rv: Name = %-7s Street = %-12s City = %s", $rv[0], $rv[1], $rv[2]);
                }
                elsif ($rdr->rx == 1) {
                    push @stm1, $rdr->path;
                    for ($rdr->rvalue) {
                        push @lin1, sprintf("Supp: Name = %s", $_->[0]);
                    }
                }
                elsif ($rdr->rx == 2) {
                    push @stm2, $rdr->path;
                    for ($rdr->rvalue) {
                        push @lin2, $_;
                    }
                    push @lrv2, $rdr->value;
                }
                elsif ($rdr->rx == 3) {
                    for ($rdr->rvalue) {
                        push @lin3, $_;
                    }
                }
                elsif ($rdr->rx == 4) {
                    for ($rdr->rvalue) {
                        local $" = "', '";
                        push @lin4, "Pyx: '@$_'";
                    }
                }
            }

            Test::More::is(scalar(@stm0),   5,                          'Pod-Test case no 21-a: number of stems');
            Test::More::is($stm0[ 0], q{/data/customer},                'Pod-Test case no 21-a: stem  0');
            Test::More::is($stm0[ 1], q{/data/zzz/customer},            'Pod-Test case no 21-a: stem  1');
            Test::More::is($stm0[ 2], q{/data/order/database/customer}, 'Pod-Test case no 21-a: stem  2');
            Test::More::is($stm0[ 3], q{/data/order/database/customer}, 'Pod-Test case no 21-a: stem  3');
            Test::More::is($stm0[ 4], q{/data/order/database/customer}, 'Pod-Test case no 21-a: stem  4');

            Test::More::is(scalar(@stm1),   4,           'Pod-Test case no 21-b: number of stems');
            Test::More::is($stm1[ 0], q{/data/supplier}, 'Pod-Test case no 21-b: stem  0');
            Test::More::is($stm1[ 1], q{/data/supplier}, 'Pod-Test case no 21-b: stem  1');
            Test::More::is($stm1[ 2], q{/data/supplier}, 'Pod-Test case no 21-b: stem  2');
            Test::More::is($stm1[ 3], q{/data/supplier}, 'Pod-Test case no 21-b: stem  3');

            Test::More::is(scalar(@stm2),   5,                          'Pod-Test case no 21-c: number of stems');
            Test::More::is($stm2[ 0], q{/data/customer},                'Pod-Test case no 21-c: stem  0');
            Test::More::is($stm2[ 1], q{/data/zzz/customer},            'Pod-Test case no 21-c: stem  1');
            Test::More::is($stm2[ 2], q{/data/order/database/customer}, 'Pod-Test case no 21-c: stem  2');
            Test::More::is($stm2[ 3], q{/data/order/database/customer}, 'Pod-Test case no 21-c: stem  3');
            Test::More::is($stm2[ 4], q{/data/order/database/customer}, 'Pod-Test case no 21-c: stem  4');

            Test::More::is(scalar(@lin0),   5,                                                       'Pod-Test case no 21-d: number of output lines');
            Test::More::is($lin0[ 0], q{Cust: Name = o'rob   Street = pod alley    City = no city},  'Pod-Test case no 21-d: output line  0');
            Test::More::is($lin0[ 1], q{Cust: Name = "sue"   Street = baker street City = sidney},   'Pod-Test case no 21-d: output line  1');
            Test::More::is($lin0[ 2], q{Cust: Name = <smith> Street = high street  City = boston},   'Pod-Test case no 21-d: output line  2');
            Test::More::is($lin0[ 3], q{Cust: Name = &jones  Street = maple street City = new york}, 'Pod-Test case no 21-d: output line  3');
            Test::More::is($lin0[ 4], q{Cust: Name = stewart Street = ring road    City = "'&<A>'"}, 'Pod-Test case no 21-d: output line  4');

            Test::More::is(scalar(@lin1),   4,                                                       'Pod-Test case no 21-e: number of output lines');
            Test::More::is($lin1[ 0], q{Supp: Name = ggg},                                           'Pod-Test case no 21-e: output line  0');
            Test::More::is($lin1[ 1], q{Supp: Name = hhh},                                           'Pod-Test case no 21-e: output line  1');
            Test::More::is($lin1[ 2], q{Supp: Name = iii},                                           'Pod-Test case no 21-e: output line  2');
            Test::More::is($lin1[ 3], q{Supp: Name = jjj},                                           'Pod-Test case no 21-e: output line  3');

            Test::More::is(scalar(@lin2),   5, 'Pod-Test case no 21-f: number of output lines');

            Test::More::is($lin2[ 0],
                q{<customer id='444' name='o&apos;rob'>}.
                  q{<street>pod alley</street>}.
                  q{<city>no city</city>}.
                q{</customer>},
              'Pod-Test case no 21-f: output line  0');

            Test::More::is($lin2[ 1],
                q{<customer id='111' name='"sue"'>}.
                  q{<street>baker street</street>}.
                  q{<city>sidney</city>}.
                q{</customer>},
              'Pod-Test case no 21-f: output line  1');

            Test::More::is($lin2[ 2],
                q{<customer id='652' name='&lt;smith&gt;'>}.
                  q{<street>high street</street>}.
                  q{<city>boston</city>}.
                q{</customer>},
              'Pod-Test case no 21-f: output line  2');

            Test::More::is($lin2[ 3],
                q{<customer id='184' name='&amp;jones'>}.
                  q{<street>maple street</street>}.
                  q{<city>new york</city>}.
                q{</customer>},
              'Pod-Test case no 21-f: output line  3');

            Test::More::is($lin2[ 4],
                q{<customer id='520' name='stewart'>}.
                  q{<street>ring road</street>}.
                  q{<city>"'&amp;&lt;A&gt;'"</city>}.
                q{</customer>},
              'Pod-Test case no 21-f: output line  4');

            Test::More::is(scalar(@lin3),   5, 'Pod-Test case no 21-g: number of output lines');

            Test::More::is($lin3[ 0], undef, 'Pod-Test case no 21-g: output line  0');
            Test::More::is($lin3[ 1], undef, 'Pod-Test case no 21-g: output line  1');
            Test::More::is($lin3[ 2], undef, 'Pod-Test case no 21-g: output line  2');
            Test::More::is($lin3[ 3], undef, 'Pod-Test case no 21-g: output line  3');
            Test::More::is($lin3[ 4], undef, 'Pod-Test case no 21-g: output line  4');


            Test::More::is(scalar(@lrv0),   5,                                                       'Pod-Test case no 21-h: number of output lines');
            Test::More::is($lrv0[ 0], q{C-rv: Name = o'rob   Street = pod alley    City = no city},  'Pod-Test case no 21-h: output line  0');
            Test::More::is($lrv0[ 1], q{C-rv: Name = "sue"   Street = baker street City = sidney},   'Pod-Test case no 21-h: output line  1');
            Test::More::is($lrv0[ 2], q{C-rv: Name = <smith> Street = high street  City = boston},   'Pod-Test case no 21-h: output line  2');
            Test::More::is($lrv0[ 3], q{C-rv: Name = &jones  Street = maple street City = new york}, 'Pod-Test case no 21-h: output line  3');
            Test::More::is($lrv0[ 4], q{C-rv: Name = stewart Street = ring road    City = "'&<A>'"}, 'Pod-Test case no 21-h: output line  4');

            Test::More::is(scalar(@lrv2),   5, 'Pod-Test case no 21-i: number of output lines');

            Test::More::is($lrv2[ 0],
                q{<customer id='444' name='o&apos;rob'>}.
                  q{<street>pod alley</street>}.
                  q{<city>no city</city>}.
                q{</customer>},
              'Pod-Test case no 21-i: output line  0');

            Test::More::is($lrv2[ 1],
                q{<customer id='111' name='"sue"'>}.
                  q{<street>baker street</street>}.
                  q{<city>sidney</city>}.
                q{</customer>},
              'Pod-Test case no 21-i: output line  1');

            Test::More::is($lrv2[ 2],
                q{<customer id='652' name='&lt;smith&gt;'>}.
                  q{<street>high street</street>}.
                  q{<city>boston</city>}.
                q{</customer>},
              'Pod-Test case no 21-i: output line  2');

            Test::More::is($lrv2[ 3],
                q{<customer id='184' name='&amp;jones'>}.
                  q{<street>maple street</street>}.
                  q{<city>new york</city>}.
                q{</customer>},
              'Pod-Test case no 21-i: output line  3');

            Test::More::is($lrv2[ 4],
                q{<customer id='520' name='stewart'>}.
                  q{<street>ring road</street>}.
                  q{<city>"'&amp;&lt;A&gt;'"</city>}.
                q{</customer>},
              'Pod-Test case no 21-i: output line  4');

            Test::More::is(scalar(@lin4),   5, 'Pod-Test case no 21-j: number of output lines');

            Test::More::is($lin4[ 0],
                q{Pyx: }.
                q{'(customer', }.
                q{'Aid 444', }.
                q{'Aname o'rob', }.
                q{'(street', }.
                q{'-pod alley', }.
                q{')street', }.
                q{'(city', }.
                q{'-no city', }.
                q{')city', }.
                q{')customer'},
              'Pod-Test case no 21-j: output line  0');

            Test::More::is($lin4[ 1],
                q{Pyx: }.
                q{'(customer', }.
                q{'Aid 111', }.
                q{'Aname "sue"', }.
                q{'(street', }.
                q{'-baker street', }.
                q{')street', }.
                q{'(city', }.
                q{'-sidney', }.
                q{')city', }.
                q{')customer'},
              'Pod-Test case no 21-j: output line  1');

            Test::More::is($lin4[ 2],
                q{Pyx: }.
                q{'(customer', }.
                q{'Aid 652', }.
                q{'Aname <smith>', }.
                q{'(street', }.
                q{'-high street', }.
                q{')street', }.
                q{'(city', }.
                q{'-boston', }.
                q{')city', }.
                q{')customer'},
              'Pod-Test case no 21-j: output line  2');

            Test::More::is($lin4[ 3],
                q{Pyx: }.
                q{'(customer', }.
                q{'Aid 184', }.
                q{'Aname &jones', }.
                q{'(street', }.
                q{'-maple street', }.
                q{')street', }.
                q{'(city', }.
                q{'-new york', }.
                q{')city', }.
                q{')customer'},
              'Pod-Test case no 21-j: output line  3');

            Test::More::is($lin4[ 4],
                q{Pyx: }.
                q{'(customer', }.
                q{'Aid 520', }.
                q{'Aname stewart', }.
                q{'(street', }.
                q{'-ring road', }.
                q{')street', }.
                q{'(city', }.
                q{'-"'&<A>'"', }.
                q{')city', }.
                q{')customer'},
              'Pod-Test case no 21-j: output line  4');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$line2, {filter => 5, sepchar => ' ! '},
              { root => '/data/section', branch => [
                '/tcustomer/@name',
                '/tcustomer/@id',
                '/tcustomer/street',
                '/tcustomer/city',
              ] },
            );

            my @l_name;
            my @l_id;
            my @l_street;
            my @l_city;

            while ($rdr->iterate) {
                my ($name, $id, $street, $city) = $rdr->value;
                for ($name, $id, $street, $city) { $_ = '*undef*' unless defined $_; }

                push @l_name,   $name;
                push @l_id,     $id;
                push @l_street, $street;
                push @l_city,   $city;
            }

            Test::More::is(scalar(@l_name),   2,                  'Pod-Test case no 21-k: l_name   - number of output lines');
            Test::More::is($l_name[ 0],   q{troy},                'Pod-Test case no 21-k: l_name   - output line  0');
            Test::More::is($l_name[ 1],   q{ ! nb ! john ! bob},  'Pod-Test case no 21-k: l_name   - output line  1');

            Test::More::is(scalar(@l_id),     2,                  'Pod-Test case no 21-k: l_id     - number of output lines');
            Test::More::is($l_id[ 0],     q{44},                  'Pod-Test case no 21-k: l_id     - output line  0');
            Test::More::is($l_id[ 1],     q{*undef*},             'Pod-Test case no 21-k: l_id     - output line  1');

            Test::More::is(scalar(@l_street), 2,                  'Pod-Test case no 21-k: l_street - number of output lines');
            Test::More::is($l_street[ 0], q{on},                  'Pod-Test case no 21-k: l_street - output line  0');
            Test::More::is($l_street[ 1], q{aw ! sn},             'Pod-Test case no 21-k: l_street - output line  1');

            Test::More::is(scalar(@l_city),   2,                  'Pod-Test case no 21-k: l_city   - number of output lines');
            Test::More::is($l_city[ 0],   q{rr},                  'Pod-Test case no 21-k: l_city   - output line  0');
            Test::More::is($l_city[ 1],   q{ac ! abc},            'Pod-Test case no 21-k: l_city   - output line  1');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$line2, {filter => 5}, # ... the same as the previous case, except here is no {sepchar => }
              { root => '/data/section', branch => [
                '/tcustomer/@name',
                '/tcustomer/@id',
                '/tcustomer/street',
                '/tcustomer/city',
              ] },
            );

            my @l_name;
            my @l_id;
            my @l_street;
            my @l_city;

            while ($rdr->iterate) {
                my ($name, $id, $street, $city) = $rdr->value;
                for ($name, $id, $street, $city) { $_ = '*undef*' unless defined $_; }

                push @l_name,   $name;
                push @l_id,     $id;
                push @l_street, $street;
                push @l_city,   $city;
            }

            Test::More::is(scalar(@l_name),   2,               'Pod-Test case no 21-l: l_name   - number of output lines');
            Test::More::is($l_name[ 0],   q{troy},             'Pod-Test case no 21-l: l_name   - output line  0');
            Test::More::is($l_name[ 1],   q{nbjohnbob},        'Pod-Test case no 21-l: l_name   - output line  1');

            Test::More::is(scalar(@l_id),     2,               'Pod-Test case no 21-l: l_id     - number of output lines');
            Test::More::is($l_id[ 0],     q{44},               'Pod-Test case no 21-l: l_id     - output line  0');
            Test::More::is($l_id[ 1],     q{*undef*},          'Pod-Test case no 21-l: l_id     - output line  1');

            Test::More::is(scalar(@l_street), 2,               'Pod-Test case no 21-l: l_street - number of output lines');
            Test::More::is($l_street[ 0], q{on},               'Pod-Test case no 21-l: l_street - output line  0');
            Test::More::is($l_street[ 1], q{awsn},             'Pod-Test case no 21-l: l_street - output line  1');

            Test::More::is(scalar(@l_city),   2,               'Pod-Test case no 21-l: l_city   - number of output lines');
            Test::More::is($l_city[ 0],   q{rr},               'Pod-Test case no 21-l: l_city   - output line  0');
            Test::More::is($l_city[ 1],   q{acabc},            'Pod-Test case no 21-l: l_city   - output line  1');
        }

        {
            my $rdr_strip_0 = $XML_Reader_Any->new(\$line2, {filter => 5, sepchar => '*', strip => 0},
              { root => '/data/section9', branch => [
                '/tcustomer/@y',
                '/tcustomer/@z',
                '/tcustomer/d1',
                '/tcustomer/d2',
              ] },
            );

            my $txt_strip_0 = '';
            while ($rdr_strip_0->iterate) {
                my ($y, $z, $d1, $d2) = $rdr_strip_0->value;
                for ($y, $z, $d1, $d2) { $_ = '?' unless defined $_; }
                $txt_strip_0 .= "[y='$y', z='$z', d1='$d1', d2='$d2']";
            }

            my $rdr_strip_1 = $XML_Reader_Any->new(\$line2, {filter => 5, sepchar => '*', strip => 1},
              { root => '/data/section9', branch => [
                '/tcustomer/@y',
                '/tcustomer/@z',
                '/tcustomer/d1',
                '/tcustomer/d2',
              ] },
            );

            my $txt_strip_1 = '';
            while ($rdr_strip_1->iterate) {
                my ($y, $z, $d1, $d2) = $rdr_strip_1->value;
                for ($y, $z, $d1, $d2) { $_ = '?' unless defined $_; }
                $txt_strip_1 .= "[y='$y', z='$z', d1='$d1', d2='$d2']";
            }

            Test::More::is($txt_strip_0, q{[y='?', z='', d1='f', d2='g}.q{* }.q{']}, 'Pod-Test case no 21-n: txt_strip_0');
            Test::More::is($txt_strip_1, q{[y='?', z='', d1='f', d2='g}.      q{']}, 'Pod-Test case no 21-n: txt_strip_1');
        }
    }

    {
        my $line2 = q{
        <data>
          <p>
            <p>b1</p>
            <p>b2</p>
          </p>
          <p>
            b3
          </p>
        </data>
        };

        my $rdr = $XML_Reader_Any->new(\$line2, {filter => 5},
          { root => 'p', branch => '*' },
        );

        my @lines;

        while ($rdr->iterate) {
            push @lines, $rdr->value;
        }

        Test::More::is(scalar(@lines),   2,                      'Pod-Test case no 22: number of lines');
        Test::More::is($lines[ 0], q{<p><p>b1</p><p>b2</p></p>}, 'Pod-Test case no 22: line  0');
        Test::More::is($lines[ 1], q{<p>b3</p>},                 'Pod-Test case no 22: line  1');
    }
}];

$TestProg{'0030_test_Module.t'} = [29, sub {
    my ($XML_Reader_Any) = @_;

    Test::More::use_ok($XML_Reader_Any);

    {
        $DebCnt::obj = 0;

        my $alpha = $XML_Reader_Any->new(\'<data>abc</data>', {debug => DebCnt->new});
        my $beta  = $XML_Reader_Any->new(\'<data>abc</data>', {debug => DebCnt->new});

        for (1..10) {
            my $rdr = $XML_Reader_Any->new(\'<data>abc</data>', {debug => DebCnt->new});
        }

        Test::More::is($DebCnt::obj, 2, 'XML::Reader does not leak memory');
    }

    Test::More::is(tresult($XML_Reader_Any, {filter =>   0                           }), q{[Err]},                                                    'Case 001a: {filter =>   0                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   1                           }), q{[Err]},                                                    'Case 001b: {filter =>   1                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   2                           }), q{[Ok]<@p1/a><@p2/b><dummy/><sub/data><dummy/>},             'Case 001c: {filter =>   2                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   3                           }), q{[Ok]<dummy/><sub/data><dummy/>},                           'Case 001d: {filter =>   3                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   4                           }), q{[Ok]<dummy/><@p1/a><@p2/b><sub/><sub/data><sub/><dummy/>}, 'Case 001f: {filter =>   4                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   5                           }), q{[Ok]<dummy/<dummy p1='a' p2='b'><sub>data</sub></dummy>>}, 'Case 001e: {filter =>   5                         }');
    Test::More::is(tresult($XML_Reader_Any, {filter => 888                           }), q{[Err]},                                                    'Case 001g: {filter => 888                         }');

    Test::More::is(tresult($XML_Reader_Any, {filter =>   2, mode => 'attr-bef-start*'}), q{[Err]},                                                    'Case 002a: {filter =>   2, mode => attr-bef-start*}');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   3, mode => 'attr-in-hash*'  }), q{[Err]},                                                    'Case 002b: {filter =>   3, mode => attr-in-hash*  }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   4, mode => 'pyx*'           }), q{[Err]},                                                    'Case 002c: {filter =>   4, mode => pyx*           }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   5, mode => 'branches*'      }), q{[Err]},                                                    'Case 002d: {filter =>   5, mode => branches*      }');

    Test::More::is(tresult($XML_Reader_Any, {filter =>   2, mode => 'attr-bef-start' }), q{[Ok]<@p1/a><@p2/b><dummy/><sub/data><dummy/>},             'Case 003a: {filter =>   2, mode => attr-bef-start }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   3, mode => 'attr-in-hash'   }), q{[Ok]<dummy/><sub/data><dummy/>},                           'Case 003b: {filter =>   3, mode => attr-in-hash   }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   4, mode => 'pyx'            }), q{[Ok]<dummy/><@p1/a><@p2/b><sub/><sub/data><sub/><dummy/>}, 'Case 003c: {filter =>   4, mode => pyx            }');
    Test::More::is(tresult($XML_Reader_Any, {filter =>   5, mode => 'branches'       }), q{[Ok]<dummy/<dummy p1='a' p2='b'><sub>data</sub></dummy>>}, 'Case 003d: {filter =>   5, mode => branches       }');

    Test::More::is(tresult($XML_Reader_Any, {               mode => 'attr-bef-start' }), q{[Ok]<@p1/a><@p2/b><dummy/><sub/data><dummy/>},             'Case 004a: {               mode => attr-bef-start }');
    Test::More::is(tresult($XML_Reader_Any, {               mode => 'attr-in-hash'   }), q{[Ok]<dummy/><sub/data><dummy/>},                           'Case 004b: {               mode => attr-in-hash   }');
    Test::More::is(tresult($XML_Reader_Any, {               mode => 'pyx'            }), q{[Ok]<dummy/><@p1/a><@p2/b><sub/><sub/data><sub/><dummy/>}, 'Case 004c: {               mode => pyx            }');
    Test::More::is(tresult($XML_Reader_Any, {               mode => 'branches'       }), q{[Ok]<dummy/<dummy p1='a' p2='b'><sub>data</sub></dummy>>}, 'Case 004d: {               mode => branches       }');

    {
        my $data = q{<?xml version="1.0" encoding="iso-8859-1"?><init>n <?test pi?> t<page node="400">m <!-- remark --> r</page></init>};

        {
            my $rdr = $XML_Reader_Any->new(\$data, {filter => 5, parse_ct => 0, parse_pi => 0},
              {root => '/init', branch => '*'});
            $rdr->iterate;

            Test::More::is($rdr->value, q{<init>n t<page node='400'>m r</page></init>},                         'test-branch-001: {parse_ct => 0, parse_pi => 0}');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$data, {filter => 5, parse_ct => 1, parse_pi => 0},
              {root => '/init', branch => '*'});
            $rdr->iterate;

            Test::More::is($rdr->value, q{<init>n t<page node='400'>m<!-- remark -->r</page></init>},           'test-branch-002: {parse_ct => 1, parse_pi => 0}');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$data, {filter => 5, parse_ct => 0, parse_pi => 1},
              {root => '/init', branch => '*'});
            $rdr->iterate;

            Test::More::is($rdr->value, q{<init>n<?test pi?>t<page node='400'>m r</page></init>},               'test-branch-003: {parse_ct => 0, parse_pi => 1}');
        }

        {
            my $rdr = $XML_Reader_Any->new(\$data, {filter => 5, parse_ct => 1, parse_pi => 1},
              {root => '/init', branch => '*'});
            $rdr->iterate;

            Test::More::is($rdr->value, q{<init>n<?test pi?>t<page node='400'>m<!-- remark -->r</page></init>}, 'test-branch-004: {parse_ct => 1, parse_pi => 1}');
        }
    }

    {
        my $data = q{<?xml version="1.0" encoding="iso-8859-1"?><data/>};
        my $rdr = $XML_Reader_Any->new(\$data, {parse_pi => 1});
        my %d; while ($rdr->iterate) { %d = (%d, %{$rdr->dec_hash}); }
        Test::More::is(join(' ', map {"$_='$d{$_}'"} sort keys %d), q{encoding='iso-8859-1' version='1.0'},                  'test-decl-001: <?xml version="1.0" encoding="iso-8859-1"?>');
    }

    {
        my $data = q{<?xml version="1.0" standalone="yes"?><data/>};
        my $rdr = $XML_Reader_Any->new(\$data, {parse_pi => 1});
        my %d; while ($rdr->iterate) { %d = (%d, %{$rdr->dec_hash}); }
        Test::More::is(join(' ', map {"$_='$d{$_}'"} sort keys %d), q{standalone='yes' version='1.0'},                       'test-decl-002: <?xml version="1.0" standalone="yes"?>');
    }

    {
        my $data = q{<?xml version="1.0" standalone="no"?><data/>};
        my $rdr = $XML_Reader_Any->new(\$data, {parse_pi => 1});
        my %d; while ($rdr->iterate) { %d = (%d, %{$rdr->dec_hash}); }
        Test::More::is(join(' ', map {"$_='$d{$_}'"} sort keys %d), q{standalone='no' version='1.0'},                        'test-decl-003: <?xml version="1.0" standalone="no"?>');
    }

    {
        my $data = q{<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?><data/>};
        my $rdr = $XML_Reader_Any->new(\$data, {parse_pi => 1});
        my %d; while ($rdr->iterate) { %d = (%d, %{$rdr->dec_hash}); }
        Test::More::is(join(' ', map {"$_='$d{$_}'"} sort keys %d), q{encoding='iso-8859-1' standalone='yes' version='1.0'}, 'test-decl-004: <?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>');
    }
}];

{
    package DebCnt;
$DebCnt::VERSION = '0.65';
sub new     { our $obj++; bless {}; }
    sub DESTROY { our $obj--; }
}

sub tresult {
    my ($module, $opt) = @_;

    my $text = q{<dummy p1="a" p2="b"><sub>data</sub></dummy>};

    my $rdr = eval{ $module->new(\$text, $opt, {root => '/dummy', branch => '*'}) };

    my $output = '['.($@ ? 'Err' : 'Ok').']';

    if ($rdr) {
        while ($rdr->iterate) { $output .= '<'.$rdr->tag.'/'.$rdr->value.'>'; }
    }

    $output;
}

1;

__END__

=head1 NAME

XML::Reader::Testcases - Testcontainer for XML::Reader.

Refactor/move the tests from XML::Reader out into this module XML::Reader::Testcases. The
tests will later be called by the new modules XML::Reader::RS and by XML::Reader::PP.

=head1 CONTENT

These are the tests contained in XML::Reader::Testcases

=over

=item 0010_test_Module.t

=item 0020_test_Module.t

=item 0030_test_Module.t

=back

=head1 AUTHOR

Klaus Eichner, August 2012

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
