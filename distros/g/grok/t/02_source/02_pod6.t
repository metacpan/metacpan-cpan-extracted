use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 4;
use App::Grok::Parser::Pod6;

my $pod = catfile('t_source', 'basic.pod');
ok(my $render = App::Grok::Parser::Pod6->new(), 'Constructed renderer object');

my $text = $render->render_file($pod, 'text');
my $ansi = $render->render_file($pod, 'ansi');

ok(length $text, 'Got text output');
ok(length $ansi, 'Got colored text output');
ok(length($ansi) > length($text), 'Colored output is longer than uncolored');
