use strict;
use warnings;
use Test::Base;
use DateTime;

filters { expected => 'chomp' };

my $base = DateTime->new(year => 2008, month => 1, day => 15);

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $duration = eval "use autobox; use autobox::DateTime::Duration;" . $block->input;
    die $@ if $@;
    is $base->clone->add_duration($duration)->iso8601, $block->expected, $block->input;
};

__END__

===
--- input: 1->day
--- expected: 2008-01-16T00:00:00

===
--- input: 2->days
--- expected: 2008-01-17T00:00:00

===
--- input: 1->minute
--- expected: 2008-01-15T00:01:00

===
--- input: 2->minutes
--- expected: 2008-01-15T00:02:00

===
--- input: 1->second
--- expected: 2008-01-15T00:00:01

===
--- input: 2->seconds
--- expected: 2008-01-15T00:00:02

===
--- input: 1->minute + 2->seconds
--- expected: 2008-01-15T00:01:02

===
--- input: 2->months
--- expected: 2008-03-15T00:00:00

===
--- input: 2->years
--- expected: 2010-01-15T00:00:00

===
--- input: 2->weeks
--- expected: 2008-01-29T00:00:00

===
--- input: 2->fortnights
--- expected: 2008-02-12T00:00:00
