use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 5 }


my $pd = XML::Generator::PerlData->new();

my $lcalpha = join '', ('a' .. 'z');
my $ucalpha = join '', ('A' .. 'Z');
my $numeric = join '', (0 .. 9);

{
my $t1 = $pd->_name_fixer( $lcalpha );
#warn $t1 . "\n";
ok ( $t1 eq $lcalpha );
}

{
my $t1 = $pd->_name_fixer( $ucalpha );
#warn $t1 . "\n";
ok ( $t1 eq $ucalpha );
}

{
my $t1 = $pd->_name_fixer( $numeric );
#warn $t1 . "\n";
ok ( $t1 eq '_123456789' );
}

{
my $t1 = $pd->_name_fixer( '0!@$%^&*()+{}[]"|/\><~`=' );
#warn $t1 . "\n";
ok ( $t1 eq '________________________' );
}

{
my $t1 = $pd->_name_fixer( ':-' );
#warn $t1 . "\n";
ok ( $t1 eq ':-' );
}

