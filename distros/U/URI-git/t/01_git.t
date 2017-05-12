use Test::Base;
use URI;

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $uri = URI->new($block->input);
    is $block->host, $uri->host;
    is $block->path, $uri->path;
};

__END__
===
--- input: git://github.com/miyagawa/remedie.git
--- host: github.com
--- path: /miyagawa/remedie.git
