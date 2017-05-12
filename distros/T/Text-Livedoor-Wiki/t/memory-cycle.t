use Test::More qw/no_plan/;
use Test::Memory::Cycle;
use warnings;
use strict;
use Text::Livedoor::Wiki;

my $parser = Text::Livedoor::Wiki->new();

$parser->parse("Hoge %%hoge%%");
memory_cycle_ok( $parser );
#weakened_memory_cycle_ok( $parser );


__END__
