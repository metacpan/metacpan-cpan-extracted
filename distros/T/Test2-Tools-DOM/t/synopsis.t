use Test2::V0;
use Test2::Tools::DOM;

my $html = <<'HTML';
<!DOCTYPE html>
<html lang="en-US">
    <head>
        <title>A test document</title>
        <link rel="icon" href="favicon.ico">
    </head>
    <body>
        <p class="paragraph">Some text</p>
    </body>
</html>
HTML

is $html, dom {
    children bag {
        item dom { tag 'body' };
        item dom { tag 'head' };
        end;
    };

    at 'link[rel=icon]' => dom {
        attr href => 'favicon.ico'
    };

    find '.paragraph' => array {
        item dom { text 'Some text' };
        end;
    };
};

done_testing;
