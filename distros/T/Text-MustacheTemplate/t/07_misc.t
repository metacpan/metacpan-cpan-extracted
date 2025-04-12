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

subtest 'keep default delimiters when parsed' => sub {
    my $template = do {
        local $Text::MustacheTemplate::OPEN_DELIMITER = '<%';
        local $Text::MustacheTemplate::CLOSE_DELIMITER = '%>';
        Text::MustacheTemplate->parse('{{message}}=<%message%>');
    };

    local $Text::MustacheTemplate::OPEN_DELIMITER = '{{';
    local $Text::MustacheTemplate::CLOSE_DELIMITER = '}}';
    my $text = $template->({ message => 'hello' });
    is $text, '{{message}}=hello';
};

subtest 'no lambda template rendering by default' => sub {
    my $text = Text::MustacheTemplate->render('{{{message}}}', { message => sub { 'hello {{world}}' } });
    is $text, 'hello {{world}}';
};

subtest 'nested lambda expanding and lambda template rendering' => sub {
    local $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING = 1;
    my $text = Text::MustacheTemplate->render('{{#wrappers.bold}}{{message}}{{/wrappers.bold}}', {
        wrappers => sub { +{ bold => sub { '<b>'.$_[0].'</b>' } } },
        message  => 'hello!',
    });
    is $text, '<b>hello!</b>';
};

subtest 'nested lambda expanding and lambda template rendering' => sub {
    local $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING = 1;
    my $text = Text::MustacheTemplate->render('{{#wrappers.bold}}{{message}}{{/wrappers.bold}}', {
        wrappers => sub { +{ bold => sub { '<b>{{!comment}}'.$_[0].'</b>' } } },
        message  => 'hello!',
    });
    is $text, '<b>hello!</b>';
};

subtest 'contextual optimize applies convolution operation for current context' => sub {
    my $text = Text::MustacheTemplate->render('{{#.}}success{{/.}}{{^.}}fail{{/.}}', 1);
    is $text, 'success';
};

subtest 'dynamic partial template for current context' => sub {
    local $Text::MustacheTemplate::REFERENCES{'dynamic'} = Text::MustacheTemplate->parse('success');
    my $text = Text::MustacheTemplate->render('{{>*.}}', 'dynamic');
    is $text, 'success';
};

subtest 'dynamic parent template for current context' => sub {
    local $Text::MustacheTemplate::REFERENCES{'dynamic'} = Text::MustacheTemplate->parse('success{{$a}}?{{/a}}');
    my $text = Text::MustacheTemplate->render('{{<*.}}{{$a}}!{{/a}}{{/*.}}', 'dynamic');
    is $text, 'success!';
};

subtest 'invarted section for current context' => sub {
    my $text = Text::MustacheTemplate->render('{{#ok}}{{^.}}success{{/.}}{{/ok}}', { ok => [0, 1] });
    is $text, 'success';
};

done_testing;