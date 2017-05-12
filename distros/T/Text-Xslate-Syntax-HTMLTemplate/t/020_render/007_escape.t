#!perl -w

use strict;
use warnings;

use Test::More;
use Text::Xslate;

use t::lib::Util;

compare_render('<tag><TMPL_VAR EXPR="html(foo)"></tag>',
               params => { foo => '<tag>'},
               function => { html => \&html_escape, html_escape => \&html_escape, },
               expected => '<tag>&lt;tag&gt;</tag>');

compare_render('<tag><TMPL_VAR EXPR="html(foo)"></tag>',
               params => { foo => '&'},
               function => { html => \&html_escape, html_escape => \&html_escape, },
               expected => '<tag>&</tag>');

my $tx_html = Text::Xslate->new(syntax => 'HTMLTemplate',
                                type => 'html', # enable auto escape
                                compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                                path => [ 't/template' ],
                                function => {
                                    html_escape => \&html_escape,
                                },
                            );

is($tx_html->render_string('<tag><TMPL_VAR EXPR="foo"></tag>', { foo => '<tag>', }),
   '<tag>&lt;tag&gt;</tag>', 'auto escape');

is($tx_html->render_string('<tag><TMPL_VAR NAME="foo"></tag>', { foo => '<tag>', }),
   '<tag>&lt;tag&gt;</tag>', 'auto escape');

is($tx_html->render_string('<tag><TMPL_VAR EXPR="foo" ESCAPE=0></tag>', { foo => '<tag>', }),
   '<tag><tag></tag>', 'escape=0');

is($tx_html->render_string('<tag><TMPL_VAR NAME="foo" ESCAPE=0></tag>', { foo => '<tag>', }),
   '<tag><tag></tag>', 'escape=0');

my $tx_text = Text::Xslate->new(syntax => 'HTMLTemplate',
                                type => 'text',
                                compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                                path => [ 't/template' ],
                                function => {
                                    html_escape => \&html_escape,
                                },
                            );

is($tx_text->render_string('<tag><TMPL_VAR EXPR="foo"></tag>', { foo => '<tag>', }),
   '<tag><tag></tag>');

done_testing;

sub html_escape {
    my $s = shift;
    return $s if ref $s;

    my %escape_map = (
        '<' => '&lt;',
        '>' => '&gt;',
    );
    $s =~ s/(.)/$escape_map{$1} || $1/ge;
    $s;
}
