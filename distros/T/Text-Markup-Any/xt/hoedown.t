use strict;
use utf8;
use Test::More;

use Text::Markup::Any;

my $md = Text::Markup::Any->new('Text::Markdown::Hoedown');
like $md->markup('## 新しい'), qr!<h2.*>新しい</h2>!;

my $md2 = markupper 'Markdown::Hoedown';
like $md2->markup('## 朝が来た'), qr!<h2.*>朝が来た</h2>!;

done_testing;
