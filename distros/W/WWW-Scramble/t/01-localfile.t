#!perl
use utf8;
use Test::More;
use WWW::Scramble;
use File::Temp;

BEGIN {
    plan tests => 3
}
my $scrab = WWW::Scramble->new();
my $fh = File::Temp->new( SUFFIX => '.html' );
{
    local $/;
    my $content = <DATA>;
    print $fh $content;
}
$fh->close;
my %attr = (
    xtitle => '//td[@class="gensmall"]',
    xcontent => '//div[@class="postbody"]',
);
my $entry = $scrab->fetchfile($fh->filename, \%attr);
isa_ok ( $entry , 'WWW::Scramble::Entry' );
is ($entry->title->as_trimmed_text, 'Topic: I am title', 'Check title');
is ($entry->content->as_trimmed_text, 'I am the content', 'Check content');

diag( "Testing locally" );

__DATA__
<html>
<head>
</head>
<body>
<table>
<td class="gensmall" width="100%"><b>Topic</b>: I am title </div></td>
<td><div class="postbody">I am the content</div></td>
</table>
</body>
</html>
