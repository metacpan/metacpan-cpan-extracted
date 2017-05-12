use Test::Base;
use URI::Platonic;

plan tests => 3 * blocks;

run {
    my $block = shift;
    my $uri = URI::Platonic->new(uri => $block->input);

    if ($block->path) {
        $uri->path($block->path);
    }
    elsif ($block->extension) {
        $uri->extension($block->extension);
    }

    is $uri->platonic  => $block->platonic;
    is $uri->distinct  => $block->distinct;
    is $uri->as_string => $block->as_string;
};

__END__
===
--- input: http://example.com/path/to/resource.html
--- path: /foo
--- platonic: http://example.com/foo
--- distinct: http://example.com/foo.html
--- as_string: http://example.com/foo

===
--- input: http://example.com/path/to/resource.html
--- extension: xml
--- platonic: http://example.com/path/to/resource
--- distinct: http://example.com/path/to/resource.xml
--- as_string: http://example.com/path/to/resource
