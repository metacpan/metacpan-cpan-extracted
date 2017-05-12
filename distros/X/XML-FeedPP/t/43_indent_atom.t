# ----------------------------------------------------------------
    use strict;
    use Test::More;
# ----------------------------------------------------------------
    my $link = "http://www.kawa.net/";
    my $title = "foobar";
# ----------------------------------------------------------------
{
    plan tests => 9;
    use_ok('XML::FeedPP');

    my $feeds = [
        XML::FeedPP::RDF->new(),
        XML::FeedPP::RSS->new(),
       XML::FeedPP::Atom::Atom03->new(),
       XML::FeedPP::Atom::Atom10->new(),
    ];
    foreach my $feed1 ( @$feeds ) {
        &test_indent( 2, $feed1 );
        &test_indent( 4, $feed1 );
    }
}
# ----------------------------------------------------------------
sub test_indent {
    my $indent = shift;
    my $feed   = shift;
    my $type   = ref $feed;
    $feed->link($link);
    $feed->add_item($link);
    my $string1 = $feed->to_string( indent => $indent );
    is( indent($string1), ' ' x $indent, "$type indent $indent" );
}
# ----------------------------------------------------------------
sub indent {
    my $str = shift;
    my $indent = ( $str =~ m#^(\040+)#m )[0];
    $indent;
}
# ----------------------------------------------------------------
