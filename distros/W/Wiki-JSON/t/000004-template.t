use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

sub stub_generate {
    my ( $element, $options, $parse_sub, $open_html_element_sub,
        $close_html_element_sub )
      = @_;
    my @dom;
    if ( $element->{template_name} eq 'stub' ) {
        push @dom,
          $open_html_element_sub->( 'span', 0, { style => 'color: red;' } );
        push @dom, @{ $element->{output} };
        push @dom, $close_html_element_sub->('span');
    }
    return \@dom;

}
{
    my $text = 'hola

hola {{stub}} hola

hola';
    my $parsed_html = Wiki::JSON->new->pre_html(
        $text,
        {
            is_inline => sub {
                return 0;
            },
            generate_elements => sub {
                return stub_generate(@_);
            }
        }
    );

#    print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola ',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element(
            'span', 0, { style => 'color: red;' }
        ),
        Wiki::JSON::HTML->_close_html_element('span'),
        Wiki::JSON::HTML->_open_html_element('p'),
        ' hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element( 'article', ),
      ],
      'Template works in block';
}
{
    my $text = q@hola

hola '''bold''' {{stub}} hola

hola@;
    my $parsed_html = Wiki::JSON->new->pre_html(
        $text,
        {
            is_inline => sub {
                return 1;
            },
            generate_elements => sub {
                return stub_generate(@_);
            }
        }
    );

#    print STDERR Data::Dumper::Dumper @$parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola ',
        Wiki::JSON::HTML->_open_html_element('b'),
        'bold',
        Wiki::JSON::HTML->_close_html_element('b'),
        ' ',
        Wiki::JSON::HTML->_open_html_element(
            'span', 0, { style => 'color: red;' }
        ),
        Wiki::JSON::HTML->_close_html_element('span'),
        ' hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_open_html_element('p'),
        'hola',
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element( 'article', ),
      ],
      'Inline template generates html ok';
}
{
    my $text   = '{{stub}}';
    my $parsed = Wiki::JSON->new->parse($text);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [ { type => 'template', template_name => 'stub', output => [] } ],
      'Simple template works';
    my $parsed_html = Wiki::JSON->new->pre_html(
        $text,
        {
            generate_elements => sub {
                return stub_generate(@_);
            }
        }
    );

    #    print STDERR Data::Dumper::Dumper $parsed_html;
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        Wiki::JSON::HTML->_open_html_element(
            'span', 0, { style => 'color: red;' }
        ),
        Wiki::JSON::HTML->_close_html_element('span'),
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element( 'article', ),
      ],
      'Simple template works html™';
}

{
    my $text   = '{{stub|hola|adios|<nowiki>}}</nowiki>|}}';
    my $parsed = Wiki::JSON->new->parse($text);

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type          => 'template',
            template_name => 'stub',
            output        => [ 'hola', 'adios', '}}', '' ]
        }
      ],
      'Simple template with some arguments work including nowiki and empty';
    my $parsed_html = Wiki::JSON->new->pre_html(
        $text,
        {
            generate_elements => sub {
                return stub_generate(@_);
            }
        }
    );

    #    print Data::Dumper::Dumper($parsed_html);
    is_deeply $parsed_html,
      [
        Wiki::JSON::HTML->_open_html_element(
            'article', 0, { class => 'wiki-article' }
        ),
        Wiki::JSON::HTML->_open_html_element('p'),
        Wiki::JSON::HTML->_open_html_element(
            'span', 0, { style => 'color: red;' }
        ),
        'hola', 'adios', '}}', '',
        Wiki::JSON::HTML->_close_html_element('span'),
        Wiki::JSON::HTML->_close_html_element('p'),
        Wiki::JSON::HTML->_close_html_element( 'article', ),
      ],
'Simple template with some arguments work including nowiki and empty html™';
}

{
    my $parsed = Wiki::JSON->new->parse(
        '{{stub|hola|adios|\'\'ignored italic\'\'|<nowiki>}}</nowiki>|');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        {
            type          => 'template',
            template_name => 'stub',
            output => [ 'hola', 'adios', q/''ignored italic''/, '}}', '' ]
        }
      ],
'Simple template with some arguments work including nowiki and empty unterminated';
}

{
    my $parsed = Wiki::JSON->new->parse('=== {{stub|hola|adios}} ===');

    #        print Data::Dumper::Dumper($parsed);
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
      [ '{{ hola }}', ],
      'Bad template format with spaces not parsed.';
}

{
    my $parsed =
      Wiki::JSON->new->parse('{{ hola }}{{stub|hello}}{{ hola }}}}{{123');

    #    print Data::Dumper::Dumper($parsed);
    is_deeply $parsed,
      [
        '{{ hola }}',
        {
            type          => 'template',
            template_name => 'stub',
            output        => [ 'hello', ]
        },
        '{{ hola }}}}{{123',
      ],
      'Templates do not get confused even in very bad scenarios.';
}
done_testing();
