use 5.014;
use warnings;

use Test::More tests => 2661;

my $XML_module = 'XML::Parsepp';

use_ok($XML_module);

my @result;
my $err = '';
my $line_more;
my $line_done;

my $XmlParser = $XML_module->new or die "Error-0010: Can't create $XML_module -> new";

my @Handlers = (
  [  1, Init         => \&handle_Init,         'INIT', occurs =>    0, 'Init         (Expat)'                                            ],
  [  2, Final        => \&handle_Final,        'FINL', occurs =>    0, 'Final        (Expat)'                                            ],
  [  3, Start        => \&handle_Start,        'STRT', occurs =>    0, 'Start        (Expat, Element, @Attr)'                            ],
  [  4, End          => \&handle_End,          'ENDL', occurs =>    0, 'End          (Expat, Element)'                                   ],
  [  5, Char         => \&handle_Char,         'CHAR', occurs =>    0, 'Char         (Expat, String)'                                    ],
  [  6, Proc         => \&handle_Proc,         'PROC', occurs =>    0, 'Proc         (Expat, Target, Data)'                              ],
  [  7, Comment      => \&handle_Comment,      'COMT', occurs =>    0, 'Comment      (Expat, Data)'                                      ],
  [  8, CdataStart   => \&handle_CdataStart,   'CDST', occurs =>    0, 'CdataStart   (Expat)'                                            ],
  [  9, CdataEnd     => \&handle_CdataEnd,     'CDEN', occurs =>    0, 'CdataEnd     (Expat)'                                            ],
  [ 10, Default      => \&handle_Default,      'DEFT', occurs =>    0, 'Default      (Expat, String)'                                    ],
  [ 11, Unparsed     => \&handle_Unparsed,     'UNPS', occurs =>    0, 'Unparsed     (Expat, Entity, Base, Sysid, Pubid, Notation)'      ],
  [ 12, Notation     => \&handle_Notation,     'NOTA', occurs =>    0, 'Notation     (Expat, Notation, Base, Sysid, Pubid)'              ],
  [ 13, Entity       => \&handle_Entity,       'ENTT', occurs =>    0, 'Entity       (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)'   ],
  [ 14, Element      => \&handle_Element,      'ELEM', occurs =>    0, 'Element      (Expat, Name, Model)'                               ],
  [ 15, Attlist      => \&handle_Attlist,      'ATTL', occurs =>    0, 'Attlist      (Expat, Elname, Attname, Type, Default, Fixed)'     ],
  [ 16, Doctype      => \&handle_Doctype,      'DOCT', occurs =>    0, 'Doctype      (Expat, Name, Sysid, Pubid, Internal)'              ],
  [ 17, DoctypeFin   => \&handle_DoctypeFin,   'DOCF', occurs =>    0, 'DoctypeFin   (Expat)'                                            ],
  [ 18, XMLDecl      => \&handle_XMLDecl,      'DECL', occurs =>    0, 'XMLDecl      (Expat, Version, Encoding, Standalone)'             ],
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

my @CList = map { chr($_) } (33..127);

my $rx_unc_tok = qr/["']/xms;
my $rx_tok_tok = qr/[!\$&\/;<=\@\\\^`\{\}~\x7f]/xms;
my $rx_syn_tok = qr/[\#\(\]]/xms;
my $rx_tok_syn = qr/[%)*+?]/xms;
my $rx_syn_syn = qr/[,\-.\w:>\[|]/xms;

my $code = 0;

for my $ch (@CList) { $code++;
    for my $case (0..5) {
        my $cno = ($code - 1) * 6 + $case + 1;

        my $ident = qq{chr = '$ch', code = $code, case = $case};

        my @fragments;
        my $class;

        if ($case == 0) {
            @fragments = ('    ', "  \n  \nABC".$ch."DEF  <root></root>");
            $class = 'middle';
        }
        elsif ($case == 1) {
            @fragments = (qq{ A}.$ch.qq{A <root></root>});
            $class = 'middle';
        }
        elsif ($case == 2) {
            @fragments = (qq{ }.$ch.qq{A <root></root>});
            $class = 'start';
        }
        elsif ($case == 3) {
            @fragments = (qq{ DDD }.$ch.qq{A <root></root>});
            $class = 'snd-s';
        }
        elsif ($case == 4) {
            @fragments = (qq{ D;D Z}.$ch.qq{A <root></root>});
            $class = 'snd-t';
        }
        elsif ($case == 5) {
            @fragments = (
              qq{<?xml version="1.0"?>}.
              qq{<!DOCTYPE svg PUBLIC "-//W3C" "http://www.w3.org">}.
              qq{ }.$ch.qq{A <root></root>});
            $class = 'start';
        }
        else {
            die "Error-0010: Invalid case = $case";
        }

        get_result($XmlParser, @fragments);

        my @expected;

        if ($case == 0) {
            @expected = (
              q{INIT},
              q{DEFT Str=[    ]},
              q{DEFT Str=[  &<0a>  &<0a>]},
            );
        }
        elsif ($case == 5) {
            @expected = (
              'INIT',
              'DECL Ver=[1.0], Enc=[*undef*], Sta=[*undef*]',
              'DOCT Nam=[svg], Sys=[http://www.w3.org], Pub=[-//W3C], Int=[]',
              'DOCF',
              'DEFT Str=[ ]',
            );
        }
        else {
            @expected = (
              q{INIT},
              q{DEFT Str=[ ]},
            );
        }

        my $mtype;

        if ($class eq 'middle') {
            if ($ch =~ $rx_syn_syn or $ch =~ $rx_tok_syn) {
                $mtype = 's';
            }
            elsif ($ch =~ $rx_syn_tok or $ch =~ $rx_tok_tok or $ch =~ $rx_unc_tok) {
                $mtype = 't';
            }
            else {
                $mtype = '?';
            }
        }
        elsif ($class eq 'start') {
            if ($ch =~ $rx_syn_syn or $ch =~ $rx_syn_tok) {
                $mtype = 's';
            }
            elsif ($ch =~ $rx_unc_tok) {
                $mtype = 'u';
            }
            elsif ($ch =~ $rx_tok_syn or $ch =~ $rx_tok_tok) {
                $mtype = 't';
            }
            else {
                $mtype = '?';
            }
        }
        elsif ($class eq 'snd-s') {
            $mtype = 's';
        }
        elsif ($class eq 'snd-t') {
            $mtype = 't';
        }
        else {
            die "Error-5220: invalid class ('$class')";
        }

        my $regexp;

        if ($mtype eq 's') {
            $regexp = qr{syntax \s error}xms;
        }
        elsif ($mtype eq 't') {
            $regexp = qr{not \s well-formed \s \(invalid \s token\)}xms;
        }
        elsif ($mtype eq 'u') {
            $regexp = qr{unclosed \s token}xms;
        }
        elsif ($mtype eq '?') {
            $regexp = qr{zzzzzzzzzzzz}xms;
        }
        else {
            die "Error-5230: invalid mtype ('$mtype'), not one of ('s', 't', 'u', '?')";
        }

        like($err, $regexp, 'Test-'.sprintf('%04d', $cno).'a: error ==> '.$ident);
        is(scalar(@result), scalar(@expected), 'Test-'.sprintf('%04d', $cno).'b: Number of results ==> '.$ident);
        verify(sprintf('%04d', $cno), \@result, \@expected, $ident);
    }
}

# ****************************************************************************************************************************
# ****************************************************************************************************************************
# ****************************************************************************************************************************

sub verify {
    my ($num, $res, $exp, $ident) = @_;

    for my $i (0..$#$exp) {
        is($res->[$i], $exp->[$i], 'Test-'.$num.'c-'.sprintf('%03d', $i).': correct result ==> '.$ident);

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
