use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    my $parsed = Wiki::JSON->new->parse('{{stub}}');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [ { type => 'template', template_name => 'stub', output => [] } ],
      'Simple template works';
}

{
    my $parsed = Wiki::JSON->new->parse('{{stub|hola|adios}}');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type          => 'template',
            template_name => 'stub',
            output        => [ 'hola', 'adios' ]
        }
      ],
      'Simple template with some arguments work';
}

{
    my $parsed = Wiki::JSON->new->parse('=== {{stub|hola|adios}} ===');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            'type'   => 'hx',
            'output' => [
                {
                    'output'        => [ 'hola', 'adios' ],
                    'type'          => 'template',
                    'template_name' => 'stub'
                },
            ],
            'hx_level' => 3
        }
      ],
      'Simple template with some arguments inside a title works';
}

{
    my $parsed =
      Wiki::JSON->new->parse('=== Hola: {{stub|hola|adios}} :Mundo ===');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            'type'   => 'hx',
            'output' => [
                'Hola: ',
                {
                    'output'        => [ 'hola', 'adios' ],
                    'type'          => 'template',
                    'template_name' => 'stub'
                },
                ' :Mundo'
            ],
            'hx_level' => 3
        }
      ],
'Simple template with some arguments inside a title with text content works';
}

{
    my $parsed = Wiki::JSON->new->parse('{{stub|hola|adios');
#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            'output'        => [ 'hola', 'adios' ],
            'type'          => 'template',
            'template_name' => 'stub'
        }
      ],
'Unterminated template does not wait forever';
}

{
    my $parsed = Wiki::JSON->new->parse('{{ hola }}');
#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        '{{ hola }}',
      ],
'Bad template format with spaces not parsed.';
}

{
    my $parsed = Wiki::JSON->new->parse('{{ hola }}{{stub|hello}}{{ hola }}}}{{123');
#    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        '{{ hola }}',
        {
            type => 'template',
            template_name => 'stub',
            output => [
                'hello',
            ]
        },
        '{{ hola }}}}{{123',
      ],
'Templates do not get confused even in very bad scenarios.';
}
done_testing();
