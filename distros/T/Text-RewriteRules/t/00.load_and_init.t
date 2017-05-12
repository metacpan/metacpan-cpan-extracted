# -*- cperl -*-
use Test::More tests => 1;

BEGIN { use_ok( 'Text::RewriteRules' ) }

for my $file (qw/01.simple.t 02.mark.t 03.mline.t 04.lexer.t 05.xml.t 06.parenthesis.t/) {
    open R, "t/$file" or die "Can't open file t/$file\n";
    open W, ">t/1$file" or die "Can't write file t/1$file\n";
    my $str;
    {
        undef $/;
        $str = <R>;
    }
    print W Text::RewriteRules::__compiler($str);
    close W;
    close R;
}

