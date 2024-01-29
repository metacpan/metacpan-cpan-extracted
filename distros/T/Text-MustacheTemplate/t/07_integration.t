use strict;
use warnings;

use Test::More 0.98;

use Text::MustacheTemplate;

subtest 'change default delimiters' => sub {
    local $Text::MustacheTemplate::OPEN_DELIMITER = '<%';
    local $Text::MustacheTemplate::CLOSE_DELIMITER = '%>';
    my $text = Text::MustacheTemplate->render('{{message}}=<%message%>', { message => 'hello' });
    is $text, '{{message}}=hello';
};

done_testing;