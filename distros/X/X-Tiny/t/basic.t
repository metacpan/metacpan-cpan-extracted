package t::X;

use parent qw( X::Tiny );

#----------------------------------------------------------------------

package t::X::Generic;

use parent qw( X::Tiny::Base );

#----------------------------------------------------------------------

package t::basic;

sub get_spewage {
    return "" . t::X->create('Generic', 'Bad!');
}

#----------------------------------------------------------------------

package t::main;

use Test::More;
plan tests => 6;

like(
    t::basic::get_spewage(),
    qr<t::X::Generic>,
    'spew includes the full exception type',
);

is(
    t::X->create('Generic', 'Bad!')->get_message(),
    'Bad!',
    'get_message()',
);

SKIP: {
    if ( $^V le v5.8.9 ) {
        skip 'Perl 5.8 doesn’t like our lazy-load of overload.pm', 3;
    }

    my $spewage = sub {
        t::basic::get_spewage('arg1', 424, "qu'ote", undef, [], {});
    }->();

    like(
        $spewage,
        qr<t::basic::get_spewage>,
        'spew includes the function where the exception happened',
    );

    like(
        $spewage,
        qr<Bad!>,
        'spew includes the message',
    );

    like(
        $spewage,
        qr<arg1.+'424'.+'qu\\'ote'.+undef.+ARRAY.+HASH>,
        'arguments list is in spew',
    );

    my $FILE = __FILE__;

    like(
        t::basic::get_spewage(),
        qr<\Q$FILE\E>,
        'spew includes the filename',
    );
}

1;
