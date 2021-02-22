use strict;
use warnings;

use Test::More;

my $class = 'Text::Lorem';
use_ok($class);

my $object = $class->new();
isa_ok( $object, $class );

my @methods = (qw{ new generate_wordlist wordlist wordcount get_word words get_sentence sentences get_paragraph paragraphs });
can_ok( $object, $_ ) foreach @methods;

done_testing();
