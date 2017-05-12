use strict;
use warnings;
use Test::More;

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@; 

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";

my @modules = ( 
        { module => 'WWW::MelbourneBikeShare' },
        { module => 'WWW::MelbourneBikeShare', also_private => [ 'new' ] },
);

( $@ )  ? plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
        : plan tests => ( scalar @modules );

foreach my $module ( @modules ) { 
        defined $module->{also_private}
                ? pod_coverage_ok( $module->{module}, { also_private => $module->{also_private} } ) 
                : pod_coverage_ok( $module->{module} )
}
