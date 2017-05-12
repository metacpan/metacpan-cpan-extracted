use Test::Base;
use URI::Platonic;

plan tests => 5 * blocks;

run {
    my $block = shift;
    my $uri = URI::Platonic->new(uri => $block->input);

    is $uri->path      => $block->path;
    is $uri->extension => $block->extension;
    is $uri->platonic  => $block->platonic;
    is $uri->distinct  => $block->distinct;
    is $uri->as_string => $block->as_string;
};

__END__
===
--- input: http://example.com/path/to/resource.html
--- path: /path/to/resource
--- extension: html
--- platonic: http://example.com/path/to/resource
--- distinct: http://example.com/path/to/resource.html
--- as_string: http://example.com/path/to/resource

