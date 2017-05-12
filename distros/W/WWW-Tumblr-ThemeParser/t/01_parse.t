use strict;
use Test::More;

use WWW::Tumblr::ThemeParser;

my $tests = get_tests();
plan tests => @$tests * 3;

for my $test ( @$tests ) {
    diag $test->{comment};

    my $p = WWW::Tumblr::ThemeParser->new( \$test->{html} );
    is_deeply $p->tokens, $test->{tokens};
    is_deeply $p->settings, $test->{settings};

    my @tokens;
    while ( my $t = $p->get_token ) {
        push @tokens, $t;
    }
    is_deeply \@tokens, $test->{tokens};
}

sub get_tests {
    return [
        {
            comment => 'variable + block',
            html => '<html><head><title>{Title}</title></head><body><ol id="posts">{block:Posts}<li>{Body}</li>{/block:Posts}</ol></body></html>',
            tokens => [
                [ 'TEXT', '<html><head><title>' ],
                [ 'VAR', 'Title' ],
                [ 'TEXT', '</title></head><body><ol id="posts">' ],
                [ 'SBLOCK', 'block:Posts' ],
                [ 'TEXT', '<li>' ],
                [ 'VAR', 'Body' ],
                [ 'TEXT', '</li>' ],
                [ 'EBLOCK', '/block:Posts' ],
                [ 'TEXT', '</ol></body></html>' ],
            ],
            settings => {},
        },
        {
            comment => 'no slash on end-block tag',
            html => '{block:Posts}...{block:Posts}{block:Posts}...{/block:Posts}',
            tokens => [
                [ 'SBLOCK', 'block:Posts' ],
                [ 'TEXT', '...' ],
                [ 'EBLOCK', '/block:Posts' ],
                [ 'SBLOCK', 'block:Posts' ],
                [ 'TEXT', '...' ],
                [ 'EBLOCK', '/block:Posts' ],
            ],
            settings => {},
        },
        {
            comment => 'custom colors',
            html => '<html><head><meta name="color:Background" content="#eee"/></head><body bgcolor="{color:Background}"></body></html>',
            tokens => [
                [ 'TEXT', '<html><head><meta name="color:Background" content="#eee"/></head><body bgcolor="' ],
                [ 'SETTING', 'color', 'Background' ],
                [ 'TEXT', '"></body></html>' ],
            ],
            settings => {
                color => { Background => '#eee' },
            },
        },
        {
            comment => 'booleans',
            html => '<html><head><meta name="if:Reverse pagination" content="0"/></head><body>{block:IfNotReversePagination}<a href="...">Previous</a> <a href="...">Next</a>{/block:IfNotReversePagination}{block:IfReversePagination}<a href="...">Next</a> <a href="...">Previous</a>{/block:IfReversePagination}</body></html>',
            tokens => [
                [ 'TEXT', '<html><head><meta name="if:Reverse pagination" content="0"/></head><body>' ],
                [ 'SBLOCK', 'block:IfNotReversePagination' ],
                [ 'TEXT', '<a href="...">Previous</a> <a href="...">Next</a>' ],
                [ 'EBLOCK', '/block:IfNotReversePagination' ],
                [ 'SBLOCK', 'block:IfReversePagination' ],
                [ 'TEXT', '<a href="...">Next</a> <a href="...">Previous</a>' ],
                [ 'EBLOCK', '/block:IfReversePagination' ],
                [ 'TEXT', '</body></html>' ],
            ],
            settings => {
                if => { 'Reverse pagination' => 0 },
            },
        },
    ];
}