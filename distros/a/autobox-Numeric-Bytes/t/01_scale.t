# -*- mode: cperl; -*-
use Test::Base;
use autobox::Numeric::Bytes;

filters {
    input    => [qw(autoboxnize eval)],
    expected => [qw(chomp)],
};

spec_file './t/scale.spec';

sub autoboxnize {
    return "use autobox::Numeric::Bytes; ".shift;
}

plan tests => 1 * blocks;

run {
    my $block = shift;
    is $block->input, $block->expected, $block->name;
};

__END__

