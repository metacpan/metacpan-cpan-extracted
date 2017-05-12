use strict;
use File::Spec;
use Test::More;
use lib qw(lib);

my @tests = ();
my @files = <lib/eBay/API/XML/Call/*.pm>;

foreach my $file ( @files ) {
    my( $v, $dir, $filename ) = File::Spec->splitpath( $file );

    my $call = $filename;
    $call =~ s/\.pm$//;

    push( @tests, "eBay::API::XML::Call::$call" );
    push( @tests, "eBay::API::XML::Call::${call}::${call}RequestType" );
    push( @tests, "eBay::API::XML::Call::${call}::${call}RequestType" );

}

my @dt_files = <lib/eBay/API/XML/DataType/*.pm>;

foreach my $file ( @dt_files ) {
    my( $v, $dir, $filename ) = File::Spec->splitpath( $file );

    my $call = $filename;
    $call =~ s/\.pm$//;

    push( @tests, "eBay::API::XML::DataType::$call" );
}

plan tests => scalar( @tests );

foreach my $m ( @tests ) {
    use_ok( $m );
}
