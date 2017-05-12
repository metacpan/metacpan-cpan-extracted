#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 12;
use Test::Differences;
use Test::Exception;

use File::Slurp 'read_file', 'write_file';
use Compress::Zlib ();

use FindBin qw($Bin);
use lib "$Bin/../lib";


BEGIN {
	use_ok ( 'URL::Transform' ) or exit;
	use_ok ( 'URL::Transform::using::HTML::Parser' ) or exit;
}

my $TRANSFORM_FUNCTION = sub {
    my %x = @_;
    return (
        join(', ',
            map { $_.': '.$x{$_} } sort keys %x
        )
    )
};

exit main();

sub main {
    basic_tests();
    gzip_tests();
    meta_refresh();
    css_url_transform();
    js_removal();

    return 0;
}

sub basic_tests {
    # text/html tests
    
    my $output;
    my $urlt1 = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => $TRANSFORM_FUNCTION,
    );
    
    isa_ok($urlt1, 'URL::Transform');
    
    $urlt1->parse_file($Bin.'/data/URL-Transform-01.html');
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-01-result.html') ],
        'check the parse_file',
    );
    
    $output = '';
    $urlt1->parse_string(scalar read_file($Bin.'/data/URL-Transform-01.html'));
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-01-result.html') ],
        'check the parse_string',
    );
    
    $output = '';
    open my $fh, '<', $Bin.'/data/URL-Transform-01.html' or die $@;
    while (sysread($fh, my $two_bytes, 20)) {
        $urlt1->parse_chunk($two_bytes);
    }
    $output =~ s{^\n}{}; # for some strange reason parse_chunk in HTML::Parses is adding a new line
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-01-result.html') ],
        'check the parse_chunk',
    );
}

sub gzip_tests {    
    # content_encoding tests
    my $output;
    my $urlt = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'content_encoding'   => 'gzip',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => $TRANSFORM_FUNCTION,
    );
    
    $output = '';
    $urlt->parse_file($Bin.'/data/URL-Transform-02.html.gz');

    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-01-result.html') ],
        'check the parse_string with decode_string',
    );

    $output = $urlt->encode_string($output);
#    write_file($Bin.'/data/URL-Transform-02-result.html.gz', $output);
    my $output_ungzip = Compress::Zlib::memGunzip($output);

    eq_or_diff(
        [ split "\n", $output_ungzip ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-01-result.html') ],
        'check encode_string',
    );
}

sub meta_refresh {
    # meta refresh url rewriting
    
    my $output;
    my $urlt1 = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => $TRANSFORM_FUNCTION,
    );
    
    $urlt1->parse_file($Bin.'/data/URL-Transform-03.html');
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-03-result.html') ],
        'check meta refresh transformation',
    );
}

sub css_url_transform {
    my $output;
    my $urlt1 = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => $TRANSFORM_FUNCTION,
    );
    
    $urlt1->parse_file($Bin.'/data/URL-Transform-04.html');
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-04-result.html') ],
        'check the css url transformation',
    );
}

sub js_removal {
    my $output;
    my $urlt1 = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => $TRANSFORM_FUNCTION,
    );
    
    $urlt1->parse_file($Bin.'/data/URL-Transform-05.html');
    eq_or_diff(
        [ split "\n", $output ],
        [ split "\n", scalar read_file($Bin.'/data/URL-Transform-05-result.html') ],
        'check the javascrip removal',
    );

    TODO: {
        local $TODO = 'bug is HTML::Parser?';
        $output = '';
        $urlt1->parse_file($Bin.'/data/URL-Transform-06.html');
        eq_or_diff(
            [ split "\n", $output ],
            [ split "\n", scalar read_file($Bin.'/data/URL-Transform-06-result.html') ],
            'check the javascrip empty tag handling',
        );
    }
}
