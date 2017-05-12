#!perl -w

use strict;
use warnings;

use Test::More;

use Text::Xslate;
use Text::Xslate::Syntax::HTMLTemplate;

my $tx = Text::Xslate->new(syntax => 'HTMLTemplate');
is($tx->render_string('<TMPL_VAR NAME="ad_tag">', {ad_tag => '<tag>'}), '&lt;tag&gt;');

local $Text::Xslate::Syntax::HTMLTemplate::before_parse_hook = sub {
    my $parser = shift;
    $parser->is_escaped_var(sub {
                                my $name = shift;
                                $name =~ /_(html|tag)$/;
                            });
};
$tx = Text::Xslate->new(syntax => 'HTMLTemplate');
is($tx->render_string('<TMPL_VAR NAME="ad_tag">', {ad_tag => '<tag>'}), '<tag>');


done_testing;
