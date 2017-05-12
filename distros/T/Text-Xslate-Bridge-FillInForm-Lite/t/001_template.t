use strict;
use warnings;
use Test::More tests => 1;
use Text::Xslate;

my $tx = Text::Xslate->new(
    module => [ 'Text::Xslate::Bridge::FillInForm::Lite' ]
);

my $output = $tx->render_string(<<'T', { q => { foo => 'bar' } } );
: block form | fillinform($q) -> {
<form><input name="foo" type="text" /></form>
: }
T

is $output, <<'T', 'fillinform ok';
<form><input name="foo" type="text" value="bar" /></form>
T
