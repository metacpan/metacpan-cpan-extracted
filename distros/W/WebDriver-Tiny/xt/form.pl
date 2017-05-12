use strict;
use utf8;
use warnings;

use URI;
use URI::QueryParam;

sub {
    my $drv = shift;

    is_deeply [ map $_->attr('name'), $drv->('form')->find('input,select') ], [
        'text', "text '", 'text "', 'text \\', 'text ☃',
        ('radio') x 3, 'select', 'multi select',
    ], 'names of all form fields are correct';

    # Perl 6 envy :-(
    sub pick { map { splice @_, rand @_, 1 } 1 .. shift }
    sub roll { map { $_[ rand @_ ]         } 1 .. shift }

    $drv->('form')->submit( my %values = (
        'text'         => join( '', roll 3, 'a'..'z' ),
        "text '"       => join( '', roll 3, 'a'..'z' ),
        'text "'       => join( '', roll 3, 'a'..'z' ),
        'text \\'      => join( '', roll 3, 'a'..'z' ),
        'text ☃'      => join( '', roll 3, 'a'..'z' ),
        'radio'        => roll( 1, 'a'..'c' ),
        'select'       => roll( 1, 'a'..'c' ),
        'multi select' => [ pick( 2, 'a'..'c' ) ],
    ) );

    my %expected;

    while ( my ( $k, $v ) = each %values ) {
        utf8::encode $k;

        $expected{$k} = ref $v ? bag @$v : $v;
    }

    cmp_deeply +URI->new( $drv->url )->query_form_hash, \%expected,
        'submit works on all form fields correctly';

    my $elem = $drv->('input[type=text]');

    $elem->send_keys('♥ ♦ ♣ ♠');

    is $elem->attr('value'), '♥ ♦ ♣ ♠', 'elem->send_keys';

    $elem->clear;

    is $elem->attr('value'), '', 'elem->clear';

    ok $drv->('#enabled')->enabled, 'enabled';
    ok !$drv->('#disabled')->enabled, 'not enabled';
};
