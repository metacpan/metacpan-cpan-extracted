# standard Test::Pod::Coverage recipe for module authors

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@;
my $trusted = join "|", split ' ', do { local $/; <DATA> };
all_pod_coverage_ok( { trustme => [qr/^$trusted$/] } );


# Properties and Generators are created and invoked using special
# syntax.  Thus the typical OO means of creating them are discouraged
# in the documentation.  Nevertheless, the documentation does fully
# explain how to create and use these objects.  The following hints
# help Pod::Coverage to recognize the fact:

__DATA__
Property
Gen
generate
new
