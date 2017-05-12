use strict;
use warnings;

use Test::More;
use Text::Xslate;

use Text::Xslate::Syntax::Any;

my $tx = Text::Xslate->new(syntax => 'Any', cache => 0, path => [ qw{ t/template } ]);

subtest 'Kolon' => sub {
    $Text::Xslate::Syntax::Any::DEFAULT_SYNTAX = 'TTerse';
    $Text::Xslate::Syntax::Any::DETECT_SYNTAX  = Text::Xslate::Syntax::Any::generate_syntax_detecter__by_suffix({
        tx_or_tt => 'Kolon',
    });
    is($tx->render('index.tx_or_tt', { foo => 'Kolon' }), q{Kolon [% $foo %]}, 'Kolon');
};

subtest 'TTerse' => sub {
    $Text::Xslate::Syntax::Any::DEFAULT_SYNTAX = 'Kolon';
    $Text::Xslate::Syntax::Any::DETECT_SYNTAX  = Text::Xslate::Syntax::Any::generate_syntax_detecter__by_suffix({
        tx_or_tt => 'TTerse',
    });
    is($tx->render('index.tx_or_tt', { foo => 'TTerse' }), q{<: $foo :> TTerse}, 'TTerse');
};

done_testing;

