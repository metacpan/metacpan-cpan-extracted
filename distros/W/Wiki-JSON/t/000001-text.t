use v5.38.2;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    is_deeply Wiki::JSON->new->parse(''), [], 'Empty string is empty mediawiki';
}
{
    is_deeply Wiki::JSON->new->parse( '
' ),
      [''], 'Empty lines are empty strings';
}
{
    my $parsed = Wiki::JSON->new->parse(
        'hola

adios'
    );

#    print STDERR Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [ 'hola', '', 'adios' ], 'Text parsing works';
}
done_testing();
