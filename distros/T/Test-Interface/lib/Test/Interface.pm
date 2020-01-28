package Test::Interface;

our $VERSION = '0.01';


use strict;
use warnings;


use Test::Builder;
use Role::Inspector;


use Exporter qw/import/;
our @EXPORT = qw/interface_ok/;



my $Test = Test::Builder->new;

sub interface_ok($$;$) {
    my $thing     = shift;
    my $interface = shift;
    my $test_name = shift // "$thing does interface $interface";
    
    if (Role::Inspector->does_role( $thing, $interface ) ) {
        return $Test->ok( 1, $test_name )
    }
    
    $Test->diag("$thing does not implement the $interface interface\n");
    
    return $Test->ok( 0, $test_name )
}

1;
