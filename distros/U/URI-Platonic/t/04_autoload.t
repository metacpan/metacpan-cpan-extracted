use Test::Base;
use URI::Platonic;

plan tests => 10 * blocks;

run {
    my $block = shift;
    my $uri = URI::Platonic->new(uri => $block->input);

    is $uri->scheme   => $block->scheme;
    is $uri->host     => $block->host;
    is $uri->port     => $block->port;
    is $uri->path     => $block->path;
    is $uri->query    => $block->query;
    is $uri->fragment => $block->fragment;

    is $uri->authority => $block->authority;
    is $uri->opaque    => $block->opaque;
    is $uri->userinfo  => $block->userinfo;
    is $uri->host_port => $block->host_port;
};

__END__
===
--- input: http://foo:bar@example.com/path/to.html?query#fragment
--- scheme: http
--- host: example.com
--- port: 80
--- path: /path/to
--- query: query
--- fragment: fragment
--- authority: foo:bar@example.com
--- opaque: //foo:bar@example.com/path/to?query
--- userinfo: foo:bar
--- host_port: example.com:80
