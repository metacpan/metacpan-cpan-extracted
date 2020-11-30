
use strict;
use warnings;

package BadJoiner;
use parent 'Text::Parser';

sub new {
    my $pkg = shift;
    $pkg->SUPER::new( auto_chomp => 1, multiline_type => 'join_next' );
}

package main;
use Test::More;
use Test::Exception;

throws_ok {
    my $pars = BadJoiner->new();
    $pars->read('t/data.txt');
}
'Text::Parser::Error',
    'join_next multi-line parsers must have a continuation character';

done_testing;

