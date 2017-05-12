use strict;
use warnings;

use Test::More;
use Text::Xslate;

my $tx = Text::Xslate->new(syntax => 'Any', cache => 0, path => [qw{ t/template }]);

is($tx->render('0.tx', { foo => 'Any Syntax'}), q{Hello Any Syntax.});

done_testing;

