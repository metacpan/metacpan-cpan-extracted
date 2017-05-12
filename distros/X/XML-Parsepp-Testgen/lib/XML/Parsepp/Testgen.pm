package XML::Parsepp::Testgen;
$XML::Parsepp::Testgen::VERSION = '0.03';
use 5.014;

use strict;
use warnings;

use XML::Parser;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(xml_2_test test_2_xml);

my $template;

sub xml_2_test {
    my ($input, $opts) = @_;

    my $xml = parm_2_text($input);

    my ($xml_def1, $xml_def2) = $xml =~ m{\A (\N*) \n (\N*) \n}xms
      or die "Error-0010: Can't extract xml_defs from '".
      (substr($xml, 0, 50) =~ s{\n}'\\n'xmsgr)."...'";

    unless ($xml_def1 eq '#! Testdata for XML::Parsepp') {
        die "Error-0020: Expected xml_def1 to be '#! Testdata for XML::Parsepp', but found '$xml_def1'";
    }

    unless ($xml_def2 eq '#! Ver 0.01') {
        die "Error-0030: Expected xml_def2 to be '#! Ver 0.01', but found '$xml_def2'";
    }

    # $check_positions = 1 ==> check error-positions of the following form:
    # if ($err =~ m{at \s+ line \s+ (\d+), \s+ column \s+ (\d+), \s+ byte \s+ (\d+) \s+ at \s+}xms)
    my $check_positions = defined($opts) ? $opts->{'chkpos'} : 0;

    my @HList = (
      [ 'Init',         'INIT', '(Expat)'                                          ],
      [ 'Final',        'FINL', '(Expat)'                                          ],
      [ 'Start',        'STRT', '(Expat, Element, @Attr)'                          ],
      [ 'End',          'ENDL', '(Expat, Element)'                                 ],
      [ 'Char',         'CHAR', '(Expat, String)'                                  ],
      [ 'Proc',         'PROC', '(Expat, Target, Data)'                            ],
      [ 'Comment',      'COMT', '(Expat, Data)'                                    ],
      [ 'CdataStart',   'CDST', '(Expat)'                                          ],
      [ 'CdataEnd',     'CDEN', '(Expat)'                                          ],
      [ 'Default',      'DEFT', '(Expat, String)'                                  ],
      [ 'Unparsed',     'UNPS', '(Expat, Entity, Base, Sysid, Pubid, Notation)'    ],
      [ 'Notation',     'NOTA', '(Expat, Notation, Base, Sysid, Pubid)'            ],
    # [ 'ExternEnt',    'EXEN', '(Expat, Base, Sysid, Pubid)'                      ],
    # [ 'ExternEntFin', 'EXEF', '(Expat)'                                          ],
      [ 'Entity',       'ENTT', '(Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)' ],
      [ 'Element',      'ELEM', '(Expat, Name, Model)'                             ],
      [ 'Attlist',      'ATTL', '(Expat, Elname, Attname, Type, Default, Fixed)'   ],
      [ 'Doctype',      'DOCT', '(Expat, Name, Sysid, Pubid, Internal)'            ],
      [ 'DoctypeFin',   'DOCF', '(Expat)'                                          ],
      [ 'XMLDecl',      'DECL', '(Expat, Version, Encoding, Standalone)'           ],
    );

    my %HSub;

    my $replm = q!s{([\x00-\x1f\[\]])}{sprintf('&<%02x>', ord($1))}xmsge!;

    my $i = 0;
    for my $hl (@HList) { $i++;
        my $func_body = '';

        my @vlist = split m{,}xms, $hl->[2] =~ s{[\s\(\)]}''xmsgr;
        for my $vl (@vlist) {
            $vl = '$'.$vl unless $vl =~ m{\A \@}xms;
        }

        $func_body .= "{ # ".sprintf('%2d', $i).". ".sprintf('%-15s', $hl->[0])." ".$hl->[2]."\n";
        $func_body .= "    my (".join(', ', @vlist).") = \@_;\n\n";

        my $has_array = 0;
        my $j = 0;
        for my $vl (@vlist) { $j++;
            next if $j == 1;
            if ($vl =~ m{\A \@}xms) {
                $has_array = 1;
                $func_body .= "    for my \$a ($vl) {\n";
                $func_body .= "        \$a //= '*undef*'; \$a =~ $replm;\n";
                $func_body .= "    }\n";
            }
            else {
                $func_body .= "    ".sprintf('%-12s', $vl)." //= '*undef*'; ".sprintf('%-12s', $vl).' =~ '.$replm.";\n";
            }
        }

        $func_body .= "\n";

        $func_body .= qq!    local \$" = "], [";\n! if $has_array;
        $func_body .= qq!    push \@result, "!.$hl->[1];

        $j = 0;
        for my $vl (@vlist) { $j++;
            next if $j == 1;
            $func_body .= qq!,! unless $j == 2;
            $func_body .= ' '.substr($vl, 1, 3)."=[$vl]";
        }
        $func_body .= qq!";\n!;
        $func_body .= qq!}\n!;

        $HSub{$hl->[0]} = $func_body;
    }

    my @result;
    my $err = '';

    my @HParam;
    for my $hl (@HList) {
        my $handler = eval 'sub '.$HSub{$hl->[0]};

        if ($@) {
            die "Error-0040: Can't eval 'sub ".$HSub{$hl->[0]}."' because $@";
        }

        unless (ref($handler) eq 'CODE') {
            die "Error-0050: Expected ref(handler) = 'CODE', but found '".ref($handler)."'";
        }

        push @HParam, $hl->[0], $handler;
    }

    my $XmlParser = XML::Parser->new or die "Error-0060: Can't create XML::Parser -> new";
    $XmlParser->setHandlers(@HParam);

    my @current;
    my @RList;

    for (split m{\n}xms, $xml) {
        if (m{\A \s* \#! (.*) \z}xms) {
            my $remark = $1;

            if ($remark =~ m{\A \s* =+ \s* \z}xms) {
                push @RList, { xml => [@current] } if @current;
                @current = ();
            }
        }
        else {
            s{\s+ \z}''xms;
            push @current, $_;
        }
    }

    push @RList, { xml => [@current] } if @current;

    my %HitCount = map { $_->[1] => 0 } @HList;

    my $TestCount = @HList + 1;

    for my $rl (@RList) {
        # get_result($XmlParser, map {"$_\n"} @{$rl->{xml}});

        @result = ();
        $err = '';

        my $ExpatNB = $XmlParser->parse_start or die "Error-0070: Can't create XML::Parser -> parse_start";

        eval {
            for my $buf (map {"$_\n"} @{$rl->{xml}}) {
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

        $rl->{err} = $err;
        $rl->{res} = [@result];

        $TestCount += 2 + @result;

        unless ($err eq '') {
            $err =~ m{at \s+ line \s+ (\d+), \s+ column \s+ (\d+), \s+ byte \s+ (\d+) \s+ at \s+}xms
              or die "Error-0080: Can't decompose error-line '$err'";

            $rl->{e_line}  = $1;
            $rl->{e_col}   = $2;
            $rl->{e_bytes} = $3;

            if ($check_positions) {
                $TestCount += 3;
            }
        }

        for my $res (@result) {
            my $word = !defined($res) ? '!!!!' : $res =~ m{\A (\w{4}) }xms ? $1 : '????';
            $HitCount{$word}++;
        }
    }

    my $result = '';

    open my $ofh, '>', \$result or die "Error-0090: Can't open > '\\\$result' because $!";

    for (split m{\n}xms, $template) {
        if (m{\A \s* %}xms) {
            m{\A %include \s+ (\w+) \z}xms
              or die "Error-0100: Can't parse %include from '$_'";

            my $subject = $1;

            if ($subject eq 'test_more') {
                say {$ofh} "use Test::More tests => $TestCount;"
            }
            elsif ($subject eq 'handlers') {
                my $ctr = 0;
                for my $hl (@HList) { $ctr++;
                    printf {$ofh} "  [%3d, %-12s => \\&handle_%-13s %-6s, occurs => %4d, %-65s ],\n",
                      $ctr, $hl->[0], $hl->[0].',', "'$hl->[1]'", $HitCount{$hl->[1]}, sprintf("'%-12s %s'", $hl->[0], $hl->[2]);
                }
            }
            elsif ($subject eq 'cases') {
                say {$ofh} '# No of get_result is ', scalar(@RList);
                say {$ofh} '';

                my $tno = 0;
                for my $rl (@RList) { $tno++;
                    say {$ofh} '{';
                    say {$ofh} '    get_result($XmlParser,';

                    for my $lx (@{$rl->{xml}}) {
                        if ($lx =~ m![\\{}]!xms) {
                            die "Error-0110: Found invalid character in xml line '$lx'";
                        }
                        say {$ofh} "               q{$lx}.qq{\\n},";
                    }

                    say {$ofh} '    );';
                    say {$ofh} '';

                    say {$ofh} '    my @expected = (';

                    for my $ls (@{$rl->{res}}) {
                        if ($ls =~ m![\\{}]!xms) {
                            die "Error-0120: Found invalid character in result line '$ls'";
                        }
                        say {$ofh} "        q{$ls},";
                    }

                    say {$ofh} '    );';
                    say {$ofh} '';

                    my $ecode = $rl->{err};

                    if ($ecode eq '') {
                        say {$ofh} q{    is($err, '', 'Test-}, sprintf('%03d', $tno), q{a: No error');};
                    }
                    else {
                        $ecode =~ m{\A (.*?) \s+ at \s+ line \s+ \d+}xms
                          or die "Error-0130: Can't parse message from ecode = '$ecode'";

                        my $emsg = $1;

                        $emsg =~ s{\A \s+}''xms;
                        $emsg =~ m{\A [\w\s()\-]* \z}xms
                          or die "Error-0140: Found invalid character in message = '$emsg'";

                        $emsg =~ s{\s+}' \\s+ 'xmsg;
                        $emsg =~ s{([()])}"\\$1"xmsg;

                        say {$ofh} q!    like($err, qr{!, $emsg, q!}xms, 'Test-!, sprintf('%03d', $tno), q!a: error');!;

                        if ($check_positions) {
                            say {$ofh} q!!;
                            say {$ofh} q!    my $e_line  = -1;!;
                            say {$ofh} q!    my $e_col   = -1;!;
                            say {$ofh} q!    my $e_bytes = -1;!;
                            say {$ofh} q!!;
                            say {$ofh} q!    if ($err =~ m{at \s+ line \s+ (\d+), \s+ column \s+ (\d+), \s+ byte \s+ (\d+) \s+ at \s+}xms) {!;
                            say {$ofh} q!        $e_line  = $1;!;
                            say {$ofh} q!        $e_col   = $2;!;
                            say {$ofh} q!        $e_bytes = $3;!;
                            say {$ofh} q!    }!;
                            say {$ofh} q!!;
                            say {$ofh} q!    is($e_line,  !.sprintf('%4d', $rl->{e_line}) .q!, 'Test-!, sprintf('%03d', $tno), q!v1: error - lineno');!;
                            say {$ofh} q!    is($e_col,   !.sprintf('%4d', $rl->{e_col})  .q!, 'Test-!, sprintf('%03d', $tno), q!v2: error - column');!;
                            say {$ofh} q!    is($e_bytes, !.sprintf('%4d', $rl->{e_bytes}).q!, 'Test-!, sprintf('%03d', $tno), q!v3: error - bytes');!;
                            say {$ofh} q!!;
                        }
                    }

                    say {$ofh} q{    is(scalar(@result), scalar(@expected), 'Test-}, sprintf('%03d', $tno), q{b: Number of results');};

                    say {$ofh} q{    verify('}, sprintf('%03d', $tno), q{', \\@result, \\@expected);};

                    say {$ofh} '}';
                    say {$ofh} '';
                }
            }
            elsif ($subject eq 'handles') {
                my $i = 0;
                for my $hl (@HList) { $i++;
                    say {$ofh} 'sub handle_', $hl->[0], ' ', $HSub{$hl->[0]};
                }
            }
            else {
                die "Error-0150: Found invalid %include subject '$subject'";
            }
        }
        else {
            say {$ofh} $_;
        }
    }

    close $ofh;

    return $result;
}

sub test_2_xml {
    my ($input) = @_;

    my $perl = parm_2_text($input);

    my ($def1, $def2, $def3) = $perl =~ m{\A (\N*) \n (\N*) \n (\N*) \n}xms
      or die "Error-0160: Can't extract use-statements from '".
      (substr($perl, 0, 50) =~ s{\n}'\\n'xmsgr)."...'";

    unless ($def1 eq 'use 5.014;') {
        die "Error-0170: Expected def1 to be 'use 5.014;', but found '$def1'";
    }

    unless ($def2 eq 'use warnings;') {
        die "Error-0180: Expected def2 to be 'use warnings;', but found '$def2'";
    }

    unless ($def3 eq '# Generate Tests for XML::Parsepp') {
        die "Error-0190: Expected def3 to be '# Generate Tests for XML::Parsepp', but found '$def3'";
    }

    $perl =~ m{\n\# \s No \s of \s get_result \s is \s (\d+) \n}xms
      or die "Error-0200: Can't find 'No of get_result...'";

    my $gr_count = $1;

    my @gr_list = $perl =~ m{get_result\( (.*?) \);}xmsg;

    unless (@gr_list == $gr_count) {
        die "Error-0210: Found ".scalar(@gr_list)." get_result, but expected $gr_count";
    }

    my $result = '';

    open my $ofh, '>', \$result or die "Error-0220: Can't open > '\\\$result' because $!";

    say {$ofh} '#! Testdata for XML::Parsepp';
    say {$ofh} '#! Ver 0.01';

    for my $i (0..$#gr_list) {
        my $text = $gr_list[$i];

        say {$ofh} '#! ===' unless $i == 0;

        my @lines = split m{\n}xms, $text;

        my $first = shift @lines;

        unless (defined $first) {
            die "Error-0230: Too few elements in lines";
        }

        unless ($first eq '$XmlParser,') {
            die "Error-0240: found first line = >>$first<<, but expected >>\$XmlParser,<<";
        }

        for my $fragment (@lines) {
            next if $fragment =~ m{\A \s* \z}xms;
            my ($gr_xml) = $fragment =~ m/\A \s* q\{ ([^\}]*) \}\.qq\{\\n\}, \s* \z/xms
              or do {
                  local $" = "<<, >>";
                  die "Error-0250: Can't parse fragment q{...} >>$fragment<<, all lines are (>>@lines<<)";
              };

            say {$ofh} $gr_xml;
        }
    }

    close $ofh;

    return $result;
}

sub parm_2_text {
    my ($inp) = @_;

    my $data;
    if (ref($inp)) {
        if (ref($inp) eq 'GLOB') {
            $data = do { local $/; <$inp>; };
        }
        else {
            $data = $$inp;
        }
    }
    else {
        open my $fh, '<', $inp or die "Error-0260: Can't open < '$inp' because $!";
        $data = do { local $/; <$fh>; };
    }

    return $data;
}

$template = <<'EOTXT';
use 5.014;
use warnings;
# Generate Tests for XML::Parsepp

%include test_more

my $XML_module = 'XML::Parsepp';

use_ok($XML_module);

my @result;
my $err = '';
my $line_more;
my $line_done;

my $XmlParser = $XML_module->new or die "Error-0010: Can't create $XML_module -> new";

my @Handlers = (
%include handlers
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

%include cases
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

%include handles
EOTXT

1;

__END__

=head1 NAME

XML::Parsepp::Testgen - Generate testcases for XML::Parsepp

=head1 SYNOPSIS

XML::Parsepp::Testgen uses XML::Parser to generate testcases. xml_2_test
converts from XML to testfiles. The input ist a list of XML documents,
separated by the special line "#! ===". The output is a valid test script.

The inverse function is also available: test_2_xml takes a previously generated
testfile and extracts the original XML.

  use XML::Parsepp::Testgen qw(xml_2_test test_2_xml);

=head1 xml_2_test

=head2 xml_2_test (string)

Here is an example to convert from a fixed string xml:

  use XML::Parsepp::Testgen qw(xml_2_test);

  my $xml =
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

  print xml_2_test(\$xml);

=head2 xml_2_test (file name)

If your xml is in an external file, you can convert that, too:

  use XML::Parsepp::Testgen qw(xml_2_test);

  print xml_2_test('data.xml');

=head2 xml_2_test (file handle)

Or you have a file handle of a previously opened XML file:

  use XML::Parsepp::Testgen qw(xml_2_test);

  open my $fh, '<', 'data.xml' or die "Error: $!";

  print xml_2_test($fh);

  close $fh;

=head1 test_2_xml

=head2 test_2_xml (string)

Here is an example to convert from a fixed string test script:

  use XML::Parsepp::Testgen qw(test_2_xml);

  my $test =
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

  print test_2_xml(\$test);

=head2 test_2_xml (file name)

If your test script is in an external file, you can convert that, too:

  use XML::Parsepp::Testgen qw(test_2_xml);

  print test_2_xml('test.t');

=head2 xml_2_test (file handle)

Or you have a file handle of a previously opened test file:

  use XML::Parsepp::Testgen qw(test_2_xml);

  open my $fh, '<', 'test.t' or die "Error: $!";

  print test_2_xml($fh);

  close $fh;

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=head1 SEE ALSO

L<XML::Parsepp>,
L<XML::Parser>.

=cut
