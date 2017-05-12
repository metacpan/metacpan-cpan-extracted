use strict;
use warnings;

use Test::More;
use Text::Xslate;

use Test::Requires qw(Text::Xslate::Syntax::HTMLTemplate);

use Text::Xslate::Syntax::Any;

my $tx = Text::Xslate->new(syntax => 'Any', cache => 0, path => [ qw{ t/template/HTMLTemplate } ]);

$Text::Xslate::Syntax::Any::DEFAULT_SYNTAX = 'Kolon';
$Text::Xslate::Syntax::Any::DETECT_SYNTAX  = Text::Xslate::Syntax::Any::generate_syntax_detecter__by_suffix({
    tx   => 'Metakolon',
    tmpl => 'HTMLTemplate',
});

is($tx->render('index.tmpl', {
    title => 'HTMLTemplate',
    menu_loop => [
        { item => 'top',    link => '/top'},
        { item => 'search', link => '/search'},
    ],
    loop => [
        { name => 'red', },
        { name => 'green', },
        { name => 'blue', },
    ],
}), <<'END;', 'HTMLTemplate');
<html>
<head><title>HTMLTemplate</title></head>
<body>
<ul>
<li><a href="/top">top</a>

<li><a href="/search">search</a>
</ul>

<ul>

<li>red</li>

<li>green</li>

<li>blue</li>

</ul>
<div>this is footer</div>
</body>
</html>
END;

done_testing;

