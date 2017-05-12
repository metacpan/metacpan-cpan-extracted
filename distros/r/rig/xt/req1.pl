package main;
use Inline C;
$a = 1;
hello();
eval q{ carp( "hello" ); }

__DATA__
__C__

void hello() {
    load_module(PERL_LOADMOD_NOIMPORT, newSVpvn("Carp", 4), newSVnv(0.01));

    printf("%s", "hellooooo" );
}
