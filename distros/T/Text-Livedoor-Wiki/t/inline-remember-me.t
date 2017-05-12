# this test for remember_me coverage.
use lib 't/lib';
use Test::More qw/no_plan/;
use warnings;
use strict;
use Text::Livedoor::Wiki::Inline;
use Text::Livedoor::Wiki::Function;
use Text::Livedoor::Wiki::Plugin;

my $function = Text::Livedoor::Wiki::Function->new( { plugins => Text::Livedoor::Wiki::Plugin->function_plugins  } );
my $inline = Text::Livedoor::Wiki::Inline->new({ 
    plugins => [qw/AAA BBB/],
    function => $function,
});
my $inline2 = Text::Livedoor::Wiki::Inline->new({ 
    plugins => [qw/BBB AAA/],
    function => $function,
});

is( $inline->{elements}[0]{regex} ,$inline2->{elements}[0]{regex} , 'inline order' );
