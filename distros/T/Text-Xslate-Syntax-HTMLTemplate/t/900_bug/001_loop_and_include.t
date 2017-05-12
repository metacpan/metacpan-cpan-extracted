#!perl -w

use strict;
use warnings;

use Test::More;
use Text::Xslate;

use t::lib::Util;

my $tx = Text::Xslate->new(syntax => 'HTMLTemplate',
                           type => 'html', # enable auto escape
                           compiler => 'Text::Xslate::Compiler::HTMLTemplate',
                           cache => 0,
                           path => {
                               'foo.tx' => '<TMPL_VAR EXPR=foo()>',
                               'include_foo.tx' => '<TMPL_INCLUDE NAME=foo.tx>',
                           },
                           function => {},
                       );

is($tx->render_string(<<'END;',
<TMPL_INCLUDE NAME='foo.tx'>
<TMPL_LOOP NAME=list1>
<TMPL_INCLUDE NAME='foo.tx'>
</TMPL_LOOP>
<TMPL_INCLUDE NAME='foo.tx'>
END;
{
    list1 => [ {}, ],
    foo => sub { "FOO"; }
}), <<'END;');
FOO

FOO

FOO
END;

done_testing;

