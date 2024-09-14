#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

BEGIN {
   $^V ge v5.38 or
      plan skip_all => "Not supported on Perl $^V";
}

use meta;
no warnings qw( meta::experimental );

use feature 'class';
no warnings qw( experimental::class );

package NotAClass {
   sub not_a_method {}
}

class IsAClass {
   sub not_a_method {}
   method is_a_method {}
}

# ->is_class
{
   ok( !meta::package->get( "NotAClass" )->is_class,
      'metapkg for non-class is not a class' );

   ok( meta::package->get( "IsAClass" )->is_class,
      'metapkg for class is a class' );
}

# ->is_method
{
   my $metapkg = meta::package->get( "IsAClass" );

   ok( !$metapkg->get_symbol( '&not_a_method' )->is_method,
      'metasub for not_a_method is not a method' );

   ok( $metapkg->get_symbol( '&is_a_method' )->is_method,
      'metasub for is_a_method is a method' );
}

done_testing;
