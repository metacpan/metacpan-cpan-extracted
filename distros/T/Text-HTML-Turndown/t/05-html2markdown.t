#!perl
use 5.020;
use Test2::V0 '-no_srand';
use Text::HTML::Turndown 'html2markdown';

my $html = <<'HTML';
<html>
<body>
<h1>Hello World!</h1>
</body>
</html>
HTML

my $tfm = html2markdown( $html );
like $tfm->data_text, qr/^Hello World!$/m;
like $tfm->data_text, qr/^============$/m;

done_testing();
