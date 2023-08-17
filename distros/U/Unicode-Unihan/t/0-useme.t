use Test::More;

my $class = 'Unicode::Unihan';
use_ok( $class );
isa_ok( $class->new, $class );

done_testing();
