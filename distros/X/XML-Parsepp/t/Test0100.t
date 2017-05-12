use 5.014;
use warnings;
# Generate Tests for XML::Parsepp

use Test::More tests => 930;

my $XML_module = 'XML::Parsepp';

use_ok($XML_module);

my @result;
my $err = '';
my $line_more;
my $line_done;

my $XmlParser = $XML_module->new or die "Error-0010: Can't create $XML_module -> new";

my @Handlers = (
  [  1, Init         => \&handle_Init,         'INIT', occurs =>  104, 'Init         (Expat)'                                            ],
  [  2, Final        => \&handle_Final,        'FINL', occurs =>   20, 'Final        (Expat)'                                            ],
  [  3, Start        => \&handle_Start,        'STRT', occurs =>   47, 'Start        (Expat, Element, @Attr)'                            ],
  [  4, End          => \&handle_End,          'ENDL', occurs =>   26, 'End          (Expat, Element)'                                   ],
  [  5, Char         => \&handle_Char,         'CHAR', occurs =>   47, 'Char         (Expat, String)'                                    ],
  [  6, Proc         => \&handle_Proc,         'PROC', occurs =>    3, 'Proc         (Expat, Target, Data)'                              ],
  [  7, Comment      => \&handle_Comment,      'COMT', occurs =>    2, 'Comment      (Expat, Data)'                                      ],
  [  8, CdataStart   => \&handle_CdataStart,   'CDST', occurs =>    0, 'CdataStart   (Expat)'                                            ],
  [  9, CdataEnd     => \&handle_CdataEnd,     'CDEN', occurs =>    0, 'CdataEnd     (Expat)'                                            ],
  [ 10, Default      => \&handle_Default,      'DEFT', occurs =>  270, 'Default      (Expat, String)'                                    ],
  [ 11, Unparsed     => \&handle_Unparsed,     'UNPS', occurs =>    1, 'Unparsed     (Expat, Entity, Base, Sysid, Pubid, Notation)'      ],
  [ 12, Notation     => \&handle_Notation,     'NOTA', occurs =>    4, 'Notation     (Expat, Notation, Base, Sysid, Pubid)'              ],
  [ 13, Entity       => \&handle_Entity,       'ENTT', occurs =>   14, 'Entity       (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)'   ],
  [ 14, Element      => \&handle_Element,      'ELEM', occurs =>    7, 'Element      (Expat, Name, Model)'                               ],
  [ 15, Attlist      => \&handle_Attlist,      'ATTL', occurs =>    7, 'Attlist      (Expat, Elname, Attname, Type, Default, Fixed)'     ],
  [ 16, Doctype      => \&handle_Doctype,      'DOCT', occurs =>   54, 'Doctype      (Expat, Name, Sysid, Pubid, Internal)'              ],
  [ 17, DoctypeFin   => \&handle_DoctypeFin,   'DOCF', occurs =>   15, 'DoctypeFin   (Expat)'                                            ],
  [ 18, XMLDecl      => \&handle_XMLDecl,      'DECL', occurs =>   82, 'XMLDecl      (Expat, Version, Encoding, Standalone)'             ],
);

my @HParam;
for my $H (@Handlers) {
    push @HParam, $H->[1], $H->[2];
}

my %HInd;
my @HCount;
for my $i (0..$#Handlers) {
    $HInd{$Handlers[$i][3]} = $i;
    $HCount[$i] = 0;
}

$XmlParser->setHandlers(@HParam);

# most testcases have been inspired by...
#   http://www.u-picardie.fr/~ferment/xml/xml02.html
#   http://www.comptechdoc.org/independent/web/dtd/dtddekeywords.html
#   http://xmlwriter.net/xml_guide/attlist_declaration.shtml
# *************************************************************************************

# No of get_result is 104

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-001a: No error');
    is(scalar(@result), scalar(@expected), 'Test-001b: Number of results');
    verify('001', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[1]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-002a: No error');
    is(scalar(@result), scalar(@expected), 'Test-002b: Number of results');
    verify('002', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-003a: No error');
    is(scalar(@result), scalar(@expected), 'Test-003b: Number of results');
    verify('003', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone="maybe"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-004a: error');
    is(scalar(@result), scalar(@expected), 'Test-004b: Number of results');
    verify('004', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" dummy="abc" standalone="yes"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-005a: error');
    is(scalar(@result), scalar(@expected), 'Test-005b: Number of results');
    verify('005', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml encoding="ISO-8859-1" standalone="yes"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-006a: error');
    is(scalar(@result), scalar(@expected), 'Test-006b: Number of results');
    verify('006', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-007a: No error');
    is(scalar(@result), scalar(@expected), 'Test-007b: Number of results');
    verify('007', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="9.9"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[9.9], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-008a: No error');
    is(scalar(@result), scalar(@expected), 'Test-008b: Number of results');
    verify('008', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="abc"?>}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[abc], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-009a: No error');
    is(scalar(@result), scalar(@expected), 'Test-009b: Number of results');
    verify('009', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root><?aaa bbb?></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{PROC Tar=[aaa], Dat=[bbb]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-010a: No error');
    is(scalar(@result), scalar(@expected), 'Test-010b: Number of results');
    verify('010', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root><?test aa="bbb"   cc='ddd'?></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{PROC Tar=[test], Dat=[aa="bbb"   cc='ddd']},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-011a: No error');
    is(scalar(@result), scalar(@expected), 'Test-011b: Number of results');
    verify('011', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root><?test aa="bbb"   cc='ddd'   ?></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{PROC Tar=[test], Dat=[aa="bbb"   cc='ddd'   ]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-012a: No error');
    is(scalar(@result), scalar(@expected), 'Test-012b: Number of results');
    verify('012', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root><?    test aa="bbb"   cc='ddd'   ?></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-013a: error');
    is(scalar(@result), scalar(@expected), 'Test-013b: Number of results');
    verify('013', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root>< ?test aa="bbb"   cc='ddd'? ></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-014a: error');
    is(scalar(@result), scalar(@expected), 'Test-014b: Number of results');
    verify('014', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<root>aaa</root>}.qq{\n},
               q{<root>bbb</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[aaa]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{junk \s+ after \s+ document \s+ element}xms, 'Test-015a: error');
    is(scalar(@result), scalar(@expected), 'Test-015b: Number of results');
    verify('015', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<root>a<!-  --> aa</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[a]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-016a: error');
    is(scalar(@result), scalar(@expected), 'Test-016b: Number of results');
    verify('016', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<root>b<!zzz hgjhg></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[b]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-017a: error');
    is(scalar(@result), scalar(@expected), 'Test-017b: Number of results');
    verify('017', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<root>t<%  jkjkj %>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[t]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-018a: error');
    is(scalar(@result), scalar(@expected), 'Test-018b: Number of results');
    verify('018', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<!zzz test SYSTEM "URI-de-la-dtd">}.qq{\n},
               q{<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-019a: error');
    is(scalar(@result), scalar(@expected), 'Test-019b: Number of results');
    verify('019', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<root>abc <![CDAT1[ def ]]> ghi</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[abc ]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-020a: error');
    is(scalar(@result), scalar(@expected), 'Test-020b: Number of results');
    verify('020', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{]><root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-021a: error');
    is(scalar(@result), scalar(@expected), 'Test-021b: Number of results');
    verify('021', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{aa>zzz<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-022a: error');
    is(scalar(@result), scalar(@expected), 'Test-022b: Number of results');
    verify('022', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>aaa<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-023a: error');
    is(scalar(@result), scalar(@expected), 'Test-023b: Number of results');
    verify('023', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{aaa<?xml version="1.0" encoding="ISO-8859-1"?><root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-024a: error');
    is(scalar(@result), scalar(@expected), 'Test-024b: Number of results');
    verify('024', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{aaa}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-025a: error');
    is(scalar(@result), scalar(@expected), 'Test-025b: Number of results');
    verify('025', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{aa]<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-026a: error');
    is(scalar(@result), scalar(@expected), 'Test-026b: Number of results');
    verify('026', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{aaa<root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-027a: error');
    is(scalar(@result), scalar(@expected), 'Test-027b: Number of results');
    verify('027', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{ <?xml version="1.0" encoding="ISO-8859-1"?><!DOCTYPE svg PUBLIC "-//W3C" "http://www.w3.org"><root></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DEFT Str=[ ]},
    );

    like($err, qr{XML \s+ or \s+ text \s+ declaration \s+ not \s+ at \s+ start \s+ of \s+ entity}xms, 'Test-028a: error');
    is(scalar(@result), scalar(@expected), 'Test-028b: Number of results');
    verify('028', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{  <!DOCTYPE dialogue [}.qq{\n},
               q{    <!ELEMENT dialogue (situation?, replique+)>}.qq{\n},
               q{    <!ELEMENT situation (#PCDATA) >}.qq{\n},
               q{    <!ELEMENT replique (   personnage   ,     texte     )     >}.qq{\n},
               q{    <!ELEMENT personnage (  #PCDATA ) >}.qq{\n},
               q{    <!ATTLIST personnage attitude CDATA #REQUIRED geste CDATA #IMPLIED >}.qq{\n},
               q{    <!NOTATION flash SYSTEM "/usr/bin/flash.exe">}.qq{\n},
               q{    <!ENTITY animation SYSTEM "../anim.fla" NDATA flash>}.qq{\n},
               q{    <!ELEMENT texte (#PCDATA) >}.qq{\n},
               q{    <!ATTLIST texte ton (normal | fort | faible) "normal">}.qq{\n},
               q{  ]?>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ELEM Nam=[dialogue], Mod=[(situation?,replique+)]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ELEM Nam=[situation], Mod=[(#PCDATA)]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ELEM Nam=[replique], Mod=[(personnage,texte)]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ELEM Nam=[personnage], Mod=[(#PCDATA)]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ATTL Eln=[personnage], Att=[attitude], Typ=[CDATA], Def=[#REQUIRED], Fix=[*undef*]},
        q{ATTL Eln=[personnage], Att=[geste], Typ=[CDATA], Def=[#IMPLIED], Fix=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{NOTA Not=[flash], Bas=[*undef*], Sys=[/usr/bin/flash.exe], Pub=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{UNPS Ent=[animation], Bas=[*undef*], Sys=[../anim.fla], Pub=[*undef*], Not=[flash]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ELEM Nam=[texte], Mod=[(#PCDATA)]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
        q{ATTL Eln=[texte], Att=[ton], Typ=[(normal|fort|faible)], Def=['normal'], Fix=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-029a: error');
    is(scalar(@result), scalar(@expected), 'Test-029b: Number of results');
    verify('029', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue [}.qq{\n},
               q{  <!ENTITY nom1 "<abc>def</ab">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>&nom1;</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[<abc>def</ab], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{STRT Ele=[abc], Att=[]},
        q{CHAR Str=[def]},
    );

    like($err, qr{unclosed \s+ token}xms, 'Test-030a: error');
    is(scalar(@result), scalar(@expected), 'Test-030b: Number of results');
    verify('030', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue [}.qq{\n},
               q{  <!ENTITY nom1 "<abc>def">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>&nom1;</abc></root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[<abc>def], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{STRT Ele=[abc], Att=[]},
        q{CHAR Str=[def]},
    );

    like($err, qr{asynchronous \s+ entity}xms, 'Test-031a: error');
    is(scalar(@result), scalar(@expected), 'Test-031b: Number of results');
    verify('031', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue [}.qq{\n},
               q{  <!ENTITY nom0 "<data>y<item>y &nom1; zz</data>">}.qq{\n},
               q{  <!ENTITY nom1 "<abc>def</abc></item>">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>&nom0;</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom0], Val=[<data>y<item>y &nom1; zz</data>], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[<abc>def</abc></item>], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{STRT Ele=[data], Att=[]},
        q{CHAR Str=[y]},
        q{STRT Ele=[item], Att=[]},
        q{CHAR Str=[y ]},
        q{STRT Ele=[abc], Att=[]},
        q{CHAR Str=[def]},
        q{ENDL Ele=[abc]},
    );

    like($err, qr{asynchronous \s+ entity}xms, 'Test-032a: error');
    is(scalar(@result), scalar(@expected), 'Test-032b: Number of results');
    verify('032', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa &nom2; tt &nom4; bb">}.qq{\n},
               q{  <!ENTITY nom2 "c <xx>abba</xx> c tx <ab> &nom3; dd">}.qq{\n},
               q{  <!ENTITY nom3 "dd </ab> <yy>&nom4;</yy> ee">}.qq{\n},
               q{  <!ENTITY nom4 "gg">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>hh &nom1; ii</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa &nom2; tt &nom4; bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom2], Val=[c <xx>abba</xx> c tx <ab> &nom3; dd], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom3], Val=[dd </ab> <yy>&nom4;</yy> ee], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom4], Val=[gg], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[hh ]},
        q{CHAR Str=[aa ]},
        q{CHAR Str=[c ]},
        q{STRT Ele=[xx], Att=[]},
        q{CHAR Str=[abba]},
        q{ENDL Ele=[xx]},
        q{CHAR Str=[ c tx ]},
        q{STRT Ele=[ab], Att=[]},
        q{CHAR Str=[ ]},
        q{CHAR Str=[dd ]},
    );

    like($err, qr{asynchronous \s+ entity}xms, 'Test-033a: error');
    is(scalar(@result), scalar(@expected), 'Test-033b: Number of results');
    verify('033', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test1>hh &nom1; ii</test1>}.qq{\n},
               q{  <test2>pp &nom2; qq</test2>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
        q{STRT Ele=[test1], Att=[]},
        q{CHAR Str=[hh ]},
        q{CHAR Str=[aa bb]},
        q{CHAR Str=[ ii]},
        q{ENDL Ele=[test1]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
        q{STRT Ele=[test2], Att=[]},
        q{CHAR Str=[pp ]},
    );

    like($err, qr{undefined \s+ entity}xms, 'Test-034a: error');
    is(scalar(@result), scalar(@expected), 'Test-034b: Number of results');
    verify('034', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test1 param1="&nom2;">uuuuuu</test1>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
    );

    like($err, qr{undefined \s+ entity}xms, 'Test-035a: error');
    is(scalar(@result), scalar(@expected), 'Test-035b: Number of results');
    verify('035', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test>eeeee</test***>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
        q{STRT Ele=[test], Att=[]},
        q{CHAR Str=[eeeee]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-036a: error');
    is(scalar(@result), scalar(@expected), 'Test-036b: Number of results');
    verify('036', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0"?>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test>eeeee</test>}.qq{\n},
               q{</root></dummy>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
        q{STRT Ele=[test], Att=[]},
        q{CHAR Str=[eeeee]},
        q{ENDL Ele=[test]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-037a: error');
    is(scalar(@result), scalar(@expected), 'Test-037b: Number of results');
    verify('037', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" version="1.0" encoding="ISO-8859-1" standalone="yes"?>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test>aa</test>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-038a: error');
    is(scalar(@result), scalar(@expected), 'Test-038b: Number of results');
    verify('038', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" encoding="ISO-8859-1" standalone="yes"?>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test>aa</test>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-039a: error');
    is(scalar(@result), scalar(@expected), 'Test-039b: Number of results');
    verify('039', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1" standalone="yes" standalone="yes"?>}.qq{\n},
               q{<root>}.qq{\n},
               q{  <test>aa</test>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{XML \s+ declaration \s+ not \s+ well-formed}xms, 'Test-040a: error');
    is(scalar(@result), scalar(@expected), 'Test-040b: Number of results');
    verify('040', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{] >}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-041a: No error');
    is(scalar(@result), scalar(@expected), 'Test-041b: Number of results');
    verify('041', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{]*>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-042a: error');
    is(scalar(@result), scalar(@expected), 'Test-042b: Number of results');
    verify('042', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-043a: error');
    is(scalar(@result), scalar(@expected), 'Test-043b: Number of results');
    verify('043', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb" [}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-044a: error');
    is(scalar(@result), scalar(@expected), 'Test-044b: Number of results');
    verify('044', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOC-TYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-045a: error');
    is(scalar(@result), scalar(@expected), 'Test-045b: Number of results');
    verify('045', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 "aa bb>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{unclosed \s+ token}xms, 'Test-046a: error');
    is(scalar(@result), scalar(@expected), 'Test-046b: Number of results');
    verify('046', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{    <!ELEMENT personnage (  #PCDATA >}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[    ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-047a: error');
    is(scalar(@result), scalar(@expected), 'Test-047b: Number of results');
    verify('047', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE "dialogue">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-048a: error');
    is(scalar(@result), scalar(@expected), 'Test-048b: Number of results');
    verify('048', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-049a: error');
    is(scalar(@result), scalar(@expected), 'Test-049b: Number of results');
    verify('049', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE abc>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[abc], Sys=[*undef*], Pub=[*undef*], Int=[]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-050a: No error');
    is(scalar(@result), scalar(@expected), 'Test-050b: Number of results');
    verify('050', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE abc def>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-051a: error');
    is(scalar(@result), scalar(@expected), 'Test-051b: Number of results');
    verify('051', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE SYSTEM "def">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-052a: error');
    is(scalar(@result), scalar(@expected), 'Test-052b: Number of results');
    verify('052', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<!DOCTYPE "SYSTEM">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-053a: error');
    is(scalar(@result), scalar(@expected), 'Test-053b: Number of results');
    verify('053', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE ura SYSTEM>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-054a: error');
    is(scalar(@result), scalar(@expected), 'Test-054b: Number of results');
    verify('054', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE ura SYSTEM xyz>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-055a: error');
    is(scalar(@result), scalar(@expected), 'Test-055b: Number of results');
    verify('055', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE ura SYSTEM "xyz" rrrrrrrr>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-056a: error');
    is(scalar(@result), scalar(@expected), 'Test-056b: Number of results');
    verify('056', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE ura SYSTEM "xyz" "iiii" "ffff">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-057a: error');
    is(scalar(@result), scalar(@expected), 'Test-057b: Number of results');
    verify('057', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!DOCTYPE ura SYSTEM "xyz">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-058a: error');
    is(scalar(@result), scalar(@expected), 'Test-058b: Number of results');
    verify('058', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE ura SYSTEM "xyz" [}.qq{\n},
               q{  <!ENTITY nom1 "aa bb">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[ura], Sys=[xyz], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ENTT Nam=[nom1], Val=[aa bb], Sys=[*undef*], Pub=[*undef*], Nda=[*undef*], IsP=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-059a: No error');
    is(scalar(@result), scalar(@expected), 'Test-059b: Number of results');
    verify('059', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY "aa">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-060a: error');
    is(scalar(@result), scalar(@expected), 'Test-060b: Number of results');
    verify('060', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-061a: error');
    is(scalar(@result), scalar(@expected), 'Test-061b: Number of results');
    verify('061', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-062a: error');
    is(scalar(@result), scalar(@expected), 'Test-062b: Number of results');
    verify('062', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-063a: error');
    is(scalar(@result), scalar(@expected), 'Test-063b: Number of results');
    verify('063', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM abcdddd>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-064a: error');
    is(scalar(@result), scalar(@expected), 'Test-064b: Number of results');
    verify('064', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "abcdddd" "deffffffff">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-065a: error');
    is(scalar(@result), scalar(@expected), 'Test-065b: Number of results');
    verify('065', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "abcdddd" NDAT1>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-066a: error');
    is(scalar(@result), scalar(@expected), 'Test-066b: Number of results');
    verify('066', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "abcdddd" NDATA (ABC DEF)>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-067a: error');
    is(scalar(@result), scalar(@expected), 'Test-067b: Number of results');
    verify('067', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "abcdddd" NDATA>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-068a: error');
    is(scalar(@result), scalar(@expected), 'Test-068b: Number of results');
    verify('068', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ENTITY nom1 SYSTEM "abcdddd" NDATA "AAAAAAAA" ttttttt>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-069a: error');
    is(scalar(@result), scalar(@expected), 'Test-069b: Number of results');
    verify('069', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT replique (personnage, texte)>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ELEM Nam=[replique], Mod=[(personnage,texte)]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-070a: No error');
    is(scalar(@result), scalar(@expected), 'Test-070b: Number of results');
    verify('070', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{not \s+ well-formed \s+ \(invalid \s+ token\)}xms, 'Test-071a: error');
    is(scalar(@result), scalar(@expected), 'Test-071b: Number of results');
    verify('071', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT "replique">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-072a: error');
    is(scalar(@result), scalar(@expected), 'Test-072b: Number of results');
    verify('072', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT replique>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-073a: error');
    is(scalar(@result), scalar(@expected), 'Test-073b: Number of results');
    verify('073', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT replique (personnage, texte) aaaaaaaaaaaaaa>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ELEM Nam=[replique], Mod=[(personnage,texte)]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-074a: error');
    is(scalar(@result), scalar(@expected), 'Test-074b: Number of results');
    verify('074', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ELEMENT replique "personnage, texte">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-075a: error');
    is(scalar(@result), scalar(@expected), 'Test-075b: Number of results');
    verify('075', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!ELEMENT replique (personnage, texte)>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-076a: error');
    is(scalar(@result), scalar(@expected), 'Test-076b: Number of results');
    verify('076', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST task status (important|normal) "normal">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ATTL Eln=[task], Att=[status], Typ=[(important|normal)], Def=['normal'], Fix=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-077a: No error');
    is(scalar(@result), scalar(@expected), 'Test-077b: Number of results');
    verify('077', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST "task" status (important|normal) "normal">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-078a: error');
    is(scalar(@result), scalar(@expected), 'Test-078b: Number of results');
    verify('078', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST task "status" (important|normal) "normal">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-079a: error');
    is(scalar(@result), scalar(@expected), 'Test-079b: Number of results');
    verify('079', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST task status>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-080a: error');
    is(scalar(@result), scalar(@expected), 'Test-080b: Number of results');
    verify('080', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST task status>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-081a: error');
    is(scalar(@result), scalar(@expected), 'Test-081b: Number of results');
    verify('081', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type NOTATION (GIF | JPEG | PNG) "GIF">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ATTL Eln=[image], Att=[type], Typ=[NOTATION(GIF|JPEG|PNG)], Def=['GIF'], Fix=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-082a: No error');
    is(scalar(@result), scalar(@expected), 'Test-082b: Number of results');
    verify('082', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type NOTATION>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-083a: error');
    is(scalar(@result), scalar(@expected), 'Test-083b: Number of results');
    verify('083', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type NOTATION yyyyyyyyyyyyyy>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-084a: error');
    is(scalar(@result), scalar(@expected), 'Test-084b: Number of results');
    verify('084', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type "zezezezezezez">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-085a: error');
    is(scalar(@result), scalar(@expected), 'Test-085b: Number of results');
    verify('085', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type pppppp>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-086a: error');
    is(scalar(@result), scalar(@expected), 'Test-086b: Number of results');
    verify('086', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type pppppp #FIXED>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-087a: error');
    is(scalar(@result), scalar(@expected), 'Test-087b: Number of results');
    verify('087', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type pppppp #FIXED ttttttttttt>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-088a: error');
    is(scalar(@result), scalar(@expected), 'Test-088b: Number of results');
    verify('088', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST sender company CDATA  #FIXED "Microsoft">}.qq{\n},
               q{  <!ATTLIST image  type    CDATA  #FIXED "qqqqqqqqqqq">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ATTL Eln=[sender], Att=[company], Typ=[CDATA], Def=['Microsoft'], Fix=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{ATTL Eln=[image], Att=[type], Typ=[CDATA], Def=['qqqqqqqqqqq'], Fix=[1]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-089a: No error');
    is(scalar(@result), scalar(@expected), 'Test-089b: Number of results');
    verify('089', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!ATTLIST image type pppppp (aaaaa, bbbbbbbb) "qqqqqqqqqqq">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-090a: error');
    is(scalar(@result), scalar(@expected), 'Test-090b: Number of results');
    verify('090', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!ATTLIST sender company CDATA  #FIXED "Microsoft">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-091a: error');
    is(scalar(@result), scalar(@expected), 'Test-091b: Number of results');
    verify('091', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC "public_ID3" "URI3">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{NOTA Not=[name3], Bas=[*undef*], Sys=[URI3], Pub=[public_ID3]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-092a: No error');
    is(scalar(@result), scalar(@expected), 'Test-092b: Number of results');
    verify('092', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION "name3" PUBLIC "public_ID3" "URI3">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-093a: error');
    is(scalar(@result), scalar(@expected), 'Test-093b: Number of results');
    verify('093', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 "PUBLIC" "public_ID3" "URI3">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-094a: error');
    is(scalar(@result), scalar(@expected), 'Test-094b: Number of results');
    verify('094', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 ZZZZZZZZZ "public_ID3" "URI3">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-095a: error');
    is(scalar(@result), scalar(@expected), 'Test-095b: Number of results');
    verify('095', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-096a: error');
    is(scalar(@result), scalar(@expected), 'Test-096b: Number of results');
    verify('096', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC abccccc>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-097a: error');
    is(scalar(@result), scalar(@expected), 'Test-097b: Number of results');
    verify('097', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC "abccccc" defffff>}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-098a: error');
    is(scalar(@result), scalar(@expected), 'Test-098b: Number of results');
    verify('098', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC "abccccc" "defffff">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{NOTA Not=[name3], Bas=[*undef*], Sys=[defffff], Pub=[abccccc]},
        q{DEFT Str=[&<0a>]},
        q{DOCF},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-099a: No error');
    is(scalar(@result), scalar(@expected), 'Test-099b: Number of results');
    verify('099', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!DOCTYPE dialogue}.qq{\n},
               q{[}.qq{\n},
               q{  <!NOTATION name3 PUBLIC "abccccc" "defffff" "ghiiiiii">}.qq{\n},
               q{]>}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{DOCT Nam=[dialogue], Sys=[*undef*], Pub=[*undef*], Int=[1]},
        q{DEFT Str=[&<0a>]},
        q{DEFT Str=[  ]},
        q{NOTA Not=[name3], Bas=[*undef*], Sys=[defffff], Pub=[abccccc]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-100a: error');
    is(scalar(@result), scalar(@expected), 'Test-100b: Number of results');
    verify('100', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!NOTATION name3 PUBLIC "abccccc" "defffff">}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
    );

    like($err, qr{syntax \s+ error}xms, 'Test-101a: error');
    is(scalar(@result), scalar(@expected), 'Test-101b: Number of results');
    verify('101', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<?xml version="1.0" encoding="ISO-8859-1"?>}.qq{\n},
               q{<!-- test -->}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{DECL Ver=[1.0], Enc=[ISO-8859-1], Sta=[*undef*]},
        q{DEFT Str=[&<0a>]},
        q{COMT Dat=[ test ]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-102a: No error');
    is(scalar(@result), scalar(@expected), 'Test-102b: Number of results');
    verify('102', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<!-- test -->}.qq{\n},
               q{<root>}.qq{\n},
               q{</root>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{COMT Dat=[ test ]},
        q{DEFT Str=[&<0a>]},
        q{STRT Ele=[root], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{ENDL Ele=[root]},
        q{DEFT Str=[&<0a>]},
        q{FINL},
    );

    is($err, '', 'Test-103a: No error');
    is(scalar(@result), scalar(@expected), 'Test-103b: Number of results');
    verify('103', \@result, \@expected);
}

{
    get_result($XmlParser,
               q{<data>}.qq{\n},
               q{  <item alpha="aaa" beta="bbb" alpha="ccc">test</item>}.qq{\n},
               q{</data>}.qq{\n},
    );

    my @expected = (
        q{INIT},
        q{STRT Ele=[data], Att=[]},
        q{CHAR Str=[&<0a>]},
        q{CHAR Str=[  ]},
    );

    like($err, qr{duplicate \s+ attribute}xms, 'Test-104a: error');
    is(scalar(@result), scalar(@expected), 'Test-104b: Number of results');
    verify('104', \@result, \@expected);
}

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
            $ExpatNB->parse_more($buf);
        }
    };
    if ($@) {
        $err = $@;
        $ExpatNB->release;
    }
    else {
        eval {
            $ExpatNB->parse_done;
        };
        if ($@) {
            $err = $@;
        }
    }
}

sub handle_Init { #  1. Init            (Expat)
    my ($Expat) = @_;


    push @result, "INIT";
}

sub handle_Final { #  2. Final           (Expat)
    my ($Expat) = @_;


    push @result, "FINL";
}

sub handle_Start { #  3. Start           (Expat, Element, @Attr)
    my ($Expat, $Element, @Attr) = @_;

    $Element     //= '*undef*'; $Element     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    for my $a (@Attr) {
        $a //= '*undef*'; $a =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    }

    local $" = "], [";
    push @result, "STRT Ele=[$Element], Att=[@Attr]";
}

sub handle_End { #  4. End             (Expat, Element)
    my ($Expat, $Element) = @_;

    $Element     //= '*undef*'; $Element     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "ENDL Ele=[$Element]";
}

sub handle_Char { #  5. Char            (Expat, String)
    my ($Expat, $String) = @_;

    $String      //= '*undef*'; $String      =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "CHAR Str=[$String]";
}

sub handle_Proc { #  6. Proc            (Expat, Target, Data)
    my ($Expat, $Target, $Data) = @_;

    $Target      //= '*undef*'; $Target      =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Data        //= '*undef*'; $Data        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "PROC Tar=[$Target], Dat=[$Data]";
}

sub handle_Comment { #  7. Comment         (Expat, Data)
    my ($Expat, $Data) = @_;

    $Data        //= '*undef*'; $Data        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "COMT Dat=[$Data]";
}

sub handle_CdataStart { #  8. CdataStart      (Expat)
    my ($Expat) = @_;


    push @result, "CDST";
}

sub handle_CdataEnd { #  9. CdataEnd        (Expat)
    my ($Expat) = @_;


    push @result, "CDEN";
}

sub handle_Default { # 10. Default         (Expat, String)
    my ($Expat, $String) = @_;

    $String      //= '*undef*'; $String      =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "DEFT Str=[$String]";
}

sub handle_Unparsed { # 11. Unparsed        (Expat, Entity, Base, Sysid, Pubid, Notation)
    my ($Expat, $Entity, $Base, $Sysid, $Pubid, $Notation) = @_;

    $Entity      //= '*undef*'; $Entity      =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Base        //= '*undef*'; $Base        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Sysid       //= '*undef*'; $Sysid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Pubid       //= '*undef*'; $Pubid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Notation    //= '*undef*'; $Notation    =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "UNPS Ent=[$Entity], Bas=[$Base], Sys=[$Sysid], Pub=[$Pubid], Not=[$Notation]";
}

sub handle_Notation { # 12. Notation        (Expat, Notation, Base, Sysid, Pubid)
    my ($Expat, $Notation, $Base, $Sysid, $Pubid) = @_;

    $Notation    //= '*undef*'; $Notation    =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Base        //= '*undef*'; $Base        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Sysid       //= '*undef*'; $Sysid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Pubid       //= '*undef*'; $Pubid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "NOTA Not=[$Notation], Bas=[$Base], Sys=[$Sysid], Pub=[$Pubid]";
}

sub handle_Entity { # 13. Entity          (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
    my ($Expat, $Name, $Val, $Sysid, $Pubid, $Ndata, $IsParam) = @_;

    $Name        //= '*undef*'; $Name        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Val         //= '*undef*'; $Val         =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Sysid       //= '*undef*'; $Sysid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Pubid       //= '*undef*'; $Pubid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Ndata       //= '*undef*'; $Ndata       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $IsParam     //= '*undef*'; $IsParam     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "ENTT Nam=[$Name], Val=[$Val], Sys=[$Sysid], Pub=[$Pubid], Nda=[$Ndata], IsP=[$IsParam]";
}

sub handle_Element { # 14. Element         (Expat, Name, Model)
    my ($Expat, $Name, $Model) = @_;

    $Name        //= '*undef*'; $Name        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Model       //= '*undef*'; $Model       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "ELEM Nam=[$Name], Mod=[$Model]";
}

sub handle_Attlist { # 15. Attlist         (Expat, Elname, Attname, Type, Default, Fixed)
    my ($Expat, $Elname, $Attname, $Type, $Default, $Fixed) = @_;

    $Elname      //= '*undef*'; $Elname      =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Attname     //= '*undef*'; $Attname     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Type        //= '*undef*'; $Type        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Default     //= '*undef*'; $Default     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Fixed       //= '*undef*'; $Fixed       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "ATTL Eln=[$Elname], Att=[$Attname], Typ=[$Type], Def=[$Default], Fix=[$Fixed]";
}

sub handle_Doctype { # 16. Doctype         (Expat, Name, Sysid, Pubid, Internal)
    my ($Expat, $Name, $Sysid, $Pubid, $Internal) = @_;

    $Name        //= '*undef*'; $Name        =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Sysid       //= '*undef*'; $Sysid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Pubid       //= '*undef*'; $Pubid       =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Internal    //= '*undef*'; $Internal    =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "DOCT Nam=[$Name], Sys=[$Sysid], Pub=[$Pubid], Int=[$Internal]";
}

sub handle_DoctypeFin { # 17. DoctypeFin      (Expat)
    my ($Expat) = @_;


    push @result, "DOCF";
}

sub handle_XMLDecl { # 18. XMLDecl         (Expat, Version, Encoding, Standalone)
    my ($Expat, $Version, $Encoding, $Standalone) = @_;

    $Version     //= '*undef*'; $Version     =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Encoding    //= '*undef*'; $Encoding    =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;
    $Standalone  //= '*undef*'; $Standalone  =~ s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge;

    push @result, "DECL Ver=[$Version], Enc=[$Encoding], Sta=[$Standalone]";
}

