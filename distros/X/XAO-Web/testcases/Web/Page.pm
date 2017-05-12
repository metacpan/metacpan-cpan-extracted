package testcases::Web::Page;
use strict;
use Encode;
use XAO::Objects;
use XAO::Utils;
use JSON;
use Error qw(:try);
use XAO::Errors qw(XAO::DO::Web::Page XAO::DO::Web::MyPage);

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_expand_with_throw {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $exp1='[TextBefore]';
    my $got1=$page->expand(template => $exp1);

    my $exp2='[A][Prefix][Error:Test Error][Suffix][D]';
    my $got2=$page->expand(
        'template'  => q([A]<%MyAction mode='catch-error' template='[B]<%MyAction mode="throw-error" text="Test Error"%>[C]'%>[D]),
    );

    my $exp3='[TextAfter]';
    my $got3=$page->expand(template => $exp3);

    $self->assert($got1 eq $exp1,
        "Expected text #1 to be '$exp1' got '$got1'");

    $self->assert($got2 eq $exp2,
        "Expected text #2 to be '$exp2' got '$got2'");

    $self->assert($got3 eq $exp3,
        "Expected text #3 to be '$exp3' got '$got3'");
}

###############################################################################

sub test_render_cache {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $have_memcached;
    eval {
        require Memcached::Client;
        $have_memcached=1;
    };
    if($@) {
        eval {
            require Cache::Memcached;
            $have_memcached=1;
        };
    }

    # Setting up the cache
    #
    $page->siteconfig->put('/xao/page/render_cache_name' => 'xao_render_cache');
    $page->siteconfig->put('/xao/page/render_cache_allow' => {
        'p:/bits/system-test'       => 1,
        'p:/bits/test-recurring'    => 'on',
        'p:/bits/test-unicode'      => { param  => [ '*','!*' ] },
    });

    $self->assert($page->siteconfig->get('/xao/page/render_cache_name'),
        "Failed to modify site configuration");

    $page->siteconfig->put('/cache' => {
        memcached   => {
            servers => [ '127.0.0.1:11211' ],
        },
        config => {
            common => {
                ($have_memcached ? (backend => 'Cache::Memcached') : ()),
                ### debug   => 1,
            },
        },
    });

    $page->render_cache_clear();

    foreach my $path (qw(/bits/system-test /bits/test-recurring /bits/test-unicode)) {
        my $text1=$page->expand(
            path    => $path,
            RUN     => 'foo',
            TEST    => 'test',
        );

        $self->assert(defined $text1,
            "Got undef for text1");

        $self->assert(!utf8::is_utf8($text1),
            "Expected to get bytes, got UNICODE for text1");

        ### dprint "path=$path text=$text1 utf8=".Encode::is_utf8($text1);

        my $text2=$page->expand(
            path    => $path,
            RUN     => 'foo',
            TEST    => 'test',
        );

        ### dprint "path=$path text=$text2 utf8=".Encode::is_utf8($text1);

        $self->assert(defined $text2,
            "Got undef for text2");

        $self->assert(!utf8::is_utf8($text2),
            "Expected to get bytes, got UNICODE for text2");

        $self->assert($text1 eq $text2,
            "Expected to get identical text, got '$text1' != '$text2'");

        my $text3=$page->expand(
            path    => $path,
            RUN     => 'foo',
            TEST    => 'test',
        );

        ### dprint "path=$path text=$text3 utf8=".Encode::is_utf8($text1);

        $self->assert(defined $text3,
            "Got undef for text3");

        $self->assert(!utf8::is_utf8($text3),
            "Expected to get bytes, got UNICODE for text3");

        $self->assert($text1 eq $text3,
            "Expected to get identical text, got '$text1' != '$text3'");
    }
}

###############################################################################

sub test_params_digest {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    # Checking how parameters are processed
    #
    my @ptests=(
        {   setup       => {
                param       => { foo => 'bar', path => '/bits/foo' },
            },
            spec        => '1',
            expect      => q(["/bits/foo",null,{"foo":"bar"},null,null,null]),
        },
        {   setup       => {
                param       => { foo => 'bar', 'xao.cacheable' => 'on' },
            },
            spec        => undef,
            expect      => q([null,null,{"foo":"bar","xao.cacheable":"on"},null,null,null]),
        },
        {   setup       => {
                param       => { foo => 'bar' },
                cgi         => { cgiparam => 'cgivalue', cgimult => [ 'p1','p2','p3' ] },
                cookie      => { sugar => 'cane' },
            },
            spec        => '1',
            expect      => q([null,null,{"foo":"bar"},null,null,null]),
        },
        {   setup       => {
                param       => { foo => 'bar', template => 'foo' },
                cgi         => { cgiparam => 'cgivalue', cgimult => [ 'p1','p2','p3' ] },
                cookie      => { sugar => 'cane' },
            },
            spec        => {
                param       => [ '*' ],
                cgi         => [ '*' ],
                cookie      => [ '*' ],
            },
            expect      => q([null,"foo",{"foo":"bar"},{"cgimult":["p1","p2","p3"],"cgiparam":["cgivalue"]},{"sugar":"cane"},null]),
        },
        {   setup       => {
                param       => { foo => 'bar', moo => 'cow', template => 'Template', path => '/bits/foo-bar' },
                cgi         => { cgiparam => 'cgivalue', cgimult => [ 'p1','p2','p3' ] },
                cookie      => { sugar => 'cane', 'choco' => 'late' },
            },
            spec        => {
                param       => [ '*','!m*' ],
                cgi         => [ '*','!cgim*' ],
                cookie      => [ '*','!su*' ],
            },
            expect      => q(["/bits/foo-bar","Template",{"foo":"bar"},{"cgiparam":["cgivalue"]},{"choco":"late"},null]),
        },
        {   setup       => {
                param       => { foo => 'bar', moo => 'cow' },
                cgi         => { cgiparam => 'cgivalue', cgimult => [ 'p1','p2','p3' ] },
                cookie      => { sugar => 'cane', 'choco' => 'late' },
            },
            spec        => {
                param       => [ '*','!moo' ],
                cgi         => [ '*','!cgimult' ],
                cookie      => [ '*','!sugar' ],
            },
            expect      => q([null,null,{"foo":"bar"},{"cgiparam":["cgivalue"]},{"choco":"late"},null]),
        },
        {   setup       => {
                param       => { foo => 'bar', moo => 'cow' },
                cgi         => { cgiparam => 'cgivalue', cgimult => [ 'p1','p2','p3' ] },
                cookie      => { sugar => 'cane', 'choco' => 'late' },
            },
            spec        => {
                param       => [ 'moo' ],
                cgi         => [ 'cgiparam' ],
                cookie      => [ 'choco' ],
            },
            expect      => q([null,null,{"moo":"cow"},{"cgiparam":["cgivalue"]},{"choco":"late"},null]),
        },
        {   setup       => {
                param       => { foo => 'bar', boo => 'baz' },
            },
            spec        => { param => [ 'f*' ], proto => 1 },
            expect      => q([null,null,{"foo":"bar"},null,null,"http"]),
        },
    );

    foreach my $ptest (@ptests) {
        $self->siteconfig->cleanup();
        $self->siteconfig->embedded('web')->enable_special_access();

        my $setup_cookie=$ptest->{'setup'}->{'cookie'} || { };
        my $baked='';
        while(my ($k,$v) = each %$setup_cookie) {
            $baked.="$k=$v; ";
        }
        $ENV{'HTTP_COOKIE'}=$baked;

        my $spec_json=to_json($ptest->{'spec'},{ canonical => 1, allow_nonref => 1, utf8 => 1 });
        dprint "Test $spec_json";

        my $cgi=XAO::Objects->new(objname => 'CGI');
        $self->siteconfig->cgi($cgi);

        my $setup_cgi=$ptest->{'setup'}->{'cgi'} || { };
        while(my ($k,$v) = each %$setup_cgi) {
            if(ref $v) {
                $cgi->param(-name => $k, -values => $v);
            }
            else {
                $cgi->param(-name => $k, -value => $v);
            }
        }

        my $params=$ptest->{'setup'}->{'param'} || { };

        ### dprint "..cgi:    ".$page->cgi->query_string;
        ### dprint "..cookie: ".join(';',@{$page->siteconfig->cookies});
        ### dprint "..param:  ".to_json($params,{ canonical => 1, utf8 => 1 });

        my $params_digest_1=$page->params_digest($params,$ptest->{'spec'});

        $self->assert($params_digest_1 && length($params_digest_1)>=40,
            "Expected a digest, got '$params_digest_1'");

        my ($params_digest_2,$params_json)=$page->params_digest($params,$ptest->{'spec'});

        ### dprint " --> $params_digest_2 // $params_json";

        $self->assert($params_digest_2 && length($params_digest_2)>=40,
            "Expected a digest, got '$params_digest_2'");

        $self->assert($params_digest_1 eq $params_digest_2,
            "Expected the same digest on scalar and array calls ($params_digest_1 != $params_digest_2)");

        $self->assert(defined $params_json,
            "Expected a defined JSON digest for '$spec_json'");

        $self->assert($params_json eq $ptest->{'expect'},
            "Expected '$ptest->{'expect'}', got '$params_json' for '$spec_json'");
    }
}

###############################################################################

sub test_cgi_param_charsets {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $cgi=$page->cgi;
    $self->assert(ref($cgi),
                  "Can't get page->cgi");

    $self->assert($cgi->isa('XAO::DO::CGI'),
                  "Expected CGI to be XAO::DO::CGI, got ".ref($cgi));

    $self->assert($cgi->get_param_charset eq 'UTF-8',
                  "Expected cgi->get_param_charset to return 'UTF-8', got '".($cgi->get_param_charset || '<UNDEF>')."'");

    my $ucode=$cgi->param('ucode');
    $self->assert($ucode ne '',
                  "Expected to have a ucode param from base.pm");

    $self->assert(Encode::is_utf8($ucode),
                  "Expected ucode to be perl UTF-8");

    my %tests=(
        t1  => {
            name        => 'ucode',
            expect      => 'unicode',
        },
        t2  => {
            name        => 'foo',
            expect      => 'unicode',
        },
        t3  => {
            name        => 'ucode',
            expect      => 'data',
            no_charset  => 1,
        },
        t4  => {
            name        => 'foo',
            expect      => 'data',
            no_charset  => 1,
        },
    );

    foreach my $tname (keys %tests) {
        my $test=$tests{$tname};
        my $template="<\%Unicode name='$test->{name}'%>";

        my $got;
        if($test->{'no_charset'}) {
            my $c=$page->cgi->set_param_charset(undef);
            $got=$page->expand(template => $template);
            $page->cgi->set_param_charset($c);
        }
        else {
            $got=$page->expand(template => $template);
        }

        my $expect=$test->{'expect'};
        $self->assert($got eq $expect,
                      "Test $tname - expected '$expect', got '$got'");
    }
}

###############################################################################

sub test_pass {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $template_simple=<<'EOT';
<%Page
  template={'<%SetArg name='FOO' value='IN'%><$FOO$>'}
  pass
%><%End%>
EOT

    my $template_star=<<'EOT';
<%Page
  template={'<%SetArg name='FOO' value='IN'%><$FOO$>'}
  pass='*'
%><%End%>
EOT

    my $template_map=<<'EOT';
<%Page
  template={'<%SetArg name='VAR' value='DEFAULT'%><$VAR$>'}
  pass="VAR=<$VARNAME$>"
%><%End%>
EOT

    my $template_map2=<<'EOT';
<%Page
  template={'<%SetArg name='VAR' value='DEFAULT'
             %><%SetArg name='VAR.ONE' value='DEFAULT.ONE'
             %><%SetArg name='VAR.TWO' value='DEFAULT.TWO'
             %><%SetArg name='OUTSIDE' value='DEFAULT-OUTSIDE'
             %><$VAR$>/<$VAR.ONE$>/<$VAR.TWO$>/<$OUTSIDE$>'}
  pass="<$PASS$>"
%><%End%>
EOT

    my %tests=(
       t01 => {
           args        => {
               template    => $template_simple,
           },
           expect      => 'IN',
       },
       t02 => {
           args        => {
               template    => $template_simple,
               FOO         => 'OUT',
           },
           expect      => 'OUT',
       },
       t03 => {
           args        => {
               template    => $template_star,
           },
           expect      => 'IN',
       },
       t04 => {
           args        => {
               template    => $template_star,
               FOO         => 'OUT',
           },
           expect      => 'OUT',
       },
       t10 => {
           args        => {
               template    => $template_map,
               FOO         => 'FOOVALUE',
               BAR         => 'BARVALUE',
               VARNAME     => 'FOO',
           },
           expect      => 'FOOVALUE',
       },
       t11 => {
           args        => {
               template    => $template_map,
               FOO         => 'FOOVALUE',
               BAR         => 'BARVALUE',
               VARNAME     => 'BAR',
           },
           expect      => 'BARVALUE',
       },
       t12 => {
           args        => {
               template    => $template_map,
               FOO         => 'FOOVALUE',
               BAR         => 'BARVALUE',
               VARNAME     => 'NONEXIST',
           },
           expect      => 'DEFAULT',
       },
        t20 => {
            args        => {
                template    => $template_map2,
                'PASS'      => 'VAR=FOO;VAR.*=BAR.*',
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/DEFAULT-OUTSIDE',
        },
        t21 => {
            args        => {
                template    => $template_map2,
                'PASS'      => 'VAR = FOO ; VAR.*=BAR.* ;*',        # * after
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/DEFAULT-OUTSIDE',
        },
        t22 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*;  VAR = FOO ;VAR.*=  BAR.* ; ;',        # * before
                'FOO'       => 'FOOVALUE',
                'FOO.ONE'   => 'FOO.ONEVALUE',
                'FOO.TWO'   => 'FOO.TWOVALUE',
                'BAR'       => 'BARVALUE',
                'BAR.ONE'   => 'BAR.ONEVALUE',
                'BAR.TWO'   => 'BAR.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/BAR.ONEVALUE/BAR.TWOVALUE/OUT-VALUE',
        },
        t23 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR=FOO; !OUTSIDE;',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/FOO.ONEVALUE/DEFAULT.TWO/DEFAULT-OUTSIDE',
        },
        t24 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR=FOO; !OUTSIDE; !VAR.*',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'VAR.TWO'   => 'FOO.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'FOOVALUE/DEFAULT.ONE/DEFAULT.TWO/DEFAULT-OUTSIDE',
        },
        t25 => {
            args        => {
                template    => $template_map2,
                'PASS'      => '*; VAR.*=FOO.*; !VAR.T*',
                'FOO'       => 'FOOVALUE',
                'VAR.ONE'   => 'FOO.ONEVALUE',
                'VAR.TWO'   => 'FOO.TWOVALUE',
                'OUTSIDE'   => 'OUT-VALUE',
            },
            expect      => 'DEFAULT/FOO.ONEVALUE/DEFAULT.TWO/OUT-VALUE',
        },
        t26 => {
            args        => {
                template    => <<'EOT',
<%Page
  template={'<%SetArg name='V1' value='V1-DEFAULT'
             %><%SetArg name='V2' value='V2-DEFAULT'
             %><%SetArg name='V3' value='V3-DEFAULT'
             %><$V1$>/<$V2$>/<$V3$>'}
  pass="<$PASS$>"
  V2='V2-INTERNAL'
%><%End%>
EOT
                'PASS'      => '*=FOO.*;!V3',
                'FOO'       => 'FOOVALUE',
                'FOO.V1'    => 'V1-FOO',
                'FOO.V2'    => 'V2-FOO',
                'FOO.V3'    => 'V3-FOO',
            },
            expect      => 'V1-FOO/V2-INTERNAL/V3-DEFAULT',
        },
        t27 => {
            args        => {
                template    => <<'EOT',
<%Page
  template={'<%SetArg name='V1' value='V1-DEFAULT'
             %><%SetArg name='V2' value='V2-DEFAULT'
             %><%SetArg name='V3' value='V3-DEFAULT'
             %><$V1$>/<$V2$>/<$V3$>'}
  pass="<$PASS$>"
  V2='V2-INTERNAL'
%><%End%>
EOT
                'PASS'      => '*=*.FOO;!V1',
                'V1.FOO'    => 'V1-FOO',
                'V2.FOO'    => 'V2-FOO',
                'V3.FOO'    => 'V3-FOO',
            },
            expect      => 'V1-DEFAULT/V2-INTERNAL/V3-FOO',
        },
        t28 => {
            args        => {
                template    => <<'EOT',
<%Page
  template={'<%SetArg   name='FOO.OLD'  value='FOO-OLD-DEFAULT'
             %><%SetArg name='FOO.NEW'  value='FOO-NEW-DEFAULT'
             %><%SetArg name='FOO.V1'   value='FOO-V1-DEFAULT'
             %><%SetArg name='BAR.OLD'  value='BAR-OLD-DEFAULT'
             %><%SetArg name='BAR.NEW'  value='BAR-NEW-DEFAULT'
             %><%SetArg name='BAR.V1'   value='BAR-V1-DEFAULT'
             %><$FOO.OLD$>/<$FOO.NEW$>/<$FOO.V1$>/<$BAR.OLD$>/<$BAR.NEW$>/<$BAR.V1$>'}
  pass="<$PASS$>"
  V2='V2-INTERNAL'
%><%End%>
EOT
                'PASS'          => '*=ADDR_*;!*.OLD;*.NEW=ADDR_*.OLD;!BAR.V*',
                'ADDR_FOO.OLD'  => 'FOO-OLD-PASS',
                'ADDR_FOO.V1'   => 'FOO-V1-PASS',
                'ADDR_BAR.OLD'  => 'BAR-OLD-PASS',
                'ADDR_BAR.V1'   => 'BAR-V1-PASS',
            },
            expect      => 'FOO-OLD-DEFAULT/FOO-OLD-PASS/FOO-V1-PASS/BAR-OLD-DEFAULT/BAR-OLD-PASS/BAR-V1-DEFAULT',
        },
        t29 => {
            args        => {
                template    => <<'EOT',
<%Page
  template={'<%SetArg name='RV_A' value='A-DEFAULT'
             %><%SetArg name='RV_BC' value='BC-DEFAULT'
             %><%SetArg name='RV_D' value='D-DEFAULT'
             %><$RV_A$>/<$RV_BC$>/<$RV_D$>'}
  pass="<$PASS$>"
%><%End%>
EOT
                'PASS'      => 'RV_*=RV_*_X',
                'RV_A_X'    => 'A-X',
                'RV_A_Y'    => 'A-Y',
                'RV_A_XX'   => 'A-XX',
                'RV_A_YY'   => 'A-YY',
                'RV_BC_X'   => 'BC-X',
                'RV_BC_Y'   => 'BC-Y',
                'RV_D_XX'   => 'D-XX',
            },
            expect      => 'A-X/BC-X/D-DEFAULT',
        },
    );

    foreach my $tname (keys %tests) {
        my $args=$tests{$tname}->{'args'};

        my $got=$page->expand($args);
        my $expect=$tests{$tname}->{'expect'};

        $self->assert($got eq $expect,
                      "In test '$tname' expected '$expect', got '$got'");
    }
}

###############################################################################

sub test_unicode_transparency {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    ##
    # Explanation: This is probably going to change in the future, but
    # for right now we assume that the template engine operates on
    # bytes, not characters. Thus we expect bytes back even when we
    # supply unicode.
    #
    # TODO: The better way is probably to define an encoding for input/output
    # text somewhere and always convert from that encoding to UTF and
    # back whenever we cross the border between templates and perl code.
    #
    my %tests=(
        t1  => {
            template    => "unicode - \x{263a} - ttt",
            expect      => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
        },
        t2  => {
            template    => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
            expect      => Encode::encode('utf8',"unicode - \x{263a} - ttt"),
        },
        t3  => {
            template    => Encode::encode('ucs2',"unicode - \x{263a} - ttt"),
            expect      => Encode::encode('ucs2',"unicode - \x{263a} - ttt"),
        },
        t4 => {
            template    => "8bit - \x90\x91\x92",
            expect      => "8bit - \x90\x91\x92",
        },
        t5 => {
            template    => '<%SetArg name="A" value="<$BAR/f$>"%>foo<$A$>',
            BAR         => "<\x{263a}>",
            expect      => Encode::encode('utf8',"foo<\x{263a}>"),
        },
    );

    foreach my $test (keys %tests) {
        my $template=$tests{$test}->{'template'};
        my $got=$page->expand($tests{$test});
        my $expect=$tests{$test}->{'expect'};
        ### dprint "length(template=$template)=".length($template);
        ### dprint "length(got=$got)=".length($got);
        ### dprint "length(expect=$expect)=".length($expect);
        $self->assert($got eq $expect,
                      "Test $test - expected '$expect', got '$got'");
    }
}

sub test_expand {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $str='\'"!@#$%^&*()_-=[]\\<>? ';
    my %ttt=(
        '<$TEST$>'      => $str,
        '<$TEST/h$>'    => '\'"!@#$%^&amp;*()_-=[]\\&lt;&gt;? ',
        '<$TEST/f$>'    => '\'&quot;!@#$%^&amp;*()_-=[]\\&lt;&gt;? ',
        '<$TEST/q$>'    => '\'%22!@%23$%25^%26*()_-%3d[]\\%3c%3e%3f%20',
        '<$TEST/u$>'    => '\'%22!@%23$%25^%26*()_-%3d[]\\%3c%3e%3f%20',
        '<$TEST/j$>'    => '\\\'\\"!@#$%^&*()_-=[]\\\\<>? ',
    );
    foreach my $template (keys %ttt) {
        my $got=$page->expand(template => $template,
                              TEST => $str);
        $self->assert($got eq $ttt{$template},
                      "Wrong value for $template ('$got' ne '$ttt{$template}'");
    }

    my $got=$page->expand(path => '/system.txt',
                          TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?][TEST&lt;&gt;?]]',
                  "Got wrong value for /system.txt: $got");

    $got=$page->expand(path => '/local.txt',
                       TEST => 'TEST<>?');
    $self->assert($got eq 'system:[[TEST<>?]{TEST&lt;&gt;?}]',
                  "Got wrong value for /local.txt: $got");

    my %matrix=(
        '123' => {
            template => q(<%Page
                            template={'<%Page template="<%TEST%>"%>'}
                            TEST='123'
                          %>),
        },
        '1234' => {
            template => q(<%Page
                            template={'<%Page template="<$TEST$>"%>'}
                            TEST='1234'
                          %>),
        },
    );
    foreach my $expect (keys %matrix) {
        my $args=$matrix{$expect};
        my $got=$page->expand($args);
        $self->assert($got eq $expect,
                      "Expected '$expect', got '$got'");
    }
}

sub test_fs {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $odb=$page->odb;
    $self->assert(ref($odb),
                  "Can't get database reference from Page");
}

sub test_web {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $cgi=$page->cgi;
    $self->assert(ref($cgi),
                  "Can't get CGI reference from Page");
}

sub test_end {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $got=$page->expand(template => 'AAA<%End%>BBB');
    my $expect='AAA';
    $self->assert($got eq $expect,
                  "<%End%> does not work, got '$got' instead of '$expect'");
}

sub test_throw {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

    my $error='';
    try {
        $page->throw("test - test error");
        $error="not really throwed an error";
    }
    catch XAO::E::DO::Web::MyPage with {
        # Ok!
    }
    catch XAO::E::DO::Web::Page with {
        $error="caught E...Page instead of E...MyPage";
    }
    otherwise {
        my $e=shift;
        $error="cought some unknown error ($e) instead of expected E...MyPage";
    };

    $self->assert(!$error,
                  "Page::throw error - $error");
}

###############################################################################

sub test_cache {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

    my $cache_val=123;
    my $cache_sub=sub { return $cache_val++ };

    my $cache=$page->cache(
        name        => 'test',
        retrieve    => $cache_sub,
        coords      => 'name',
        expire      => 60,
    );
    $self->assert(ref($cache),
                  "Can't load Cache object");

    my $got=$cache->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");

    $got=$cache->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");

    my $page1=XAO::Objects->new(objname => 'Web::MyPage');
    $self->assert(ref($page),
                  "Can't load MyPage object");

     my $cache1=$page1->cache(
        name        => 'test',
        retrieve    => $cache_sub,
        coords      => 'name',
        expire      => 60,
    );
    $self->assert(ref($cache1),
                  "Can't load Cache object (Page1)");

    $got=$cache1->get(name => 'foo');
    $self->assert($got == 123,
                  "Wrong value from cache, expected 123, got $got");
}

###############################################################################
1;
