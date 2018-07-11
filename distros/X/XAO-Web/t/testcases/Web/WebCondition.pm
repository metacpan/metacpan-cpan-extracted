package testcases::Web::WebCondition;
use strict;
use XAO::Projects;
use CGI::Cookie;

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    $ENV{'HTTP_COOKIE'}='cookie1=cvalue1; cookie2=cvalue2';

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    $page->clipboard->put('cb_foo' => 'bar');
    $page->clipboard->put('cb_zero' => 0);

    my $template=<<'EOT';
<%Condition
  v1.value="<%V1%>"
  v1.template="GOT-V1"
  v2.arg="V2"
  v2.path="/bits/WebCondition/text-v2"
  default.template={<%Page/f path="/bits/WebCondition/text-default"%>}
%><%End%>
EOT

    my %matrix=(
        t1 => {
            args => {
                V1 => 1,
            },
            result => 'GOT-V1',
        },
        t2 => {
            args => {
                V1 => '',
                V2 => ' ',
            },
            result => 'GOT-V2',
        },
        t3 => {
            args => {
                V1 => 'x',
                V2 => 'y',
            },
            result => 'GOT-V1',
        },
        t4 => {
            args => {
                V1 => '',
            },
            result => 'DEFAULT',
        },
        t5 => {
            args => {
                V1 => 0,
                V2 => '000',
            },
            result => 'GOT-V2',
        },
        t6 => {
            args => {
                template => q(<%Condition a.arg='V1=abc' a.template='gV1' default.template='gDF'%>),
                V1 => 'abc',
            },
            result => 'gV1',
        },
        t6gt1 => {
            args => {
                template => q(<%Condition a.arg='V1>2' a.template='gV1' default.template='gDF'%>),
                V1 => '3',
            },
            result => 'gV1',
        },
        t6gt2 => {
            args => {
                template => q(<%Condition a.arg='V1>2' a.template='gV1' default.template='gDF'%>),
                V1 => '1',
            },
            result => 'gDF',
        },
        t6lt1 => {
            args => {
                template => q(<%Condition a.arg='V1<2' a.template='gV1' default.template='gDF'%>),
                V1 => '3',
            },
            result => 'gDF',
        },
        t6lt2 => {
            args => {
                template => q(<%Condition a.arg='V1<2' a.template='gV1' default.template='gDF'%>),
                V1 => '1',
            },
            result => 'gV1',
        },
        t6ne1 => {
            args => {
                template => q(<%Condition a.arg='V1!abc' a.template='gV1' default.template='gDF'%>),
                V1 => 'def',
            },
            result => 'gV1',
        },
        t6ne2 => {
            args => {
                template => q(<%Condition a.arg='V1!abc' a.template='gV1' default.template='gDF'%>),
                V1 => 'abc',
            },
            result => 'gDF',
        },
        t7 => {
            args => {
                template => q(<%Condition a.arg='V1=abc' a.template='gV1' default.template='gDF'%>),
                V1 => 'cde',
            },
            result => 'gDF',
        },
        t8 => {
            args => {
                template => q(<%Condition a.cookie='cookie1' a.template='OK' default.template='BAD'%>),
            },
            result => 'OK',
        },
        t9 => {
            args => {
                template => q(<%Condition a.cookie='cookie1=cvalue1' a.template='OK' default.template='BAD'%>),
            },
            result => 'OK',
        },
        t10 => {
            args => {
                template => q(<%Condition a.cookie='cookie2=fubar' a.template='BAD' default.template='OK'%>),
            },
            result => 'OK',
        },
        t11 => {
            args => {
                template => q(<%Condition a.clipboard='cb_zero' a.template='BAD' default.template='OK'%>),
            },
            result => 'OK',
        },
        t12 => {
            args => {
                template => q(<%Condition a.clipboard='cb_foo' a.template='OK' default.template='BAD'%>),
            },
            result => 'OK',
        },
        t13 => {
            args => {
                template => q(<%Condition a.clipboard='cb_foo=bar' a.template='OK' default.template='BAD'%>),
            },
            result => 'OK',
        },
        t14 => {
            args => {
                template => q(<%Condition a.clipboard='cb_foo=baz' a.template='BAD' default.template='OK'%>),
            },
            result => 'OK',
        },
        t15 => {
            args => {
                template => q(<%Condition a.clipboard='cb_zero=0' a.template='OK' default.template='BAD'%>),
            },
            result => 'OK',
        },
        t20 => {
            args => {
                template => q(<%Condition a.siteconf='base_url' a.template='OK' default.template='ERR'%>),
            },
            result => 'OK',
        },
        t21 => {
            args => {
                template => q(<%Condition a.siteconfig='/charset' a.template='OK' default.template='ERR'%>),
            },
            result => 'OK',
        },
        t22 => {
            args => {
                template => q(<%Condition a.siteconfig='nothing' a.template='ERR' default.template='OK'%>),
            },
            result => 'OK',
        },
        t23 => {
            args => {
                template => q(<%Condition a.siteconf='base_url=http://xao.com' a.template='OK' default.template='ERR'%>),
            },
            result => 'OK',
        },
        t24 => {
            args => {
                template => q(<%Condition a.siteconfig='/base_url = http://xao.com' a.template='OK' default.template='ERR'%>),
            },
            result => 'OK',
        },
        t25 => {
            args => {
                template    => q(<%Condition a.arg='COND' a.pass a.template={'<%SetArg name='VAR' value='DEFAULT'%>OK-<$VAR$>'} default.template='ERR'%>),
                COND        => 'CONDVALUE',
                VAR         => 'VARVALUE',
            },
            result => 'OK-VARVALUE',
        },
        t26 => {
            args => {
                template    => q(<%Condition a.arg='COND' a.pass a.template={'<%SetArg name='VAR' value='DEFAULT'%>OK-<$VAR$>'} default.template='ERR'%>),
                COND        => 'CONDVALUE',
            },
            result => 'OK-DEFAULT',
        },
        t27 => {
            args => {
                template    => q(<%Condition a.arg='COND' a.pass a.template={'<%SetArg name='VAR' value='DEFAULT'%>OK-<$VAR$>'} default.template='ERR'%>),
            },
            result => 'ERR',
        },
    );

    foreach my $test (keys %matrix) {
        my $args=$matrix{$test}->{'args'};
        $args->{'template'}||=$template;
        my $got=$page->expand($args);
        my $expect=$matrix{$test}->{'result'};
        $self->assert($got eq $expect,
                      "Test $test failed - expected '$expect', got '$got'");
    }

    $template=<<'EOT';
<%Condition
  v1.length="<%V1%>"
  v1.template="GOT-V1"
  default.template="DEFAULT"
%><%End%>
EOT

    %matrix=(
        t1 => {
            args => {
                V1 => 0,
            },
            result => 'GOT-V1',
        },
        t2 => {
            args => {
                V1 => '',
            },
            result => 'DEFAULT',
        },
        t3 => {
            args => {
                V1 => 'x',
            },
            result => 'GOT-V1',
        },
    );

    foreach my $test (keys %matrix) {
        my $args=$matrix{$test}->{'args'};
        $args->{'template'}||=$template;
        my $got=$page->expand($args);
        my $expect=$matrix{$test}->{'result'};
        $self->assert($got eq $expect,
                      "Test $test failed - expected '$expect', got '$got'");
    }
}

###############################################################################
1;
