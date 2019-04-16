
use strict;
use warnings;

package My::Text::Parser;
use Exception::Class (
    'My::Text::Parser::SyntaxError' => {
        description => 'syntax error',
        alias       => 'throw_syntax_error',
    },
);

use parent 'Text::Parser';

sub save_record {
    my ( $self, $line ) = @_;
    throw_syntax_error( error => 'syntax error' ) if _syntax_error($line);
    $self->SUPER::save_record($line);
}

sub _syntax_error {
    my $line = shift;
    $line =~ /Email:/ and $line !~ /[a-z0-9._]+[@][a-z0-9_]+[.][a-z]+/;
}

package main;

use Test::More;
use Test::Exception;
use Try::Tiny;

my $parser = My::Text::Parser->new();
throws_ok {
    $parser->read('t/account.txt');
}
'My::Text::Parser::SyntaxError', 'Syntax error caught';

done_testing;
