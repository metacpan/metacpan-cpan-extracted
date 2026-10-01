use strict;
use warnings;
use utf8;
use Test::More;
use Text::Markdown::Discount qw/markdown/;

my $html = '<article>abc</article>';
{
    my $md = Text::Markdown::Discount->new();
    is trim(markdown($html)), '<article>abc</article>';
}

{
    is trim(Text::Markdown::Discount::markdown($html)), '<article>abc</article>';
}

done_testing;

sub trim {
    my $text = shift;
    $text =~ s/\A\s+//ms;
    $text =~ s/\s+$//ms;
    $text;
}
