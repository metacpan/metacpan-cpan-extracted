use t::oEmbed;

plan skip_all => "inc/.author is not there" unless -e "inc/.author";
plan tests => 2 * blocks;

use Web::oEmbed;

my $consumer = Web::oEmbed->new;

my $providers = read_json("t/providers.json");
for my $provider (@$providers) {
    $consumer->register_provider($provider);
}

run {
    my $block = shift;

    my $res1 = $consumer->embed($block->input, { format => 'json' });
    my $res2 = $consumer->embed($block->input, { format => 'xml' });

    is $res1->url, $res2->url;
    is canon($res1->render), canon($block->html);
};

sub canon {
    use HTML::TreeBuilder;
    my $t = HTML::TreeBuilder->new;
    $t->parse(shift);
    return $t->as_HTML;
}

__END__
===
--- input: http://www.flickr.com/photos/bees/2362225867/
--- html: <img src="http://farm4.static.flickr.com/3040/2362225867_4a87ab8baf.jpg" width="500" height="375" alt="Bacon Lollys" />

===
--- input: http://www.vimeo.com/757219
--- html
<object type="application/x-shockwave-flash" width="504" height="380" data="http://vimeo.com/moogaloop.swf?clip_id=757219&amp;server=vimeo.com&amp;fullscreen=1&amp;show_title=1&amp;show_byline=1&amp;show_portrait=1&amp;color=00ADEF">
        <param name="quality" value="best" />
        <param name="allowfullscreen" value="true" />
        <param name="scale" value="showAll" />
        <param name="movie" value="http://vimeo.com/moogaloop.swf?clip_id=757219&amp;server=vimeo.com&amp;fullscreen=1&amp;show_title=1&amp;show_byline=1&amp;show_portrait=1&amp;color=00ADEF" />
</object>
