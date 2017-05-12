# A test for cookies, both XAO::DO::Web::Cookie, and general
# CGI/siteconfig cookie access.
#
package testcases::Web::WebCookie;
use strict;
use HTTP::Response;
use POSIX qw(strftime mktime);
use XAO::Utils;
use XAO::Web;
use XAO::Objects;
use Data::Dumper;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_cookie {
    my $self=shift;

    my $web=$self->web;
    $self->assert(ref($web),
                  "Can't create an instance of XAO::Web");

    my $cgi=$self->siteconfig->cgi;
    $self->assert(ref($cgi),
                  "Can't create an instance of CGI");

    my $cookie_name='test_cookie';
    my $cookie_value=time;

    my %tests=(
        t01 => {
            path    => '/cookie1.html',
            expect  => {
                all     => {
                    $cookie_name.'-t02' => undef,
                    $cookie_name.'-t03' => undef,
                    $cookie_name.'-t04' => undef,
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t02 => {
            path    => '/cookie1.html',
            run     => sub {
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t02',
                    -value      => $cookie_value.'-t02',
                    -path       => '/',
                    -expires    => '+600s',
                );
            },
            expect  => {
                all => {
                    $cookie_name.'-t02' => $cookie_value.'-t02',
                },
                cgi => {
                    $cookie_name.'-t02' => undef,
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t03 => {
            path    => '/cookie1.html',
            run     => sub {
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t03',
                    -value      => $cookie_value.'-t03',
                    -path       => '/',
                    -expires    => 'now',
                );
            },
            expect  => {
                all => {
                    $cookie_name.'-t02' => $cookie_value.'-t02',
                    $cookie_name.'-t03' => undef,
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t04 => {                            # Overriding (hash over hash)
            path    => '/cookie1.html',
            run     => sub {
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t04-a',
                    -value      => $cookie_value.'-t04-a',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t04-b',
                    -value      => $cookie_value.'-t04-a',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t04-a',
                    -value      => $cookie_value.'-t04-b',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t04-b',
                    -value      => $cookie_value.'-t04-b',
                    -path       => '/',
                    -expires    => '+6000s',
                );
            },
            expect  => {
                all => {
                    $cookie_name.'-t04-a'   => $cookie_value.'-t04-b',
                    $cookie_name.'-t04-b'   => $cookie_value.'-t04-b',
                },
                cgi => {
                    $cookie_name.'-t02' => $cookie_value.'-t02',
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t05 => {                            # Overriding (baked over hash)
            path    => '/cookie1.html',
            run     => sub {
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t05-a',
                    -value      => $cookie_value.'-t05-a',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t05-b',
                    -value      => $cookie_value.'-t05-a',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(CGI::Cookie->new(
                    -name       => $cookie_name.'-t05-a',
                    -value      => $cookie_value.'-t05-b',
                    -path       => '/',
                    -expires    => '+6000s',
                )->as_string());
                $self->siteconfig->add_cookie(CGI::Cookie->new(
                    -name       => $cookie_name.'-t05-b',
                    -value      => $cookie_value.'-t05-b',
                    -path       => '/',
                    -expires    => '+6000s',
                )->as_string());
            },
            expect  => {
                all => {
                    $cookie_name.'-t05-a'   => $cookie_value.'-t05-b',
                    $cookie_name.'-t05-b'   => $cookie_value.'-t05-b',
                },
                cgi => {
                    $cookie_name.'-t02'     => $cookie_value.'-t02',
                    $cookie_name.'-t04-a'   => $cookie_value.'-t04-b',
                    $cookie_name.'-t04-b'   => $cookie_value.'-t04-b',
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t06 => {                            # Overriding (hash over baked)
            path    => '/cookie1.html',
            run     => sub {
                $self->siteconfig->add_cookie(CGI::Cookie->new(
                    -name       => $cookie_name.'-t06-a',
                    -value      => $cookie_value.'-t06-a',
                    -path       => '/',
                    -expires    => '+6000s',
                )->as_string());
                $self->siteconfig->add_cookie(CGI::Cookie->new(
                    -name       => $cookie_name.'-t06-b',
                    -value      => $cookie_value.'-t06-a',
                    -path       => '/',
                    -expires    => '+6000s',
                )->as_string());
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t06-a',
                    -value      => $cookie_value.'-t06-b',
                    -path       => '/',
                    -expires    => '+6000s',
                );
                $self->siteconfig->add_cookie(
                    -name       => $cookie_name.'-t06-b',
                    -value      => $cookie_value.'-t06-b',
                    -path       => '/',
                    -expires    => '+6000s',
                );
            },
            expect  => {
                all => {
                    $cookie_name.'-t06-a'   => $cookie_value.'-t06-b',
                    $cookie_name.'-t06-b'   => $cookie_value.'-t06-b',
                },
                cgi => {
                    $cookie_name.'-t02'     => $cookie_value.'-t02',
                    $cookie_name.'-t04-a'   => $cookie_value.'-t04-b',
                    $cookie_name.'-t04-b'   => $cookie_value.'-t04-b',
                    $cookie_name.'-t05-a'   => $cookie_value.'-t05-b',
                    $cookie_name.'-t05-b'   => $cookie_value.'-t05-b',
                },
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t10 => {
            path    => '/cookie2.html',
            args    => {
                COOKIE_NAME     => $cookie_name.'-t10',
                COOKIE_VALUE    => $cookie_value.'-t10',
            },
            expect  => {
                all => {
                    $cookie_name.'-t10' => $cookie_value.'-t10',
                },
                cgi => {
                    $cookie_name.'-t10' => undef,
                },
                text    => $cookie_value.'-t10',
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
        t11 => {
            path    => '/cookie2.html',
            args    => {
                COOKIE_NAME     => $cookie_name.'-t11',
                COOKIE_VALUE    => $cookie_value.'-t11',
            },
            expect  => {
                all => {
                    $cookie_name.'-t11' => $cookie_value.'-t11',
                },
                cgi => {
                    $cookie_name.'-t10' => $cookie_value.'-t10',
                    $cookie_name.'-t11' => undef,
                },
                text    => $cookie_value.'-t11',
            },
            ignore_stderr   => 1,           # Hiding expected deprecation warning
        },
    );

    my $config=$self->siteconfig;

    my $cjar={};

    foreach my $tname (sort keys %tests) {
        my $tdata=$tests{$tname};

        dprint "TEST $tname";

        my $rcjar=$tdata->{'cookie_jar'} || merge_refs($cjar,$tdata->{'cookies'});
        my $wcjar=$tdata->{'cookie_jar'} || $cjar;

        my $cenv='';
        foreach my $cname (keys %$rcjar) {
            next unless defined $rcjar->{$cname};
            $cenv.='; ' if length($cenv);
            $cenv.="$cname=$rcjar->{$cname}";
            $wcjar->{$cname}=$rcjar->{$cname};
        }

        ### dprint "..cookies: $cenv";

        $ENV{'HTTP_COOKIE'}=$cenv;

        my $cgi=XAO::Objects->new(
            objname => 'CGI',
            query   => 'foo=bar&bar=foo'
        );

        $config->embedded('web')->cleanup;
        $config->embedded('web')->enable_special_access;
        $config->embedded('web')->cgi($cgi);
        $config->embedded('web')->disable_special_access;

        $self->catch_stderr() if $tdata->{'ignore_stderr'};

        if($tdata->{'run'}) {
            &{$tdata->{'run'}}();
        }

        my $text;

        my $objargs=$tdata->{'args'} || {};

        if($tdata->{'path'}) {
            $text=XAO::Objects->new(objname => 'Web::Page')->expand($objargs,{
                path        => $tdata->{'path'},
            });
        }
        else {
            $text=XAO::Objects->new(objname => 'Web::Page')->expand($objargs,{
                template    => $tdata->{'template'} || 'FUBAR',
            });
        }

        # Converting cookies back into a hash
        #
        foreach my $cd (@{$config->cookies}) {
            next unless defined $cd;

            my $expires_text=$cd->expires;

            $self->assert($expires_text =~ /(\d{2})\W+([a-z]{3})\W+(\d{4})\W+(\d{2})\W+(\d{2})\W+(\d{2})/i,
                "Invalid cookie expiration '".$expires_text." for name '".$cd->name."' value '".$cd->value."'");

            my $midx=index('janfebmaraprmayjunjulaugsepoctnovdec',lc($2));
            $self->assert($midx>=0,
                "Invalid month '$2' in cookie '".$cd->name."' expiration '".$expires_text."'");

            my $expires;
            {
                local($ENV{'TZ'})='UTC';
                $expires=mktime($6,$5,$4,$1,$midx/3,$3-1900);
            }

            ### dprint "...cookie name='".$cd->name."' value='".$cd->value." expires=".$expires_text." (".localtime($expires)." - ".($expires<=time ? 'EXPIRED' : 'ACTIVE').")";

            if($expires <= time) {
                $wcjar->{$cd->name}=undef;
            }
            else {
                $wcjar->{$cd->name}=$cd->value;
            }
        }

        %$cjar=%$wcjar;

        my $expect=$tdata->{'expect'};

        if(exists $expect->{'text'}) {
            $self->assert($text eq $expect->{'text'},
                "$tname - expected '$expect->{'text'}', got '$text'");
        }

        foreach my $kind (qw(cgi config stored)) {
            my $cexp=$expect->{$kind} || $expect->{'all'};
            next unless $cexp;

            my $getter;
            if($kind eq 'cgi') {
                $getter=sub {
                    my $n=shift;
                    return $cgi->cookie($n);
                };
            }
            elsif($kind eq 'config') {
                $getter=sub {
                    my $n=shift;
                    return $self->siteconfig->get_cookie($n);
                };
            }
            elsif($kind eq 'stored') {
                $getter=sub {
                    my $n=shift;
                    return $wcjar->{$n};
                };
            }
            else {
                $self->assert(undef,
                    "Invalid cookie checking kind '$kind'");
            }

            while(my ($n,$ev)=(each %$cexp)) {
                my $cv=$getter->($n);

                if(defined $ev) {
                    $self->assert(defined($cv) && $ev eq $cv,
                        "Expected to have cookie '$n' set to '",($ev || 'UNDEF'),"', got '".($cv || 'UNDEF')."' for test $tname ($kind)");
                }
                else {
                    $self->assert(!defined($cv),
                        "Expected to have no value for '$n', got '".($cv || '<UNDEF>')."' for test $tname ($kind)");
                }
            }
        }

        if($tdata->{'ignore_stderr'}) {
            my $stderr=$self->get_stderr();
            $stderr=~s/\r?\n/\\n/sg;
            dprint "IGNORED(OK-STDERR): ".substr($stderr,0,60)."...";
        }
    }
}

###############################################################################
1;
