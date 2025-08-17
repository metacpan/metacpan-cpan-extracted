use v5.38.2;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

# I refuse to implement multiple levels of lists.
{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey
end of list/
    );

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'hey', ],
                },

            ],
        },
        'end of list',
      ],
      'Simple list test';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey '''bold'''
end of list/
    );

#            print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'hey ',
                        {
                            type   => 'bold',
                            output => ['bold'],
                        }
                    ],
                },

            ],
        },
        'end of list',
      ],
      'List works fine with bold';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/hola:
* hola<br>hola
* adios
* hey/
    );

    #        print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        'hola:',
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'hola', 'hola', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'adios', ],
                },
                {
                    type   => 'list_element',
                    output => [ 'hey', ],
                },

            ],
        },
      ],
      'A list can end being just a list';
}

{
    my $parsed = Wiki::JSON->new->parse(
        q/* one
* three [[Xinadi Legend]] xd
* two/
    );
    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed, [
        {
            type   => 'unordered_list',
            output => [
                {
                    type   => 'list_element',
                    output => [ 'one', ],
                },
                {
                    type   => 'list_element',
                    output => [
                        'three ',
                        {
                            type  => 'link',
                            title => 'Xinadi Legend',
                            link  => 'Xinadi Legend',
                        },
                        ' xd',
                    ],
                },
                {
                    type   => 'list_element',
                    output => [ 'two', ],
                },

            ],
        },
      ],
      'Parsing embedded elements works fine';
}
done_testing();
