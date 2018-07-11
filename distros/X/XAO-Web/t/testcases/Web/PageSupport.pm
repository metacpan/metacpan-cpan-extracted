package testcases::Web::PageSupport;
use strict;
use Data::Dumper;
use XAO::Utils;
use base qw(XAO::testcases::Web::base);

use XAO::PageSupport;

sub test_parse {
    my $self=shift;

    eval 'use Data::Compare';
    if($@) {
        print STDERR "\n" .
                     "Perl extension Data::Compare is not available,\n" .
                     "skipping XAO::PageSupport::parse tests\n";
        return;
    }

    my %matrix=(
        '' => [
        ],
        '0' => [
            {   text    => '0',
            },
        ],
        'aaa' => [
            {   text    => 'aaa',
            },
        ],
        'aaa<%%>bbb' => [
            {   text    => 'aaa<%',
            },
            {   text    => 'bbb',
            }
        ],
        'aaa<$$>bbb' => [
            {   text    => 'aaa<$',
            },
            {   text    => 'bbb',
            },
        ],
        'zzz<$BB/f$>' => [
            {   text    => 'zzz',
            },
            {   varname => 'BB',
                flag    => 'f',
            }
        ],
        'zzz<$BB/f x $>' => 'error',
        '<$BB' => 'error',
        'aaa<%BB/f empty%>xx' => [
            {   text    => 'aaa',
            },
            {   objname => 'BB',
                args    => {
                    empty => [
                        {   text    => 'on',
                        },
                    ],
                },
                flag    => 'f',
            },
            {   text    => 'xx',
            },
        ],
        'aaa<%BB%>' => [
            {   text    => 'aaa',
            },
            {   objname => 'BB',
                args    => {},
            }
        ],
        '<%BB arg=' => 'error',
        '<%BB arg="' => 'error',
        '<%BB/f arg1="value1" arg2=value2 arg3=\'value3\' arg4%>' => [
            {   objname => 'BB',
                args    => {
                    arg1 => [
                        {   text    => 'value1',
                        },
                    ],
                    arg2 => [
                        {   text    => 'value2',
                        },
                    ],
                    arg3 => 'value3',
                    arg4 => [
                        {   text    => 'on',
                        },
                    ],
                },
                flag    => 'f',
            },
        ],
        '<$A$><$ A $><$  A  $><$  A  /f $>|<%A%><% A %><%  A  %><%   A /q%>' => [
            {   varname => 'A',
            },
            {   varname => 'A',
            },
            {   varname => 'A',
            },
            {   varname => 'A',
                flag    => 'f',
            },
            {   text    => '|',
            },
            {   objname => 'A',
                args    => {},
            },
            {   objname => 'A',
                args    => {},
            },
            {   objname => 'A',
                args    => {},
            },
            {   objname => 'A',
                args    => {},
                flag    => 'q',
            },
        ],
        '<%B a="<%D/f da="%>' => 'error',
        '<$A$><%B a1={\'v1\'} a2=<%C/f%> a3={\'<%D/f da="1" db dc={\'<%E%>\'}%>' => 'error',
        '<$A$><%B a1={\'v1\'} a2=<%C/f%> a3={\'<%D/f da="1" db dc={\'<%E%>\'}%>\'}%>' => [
            {   varname => 'A'
            },
            {   objname => 'B',
                args    => {
                    a2 => [
                        {   args    => {},
                            flag    => 'f',
                            objname => 'C'
                        }
                    ],
                    a3 => '<%D/f da="1" db dc={\'<%E%>\'}%>',
                    a1 => 'v1'
                },
            },
        ],
        '<%B a={<%D/f da="%>}%>' => 'error',
        '<%B a={<%D/f da={%>}%>' => 'error',
        '<$$><%B a={<%D/f da={va} db={\'vb\'} dc="<$DC/f$>"%>}%>$>' => [
            {   text    => '<$',
            },
            {   objname => 'B',
                args    => {
                    a => [
                        {   objname => 'D',
                            flag    => 'f',
                            args    => {
                                da => [
                                    {   text    => 'va',
                                    },
                                ],
                                db => 'vb',
                                dc => [
                                    {   varname => 'DC',
                                        flag    => 'f',
                                    },
                                ],
                            },
                        },
                    ],
                },
            },
            {   text    => '$>',
            },
        ],
        '<%Debug text=3%>' => [
            {   objname => 'Debug',
                args    => {
                    text    => [
                        {   text    => '3',
                        }
                    ],
                },
            },
        ],
        '<%Date style="dateonly" gmtime=  {<%VAR/f%>} %>' => [
            {   objname => 'Date',
                args    => {
                    style   => [
                        {   text    => 'dateonly',
                        },
                    ],
                    gmtime  => [
                        {   objname => 'VAR',
                            flag    => 'f',
                            args    => {},
                        },
                    ],
                },
            },
        ],
        q(Text<%End%>Text<%) => [
            {   text    => 'Text',
            },
        ],
        q(<!-- Comment --><%Condition
                            a.cgiparam="printable"
                            a.path="/bits/header-printable"
                            a.pa_ss
                            default.path="/bits/header-normal"
                            default.pass
                          %><!--//javascript-->foo<!--bar-->baz<!--[if IE]>CODE<![endif]--><!--[if (gt IE 9)|!(IE)]><!--><html lang="en"><!--<![endif]--><%End%>Something) => [
            {   objname => 'Condition',
                args    => {
                    'a.cgiparam'    => [
                        {   text    => 'printable',
                        },
                    ],
                    'a.path'        => [
                        {   text    => '/bits/header-printable',
                        },
                    ],
                    'a.pa_ss'        => [
                        {   text    => 'on',
                        },
                    ],
                    'default.path'   => [
                        {   text    => '/bits/header-normal',
                        },
                    ],
                    'default.pass'   => [
                        {   text    => 'on',
                        },
                    ],
                },
            },
            {   text    => '<!--//javascript-->foo' },
            {   text    => 'baz<!--[if IE]>CODE<![endif]--><!--[if (gt IE 9)|!(IE)]><!--><html lang="en"><!--<![endif]-->' },
        ],
        # Sample from the man page
        q(Text <%Object a=A b="B" c={<%C/f ca={CA}%>} d='D' e={'<$E$>'}%>) => [
            {   text    => 'Text ',
            },
            {   objname => 'Object',
                args    => {
                    a => [
                        {   text    => 'A',
                        },
                    ],
                    b => [
                        {   text    => 'B',
                        },
                    ],
                    c => [
                        {   objname => 'C',
                            flag    => 'f',
                            args    => {
                                ca => [
                                    {   text    => 'CA',
                                    },
                                ],
                            },
                        },
                    ],
                    d => 'D',
                    e => '<$E$>',
                },
            },
        ],
    );

    foreach my $template (keys %matrix) {
        my $parsed=XAO::PageSupport::parse($template,0);
        my $expect=$matrix{$template};
        my $rc=ref($expect) ? Compare($expect,$parsed) : !ref($parsed);
        $rc ||
            dprint "========== Expect:",Dumper($expect),
                   "========== Got:",Dumper($parsed);
        $self->assert($rc,
                      "Wrong result for '$template'");
    }
}

###############################################################################

sub test_peek {
    my $self=shift;

    my $text1="t1:{abcdefg}";
    my $text2="t2:{ABCDEFGH}";
    my $text3="t3:{123456789}";

    my $tpsub=sub ($) {
        my $name=shift;
        XAO::PageSupport::push();
        XAO::PageSupport::addtext('foo');
        XAO::PageSupport::addtext('bar');
        XAO::PageSupport::push();
        XAO::PageSupport::addtext('baz');
        my $got=XAO::PageSupport::pop(0);
        $self->assert($got eq 'baz',
            "Expected 'baz', got '$got' ($name-1)");
        $got=XAO::PageSupport::pop(0);
        $self->assert($got eq 'foobar',
            "Expected 'foobar', got '$got' ($name-2)");
    };

    $tpsub->('t0');

    my $bm1=XAO::PageSupport::bookmark();
    ### dprint "..bookmark1=$bm1";

    XAO::PageSupport::addtext($text1);

    my $got1=XAO::PageSupport::peek($bm1,0);

    $self->assert($got1 eq $text1,
        "Expected '$text1', got '$got1' (t1)");

    $tpsub->('t2');

    $got1=XAO::PageSupport::peek($bm1,0);

    $self->assert($got1 eq $text1,
        "Expected '$text1', got '$got1' (t3)");

    my $bm2=XAO::PageSupport::bookmark();
    ### dprint "..bookmark2=$bm2";

    XAO::PageSupport::addtext($text2);

    my $got2=XAO::PageSupport::peek($bm2,0);

    $self->assert($got2 eq $text2,
        "Expected '$text2', got '$got2' (t4)");

    $got1=XAO::PageSupport::peek($bm1,0);

    $self->assert($got1 eq $text1.$text2,
        "Expected '$text1$text2', got '$got1' (t5)");

    $tpsub->('t6');

    $got2=XAO::PageSupport::peek($bm2,0);

    $self->assert($got2 eq $text2,
        "Expected '$text2', got '$got2' (t7)");

    $got1=XAO::PageSupport::peek($bm1,0);

    $self->assert($got1 eq $text1.$text2,
        "Expected '$text1$text2', got '$got1' (t8)");
}

sub test_textadd {
    my $self=shift;

    XAO::PageSupport::reset();

    XAO::PageSupport::addtext("123abcABC");
    XAO::PageSupport::push();
    XAO::PageSupport::addtext("INNER");

    my $inner=XAO::PageSupport::pop(0);
    my $outer=XAO::PageSupport::pop(0);

    $self->assert($inner eq 'INNER',
                  "Inner block is not correct (expected 'INNER', got '$inner')");

    $self->assert($outer eq '123abcABC',
                  "Outer block is not correct (expected '123abcABC', got '$outer'");

    $inner=$outer='';
    for(1..10) {
        XAO::PageSupport::addtext(scalar($_ * 13) x 5);
        XAO::PageSupport::addtext("Before \0 After");
        for(1..10) {
            XAO::PageSupport::addtext(scalar($_ * 29) x 5);
            XAO::PageSupport::push();
            for(1..10) {
                XAO::PageSupport::addtext("ABCdef\200\270\300\370");
                XAO::PageSupport::addtext("\3\2\1\0AFTER");
            }
            $inner.=XAO::PageSupport::pop(0);
        }
    }
    $outer=XAO::PageSupport::pop(0);
    $self->assert(length($inner) == 19000,
                  "Got wrong inner block length");

    my $c1=unpack('%16C*',$inner);
    $self->assert($c1 eq 56136,
                  "Wrong checksum, probably zeroes are not handled correctly");

    $self->assert(length($outer) == 1605,
                  "Got wrong outer block length");

    my $c2=unpack('%16C*',$outer);
    $self->assert($c2 eq 21829,
                  "Wrong checksum for outer");
}

1;
