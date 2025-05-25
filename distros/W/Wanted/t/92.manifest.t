#!perl
BEGIN
{
    use strict;
    use warnings FATAL => 'all';
    use lib qw( ./blib/lib ./blib/arch ./lib ./t/lib );
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} )
    {
        plan( skip_all => "Author tests not required for installation" );
    }
};

my $min_tcm = 0.9;

eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if( $@ );

ok_manifest({ filter => [qr/Wanted\.(bs|c|o)$/] });

done_testing;
