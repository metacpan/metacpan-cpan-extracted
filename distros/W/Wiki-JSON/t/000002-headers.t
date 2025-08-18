use v5.16.3;

use strict;
use warnings;

use lib 'lib';

use Test::Most;

use_ok 'Wiki::JSON';

{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $parsed =
          Wiki::JSON->new->parse( ( '=' x $i ) . ' hola ' . ( '=' x $i ) );
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header well-formed';
    }
}
{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $parsed =
          Wiki::JSON->new->parse( ( '=' x $i ) . ' hola ' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header without equal signs in the end';
    }
}

{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $parsed =
          Wiki::JSON->new->parse( ( '=' x $i ) . ' hola =' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
          ],

          'Single header unbalanced';
    }
}
{
    for ( my $i = 1 ; $i < 7 ; $i++ ) {
        my $parsed =
          Wiki::JSON->new->parse( ( '=' x $i ) . ' hola 
hola
hola
hola' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => $i,
                'type'     => 'hx'
            },
            'hola',
            'hola',
            'hola',
          ],

          'Single header without equal signs in the end plus text';
    }
}
{
        my $parsed =
          Wiki::JSON->new->parse( 'hola === hola === hola
hola
hola
hola' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            'hola ',
            {
                'output'   => ['hola'],
                'hx_level' => 3,
                'type'     => 'hx'
            },
            ' hola',
            'hola',
            'hola',
            'hola',
          ],

          'Cursed titles in the same line work too';
}

{
        my $parsed =
          Wiki::JSON->new->parse( '=== hola = hola
hola
hola
hola' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            {
                'output'   => ['hola'],
                'hx_level' => 3,
                'type'     => 'hx'
            },
            ' hola',
            'hola',
            'hola',
            'hola',
          ],

          'Cursed titles in the same line work too unbalanced and without start';
}

{
        my $parsed =
          Wiki::JSON->new->parse( 'hola = hola ===
hola
hola
hola' ); 
#        print STDERR Data::Dumper::Dumper $parsed;
        is_deeply $parsed,
          [
            'hola ',
            {
                'output'   => ['hola'],
                'hx_level' => 1,
                'type'     => 'hx'
            },
            'hola',
            'hola',
            'hola',
          ],

          'Cursed titles in the same line work too unbalanced and without end';
}

done_testing();
