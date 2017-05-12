package testcases::Web::WebCgiParam;
use strict;
use XAO::Utils;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    my $cgi=$self->cgi;
    $self->assert(ref($cgi),
                  "Can't get a CGI reference");

    my $cgiparam=XAO::Objects->new(objname => 'Web::CgiParam');
    $self->assert(ref($cgiparam),
                  "Can't load CgiParam object");

    my %matrix=(
        t01 => {
            args    => {
                name    => 'foo',
            },
            expect  => 'bar',
        },
        t02 => {
            args    => {
                name    => 'fooZ',
            },
            expect  => '',
        },
        t03 => {
            args    => {
                param   => 'fooZ',
                default => 'barZ',
            },
            expect  => 'barZ',
        },
        ####
        t10 => {
            args    => {
                name    => 'ucode',
            },
            expect  => 'тест',
        },
        ####
        t20 => {
            set     => {
                q   => '<script>alert(1)</script>',
            },
            args    => {
                param   => 'q',
            },
            expect  => 'script alert(1) /script',
        },
        t21 => {
            set     => {
                q   => '<script>alert(1)</script>',
            },
            args    => {
                param           => 'q',
                dont_sanitize   => '',
            },
            expect  => 'script alert(1) /script',
        },
        t22 => {
            set     => {
                q   => '<script>alert(1)</script>',
            },
            args    => {
                param           => 'q',
                dont_sanitize   => 'on',
            },
            expect  => '<script>alert(1)</script>',
        },
        #
        t30 => {
            set     => { q      => 'foo ' },
            args    => { param  => 'q' },
            expect  => 'foo',
        },
        t31 => {
            set     => { q      => "foo\t " },
            args    => { param  => 'q' },
            expect  => 'foo',
        },
        t32 => {
            set     => { q      => " foo" },
            args    => { param  => 'q' },
            expect  => 'foo',
        },
        t33 => {
            set     => { q      => "\t\tfoo" },
            args    => { param  => 'q' },
            expect  => 'foo',
        },
        t34 => {
            set     => { q      => ' foo ' },
            args    => { param  => 'q', keep_spaces => '' },
            expect  => 'foo',
        },
        t35 => {
            set     => { q      => 'foo ' },
            args    => { param  => 'q', keep_spaces => 1 },
            expect  => 'foo ',
        },
        t36 => {
            set     => { q      => '  foo ' },
            args    => { param  => 'q', keep_spaces => 1 },
            expect  => '  foo ',
        },
    );

    foreach my $tname (keys %matrix) {
        my $tdata=$matrix{$tname};

        if(my $tset=$tdata->{'set'}) {
            foreach my $k (keys %$tset) {
                $cgi->param(-name => $k, -value => $tset->{$k});
            }
        }

        my $got=$cgiparam->expand($tdata->{'args'});
        my $expect=$tdata->{'expect'};

        $self->assert($got eq $expect,
                      "Test '$tname' failed - expected '$expect', got '$got'");
    }
}

1;
