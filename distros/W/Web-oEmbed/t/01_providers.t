use t::oEmbed;
plan tests => 1 * blocks;

use Web::oEmbed;

my $consumer = Web::oEmbed->new;

my $providers = read_json("t/providers.json");
for my $provider (@$providers) {
    $consumer->register_provider($provider);
}

run {
    my $block = shift;

    my $api_url = $consumer->request_url($block->input);
    is( canon($api_url), canon($block->output) );
};

sub canon {
    my $uri = URI->new(shift);
    my %params = $uri->query_form;
    $uri->query_form(map { $_ => $params{$_} } sort keys %params);
    $uri;
}

__END__
===
--- input: http://www.flickr.com/photos/bees/2362225867/
--- output: http://www.flickr.com/services/oembed/?url=http%3A%2F%2Fwww.flickr.com%2Fphotos%2Fbees%2F2362225867%2F&format=json

===
--- input: http://www.hulu.com/watch/20807/late-night-with-conan-obrien-wed-may-21-2008
--- output: http://www.hulu.com/api/oembed.json?url=http%3A//www.hulu.com/watch/20807/late-night-with-conan-obrien-wed-may-21-2008
