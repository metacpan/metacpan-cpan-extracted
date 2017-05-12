# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
{
    local $@;
    eval { require 5.008001; };
    plan skip_all => 'Perl 5.8.1 is required.' if $@;
}
# ----------------------------------------------------------------
{
    plan tests => 31;
    use_ok('XML::FeedPP');
    &test_indent( 2 );
    &test_indent( 4 );
}
# ----------------------------------------------------------------
sub test_indent {
    my $indent = shift;
    my $feed   = XML::FeedPP::RSS->new();
    $feed->title( "\xC3\xAB" );

    my $string1 = $feed->to_string( indent => $indent );
    my $string2 = $feed->to_string( 'UTF-8'  , indent => $indent );
    my $string3 = $feed->to_string( 'Latin-1', indent => $indent );
    my $string4 = $feed->to_string( output_encoding => 'UTF-8'  , indent => $indent );
    my $string5 = $feed->to_string( output_encoding => 'Latin-1', indent => $indent );

    is( encoding($string1), 'UTF-8',   'encoding default' );
    is( encoding($string2), 'UTF-8',   'encoding 3 args UTF-8' );
    is( encoding($string3), 'LATIN-1', 'encoding 3 args Latin-1' );
    is( encoding($string4), 'UTF-8',   'encoding 4 args UTF-8' );
    is( encoding($string5), 'LATIN-1', 'encoding 4 args Latin-1' );

    is( title($string1), "\xC3\xAB", 'title default' );
    is( title($string2), "\xC3\xAB", 'title 3 args UTF-8' );
    is( title($string3), "\xEB",     'title 3 args Latin-1' );
    is( title($string4), "\xC3\xAB", 'title 4 args UTF-8' );
    is( title($string5), "\xEB",     'title 4 args Latin-1' );

    is( indent($string1), ' ' x $indent, 'indent default' );
    is( indent($string2), ' ' x $indent, 'indent 3 args UTF-8' );
    is( indent($string3), ' ' x $indent, 'indent 3 args Latin-1' );
    is( indent($string4), ' ' x $indent, 'indent 4 args UTF-8' );
    is( indent($string5), ' ' x $indent, 'indent 4 args Latin-1' );
}
# ----------------------------------------------------------------
sub indent {
    my $str = shift;
    my $indent = ( $str =~ m#^(\040+)#m )[0];
    $indent;
}
sub encoding {
    my $str = shift;
    my $encoding = ( $str =~ m#<?xml[^<>]*encoding="([^"]*)"# )[0];
    uc($encoding);
}
sub title {
    my $str = shift;
    my $title = ( $str =~ m#<title>([^<>]*)</title># )[0];
    $title =~ s/^\s+//;
    $title =~ s/\s+$//;
    $title;
}
# ----------------------------------------------------------------
