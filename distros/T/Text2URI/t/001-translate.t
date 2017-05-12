use strict;
use Text2URI;
use Test::More;
use utf8;

my $txt = new Text2URI();

is(
    $txt->translate('Atenção SomeText (0)2302-3234   otherthing    !!'),
    'atencao-sometext-0-2302-3234-otherthing',
    'atencao-sometext-0-2302-3234-otherthing ok');



is($txt->translate('other text', '_'), 'other_text', 'other_text ok');

is($txt->translate('that Name of file.jpg'), 'that-name-of-file.jpg', 'filename ok!');

$txt->old_alphanumeric_regexp(1);

is($txt->translate('that Name of file.jpg'), 'that-name-of-file-jpg', 'filename with old_alphanumeric_regexp ok!');


done_testing;



