use strict;
use warnings;
use Test::Base;
use DateTime;

filters { expected => 'chomp', input => 'chomp' };

my $base = DateTime->new(year => 2008, month => 1, day => 15);

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $datetime = eval "use autobox; use autobox::DateTime::Duration;" . $block->input . "(\$base)";
    die $@ if $@;
    is $datetime->iso8601, $block->expected, $block->input;
};

__END__

===
--- input: 1->year->ago
--- expected: 2007-01-15T00:00:00

===
--- input: 2->minutes->until
--- expected: 2008-01-14T23:58:00

===
--- input: 2->hours->from_now
--- expected: 2008-01-15T02:00:00

===
--- input: 3->years->since
--- expected: 2011-01-15T00:00:00
