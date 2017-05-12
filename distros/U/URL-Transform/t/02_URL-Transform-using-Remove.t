#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 2;
use Test::Differences;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/../lib";


BEGIN {
	use_ok ( 'URL::Transform::using::Remove' ) or exit;
}


exit main();

sub main {
    my @javascript = (
        "window.location='http://perl.org';",
        'form.test.focus();',
    );
    
    my $output = '';
    my $parser = URL::Transform::using::Remove->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { my %x=@_; return "OK".$x{'url'} },        
    );
    eq_or_diff(
        [ map { $output = ''; $parser->parse_string($_); $output; } @javascript ],
        [ map { '' } @javascript ],
        'more urls'
    );

    return 0;
}

