use Test::More qw/no_plan/;
use Test::Exception;
use warnings;
use strict;
use Text::Livedoor::Wiki::Inline;
use Text::Livedoor::Wiki::Function;
use Text::Livedoor::Wiki::Plugin;

my $function = Text::Livedoor::Wiki::Function->new( { plugins => Text::Livedoor::Wiki::Plugin->function_plugins  } );

throws_ok { Text::Livedoor::Wiki::Inline->new({ 
    plugins => [ 'NotFoundHoge' ],
    function => $function,
}) } qr/NotFoundHoge\.pm/ , 'fail to load inline plugin';
