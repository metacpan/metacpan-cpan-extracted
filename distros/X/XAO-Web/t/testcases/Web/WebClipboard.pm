package testcases::Web::WebClipboard;
use strict;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

sub test_misc {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my %matrix=(
        t10 => {
            template    => q(<%Clipboard mode='array-size' name='arBAD'%>),
            result      => '',
        },
        t11 => {
            template    => q(<%Clipboard name='arBAD'%>),
            result      => '',
        },
        t12 => {
            template    => q(<%Clipboard mode='array-pop' name='arBAD'%>),
            result      => '',
        },
        t20 => {
            template    => q(<%Clipboard mode='array-push' name='ar1' value='val'%>),
            result      => '',
        },
        t21 => {
            template    => q(<%Clipboard mode='array-size' name='ar1'%>),
            result      => '1',
        },
        t22a => {
            template    => q(<%Clipboard mode='array-pop' name='ar1'%>),
            result      => 'val',
        },
        t22b => {
            template    => q(<%Clipboard mode='array-size' name='ar1'%>),
            result      => '0',
        },
        t23a => {
            template    => q(<%Clipboard mode='array-push' name='ar1' value="<$VALUE/f$>"%>),
            args        => {
                VALUE       => "multi\nline",
            },
            result      => '',
        },
        t23b => {
            template    => q(<%Clipboard mode='array-push' name='/ar1' value="<$VALUE/f$>"%>),
            args        => {
                VALUE       => '<&>',
            },
            result      => '',
        },
        t23c => {
            template    => q(<%Clipboard mode='array-push' name='//ar1' value="<$VALUE/f$>"%>),
            args        => {
                VALUE       => '"',
            },
            result      => '',
        },
        t24 => {
            template    => q(<%Clipboard mode='array-size' name='ar1'%>),
            result      => '3',
        },
        t25a => {
            template    => q(<%Clipboard mode='array-list' name='ar1' template='<$VALUE$>'%>),
            result      => qq(multi\nline<&>"),
        },
        t25b => {
            template    => q(<%Clipboard mode='array-list' name='ar1' template='[<$VALUE$>]'%>),
            result      => qq([multi\nline][<&>]["]),
        },
        t26a => {
            template    => q(<%Clipboard mode='show' name='ar1'%>),
            result      => '',
        },
        t26b => {
            template    => q(<%Clipboard mode='show' name='ar1' default='zzz'%>),
            result      => 'zzz',
        },
        #
        t30 => {
            template    => q(<%Clipboard mode='set' name='/prefix/ar2' value='123'%>),
            result      => '',
        },
        t31 => {
            template    => q(<%Clipboard mode='array-size' name='/prefix/ar2'%>),
            result      => '',
        },
        t32 => {
            template    => q(<%Clipboard mode='array-pop' name='/prefix/ar2'%>),
            result      => '',
        },
        t33 => {
            template    => q(<%Clipboard mode='show' name='/prefix/ar2'%>),
            result      => '123',
        },
        t34 => {
            template    => q(<%Clipboard mode='array-push' name='/prefix/ar2' value='qwerty'%>),
            result      => '',
        },
        t35 => {
            template    => q(<%Clipboard mode='array-size' name='/prefix/ar2'%>),
            result      => '1',
        },
        t36 => {
            template    => q(<%Clipboard mode='show' name='/prefix/ar2'%>),
            result      => '',
        },
        t37 => {
            template    => q(<%Clipboard mode='array-list' name='/prefix/ar2' template='<$VALUE$>'%>),
            result      => 'qwerty',
        },
    );

    foreach my $test (sort keys %matrix) {
        my $args=$matrix{$test}->{'args'} // {};
        my $template=$matrix{$test}->{'template'} // '';
        my $got=$page->expand($args,{ template => $template });
        my $expect=$matrix{$test}->{'result'};
        $self->assert($got eq $expect,
                      "Test $test failed - expected '$expect', got '$got'");
    }
}

sub test_show {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    $page->clipboard->put('foo' => 'bar');
    $page->clipboard->put('/fu/foo' => 'fubar');

    my $template='<%Clipboard name="<%NAME/f%>" default="DFLT"%>';

    my %matrix=(
        t1 => {
            args => {
                NAME => 'nothing',
            },
            result => 'DFLT',
        },
        t2 => {
            args => {
                NAME => 'foo',
            },
            result => 'bar',
        },
        t3 => {
            args => {
                NAME => 'fu/foo',
            },
            result => 'fubar',
        },
        t4 => {
            args => {
                NAME => '/fu/foo',
            },
            result => 'fubar',
        },
        t5 => {
            args => {
                NAME => '////foo',
            },
            result => 'bar',
        },
    );

    foreach my $test (keys %matrix) {
        my $args=$matrix{$test}->{args};
        $args->{template}=$template;
        my $got=$page->expand($args);
        my $expect=$matrix{$test}->{result};
        $self->assert($got eq $expect,
                      "Test $test failed - expected '$expect', got '$got'");
    }
}

sub test_set {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    $page->clipboard->put('foo' => 'bar');
    $page->clipboard->put('/fu/foo' => 'fubar');

    my %matrix=(
        t1 => {
            template => '<%Clipboard mode="set" name="foo" value="bar"%>',
            result => {
                foo => 'bar',
            }
        },
        t2 => {
            template => '<%Clipboard mode="set" name="foo" value=""%>',
            result => {
                foo => '',
            }
        },
        t3 => {
            template => '<%Clipboard mode="set" name="/some/path" value="0"%>',
            result => {
                '/some/path' => 0,
            }
        },
        t4 => {
            template => '<%Clipboard mode="set" name="/some/path"%>',
            result => {
                '/some/path' => undef,
            }
        },
        t5 => {
            template => '<%Clipboard mode="set" name="newname"%>',
            result => {
                newname => undef,
            }
        },
    );

    foreach my $test (keys %matrix) {
        my $template=$matrix{$test}->{template};
        my $got=$page->expand(template => $template);
        $self->assert($got eq '',
                      "Test $test returned '$got' instead of ''");
        my $cbhash=$matrix{$test}->{result};
        foreach my $k (keys %$cbhash) {
            $self->assert($page->clipboard->exists($k),
                          "$test - $k should exist");
            my $expect=$cbhash->{$k};
            $got=$page->clipboard->get($k);
            if(defined $expect) {
                $self->assert(defined $got && $got eq $expect,
                              "$test - expected '$expect', got '$got'");
            }
            else {
                $self->assert(!defined($got),
                              "$test - expected nothing, got '".($got || '')."'");
            }
        }
    }
}

1;
