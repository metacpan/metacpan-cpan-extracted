#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 4;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/../lib";


BEGIN {
	use_ok ( 'URL::Transform::using::CSS::RegExp' ) or exit;
}


exit main();

sub main {
    my $css_url_reqexp = $URL::Transform::using::CSS::RegExp::STYLE_URL_REGEXP;
    
    my @css_url_formats = (
        'url(/some/url)',
        'url("/some/url")',
        "url('/some/url')",
        'url( /some/url )',
        'url ( "/some/url"    ) ',
        "url    (  '/some/url')",
        '@import url("/some/url")',
        '@import "/some/url"',
        "url('/some/url')",
    );
    
    eq_or_diff(
        [ map { $_ =~ $css_url_reqexp ? $_ : "don't match" } @css_url_formats ],
        [ @css_url_formats ],
        'all css format url should match the regexp'
    );
    
    eq_or_diff(
        [ map { $_ =~ $css_url_reqexp; $3 || $7; } @css_url_formats ],
        [ map { '/some/url' } @css_url_formats ],
        'all css format url should match the regexp'
    );
    
    my $more_urls = qq{ blabla url(/some/url); blabla\n url("/some/other/url ");\n url    (  '//url');\n };
    my $output = '';
    my $parser = URL::Transform::using::CSS::RegExp->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { my %x=@_; return "OK".$x{'url'} },        
    );
    $parser->parse_string($more_urls);
    is(
        $output,
        qq{ blabla url(OK/some/url); blabla\n url("OK/some/other/url ");\n url    (  'OK//url');\n },
        'more urls'
    );

    return 0;
}

