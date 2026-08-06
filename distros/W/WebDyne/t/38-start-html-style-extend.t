#!/bin/perl
#
#  Check start_html stylesheet/script prepend/append pseudo attributes
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='t/start_html_style_extend.conf.pl';
}

use Test::More tests=>8;
use WebDyne::HTML::Tiny;


sub style_hrefs {

    my $html=shift;
    return [ $html=~/<link\b[^>]*\bhref="([^"]+)"/g ];

}


sub script_srcs {

    my $html=shift;
    return [ $html=~/<script\b[^>]*\bsrc="([^"]+)"/g ];

}


my $html_or=WebDyne::HTML::Tiny->new();

is_deeply(
    style_hrefs($html_or->start_html({ style_append=>'app.css' })),
    [qw(default.css base.css app.css)],
    'style_append adds stylesheet after configured styles'
);

is_deeply(
    style_hrefs($html_or->start_html({ style_prepend=>'reset.css' })),
    [qw(reset.css default.css base.css)],
    'style_prepend adds stylesheet before configured styles'
);

is_deeply(
    style_hrefs($html_or->start_html({ style=>'app.css' })),
    [qw(app.css)],
    'style still overrides configured styles'
);

is_deeply(
    style_hrefs($html_or->start_html({
        style_prepend => 'reset.css',
        style         => 'app.css',
        style_append  => 'theme.css'
    })),
    [qw(reset.css app.css theme.css)],
    'style_prepend and style_append wrap explicit style'
);

is_deeply(
    script_srcs($html_or->start_html({ script_append=>'app.js' })),
    [qw(default.js base.js app.js)],
    'script_append adds script after configured scripts'
);

is_deeply(
    script_srcs($html_or->start_html({ script_prepend=>'boot.js' })),
    [qw(boot.js default.js base.js)],
    'script_prepend adds script before configured scripts'
);

is_deeply(
    script_srcs($html_or->start_html({ script=>'app.js' })),
    [qw(app.js)],
    'script still overrides configured scripts'
);

is_deeply(
    script_srcs($html_or->start_html({
        script_prepend => 'boot.js',
        script         => 'app.js',
        script_append  => 'theme.js'
    })),
    [qw(boot.js app.js theme.js)],
    'script_prepend and script_append wrap explicit script'
);
