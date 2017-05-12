use 5.012;
use warnings;

use Test::More tests => 1091;

my $XML_module = 'XML::Parsepp';

use_ok($XML_module);

my @result;
my $err = '';
my $line_more;
my $line_done;

my $retval;

my $XmlParser1 = $XML_module->new or die "Error-0010: Can't create $XML_module -> new";
my $XmlParser2 = $XML_module->new or die "Error-0015: Can't create $XML_module -> new";
my $XmlParser3 = $XML_module->new(dupatt => '|') or die "Error-0018: Can't create $XML_module -> new";

my $test_parser = eval{ $XML_module->new(dupatt => 'é')}; my $emsg = $@ ? $@ : '';
like($emsg, qr{invalid \s dupatt}xms,      'Test-900a: error');

my @Handlers = (
  [  1, Init         => \&handle_Init,         'INIT', occurs =>  108, 'Init         (Expat)'                                          ],
  [  2, Final        => \&handle_Final,        'FINL', occurs =>   54, 'Final        (Expat)'                                          ],
  [  3, Start        => \&handle_Start,        'STRT', occurs =>  115, 'Start        (Expat, Element [, Attr, Val [,...]])'            ],
  [  4, End          => \&handle_End,          'ENDL', occurs =>   80, 'End          (Expat, Element)'                                 ],
  [  5, Char         => \&handle_Char,         'CHAR', occurs =>  153, 'Char         (Expat, String)'                                  ],
  [  6, Proc         => \&handle_Proc,         'PROC', occurs =>    8, 'Proc         (Expat, Target, Data)'                            ],
  [  7, Comment      => \&handle_Comment,      'COMT', occurs =>    7, 'Comment      (Expat, Data)'                                    ],
  [  8, CdataStart   => \&handle_CdataStart,   'CDST', occurs =>    2, 'CdataStart   (Expat)'                                          ],
  [  9, CdataEnd     => \&handle_CdataEnd,     'CDEN', occurs =>    2, 'CdataEnd     (Expat)'                                          ],
  [ 10, Default      => \&handle_Default,      'DEFT', occurs =>   58, 'Default      (Expat, String)'                                  ],
  [ 11, Unparsed     => \&handle_Unparsed,     'UNPS', occurs =>   11, 'Unparsed     (Expat, Entity, Base, Sysid, Pubid, Notation)'    ],
  [ 12, Notation     => \&handle_Notation,     'NOTA', occurs =>    5, 'Notation     (Expat, Notation, Base, Sysid, Pubid)'            ],
  [ 13, ExternEnt    => \&handle_ExternEnt,    'EXEN', occurs =>    3, 'ExternEnt    (Expat, Base, Sysid, Pubid)'                      ],
  [ 14, ExternEntFin => \&handle_ExternEntFin, 'EXEF', occurs =>    3, 'ExternEntFin (Expat)'                                          ],
  [ 15, Entity       => \&handle_Entity,       'ENTT', occurs =>   67, 'Entity       (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)' ],
  [ 16, Element      => \&handle_Element,      'ELEM', occurs =>    5, 'Element      (Expat, Name, Model)'                             ],
  [ 17, Attlist      => \&handle_Attlist,      'ATTL', occurs =>   20, 'Attlist      (Expat, Elname, Attname, Type, Default, Fixed)'   ],
  [ 18, Doctype      => \&handle_Doctype,      'DOCT', occurs =>   45, 'Doctype      (Expat, Name, Sysid, Pubid, Internal)'            ],
  [ 19, DoctypeFin   => \&handle_DoctypeFin,   'DOCF', occurs =>   40, 'DoctypeFin   (Expat)'                                          ],
  [ 20, XMLDecl      => \&handle_XMLDecl,      'DECL', occurs =>   66, 'XMLDecl      (Expat, Version, Encoding, Standalone)'           ],
);

my @HParam1;
my @HParam2;
my @HParam3;
for my $H (@Handlers) {
    push @HParam1, $H->[1], $H->[2];
    push @HParam2, $H->[1], $H->[2] unless $H->[1] eq 'ExternEnt' or $H->[1] eq 'ExternEntFin';
    push @HParam3, $H->[1], $H->[2];
}

my %HInd;
my @HCount;
for my $i (0..$#Handlers) {
    $HInd{$Handlers[$i][3]} = $i;
    $HCount[$i] = 0;
}

$XmlParser1->setHandlers(@HParam1);
$XmlParser2->setHandlers(@HParam2);
$XmlParser3->setHandlers(@HParam3);

# most testcases have been inspired by...
#   http://www.u-picardie.fr/~ferment/xml/xml02.html
#   http://www.comptechdoc.org/independent/web/dtd/dtddekeywords.html
#   http://xmlwriter.net/xml_guide/attlist_declaration.shtml
# *************************************************************************************

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<root> <item ff='pt1' gg="pt2">yyy</item><dummy/>}.
               q{<data>a }.qq{\n}.q{  gggggg<!-- cmt1  > < & --> bc<![CDATA[  x  <!-- cmt2 -->  y  z >  <  &  ]]>d <!-- cmt3 <![CDATA[ zzz ]]> --> ef</data>}.
               q{tt <?ab cde?> uu}.qq{\n\t\t}.
               q{<sléép>abc&gt;&amp;&lt;d [] ef</sléép>}.
               q{</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[ ]',
      'STRT ele=[item], atr=[ff], [pt1], [gg], [pt2]',
      'CHAR txt=[yyy]',
      'ENDL ele=[item]',
      'STRT ele=[dummy], atr=[]',
      'ENDL ele=[dummy]',
      'STRT ele=[data], atr=[]',
      'CHAR txt=[a ]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  gggggg]',
      'COMT cmt=[ cmt1  > < & ]',
      'CHAR txt=[ bc]',
      'CDST',
      'CHAR txt=[  x  <!-- cmt2 -->  y  z >  <  &  ]',
      'CDEN',
      'CHAR txt=[d ]',
      'COMT cmt=[ cmt3 <!&<5b>CDATA&<5b> zzz &<5d>&<5d>> ]',
      'CHAR txt=[ ef]',
      'ENDL ele=[data]',
      'CHAR txt=[tt ]',
      'PROC tgt=[ab], dat=[cde]',
      'CHAR txt=[ uu]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[&<09>&<09>]',
      'STRT ele=[sléép], atr=[]',
      'CHAR txt=[abc]',
      'CHAR txt=[>]',
      'CHAR txt=[&]',
      'CHAR txt=[<]',
      'CHAR txt=[d &<5b>&<5d> ef]',
      'ENDL ele=[sléép]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-001a: No error');
    is(scalar(@result), scalar(@expected), 'Test-001b: Number of results');
    verify('001', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test><long d1="'" d2='"' d3}, q{=}, q{'},
               q{&}, q{a}, q{m}, q{p}, q{;}, q{'}, q{>}, q{aa}, q{bbbb},
               q{cc</long><!-- xx}, q{yyyy}, q{ },
               q{&}, q{l}, q{t}, q{;}, q{z}, q{&amp;}, q{z}, q{-}, q{-}, q{>},
               q{&}, q{g}, q{t}, q{;}, q{<}, q{/}, q{t}, q{e}, q{st>});

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[]',
      'STRT ele=[long], atr=[d1], [\'], [d2], ["], [d3], [&]',
      'CHAR txt=[aa]',
      'CHAR txt=[bbbb]',
      'CHAR txt=[cc]',
      'ENDL ele=[long]',
      'COMT cmt=[ xxyyyy &lt;z&amp;z]',
      'CHAR txt=[>]',
      'ENDL ele=[test]',
      'FINL',
    );

    is($err, '',                           'Test-002a: No error');
    is(scalar(@result), scalar(@expected), 'Test-002b: Number of results');
    verify('002', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<aaaa><test><open>});

    like($err, qr{no \s element \s found}xms, 'Test-003a: error');

    my @expected = (
      'INIT',
      'STRT ele=[aaaa], atr=[]',
      'STRT ele=[test], atr=[]',
      'STRT ele=[open], atr=[]',
    );

    is(scalar(@result), scalar(@expected), 'Test-003b: Number of results');
    verify('003', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<aaaa><test><open>z</open></test></aaaa>uuu});

    like($err, qr{junk \s after \s document \s element}xms, 'Test-005a: error');

    my @expected = (
      'INIT',
      'STRT ele=[aaaa], atr=[]',
      'STRT ele=[test], atr=[]',
      'STRT ele=[open], atr=[]',
      'CHAR txt=[z]',
      'ENDL ele=[open]',
      'ENDL ele=[test]',
      'ENDL ele=[aaaa]',
    );

    is(scalar(@result), scalar(@expected), 'Test-005b: Number of results');
    verify('005', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<aaaa><test><open>z</open></test></aaaa>    }.qq{\n\n});

    my @expected = (
      'INIT',
      'STRT ele=[aaaa], atr=[]',
      'STRT ele=[test], atr=[]',
      'STRT ele=[open], atr=[]',
      'CHAR txt=[z]',
      'ENDL ele=[open]',
      'ENDL ele=[test]',
      'ENDL ele=[aaaa]',
      'DEFT str=[    &<0a>&<0a>]',
      'FINL',
    );
       
    is($err, '',                           'Test-006a: No error');
    is(scalar(@result), scalar(@expected), 'Test-006b: Number of results');
    verify('006', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<aaaa><test><open>z</open></test2></aaaa>});

    like($err, qr{mismatched \s tag}xms, 'Test-007a: error');

    my @expected = (
      'INIT',
      'STRT ele=[aaaa], atr=[]',
      'STRT ele=[test], atr=[]',
      'STRT ele=[open], atr=[]',
      'CHAR txt=[z]',
      'ENDL ele=[open]',
    );

    is(scalar(@result), scalar(@expected), 'Test-007b: Number of results');
    verify('007', \@result, \@expected);
}

{
    my $xmldoc = qq{<aaaa>\n  <test>\n    <open>z</open>\n  </test2>\n</aaaa>};

    my ($prefix, $found, $suffix) = $xmldoc =~ m{\A (.*?) (</test2>) (.*) \z}xms ? ($1, $2, $3) : ('', '', ''); 
    my $pref_1 = $prefix =~ m{\n ([^\n]*) \z}xms ? $1 : '';

    my $exp_lineno  = $prefix =~ tr/\n// + 1;
    my $exp_column  = length($pref_1) + 2;
    my $exp_bytes   = length($prefix) + 2;
    my $exp_program = $0;
    my $exp_proglin = $line_more;

    get_result($XmlParser1,
               $xmldoc);

    like($err, qr{mismatched \s+ tag}xms, 'Test-008a: error');

    my @expected = (
      'INIT',
      'STRT ele=[aaaa], atr=[]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
      'STRT ele=[test], atr=[]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[    ]',
      'STRT ele=[open], atr=[]',
      'CHAR txt=[z]',
      'ENDL ele=[open]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-008b: Number of results');
    verify('008', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dat="abc>" dfp="def&lt;"></test>});

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dat], [abc>], [dfp], [def<]',
      'ENDL ele=[test]',
      'FINL',
    );

    is($err, '',                           'Test-009a: No error');
    is(scalar(@result), scalar(@expected), 'Test-009b: Number of results');
    verify('009', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def&lt"></test>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-010a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-010b: Number of results');
    verify('010', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">abc &zzz; def</test>});

    like($err, qr{undefined \s entity}xms, 'Test-011a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[abc ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-011b: Number of results');
    verify('011', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">abc &amp def</test>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-012a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[abc ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-012b: Number of results');
    verify('012', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">abc &zzz def</test>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-013a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[abc ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-013b: Number of results');
    verify('013', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">abc &</test>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-014a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[abc ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-014b: Number of results');
    verify('014', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">abc &zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz; def</test>});

    like($err, qr{undefined \s entity}xms, 'Test-015a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[abc ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-015b: Number of results');
    verify('015', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<test dfp="def">ab}, q{c}, q{ }, q{&}, q{a}, q{m}, q{p}, q{z}, q{z}, q{zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz; def</test>});

    like($err, qr{undefined \s entity}xms, 'Test-016a: error');

    my @expected = (
      'INIT',
      'STRT ele=[test], atr=[dfp], [def]',
      'CHAR txt=[ab]',
      'CHAR txt=[c]',
      'CHAR txt=[ ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-016b: Number of results');
    verify('016', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><test d1="aa" d2="bb"/></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'STRT ele=[test], atr=[d1], [aa], [d2], [bb]',
      'ENDL ele=[test]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-017a: No error');
    is(scalar(@result), scalar(@expected), 'Test-017b: Number of results');
    verify('017', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><?abc def?></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'PROC tgt=[abc], dat=[def]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-018a: No error');
    is(scalar(@result), scalar(@expected), 'Test-018b: Number of results');
    verify('018', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><?  abc    def   ghi  ?></zzz>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-019a: error');

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
    );

    is(scalar(@result), scalar(@expected), 'Test-019b: Number of results');
    verify('019', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><?abc    def   ghi  ?></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'PROC tgt=[abc], dat=[def   ghi  ]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-020a: No error');
    is(scalar(@result), scalar(@expected), 'Test-020b: Number of results');
    verify('020', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><?abc?></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'PROC tgt=[abc], dat=[]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-021a: No error');
    is(scalar(@result), scalar(@expected), 'Test-021b: Number of results');
    verify('021', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><test     d1  =   "aa" d2    =    "bb"  /></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'STRT ele=[test], atr=[d1], [aa], [d2], [bb]',
      'ENDL ele=[test]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-022a: No error');
    is(scalar(@result), scalar(@expected), 'Test-022b: Number of results');
    verify('022', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz>< test/></zzz>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-023a: error');

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
    );

    is(scalar(@result), scalar(@expected), 'Test-023b: Number of results');
    verify('023', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><test/ ></zzz>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-024a: error');

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
    );

    is(scalar(@result), scalar(@expected), 'Test-024b: Number of results');
    verify('024', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><test /></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'STRT ele=[test], atr=[]',
      'ENDL ele=[test]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-025a: No error');
    is(scalar(@result), scalar(@expected), 'Test-025b: Number of results');
    verify('025', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz><!-- a}, q{b}, q{c --></zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'COMT cmt=[ abc ]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-026a: No error');
    is(scalar(@result), scalar(@expected), 'Test-026b: Number of results');
    verify('026', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz>a}, q{b}, q{c</zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'CHAR txt=[a]',
      'CHAR txt=[b]',
      'CHAR txt=[c]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-027a: No error');
    is(scalar(@result), scalar(@expected), 'Test-027b: Number of results');
    verify('027', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz>a}, q{bx<![CDATA[}, q{y}, q{z123]]>45}, q{c</zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'CHAR txt=[a]',
      'CHAR txt=[bx]',
      'CDST',
      'CHAR txt=[y]',
      'CHAR txt=[z123]',
      'CDEN',
      'CHAR txt=[45]',
      'CHAR txt=[c]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-028a: No error');
    is(scalar(@result), scalar(@expected), 'Test-028b: Number of results');
    verify('028', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone='yes'?><data/>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[1]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-029a: No error');
    is(scalar(@result), scalar(@expected), 'Test-029b: Number of results');
    verify('029', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone='maybe'?><data/>});

    like($err, qr{XML \s declaration \s not \s well-formed}xms, 'Test-030a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-030b: Number of results');
    verify('030', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone='Yes'?><data/>});

    like($err, qr{XML \s declaration \s not \s well-formed}xms, 'Test-031a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-031b: Number of results');
    verify('031', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" Standalone='yes'?><data/>}); # Captital S in "Standalone"

    like($err, qr{XML \s declaration \s not \s well-formed}xms, 'Test-032a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-032b: Number of results');
    verify('032', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.1" encoding="ISO-8859-1" standalone='yes'?><data/>}); # Version is not "1.0"

    my @expected = (
      'INIT',
      'DECL ver=[1.1], enc=[ISO-8859-1], stand=[1]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-033a: No error');
    is(scalar(@result), scalar(@expected), 'Test-033b: Number of results');
    verify('033', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone='no'?><data/>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-034a: No error');
    is(scalar(@result), scalar(@expected), 'Test-034b: Number of results');
    verify('034', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="3.9" encoding="ISO-8859-1" standalone='yes'?><data/>}); # Version is not "1.0"

    my @expected = (
      'INIT',
      'DECL ver=[3.9], enc=[ISO-8859-1], stand=[1]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-035a: No error');
    is(scalar(@result), scalar(@expected), 'Test-035b: Number of results');
    verify('035', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="aaa" encoding="ISO-8859-1" standalone='yes'?><data/>}); # Version is not "1.0"

    my @expected = (
      'INIT',
      'DECL ver=[aaa], enc=[ISO-8859-1], stand=[1]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-036a: No error');
    is(scalar(@result), scalar(@expected), 'Test-036b: Number of results');
    verify('036', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" dummy encoding="ISO-8859-1" standalone='yes'?><data/>}); # add a "dummy" to the XML declaration

    like($err, qr{XML \s declaration \s not \s well-formed}xms, 'Test-037a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-037b: Number of results');
    verify('037', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>tttt<data/>}); # données "tttt" avant <data>

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-040a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-040b: Number of results');
    verify('040', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{uuuu<?xml version="1.0" encoding="ISO-8859-1"?><data/>}); # données "uuuu" avant <?xml>

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-041a: error');

    my @expected = (
      'INIT',
    );

    is(scalar(@result), scalar(@expected), 'Test-041b: Number of results');
    verify('041', \@result, \@expected);
}

{
    get_result($XmlParser1,
               qq{\n\n}.q{<?xml version="1.0" encoding="ISO-8859-1"?><data/>}); # données "\n\n" avant <?xml>

    like($err, qr{XML \s or \s text \s declaration \s not \s at \s start \s of \s entity}xms, 'Test-042a: error');

    my @expected = (
      'INIT',
      'DEFT str=[&<0a>&<0a>]',
    );

    is(scalar(@result), scalar(@expected), 'Test-042b: Number of results');
    verify('042', \@result, \@expected);

}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n\n}.q{<data/>}); # données "\n\n" avant <data>

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>&<0a>]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-043a: No error');
    is(scalar(@result), scalar(@expected), 'Test-043b: Number of results');
    verify('043', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.q{<data/>}.qq{\n\n}); # données "\n\n" apres <data>

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
      'DEFT str=[&<0a>&<0a>]',
      'FINL',
    );

    is($err, '',                           'Test-044a: No error');
    is(scalar(@result), scalar(@expected), 'Test-044b: Number of results');
    verify('044', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.q{<data/>}.q{abcdefg}); # données "abcdefg" apres <data>

    like($err, qr{junk \s after \s document \s element}xms, 'Test-045a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'STRT ele=[data], atr=[]',
      'ENDL ele=[data]',
    );

    is(scalar(@result), scalar(@expected), 'Test-045b: Number of results');
    verify('045', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?><data>abc></data>}); # un charactère > dans le texte (après "abc")

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'STRT ele=[data], atr=[]',
      'CHAR txt=[abc>]',
      'ENDL ele=[data]',
      'FINL',
    );

    is($err, '',                           'Test-046a: No error');
    is(scalar(@result), scalar(@expected), 'Test-046b: Number of results');
    verify('046', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?><data name="xyz>"></data>}); # un charactère > dans le paramètre (après "xyz")

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'STRT ele=[data], atr=[name], [xyz>]',
      'ENDL ele=[data]',
      'FINL',
     );

    is($err, '',                           'Test-047a: No error');
    is(scalar(@result), scalar(@expected), 'Test-047b: Number of results');
    verify('047', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?><data name="x&yz>"></data>}); # le charactère & dans le paramètre (entre "x" et "y")

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-048a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-048b: Number of results');
    verify('048', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?><data name="&lt;&amp;&gt;"></data>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'STRT ele=[data], atr=[name], [<&>]',
      'ENDL ele=[data]',
      'FINL',
     );

    is($err, '',                           'Test-049a: No error');
    is(scalar(@result), scalar(@expected), 'Test-049b: Number of results');
    verify('049', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE racine SYSTEM "URI-de-la-dtd">}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[racine], sys=[URI-de-la-dtd], pub=[*undef*], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );
 
    is($err, '',                           'Test-050a: No error');
    is(scalar(@result), scalar(@expected), 'Test-050b: Number of results');
    verify('050', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG December 1999//EN" "http://www.w3.org/Graphics/SVG/SVG-19991203.dtd">}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[svg], sys=[http://www.w3.org/Graphics/SVG/SVG-19991203.dtd], pub=[-//W3C//DTD SVG December 1999//EN], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-051a: No error');
    is(scalar(@result), scalar(@expected), 'Test-051b: Number of results');
    verify('051', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.0//EN' 'http://www.w3.org/TR/REC-html40/strict.dtd'>}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[html], sys=[http://www.w3.org/TR/REC-html40/strict.dtd], pub=[-//W3C//DTD HTML 4.0//EN], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-052a: No error');
    is(scalar(@result), scalar(@expected), 'Test-052b: Number of results');
    verify('052', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE racine SYSTEM "URI-de-la-dtd">}.qq{\n}.
               q{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG December 1999//EN" "http://www.w3.org/Graphics/SVG/SVG-19991203.dtd">}.qq{\n}.
               q{<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.0//EN' 'http://www.w3.org/TR/REC-html40/strict.dtd'>}.qq{\n}.
               q{<root></root>});

    like($err, qr{syntax \s error}xms, 'Test-053a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[racine], sys=[URI-de-la-dtd], pub=[*undef*], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
    );

    is(scalar(@result), scalar(@expected), 'Test-053b: Number of results');
    verify('053', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!-- fichier dialogue4.xml -->}.qq{\n}.
               q{<!DOCTYPE dialogue}.qq{\n}.
               q{[}.qq{\n}.
               q{ <!ELEMENT dialogue (situation?, replique+)>}.qq{\n}.
               q{ <!ELEMENT situation (#PCDATA) >}.qq{\n}.
               q{ <!ELEMENT replique (   personnage   ,     texte     )     >}.qq{\n}.
               q{ <!ELEMENT personnage (  #PCDATA ) >}.qq{\n}.
               q{ <!ATTLIST personnage attitude CDATA #REQUIRED geste CDATA #IMPLIED >}.qq{\n}. 
               q{ <!NOTATION flash SYSTEM "/usr/bin/flash.exe">}.qq{\n}.
               q{ <!ENTITY animation SYSTEM "../anim.fla" NDATA flash>}.qq{\n}.
               q{ <!ELEMENT texte (#PCDATA) >}.qq{\n}.
               q{ <!ATTLIST texte ton (normal | fort | faible) "normal">}.qq{\n}.
               q{]>}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'COMT cmt=[ fichier dialogue4.xml ]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'DEFT str=[&<0a> ]',
      'ELEM nam=[dialogue], mod=[(situation?,replique+)]',
      'DEFT str=[&<0a> ]',
      'ELEM nam=[situation], mod=[(#PCDATA)]',
      'DEFT str=[&<0a> ]',
      'ELEM nam=[replique], mod=[(personnage,texte)]',
      'DEFT str=[&<0a> ]',
      'ELEM nam=[personnage], mod=[(#PCDATA)]',
      'DEFT str=[&<0a> ]',
      'ATTL eln=[personnage], atn=[attitude], typ=[CDATA], def=[#REQUIRED], fix=[*undef*]',
      'ATTL eln=[personnage], atn=[geste], typ=[CDATA], def=[#IMPLIED], fix=[*undef*]',
      'DEFT str=[&<0a> ]',
      'NOTA not=[flash], base=[*undef*], sys=[/usr/bin/flash.exe], pub=[*undef*]',
      'DEFT str=[&<0a> ]',
      'UNPS ent=[animation], base=[*undef*], sys=[../anim.fla], pub=[*undef*], not=[flash]',
      'DEFT str=[&<0a> ]',
      'ELEM nam=[texte], mod=[(#PCDATA)]',
      'DEFT str=[&<0a> ]',
      'ATTL eln=[texte], atn=[ton], typ=[(normal|fort|faible)], def=[\'normal\'], fix=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-054a: No error');
    is(scalar(@result), scalar(@expected), 'Test-054b: Number of results');
    verify('054', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!-- fichier dialogue5.xml -->}.qq{\n}.
               q{<!DOCTYPE dialogue SYSTEM "di  a2.dtd" [}.qq{\n}.
               q{ <!ENTITY prl "madame pernelle">}.qq{\n}.
               q{ <!ENTITY elm "elmire">}.qq{\n}.
               q{ <!ENTITY dialogue_a SYSTEM "dialogue5a.xml">}.qq{\n}.
               q{ <!ENTITY dialogue_b SYSTEM "dialogue5b.xml">}.qq{\n}.
               q{]>}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'COMT cmt=[ fichier dialogue5.xml ]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[dialogue], sys=[di  a2.dtd], pub=[*undef*], int=[1]',
      'DEFT str=[&<0a> ]',
      'ENTT nam=[prl], val=[madame pernelle], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[&<0a> ]',
      'ENTT nam=[elm], val=[elmire], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[&<0a> ]',
      'ENTT nam=[dialogue_a], val=[*undef*], sys=[dialogue5a.xml], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[&<0a> ]',
      'ENTT nam=[dialogue_b], val=[*undef*], sys=[dialogue5b.xml], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-055a: No error');
    is(scalar(@result), scalar(@expected), 'Test-055b: Number of results');
    verify('055', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone='yes'?>}.qq{\n}.
               q{<!DOCTYPE racine SYSTEM "URI-de-la-dtd">}.qq{\n}.
               q{<root>}.
               q{  Text}.qq{\n}.
               q{  <item at1='jk' at2="uu" />}.qq{\n}.
               q{  <break test='j}.qq{\n\n\n}.q{k' />}.qq{\n}.
               q{  <?abc   def ghi   jkl ?>}.qq{\n}.
               q{</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[1]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[racine], sys=[URI-de-la-dtd], pub=[*undef*], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[  Text]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
      'STRT ele=[item], atr=[at1], [jk], [at2], [uu]',
      'ENDL ele=[item]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
      'STRT ele=[break], atr=[test], [j   k]',
      'ENDL ele=[break]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
      'PROC tgt=[abc], dat=[def ghi   jkl ]',
      'CHAR txt=[&<0a>]',
      'ENDL ele=[root]',
      'FINL',
    );
 
    is($err, '',                           'Test-056a: No error');
    is(scalar(@result), scalar(@expected), 'Test-056b: Number of results');
    verify('056', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<root>}.
               q{  <? abc def?>}.qq{\n}.
               q{</root>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-057a: error');

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[  ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-057b: Number of results');
    verify('057', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<root>}.
               q{  <?abc?>}.qq{\n}.
               q{  <?def  ?>}.qq{\n}.
               q{</root>});

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[  ]',
      'PROC tgt=[abc], dat=[]',
      'CHAR txt=[&<0a>]',
      'CHAR txt=[  ]',
      'PROC tgt=[def], dat=[]',
      'CHAR txt=[&<0a>]',
      'ENDL ele=[root]',
      'FINL',
    );
 
    is($err, '',                           'Test-058a: No error');
    is(scalar(@result), scalar(@expected), 'Test-058b: Number of results');
    verify('058', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation1 SYSTEM "../an  im.fla"    NDATA flash>}.
               q{<!ENTITY animation2 SYSTEM "../an  im.fla">}.
               q{<!ENTITY animation2 SYSTEM "dummy">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash]',
      'ENTT nam=[animation2], val=[*undef*], sys=[../an  im.fla], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[animation2]',
      'DEFT str=["dummy"]',
      'DEFT str=[>]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-059a: No error');
    is(scalar(@result), scalar(@expected), 'Test-059b: Number of results');
    verify('059', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!DOCTYPE test SYSTEM "URI-de-la-dtd">}.
               q{]>}.
               q{<root></root>});

    like($err, qr{syntax \s error}xms, 'Test-060a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
    );

    is(scalar(@result), scalar(@expected), 'Test-060b: Number of results');
    verify('060', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!doctype test SYSTEM "URI-de-la-dtd">}.
               q{<root></root>});

    like($err, qr{syntax \s error}xms, 'Test-061a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-061b: Number of results');
    verify('061', \@result, \@expected);

}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE test system "URI-de-la-dtd">}.
               q{<root></root>});

    like($err, qr{syntax \s error}xms, 'Test-062a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-062b: Number of results');
    verify('062', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE test SYSTEM "URI-de-la-dtd">}.
               q{zzz}.
               q{<root></root>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-063a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[test], sys=[URI-de-la-dtd], pub=[*undef*], int=[]',
      'DOCF',
    );

    is(scalar(@result), scalar(@expected), 'Test-063b: Number of results');
    verify('063', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation2 SYSTEM "dummy">}.
               q{aaa}.
               q{]>}.
               q{<root></root>});

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-064a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[animation2], val=[*undef*], sys=[dummy], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-064b: Number of results');
    verify('064', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   nom1 "chaine1">}.
               q{<!ENTITY   nom2 SYSTEM "uri1">}.
               q{<!ENTITY % nom3 "chaine3">}.
               q{<!ENTITY % nom4 SYSTEM "uri3">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[chaine1], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[uri1], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[chaine3], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'ENTT nam=[nom4], val=[*undef*], sys=[uri3], pub=[*undef*], nda=[*undef*], isp=[1]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-065a: No error');
    is(scalar(@result), scalar(@expected), 'Test-065b: Number of results');
    verify('065', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!ENTITY nom1 "chaine1">}.
               q{<root></root>});

    like($err, qr{syntax \s error}xms, 'Test-066a: error');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    is(scalar(@result), scalar(@expected), 'Test-066b: Number of results');
    verify('066', \@result, \@expected);
}

{
    $retval = 'abc';

    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY nom SYSTEM "uri.txt">}.
               q{]>}.
               q{<root>hij&nom;klm</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom], val=[*undef*], sys=[uri.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hij]',
      'EXEN base=[*undef*], sys=[uri.txt], pub=[*undef*]',
      'CHAR txt=[abc]',
      'EXEF',
      'CHAR txt=[klm]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-067a: No error');
    is(scalar(@result), scalar(@expected), 'Test-067b: Number of results');
    verify('067', \@result, \@expected);
}

{
    crfile('fi  le1.txt', 'opera456');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY ent1 SYSTEM "fi  le1.txt">}.
               q{]>}.
               q{<root>z&ent1;y</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[ent1], val=[*undef*], sys=[fi  le1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[z]',
      'CHAR txt=[opera456]',
      'CHAR txt=[y]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-068a: No error');
    is(scalar(@result), scalar(@expected), 'Test-068b: Number of results');
    verify('068', \@result, \@expected);
}

{
    dlfile('file2.txt');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY ent2 SYSTEM "file2.txt">}.
               q{]>}.
               q{<root>z&ent2;y</root>});

# 404 File `C:\Users\Klaus\Documents\Work\Wk 0037 (Test XML Parser)\file2.txt' does not exist file:///C:/Users/Klaus/Documents/Work/Wk%200037%20(Test%20XML%20Parser)/file2.txt
# Handler couldn't resolve external entity at line 1, column 100, byte 100
# error in processing external entity reference at line 1, column 100, byte 100 at t/Test0030.t line 1203
# '

    like($err, qr{Handler \s couldn't \s resolve \s external \s entity}xms,    'Test-069a: error1');
    like($err, qr{404 \s File \s `[^']+file2.txt' \s does \s not \s exist}xms, 'Test-069a: error2');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[ent2], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[z]',
    );

    is(scalar(@result), scalar(@expected), 'Test-069b: Number of results');
    verify('069', \@result, \@expected);
}

{
    crfile('file1.txt', 'test &amp; hello &#33; bonjour');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY dat7 SYSTEM "file1.txt">}.
               q{]>}.
               q{<root>z&dat7;y</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[dat7], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[z]',
      'CHAR txt=[test ]',
      'CHAR txt=[&]',
      'CHAR txt=[ hello ]',
      'CHAR txt=[!]',
      'CHAR txt=[ bonjour]',
      'CHAR txt=[y]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-070a: No error');
    is(scalar(@result), scalar(@expected), 'Test-070b: Number of results');
    verify('070', \@result, \@expected);
}

{
    crfile('file1.txt', 'zz &fil2; yy');
    crfile('file2.txt', 'aa &amp; hello &#33; bb');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY fil1 SYSTEM "file1.txt">}.
               q{<!ENTITY fil2 SYSTEM "file2.txt">}.
               q{]>}.
               q{<root>qq &fil1; rr</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[fil1], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[fil2], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[qq ]',
      'CHAR txt=[zz ]',
      'CHAR txt=[aa ]',
      'CHAR txt=[&]',
      'CHAR txt=[ hello ]',
      'CHAR txt=[!]',
      'CHAR txt=[ bb]',
      'CHAR txt=[ yy]',
      'CHAR txt=[ rr]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-071a: No error');
    is(scalar(@result), scalar(@expected), 'Test-071b: Number of results');
    verify('071', \@result, \@expected);
}

{
    crfile('file1.txt', 'zz &fil2; yy'); # Mutually recursive calls &fil1; --> &fil2; --> &fil1;
    crfile('file2.txt', 'aa &fil1; bb');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY fil1 SYSTEM "file1.txt">}.
               q{<!ENTITY fil2 SYSTEM "file2.txt">}.
               q{]>}.
               q{<root>qq &fil1; rr</root>});

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,      'Test-072a: error1');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[fil1], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[fil2], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[qq ]',
      'CHAR txt=[zz ]',
      'CHAR txt=[aa ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-072b: Number of results');
    verify('072', \@result, \@expected);
}

{
    crfile('file1.txt', 'c <xx>abba</xx> c tx &nom3; dd');
    crfile('file2.txt', 'gg');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY nom1                         "aa &nom2; tt &nom4; bb">}.
               q{<!ENTITY nom2 SYSTEM "file1.txt">}. # "c <xx>abba</xx> c tx &nom3; dd"
               q{<!ENTITY nom3                         "dd <yy>&nom4;</yy> ee">}.
               q{<!ENTITY nom4 SYSTEM "file2.txt">}. # gg
               q{]>}.
               q{<root>hh &nom1; ii</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[aa &nom2; tt &nom4; bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[dd <yy>&nom4;</yy> ee], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hh ]',
      'CHAR txt=[aa ]',
      'CHAR txt=[c ]',
      'STRT ele=[xx], atr=[]',
      'CHAR txt=[abba]',
      'ENDL ele=[xx]',
      'CHAR txt=[ c tx ]',
      'CHAR txt=[dd ]',
      'STRT ele=[yy], atr=[]',
      'CHAR txt=[gg]',
      'ENDL ele=[yy]',
      'CHAR txt=[ ee]',
      'CHAR txt=[ dd]',
      'CHAR txt=[ tt ]',
      'CHAR txt=[gg]',
      'CHAR txt=[ bb]',
      'CHAR txt=[ ii]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-073a: No error');
    is(scalar(@result), scalar(@expected), 'Test-073b: Number of results');
    verify('073', \@result, \@expected);
}

{
    crfile('file1.txt', 'c <xx>abba</xx> c tx <ab> &nom3; dd');
    crfile('file2.txt', 'gg');

    # The <ab> tag opens in &nom2; and closes in &nom3;

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   nom1                         "aa &nom2; tt &nom4; bb">}.
               q{<!ENTITY   nom2 SYSTEM "file1.txt">}. # "c <xx>abba</xx> c tx <ab> &nom3; dd"
               q{<!ENTITY   nom3                         "dd </ab> <yy>&nom4;</yy> ee">}.
               q{<!ENTITY   nom4 SYSTEM "file2.txt">}. # "gg"
               q{]>}.
               q{<root>hh &nom1; ii</root>});

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,      'Test-074a: error1');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[aa &nom2; tt &nom4; bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[dd </ab> <yy>&nom4;</yy> ee], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hh ]',
      'CHAR txt=[aa ]',
      'CHAR txt=[c ]',
      'STRT ele=[xx], atr=[]',
      'CHAR txt=[abba]',
      'ENDL ele=[xx]',
      'CHAR txt=[ c tx ]',
      'STRT ele=[ab], atr=[]',
      'CHAR txt=[ ]',
      'CHAR txt=[dd ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-074b: Number of results');
    verify('074', \@result, \@expected);
}

{
    crfile('file1.txt', 'c <xx>abba</xx> c tx  <ab&nom3;</ab> dd');
    crfile('file2.txt', 'gg');

    # The <ab in &nom2; and > in &nom3;

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   nom1                         "aa &nom2; tt &nom4; bb">}.
               q{<!ENTITY   nom2 SYSTEM "file1.txt">}. # "c <xx>abba</xx> c tx  <ab&nom3;</ab> dd"
               q{<!ENTITY   nom3                         ">dd <yy>&nom4;</yy> ee">}.
               q{<!ENTITY   nom4 SYSTEM "file2.txt">}. # gg
               q{]>}.
               q{<root>hh &nom1; ii</root>});

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,      'Test-075a: error1');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[aa &nom2; tt &nom4; bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[>dd <yy>&nom4;</yy> ee], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hh ]',
      'CHAR txt=[aa ]',
      'CHAR txt=[c ]',
      'STRT ele=[xx], atr=[]',
      'CHAR txt=[abba]',
      'ENDL ele=[xx]',
      'CHAR txt=[ c tx  ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-075b: Number of results');
    verify('075', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE racine "ZZZ-de-la-dtd">}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
    );
 
    like($err, qr{syntax \s error}xms,     'Test-076a: error');
    is(scalar(@result), scalar(@expected), 'Test-076b: Number of results');
    verify('076', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE racine>}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[racine], sys=[*undef*], pub=[*undef*], int=[]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );
 
    is($err, '',                           'Test-077a: No error');
    is(scalar(@result), scalar(@expected), 'Test-077b: Number of results');
    verify('077', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG December 1999//EN" "http://www.w3.org/Graphics/SVG/SVG-19991203.dtd" [}.
               q{<!ENTITY abc1 "aa bb">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[svg], sys=[http://www.w3.org/Graphics/SVG/SVG-19991203.dtd], pub=[-//W3C//DTD SVG December 1999//EN], int=[1]',
      'ENTT nam=[abc1], val=[aa bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );
 
    is($err, '',                           'Test-078a: No error');
    is(scalar(@result), scalar(@expected), 'Test-078b: Number of results');
    verify('078', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n}.
               q{<!DOCTYPE racine "tttt">}.qq{\n}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
    );
 
    like($err, qr{syntax \s error}xms,     'Test-079a: error');
    is(scalar(@result), scalar(@expected), 'Test-079b: Number of results');
    verify('079', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!NOTATION flash1 SYSTEM "/usr/bin/flash.exe">}.
               q{<!ENTITY animation1 SYSTEM "../anim1.fla" NDATA flash1>}.
               q{<!ENTITY animation2 SYSTEM "../anim2.fla" NDATA flash2>}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'NOTA not=[flash1], base=[*undef*], sys=[/usr/bin/flash.exe], pub=[*undef*]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../anim1.fla], pub=[*undef*], not=[flash1]',
      'UNPS ent=[animation2], base=[*undef*], sys=[../anim2.fla], pub=[*undef*], not=[flash2]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-080a: No error');
    is(scalar(@result), scalar(@expected), 'Test-080b: Number of results');
    verify('080', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY % coreattrs }.
               q{"id ID #IMPLIED -- document-wide unique id -- }.
               q{class CDATA #IMPLIED -- space-separated list of classes -- }.
               q{style StyleSheet; #IMPLIED -- associated style info -- }.
               q{title Text; #IMPLIED -- advisory title --">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[coreattrs], val=['.
           'id ID #IMPLIED'.             ' -- document-wide unique id -- '.
           'class CDATA #IMPLIED'.       ' -- space-separated list of classes -- '.
           'style StyleSheet; #IMPLIED'. ' -- associated style info -- '.
           'title Text; #IMPLIED'.       ' -- advisory title --'.
           '], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-081a: No error');
    is(scalar(@result), scalar(@expected), 'Test-081b: Number of results');
    verify('081', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   attr1 "id ID #IMPLIED -- id -- ">}.
               q{<!ENTITY % attr2 "id ID #IMPLIED -- id -- ">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[attr1], val=[id ID #IMPLIED -- id -- ], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[attr2], val=[id ID #IMPLIED -- id -- ], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-082a: No error');
    is(scalar(@result), scalar(@expected), 'Test-082b: Number of results');
    verify('082', \@result, \@expected);
}

{
    crfile('file 3.txt', 'drop <ze>abba</ze> dump &nom3; uu');
    crfile('file 4.txt', 'dummy &lt;&gt;');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   nom1                          "test &nom2; data &nom4; end">}.
               q{<!ENTITY   nom2 SYSTEM "file 3.txt">}. # "drop <ze>abba</ze> dump &nom3; uu"
               q{<!ENTITY   nom3                          "give <more>&nom4;</more> text">}.
               q{<!ENTITY   nom4 SYSTEM "file 4.txt">}. # "dummy &lt;&gt;"
               q{<!ENTITY % nom5                          "test5">}.
               q{<!ENTITY % nom6 SYSTEM "file 6.txt">}.
               q{]>}.
               q{<root>hh &nom1; ii</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[test &nom2; data &nom4; end], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file 3.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[give <more>&nom4;</more> text], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file 4.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom5], val=[test5], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'ENTT nam=[nom6], val=[*undef*], sys=[file 6.txt], pub=[*undef*], nda=[*undef*], isp=[1]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hh ]',
      'CHAR txt=[test ]',
      'CHAR txt=[drop ]',
      'STRT ele=[ze], atr=[]',
      'CHAR txt=[abba]',
      'ENDL ele=[ze]',
      'CHAR txt=[ dump ]',
      'CHAR txt=[give ]',
      'STRT ele=[more], atr=[]',
      'CHAR txt=[dummy ]',
      'CHAR txt=[<]',
      'CHAR txt=[>]',
      'ENDL ele=[more]',
      'CHAR txt=[ text]',
      'CHAR txt=[ uu]',
      'CHAR txt=[ data ]',
      'CHAR txt=[dummy ]',
      'CHAR txt=[<]',
      'CHAR txt=[>]',
      'CHAR txt=[ end]',
      'CHAR txt=[ ii]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-083a: No error');
    is(scalar(@result), scalar(@expected), 'Test-083b: Number of results');
    verify('083', \@result, \@expected);
}

{
    crfile('file 3.txt', 'drop <ze>abba</ze> dump &nom3; uu');
    crfile('file 4.txt', 'dummy &lt;&nom5;&gt;');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   nom1                          "test &nom2; data &nom4; end">}.
               q{<!ENTITY   nom2 SYSTEM "file 3.txt">}. # "drop <ze>abba</ze> dump &nom3; uu"
               q{<!ENTITY   nom3                          "give <more>&nom4;</more> text">}.
               q{<!ENTITY   nom4 SYSTEM "file 4.txt">}. # "dummy &lt;&nom5;&gt;"
               q{<!ENTITY % nom5                          "test5">}.
               q{<!ENTITY % nom6 SYSTEM "file 6.txt">}.
               q{]>}.
               q{<root>hh &nom1; ii</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[test &nom2; data &nom4; end], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file 3.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[give <more>&nom4;</more> text], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file 4.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom5], val=[test5], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'ENTT nam=[nom6], val=[*undef*], sys=[file 6.txt], pub=[*undef*], nda=[*undef*], isp=[1]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hh ]',
      'CHAR txt=[test ]',
      'CHAR txt=[drop ]',
      'STRT ele=[ze], atr=[]',
      'CHAR txt=[abba]',
      'ENDL ele=[ze]',
      'CHAR txt=[ dump ]',
      'CHAR txt=[give ]',
      'STRT ele=[more], atr=[]',
      'CHAR txt=[dummy ]',
      'CHAR txt=[<]',
    );

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms, 'Test-084a: error');
    is(scalar(@result), scalar(@expected),                                          'Test-084b: Number of results');
    verify('084', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY   tst1 "test data 1">}.
               q{<!ENTITY   tst2 SYSTEM "dat2.txt">}.
               q{<!ENTITY % nom3 "test data 3">}.
               q{<!ENTITY % nom4 SYSTEM "dat4.txt">}.
               q{<!ENTITY * nom5 "test data 5">}.
               q{<!ENTITY * nom6 SYSTEM "dat6.txt">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[tst1], val=[test data 1], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[tst2], val=[*undef*], sys=[dat2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[test data 3], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',
      'ENTT nam=[nom4], val=[*undef*], sys=[dat4.txt], pub=[*undef*], nda=[*undef*], isp=[1]',
    );

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-085a: error');
    is(scalar(@result), scalar(@expected),                        'Test-085b: Number of results');
    verify('085', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY nom1 "test   <&amp;>">}.
               q{]>}.
               q{<root parm1="'" parm2='"' parm3 = " ' data &amp;"></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[test   <&amp;>], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[parm1], [\'], [parm2], ["], [parm3], [ \' data &]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-086a: No error');
    is(scalar(@result), scalar(@expected), 'Test-086b: Number of results');
    verify('086', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY nom1 "test   <&amp;>">}.
               q{]>}.
               q{<root parm1="'" parm2='"' parm3 = " <>' data &amp;"></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[test   <&amp;>], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
    );

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-087a: error');
    is(scalar(@result), scalar(@expected),                        'Test-087b: Number of results');
    verify('087', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE svg PUBLIC "[" "[">}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    like($err, qr{illegal \s character\(s\) \s in \s public \s id}xms, 'Test-088a: error');
    is(scalar(@result), scalar(@expected),                             'Test-088b: Number of results');
    verify('088', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE html "http://www.w3.org/TR/REC-html40/strict.dtd">}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
    );

    like($err, qr{syntax \s error}xms,     'Test-089a: error');
    is(scalar(@result), scalar(@expected), 'Test-089b: Number of results');
    verify('089', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY t1        "test1">}.
               q{<!ENTITY t2 SYSTEM "test2">}.
               q{<!ENTITY t3 PUBLIC "test3">}.
               q{<!ENTITY t4 DUMMY  "test4">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[t1], val=[test1], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[t2], val=[*undef*], sys=[test2], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
    );

    like($err, qr{syntax \s error}xms,     'Test-090a: error');
    is(scalar(@result), scalar(@expected), 'Test-090b: Number of results');
    verify('090', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation1 SYSTEM "../an  im.fla"    NDATA flash>}.
               q{<!ENTITY t7         SYSTEM "test7"            NDATA nd7>}.
               q{<!ENTITY t8         PUBLIC "test8"            NDATA nd8>}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash]',
      'UNPS ent=[t7], base=[*undef*], sys=[test7], pub=[*undef*], not=[nd7]',
    );

    like($err, qr{syntax \s error}xms,     'Test-091a: error');
    is(scalar(@result), scalar(@expected), 'Test-091b: Number of results');
    verify('091', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation1 SYSTEM "../an  im.fla"    NDATA flash1>}.
               q{<!ENTITY animation2 SYSTEM "../an  im.fla"    NDATA flash2>}.
               q{<!ENTITY t6         SYSTEM "test6"            NDATA nd6>}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash1]',
      'UNPS ent=[animation2], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash2]',
      'UNPS ent=[t6], base=[*undef*], sys=[test6], pub=[*undef*], not=[nd6]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-092a: no error');
    is(scalar(@result), scalar(@expected), 'Test-092b: Number of results');
    verify('092', \@result, \@expected);
}

{
    crfile('file1.txt', 'c <xx>abba</xx> c tx &nom3; dd');
    crfile('file2.txt', 'gg');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY nom1                         "aa &nom2; tt &nom4; bb">}.
               q{<!ENTITY nom2 SYSTEM "file1.txt">}. # "c <xx>abba</xx> c tx &nom3; dd"
               q{<!ENTITY nom3                         "dd <yy>&nom4;</yy> ee">}.
               q{<!ENTITY nom4 SYSTEM "file2.txt">}. # gg
               q{]>}.
               q{<root parm='gg &nom1; tt'>uuuu</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[aa &nom2; tt &nom4; bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom2], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom3], val=[dd <yy>&nom4;</yy> ee], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[nom4], val=[*undef*], sys=[file2.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
    );

    like($err, qr{reference \s to \s external \s entity \s in \s attribute}xms, 'Test-093a: Error');
    is(scalar(@result), scalar(@expected),                                      'Test-093b: Number of results');
    verify('093', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ATTLIST image        height     CDATA                     #REQUIRED>}.
               q{<!ATTLIST image        width      CDATA                     #REQUIRED>}.
               q{<!ATTLIST student_name student_no ID                        #REQUIRED>}.
               q{<!ATTLIST student_name tutor_1    IDREF                     #IMPLIED>}.
               q{<!ATTLIST student_name tutor_2    IDREF                     #IMPLIED>}.
               q{<!ATTLIST results      image      ENTITY                    #REQUIRED>}.
               q{<!ATTLIST results      images     ENTITIES                  #REQUIRED>}.
               q{<!ATTLIST student_name student_no NMTOKEN                   #REQUIRED>}.
               q{<!ATTLIST code         lang       NOTATION (vrml)           #REQUIRED>}.
               q{<!ATTLIST task         status     (  important | normal )   #REQUIRED>}.
               q{<!ATTLIST task         status     (important|normal)        "normal">}.
               q{<!ATTLIST task         status     NMTOKEN            #FIXED "monthly">}.
               q{<!ATTLIST description  xml:lang   NMTOKEN            #FIXED "en">}.
               q{<!ATTLIST code         xml:space  (default|preserve)        "preserve">}.
               q{<!ATTLIST personnage   attitude   CDATA                     #REQUIRED }.
                                      q{geste      CDATA                     #IMPLIED >}.
               q{<!ATTLIST texte        ton        (normal | fort | faible)  "normal">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',

      'ATTL eln=[image], '.        'atn=[height], '.     'typ=[CDATA], '.                'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[image], '.        'atn=[width], '.      'typ=[CDATA], '.                'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[student_name], '. 'atn=[student_no], '. 'typ=[ID], '.                   'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[student_name], '. 'atn=[tutor_1], '.    'typ=[IDREF], '.                'def=[#IMPLIED], '.     'fix=[*undef*]',
      'ATTL eln=[student_name], '. 'atn=[tutor_2], '.    'typ=[IDREF], '.                'def=[#IMPLIED], '.     'fix=[*undef*]',
      'ATTL eln=[results], '.      'atn=[image], '.      'typ=[ENTITY], '.               'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[results], '.      'atn=[images], '.     'typ=[ENTITIES], '.             'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[student_name], '. 'atn=[student_no], '. 'typ=[NMTOKEN], '.              'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[code], '.         'atn=[lang], '.       'typ=[NOTATION(vrml)], '.       'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[task], '.         'atn=[status], '.     'typ=[(important|normal)], '.   'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[task], '.         'atn=[status], '.     'typ=[(important|normal)], '.   'def=[\'normal\'], '.   'fix=[*undef*]',
      'ATTL eln=[task], '.         'atn=[status], '.     'typ=[NMTOKEN], '.              'def=[\'monthly\'], '.  'fix=[1]',
      'ATTL eln=[description], '.  'atn=[xml:lang], '.   'typ=[NMTOKEN], '.              'def=[\'en\'], '.       'fix=[1]',
      'ATTL eln=[code], '.         'atn=[xml:space], '.  'typ=[(default|preserve)], '.   'def=[\'preserve\'], '. 'fix=[*undef*]',
      'ATTL eln=[personnage], '.   'atn=[attitude], '.   'typ=[CDATA], '.                'def=[#REQUIRED], '.    'fix=[*undef*]',
      'ATTL eln=[personnage], '.   'atn=[geste], '.      'typ=[CDATA], '.                'def=[#IMPLIED], '.     'fix=[*undef*]',
      'ATTL eln=[texte], '.        'atn=[ton], '.        'typ=[(normal|fort|faible)], '. 'def=[\'normal\'], '.   'fix=[*undef*]',

      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-094a: no error');
    is(scalar(@result), scalar(@expected), 'Test-094b: Number of results');
    verify('094', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!NOTATION name1 SYSTEM "URI1">}.
               q{<!NOTATION name2 PUBLIC "public_ID2">}.
               q{<!NOTATION name3 PUBLIC "public_ID3" "URI3">}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'NOTA not=[name1], base=[*undef*], sys=[URI1], pub=[*undef*]',
      'NOTA not=[name2], base=[*undef*], sys=[*undef*], pub=[public_ID2]',
      'NOTA not=[name3], base=[*undef*], sys=[URI3], pub=[public_ID3]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-095a: no error');
    is(scalar(@result), scalar(@expected), 'Test-095b: Number of results');
    verify('095', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<root param='>'></root>});

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[param], [>]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-096a: no error');
    is(scalar(@result), scalar(@expected), 'Test-096b: Number of results');
    verify('096', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<root><?abc def?></root>});

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
      'PROC tgt=[abc], dat=[def]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-097a: no error');
    is(scalar(@result), scalar(@expected), 'Test-097b: Number of results');
    verify('097', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<root><? abc def ?></root>});

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
    );

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms, 'Test-098a: Error');
    is(scalar(@result), scalar(@expected), 'Test-098b: Number of results');
    verify('098', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<zzz>a}, q{bx<!-- b}, q{c}, q{d --> ef}, q{g</zzz>});

    my @expected = (
      'INIT',
      'STRT ele=[zzz], atr=[]',
      'CHAR txt=[a]',
      'CHAR txt=[bx]',
      'COMT cmt=[ bcd ]',
      'CHAR txt=[ ef]',
      'CHAR txt=[g]',
      'ENDL ele=[zzz]',
      'FINL',
    );

    is($err, '',                           'Test-099a: No error');
    is(scalar(@result), scalar(@expected), 'Test-099b: Number of results');
    verify('099', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation1 SYSTEM "../an  im.fla"    NDATA flash>}.
               q{<!ENTITY animation2 SYSTEM "../an  im.fla">}.
               q{<!ENTITY animation2 SYSTEM 'dummy'>}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash]',
      'ENTT nam=[animation2], val=[*undef*], sys=[../an  im.fla], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[animation2]',
     q{DEFT str=['dummy']},
      'DEFT str=[>]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-100a: No error');
    is(scalar(@result), scalar(@expected), 'Test-100b: Number of results');
    verify('100', \@result, \@expected);
}

{
    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY animation1 SYSTEM "../an  im.fla"    NDATA flash>}.
               q{<!ENTITY animation2 SYSTEM "../an  im.fla">}.
               q{<!ENTITY animation2 'uuuu'>}.
               q{]>}.
               q{<root></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'UNPS ent=[animation1], base=[*undef*], sys=[../an  im.fla], pub=[*undef*], not=[flash]',
      'ENTT nam=[animation2], val=[*undef*], sys=[../an  im.fla], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DEFT str=[animation2]',
     q{DEFT str=['uuuu']},
      'DOCF',
      'STRT ele=[root], atr=[]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-101a: No error');
    is(scalar(@result), scalar(@expected), 'Test-101b: Number of results');
    verify('101', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE dialogue}.
               q{[}.
               q{<!ENTITY nom1 "test   <&amp;>">}.
               q{]>}.
               q{<root parm1="'" parm2='"' parm3 = " ()' data &amp;"></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom1], val=[test   <&amp;>], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[parm1], [\'], [parm2], ["], [parm3], [ ()\' data &]',
      'ENDL ele=[root]',
      'FINL',
    );

    is($err, '',                           'Test-102a: No error');
    is(scalar(@result), scalar(@expected), 'Test-102b: Number of results');
    verify('102', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{  "abc},
               q{<root},
               q{ parm1="'" parm2='"' parm3 = " ()' data &amp;"></root>});

    my @expected = (
      'INIT',
      'DEFT str=[  ]',
    );

    like($err, qr{not \s well-formed \s \(invalid \s token\)}xms,   'Test-103a: error');
    is(scalar(@result), scalar(@expected),                          'Test-103b: Number of results');
    verify('103', \@result, \@expected);
}

{
    crfile('file1.txt', '<abc>def</ab');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue [}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "file1.txt">}.
               q{]>}.qq{\n},
               q{<root>&nom1;</root>}.qq{\n},
    );

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'DEFT str=[&<0a>]',
      'DEFT str=[  ]',
      'ENTT nam=[nom1], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'STRT ele=[abc], atr=[]',
      'CHAR txt=[def]',
    );

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,  'Test-104a: error');
    is(scalar(@result), scalar(@expected), 'Test-104b: Number of results');
    verify('104', \@result, \@expected);
}

{
    $retval = '<abc>def</ab';

    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY nom SYSTEM "uri.txt">}.
               q{]>}.
               q{<root>hij&nom;klm</root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom], val=[*undef*], sys=[uri.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hij]',
      'EXEN base=[*undef*], sys=[uri.txt], pub=[*undef*]',
      'STRT ele=[abc], atr=[]',
      'CHAR txt=[def]',
      'EXEF',
    );

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,   'Test-105a: error');
    is(scalar(@result), scalar(@expected), 'Test-105b: Number of results');
    verify('105', \@result, \@expected);
}

{
    $retval = '<abc>def';

    get_result($XmlParser1,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY nom SYSTEM "uri.txt">}.
               q{]>}.
               q{<root>hij&nom;klm</abc></root>});

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[nom], val=[*undef*], sys=[uri.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[hij]',
      'EXEN base=[*undef*], sys=[uri.txt], pub=[*undef*]',
      'STRT ele=[abc], atr=[]',
      'CHAR txt=[def]',
      'EXEF',
    );

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,   'Test-106a: error');
    is(scalar(@result), scalar(@expected), 'Test-106b: Number of results');
    verify('106', \@result, \@expected);
}

{
    crfile('file1.txt', '<abc>def');

    get_result($XmlParser2,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue [}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "file1.txt">}.
               q{]>}.qq{\n},
               q{<root>&nom1;</abc></root>}.qq{\n},
    );

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DEFT str=[&<0a>]',
      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]',
      'DEFT str=[&<0a>]',
      'DEFT str=[  ]',
      'ENTT nam=[nom1], val=[*undef*], sys=[file1.txt], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'DEFT str=[&<0a>]',
      'STRT ele=[root], atr=[]',
      'STRT ele=[abc], atr=[]',
      'CHAR txt=[def]',
    );

    like($err, qr{error \s in \s processing \s external \s entity \s reference}xms,  'Test-107a: error');
    is(scalar(@result), scalar(@expected), 'Test-107b: Number of results');
    verify('107', \@result, \@expected);
}

{
    #~ crfile('file1.txt', 'zz &fil2; yy'); # Mutually recursive calls &fil1; --> &fil2; --> &fil1;
    #~ crfile('file2.txt', 'aa &fil1; bb');

    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.
               q{<!DOCTYPE root}.
               q{[}.
               q{<!ENTITY fil1 "zz &fil2; yy">}.
               q{<!ENTITY fil2 "aa &fil1; bb">}.
               q{]>}.
               q{<root>qq &fil1; rr</root>});

    like($err, qr{recursive \s entity \s reference}xms,      'Test-108a: error1');

    my @expected = (
      'INIT',
      'DECL ver=[1.0], enc=[ISO-8859-1], stand=[*undef*]',
      'DOCT nam=[root], sys=[*undef*], pub=[*undef*], int=[1]',
      'ENTT nam=[fil1], val=[zz &fil2; yy], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'ENTT nam=[fil2], val=[aa &fil1; bb], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]',
      'DOCF',
      'STRT ele=[root], atr=[]',
      'CHAR txt=[qq ]',
      'CHAR txt=[zz ]',
      'CHAR txt=[aa ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-108b: Number of results');
    verify('108', \@result, \@expected);
}

{
    get_result($XmlParser2, # $XmlParser2 = XmlParser without handler 'ExternEnt' or 'ExternEntFin'
               q{  aaaaaaaaaaaa});

    like($err, qr{syntax \s error}xms,      'Test-109a: error1');

    my @expected = (
      'INIT',
      'DEFT str=[  ]',
    );

    is(scalar(@result), scalar(@expected), 'Test-109b: Number of results');
    verify('109', \@result, \@expected);
}

{
    get_result($XmlParser2,
               q{<root><data a2="zzz" a1="yyy" a2="xxx">ttt</data></root>});

    like($err, qr{duplicate \s attribute}xms,      'Test-110a: error');

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
    );

    is(scalar(@result), scalar(@expected), 'Test-110b: Number of results');
    verify('110', \@result, \@expected);
}

{
    get_result($XmlParser3,
               q{<root><data a2="zzz" a1="yyy" a2="xxx">ttt</data></root>});

    is($err, '',      'Test-111a: error');

    my @expected = (
      'INIT',
      'STRT ele=[root], atr=[]',
      'STRT ele=[data], atr=[a1], [yyy], [a2], [zzz|xxx]',
      'CHAR txt=[ttt]',
      'ENDL ele=[data]',
      'ENDL ele=[root]',
      'FINL',
    );

    is(scalar(@result), scalar(@expected), 'Test-111b: Number of results');
    verify('111', \@result, \@expected);
}

#~ {
    #~ get_result($XmlParser2,
               #~ q{<r}.(q{o} x 11000).q{t></r}.(q{o} x 11000).q{t>});

    #~ my @expected = ('rrr') x @result;

    #~ like($err, qr{zzzzzzzz}xms,            'Test-103a: error');
    #~ is(scalar(@result), scalar(@expected), 'Test-103b: Number of results');
    #~ verify('103', \@result, \@expected);
#~ }

# ****************************************************************************************************************************
# ****************************************************************************************************************************
# ****************************************************************************************************************************

{
    for my $i (0..$#Handlers) {
        is($HCount[$i], $Handlers[$i][5], 'Test-890c-'.sprintf('%03d', $i).': correct counts for <'.$Handlers[$i][3].'>');
    }
}

# ****************************************************************************************************************************
# ****************************************************************************************************************************
# ****************************************************************************************************************************

sub verify {
    my ($num, $res, $exp) = @_;

    for my $i (0..$#$exp) {
        is($res->[$i], $exp->[$i], 'Test-'.$num.'c-'.sprintf('%03d', $i).': correct result');

        my $word = !defined($res->[$i]) ? '!!!!' : $res->[$i] =~ m{\A (\w{4}) }xms ? $1 : '????';
        my $ind = $HInd{$word};
        if (defined $ind) {
            $HCount[$ind]++;
        }
    }
}

sub get_result {
    my $Parser = shift;
    @result = ();
    $err = '';

    my $ExpatNB = $Parser->parse_start or die "Error-0020: Can't create XML::Parser->parse_start";

    eval {
        for my $buf (@_) {
            $ExpatNB->parse_more($buf); BEGIN { $line_more = __LINE__; }
        }
    };
    if ($@) {
        $err = $@;
        $ExpatNB->release;
    }
    else {
        eval {
            $ExpatNB->parse_done; BEGIN { $line_done = __LINE__; }
        };
        if ($@) {
            $err = $@;
        }
    }
}

sub handle_Init { #  1. Init         (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("INIT");
}

sub handle_Final { #  2. Final        (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("FINL");
}

sub handle_Start { #  3. Start        (Expat, Element [, Attr, Val [,...]])
    my ($ExpatNB, $element, @attr) = @_;

    $element =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    for my $at (@attr) {
        $at =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    }

    local $" = "], [";
    push @result, quote("STRT ele=[$element], atr=[@attr]");
}

sub handle_End { #  4. End          (Expat, Element)
    my ($ExpatNB, $element) = @_;

    $element =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("ENDL ele=[$element]");
}

sub handle_Char { #  5. Char         (Expat, String)
    my ($ExpatNB, $text) = @_;

    $text =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("CHAR txt=[$text]");
}

sub handle_Proc { #  6. Proc         (Expat, Target, Data)
    my ($ExpatNB, $target, $data) = @_;

    $target =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $data   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("PROC tgt=[$target], dat=[$data]");
}

sub handle_Comment { #  7. Comment      (Expat, Data)
    my ($ExpatNB, $comment) = @_;

    $comment =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("COMT cmt=[$comment]");
}

sub handle_CdataStart { #  8. CdataStart   (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("CDST");
}

sub handle_CdataEnd { #  9. CdataEnd     (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("CDEN");
}

sub handle_Default { # 10. Default      (Expat, String)
    my ($ExpatNB, $string) = @_;

    $string =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("DEFT str=[$string]");
}

sub handle_Unparsed { # 11. Unparsed     (Expat, Entity, Base, Sysid, Pubid, Notation)
    my ($ExpatNB, $entity, $base, $sysid, $pubid, $notation) = @_;

    $entity   //= '*undef*'; $entity   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $base     //= '*undef*'; $base     =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $sysid    //= '*undef*'; $sysid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $pubid    //= '*undef*'; $pubid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $notation //= '*undef*'; $notation =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("UNPS ent=[$entity], base=[$base], sys=[$sysid], pub=[$pubid], not=[$notation]");
}

sub handle_Notation { # 12. Notation     (Expat, Notation, Base, Sysid, Pubid)
    my ($ExpatNB, $notation, $base, $sysid, $pubid) = @_;

    $notation //= '*undef*'; $notation =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $base     //= '*undef*'; $base     =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $sysid    //= '*undef*'; $sysid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $pubid    //= '*undef*'; $pubid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("NOTA not=[$notation], base=[$base], sys=[$sysid], pub=[$pubid]");
}

sub handle_ExternEnt { # 13. ExternEnt    (Expat, Base, Sysid, Pubid)
    my ($ExpatNB, $base, $sysid, $pubid) = @_;

    $base     //= '*undef*'; $base  =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $sysid    //= '*undef*'; $sysid =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $pubid    //= '*undef*'; $pubid =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("EXEN base=[$base], sys=[$sysid], pub=[$pubid]");

    return $retval;
}

sub handle_ExternEntFin { # 14. ExternEntFin (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("EXEF");
}

sub handle_Entity { # 15. Entity       (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
    my ($ExpatNB, $name, $val, $sysid, $pubid, $ndata, $isparam) = @_;

    $name     //= '*undef*'; $name    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $val      //= '*undef*'; $val     =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $sysid    //= '*undef*'; $sysid   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $pubid    //= '*undef*'; $pubid   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $ndata    //= '*undef*'; $ndata   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $isparam  //= '*undef*'; $isparam =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("ENTT nam=[$name], val=[$val], sys=[$sysid], pub=[$pubid], nda=[$ndata], isp=[$isparam]");
}

sub handle_Element { # 16. Element      (Expat, Name, Model)
    my ($ExpatNB, $name, $model) = @_;

    $name     //= '*undef*'; $name  =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $model    //= '*undef*'; $model =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("ELEM nam=[$name], mod=[$model]");
}

sub handle_Attlist { # 17. Attlist      (Expat, Elname, Attname, Type, Default, Fixed)
    my ($ExpatNB, $elname, $attname, $type, $default, $fixed) = @_;

    $elname   //= '*undef*'; $elname  =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $attname  //= '*undef*'; $attname =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $type     //= '*undef*'; $type    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $default  //= '*undef*'; $default =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $fixed    //= '*undef*'; $fixed   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("ATTL eln=[$elname], atn=[$attname], typ=[$type], def=[$default], fix=[$fixed]");
}

sub handle_Doctype { # 18. Doctype      (Expat, Name, Sysid, Pubid, Internal)
    my ($ExpatNB, $name, $sysid, $pubid, $internal) = @_;

    $sysid    //= '*undef*'; $sysid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $pubid    //= '*undef*'; $pubid    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $internal //= '*undef*'; $internal =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("DOCT nam=[$name], sys=[$sysid], pub=[$pubid], int=[$internal]");
}

sub handle_DoctypeFin { # 19. DoctypeFin   (Expat)
    my ($ExpatNB) = @_;

    push @result, quote("DOCF");
}

sub handle_XMLDecl { # 20. XMLDecl      (Expat, Version, Encoding, Standalone)
    my ($ExpatNB, $version, $encoding, $standalone) = @_;

    $version    //= '*undef*'; $version    =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $encoding   //= '*undef*'; $encoding   =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $standalone //= '*undef*'; $standalone =~ s{([\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, quote("DECL ver=[$version], enc=[$encoding], stand=[$standalone]");
}

sub quote {
    my ($txt) = @_;
    $txt =~ s{([\x00-\x1f])}{sprintf('&<%02x>', ord($1))}xmsge;
    return $txt;
}

sub crfile {
    my $fname = shift;

    open my $fh1, '>', $fname or die "Error-0005: Can't open > '$fname' because $!";

    for my $item (@_) {
        print {$fh1} $item;
    }

    close $fh1;
}

sub dlfile {
    my $fname = shift;

    if (-e $fname) {
        unlink $fname or die "Error-0007: Can't unlink '$fname' because $!";
    }
}
