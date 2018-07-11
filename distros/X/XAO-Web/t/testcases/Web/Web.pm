# A test for XAO::Web
#
package testcases::Web::Web;
use warnings;
use strict;
use utf8;
use XAO::Utils;
use XAO::Web;
use XAO::Objects;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_execute {
    my $self=shift;

    my %tests=(
        t01a => {
            path    => '/index.html',
            expect  => [
                qr/^Content-Type: text\/html/m,
                qr/^Set-Cookie: .*test=INDEX/m,
                qr/^TEST\[bar\]INDEX/m,
            ],
        },
        t01b => {
            path    => '/index.html',
            charmode=> 1,
            expect  => [
                qr/^Content-Type: text\/html/m,
                qr/^Set-Cookie: .*test=INDEX/m,
                qr/^TEST\[bar\]INDEX/m,
            ],
        },
        t02a => {
            path    => '/blob-1.gif',
            expect  => [
                qr/^Content-Type:\s+image\/gif\s*$/mi,
                qr/^Content-Length:\s+35\s*$/mi,
                qr/GIF87a.{29}$/s,
            ],
        },
        t02b => {
            path    => '/blob-1.gif',
            charmode=> 1,
            expect  => [
                qr/^Content-Type:\s+image\/gif\s*$/mi,
                qr/^Content-Length:\s+35\s*$/mi,
                qr/GIF87a.{29}$/s,
            ],
        },
        t03a => {
            path    => '/blob-2.dat',
            expect  => [
                qr/^Content-Type:\s+text\/html;\s*charset=UTF-8/mi,
                qr/^Content-Length:\s+24\s*$/mi,
            ],
        },
        t03b => {
            path    => '/blob-2.dat',
            charmode=> 1,
            expect  => [
                qr/^Content-Type:\s+text\/html;\s*charset=UTF-8/mi,
                qr/^Content-Length:\s+24\s*$/mi,
            ],
        },
        t04a => {
            path    => '/blob-3.dat',
            expect  => [
                qr/^Content-Type:\s+text\/plain;\s*charset=UTF-8/mi,
                qr/^Content-Length:\s+24\s*$/mi,
            ],
        },
        t04b => {
            path    => '/blob-3.dat',
            charmode=> 1,
            expect  => [
                qr/^Content-Type:\s+text\/plain;\s*charset=UTF-8/mi,
                qr/^Content-Length:\s+24\s*$/mi,
            ],
        },
    );

    # Testing is incomplete without these - they used to mess up
    # character mode processing.
    #
    $self->siteconfig->put(
        auto_before => [
            'Web::Page' => {
                template        => '',
            },
        ],
    );
    $self->siteconfig->put(
        auto_after =>  [
            'Web::Page' => {
                template        => '',
            },
        ],
    );

    foreach my $tname (sort keys %tests) {
        my $tdata=$tests{$tname};

        my $path=$tdata->{'path'};
        my $charmode=$tdata->{'charmode'} || 0;

        $self->siteconfig->cleanup();

        $self->siteconfig->put('/xao/page/character_mode' => $charmode);

        my $web=$self->web;

        $self->assert(ref($web),
            "Can't create an instance of XAO::Web");

        $self->catch_stdout();
        $web->execute(path => $path, cgi => $self->cgi);
        my $text=$self->get_stdout();

        foreach my $expect (@{$tdata->{'expect'}}) {
            my $match=scalar($text =~ $expect);

            dprint "----------\n$text\n---------" if !$match;

            $self->assert($match,
                  "No match for '$expect' (test '$tname', path '$path', charmode '$charmode')");
        }
    }
}

###############################################################################

sub test_auto_lists {
    my $self=shift;

    my %tests=(
        t01 => {
            path        => '/test-auto-lists.html',
            expect      => '',
        },
        t02 => {
            path        => '/test-auto-lists.html',
            auto_before => [
                'Web::Page' => {
                    template    => '123',
                },
                'Web::Page' => {
                    template    => '45',
                },
            ],
            expect      => '12345',
        },
        t03 => {
            path        => '/test-auto-lists.html',
            auto_before => [
                'Web::Page' => {
                    template    => '123',
                },
                'Web::Clipboard' => {
                    mode        => 'set',
                    name        => 'ttt',
                    value       => 'cbvalue',
                },
            ],
            expect      => '123cbvalue',
        },
        t04 => {
            path        => '/test-auto-lists.html',
            auto_before => [
                'Web::Clipboard' => {
                    mode        => 'set',
                    name        => 'ttt',
                    value       => 'Encyclopædia Britannica',
                },
            ],
            expect      => Encode::encode('utf8','Encyclopædia Britannica'),
        },
        t05 => {
            path        => '/test-auto-lists.html',
            auto_before => [
                'Web::Clipboard' => {
                    mode        => 'set',
                    name        => 'ttt',
                    value       => 'Encyclopædia Britannica',
                },
                'Web::Clipboard' => {
                    mode        => 'set',
                    name        => 'ddd',
                    value       => '[footer]',
                },
            ],
            auto_after => [
                'Web::Clipboard' => {
                    name        => 'ddd',
                },
            ],
            expect      => Encode::encode('utf8','Encyclopædia Britannica[footer]'),
        },
        t06 => {
            path        => '/test-auto-lists.html',
            auto_after => [
                'Web::Clipboard' => {
                    name        => 'ddd',
                },
                'Web::Page' => {
                    template    => '123',
                },
                'Web::Page' => {
                    template    => '456',
                },
            ],
            expect      => '123456',
        },
        #
        # If there was a redirect in auto_before section then nothing else
        # is to be processed. Doing so might break the redirect and might be
        # a security risk.
        #
        t07 => {
            path        => '/test-auto-lists.html',
            auto_before => [
                'Web::Redirect' => {
                    url     => 'https://www.google.com/',
                },
                'Web::Page' => {
                    template    => 'BEFORE',
                },
            ],
            auto_after  => [
                'Web::Page' => {
                    template    => 'AFTER',
                },
            ],
            expect      => qr/www\.google\.com/,
            not_expect  => qr/(?:BEFORE|AFTER)/,
        },
    );

    foreach my $tname (sort keys %tests) {
        my $tdata=$tests{$tname};

        my $charmode=$tdata->{'charmode'} || 0;

        $self->siteconfig->cleanup();

        $self->siteconfig->put('/xao/page/character_mode' => $charmode);
        $self->siteconfig->put('/auto_before' => $tdata->{'auto_before'});
        $self->siteconfig->put('/auto_after' => $tdata->{'auto_after'});

        my $web=$self->web;

        $self->assert(ref($web),
            "Can't create an instance of XAO::Web");

        my $path=$tdata->{'path'};
        my $got=$web->expand(path => $path);

        if(my $expect=$tdata->{'expect'}) {
            dprint "expect: ".(ref($expect) eq 'Regexp' ? $got =~ $expect : $got eq $expect);
            $self->assert((ref($expect) eq 'Regexp' ? $got =~ $expect : $got eq $expect),
                "Expected '$expect', got '$got' (test '$tname', path '$path', charmode '$charmode')");
        }

        if(my $not_expect=$tdata->{'not_expect'}) {
            dprint "not-expect: ".(ref($not_expect) eq 'Regexp' ? $got !~ $not_expect : $got ne $not_expect);
            $self->assert(ref($not_expect) eq 'Regexp' ? $got !~ $not_expect : $got ne $not_expect,
                "Expected to NOT match '$not_expect', got '$got' (test '$tname', path '$path', charmode '$charmode')");
        }
    }
}

###############################################################################

sub test_urlstyle_raw {
    my $self=shift;

    my $web=$self->web;
    $self->assert(ref($web),
                  "Can't create an instance of XAO::Web");

    $self->catch_stdout();
    $web->execute(path => '/raw', cgi => $self->cgi);
    my $text=$self->get_stdout();
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
    $self->assert(scalar($text =~ m/^RAWFILE/m),
                  "No expected content returned");

    $self->catch_stdout();
    $web->execute(path => '/rawobj', cgi => $self->cgi);
    $text=$self->get_stdout();
    $self->assert(scalar($text !~ m/^Location:\s+(.*?)[\r\n\s]+/m),
                  "Should not have redirected (".($1 || '').") for /rawobj");
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
    $self->assert(scalar($text =~ m/^RAWOBJ/m),
                  "No expected content returned");

    $self->catch_stdout();
    $web->execute(path => '/filesobj', cgi => $self->cgi);
    $text=$self->get_stdout();
    $self->assert(scalar($text =~ m/^Location:\s+http:\/\/xao.com\/filesobj\//m),
                  "Should have redirected for /filesobj");
    $self->assert(scalar($text =~ m/^Content-Type: text\/html/m),
                  "No Content-Type header returned");
}

###############################################################################
1;
