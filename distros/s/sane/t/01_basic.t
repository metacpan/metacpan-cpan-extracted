use Test::More;
use sane;
use Encode;

# strict
{
    eval '$foo = 1;';
    like ($@, qr/Global symbol "\$foo" requires explicit/, 'strict vars');
}

{
    eval 'bar';
    like ($@, qr/Bareword "bar" not allowed while "strict subs"/, 'strict subs');
}

{
    eval 'my $baz = "BAZ"; print $$baz;';
    like ($@, qr/Can't use string \("BAZ"\) as a SCALAR ref while "strict refs"/, 'strict refs');
}

# warnings

{
    my $w;
    local $SIG{__WARN__} = sub { $w = shift; };

    eval 'my $b; chop $b;';
    like ($w, qr/Use of uninitialized value \$b in scalar chop/, 'warnings');
}

# utf8

{
    my $string = 'いろは';
    my $binary;

    {
        no utf8;
        $binary = 'いろは';
    }

    is ($string, Encode::decode_utf8($binary), 'utf8: string is string');
    isnt ($string, $binary, 'utf8: string is not binary');
}

# feature

{
    eval 'say "we can use say";';
    is ($@, '', 'feature: say');
}

{
    eval q%
        my $foo = 'abc';
        my ($abc, $def, $xyz, $nothing);

        given($foo) {
            when (/^abc/) { $abc = 1; }
            when (/^def/) { $def = 1; }
            when (/^xyz/) { $xyz = 1; }
            default { $nothing = 1; }
        }
    %;
    is ($@, '', 'feature: switch');
}

{
    eval 'state $x = 42;';
    is ($@, '', 'feature: state');
}

done_testing;
