use Test::Base;
use URI::Platonic;

plan tests => 4 * blocks;

run {
    my $block = shift;
    my $uri = URI::Platonic->new(uri => $block->input);

    is $uri->path      => $block->path;
    is $uri->extension => $block->extension;
    is $uri->platonic  => $block->platonic;
    is $uri->distinct  => $block->distinct;
};

__END__
===
--- input: http://example.com/.dot
--- path: /.dot
--- platonic: http://example.com/.dot
--- distinct: http://example.com/.dot

===
--- input: http://example.com/.dot.ext
--- path: /.dot
--- extension: ext
--- platonic: http://example.com/.dot
--- distinct: http://example.com/.dot.ext
