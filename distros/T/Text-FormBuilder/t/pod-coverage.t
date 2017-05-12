use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 2;

# init is a overridden base class method
pod_coverage_ok("Text::FormBuilder", { trustme => [qr/^init$/] } );
pod_coverage_ok("Class::ParseText::Base");
