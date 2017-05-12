package Test::MockPackages;
use strict;
use warnings;
use utf8;
use 5.010;

our $VERSION = '1.01';

use Carp qw(croak);
use English qw(-no_match_vars);
use Exporter qw(import);
use Test::MockPackages::Mock();
use Test::MockPackages::Package();
use Test::MockPackages::Returns qw(returns_code);

our @EXPORT_OK = qw(mock returns_code);

sub new {
    my ( $pkg ) = @ARG;

    return bless { '_packages' => {}, }, $pkg;
}

sub pkg {
    my ( $self, $pkg_name ) = @ARG;

    if ( !$pkg_name || ref( $pkg_name ) ) {
        croak( '$pkg_name is required and must be a SCALAR' );
    }

    if ( my $pkg = $self->{_packages}{$pkg_name} ) {
        return $pkg;
    }

    return $self->{_packages}{$pkg_name} = Test::MockPackages::Package->new( $pkg_name );
}

sub mock {
    my ( $config ) = @ARG;

    _must_validate( $config );

    # this while loop is similar to the one found in _must_validate, but I'm explicitly keeping them separate
    # so that we don't end up with partially built and mocked subroutines and methods.
    my $m = Test::MockPackages->new();
    while ( my ( $pkg, $subs_href ) = each %$config ) {
        my $mp = $m->pkg( $pkg );

        while ( my ( $sub, $config_aref ) = each %$subs_href ) {
            my $ms = $mp->mock( $sub );

            for ( my $i = 0; $i < @$config_aref; $i += 2 ) {
                my ( $mock_method, $args_aref ) = @$config_aref[ $i, $i + 1 ];

                my $method = $ms->can( $mock_method );
                $ms->$method( @$args_aref );
            }
        }
    }

    return $m;
}

sub _must_validate {
    my ( $config ) = @ARG;

    if ( ref( $config ) ne 'HASH' ) {
        croak( 'config must be a HASH' );
    }

    while ( my ( $pkg, $subs_href ) = each %$config ) {
        if ( ref( $subs_href ) ne 'HASH' ) {
            croak( "value for $pkg must be a HASH" );
        }

        while ( my ( $sub, $config_aref ) = each %$subs_href ) {
            if ( ref( $config_aref ) ne 'ARRAY' ) {
                croak( "value for ${pkg}::$sub must be an ARRAY" );
            }

            if ( @$config_aref % 2 > 0 ) {
                croak( "value for ${pkg}::$sub must be an even-sized ARRAY" );
            }

            for ( my $i = 0; $i < @$config_aref; $i += 2 ) {
                my ( $mock_method, $args_aref ) = @$config_aref[ $i, $i + 1 ];

                if ( ref( $args_aref ) ne 'ARRAY' ) {
                    croak( "arguments must be an ARRAY for mock method $mock_method in ${pkg}::$sub" );
                }

                if (!do {
                        local $EVAL_ERROR = undef;
                        eval { Test::MockPackages::Mock->can( $mock_method ) };
                    }
                    )
                {
                    croak( "$mock_method is not a capability of Test::MockPackages::Mock in ${pkg}::$sub" );
                }
            }
        }
    }

    return 1;
}

sub DESTROY {
    my ( $self ) = @ARG;

    # this is to ensure that the objects are destroyed in a consistent order.
    for my $pkg ( sort keys %{ $self->{_packages} } ) {
        delete $self->{_packages}{$pkg};
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::MockPackages - Mock external dependencies in tests

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

 my $m = Test::MockPackages->new();

 # basic mocking
 $m->pkg( 'ACME::Widget' )
   ->mock( 'do_thing' )
   ->expects( $arg1, $arg2 )
   ->returns( $retval );

 # ensure something is never called
 $m->pkg( 'ACME::Widget' )
   ->mock( 'dont_do_other_thing' )
   ->never_called();

 # complex expectation checking
 $m->pkg( 'ACME::Widget' )
   ->mock( 'do_multiple_things' )
   ->is_method()                      # marks do_multiple_things() as a method
   ->expects( $arg1, $arg2 )          # expects & returns for call #1
   ->returns( $retval )
   ->expects( $arg3, $arg4, $arg5 )   # expects & returns for call #2
   ->returns( $retval2 );

 # using the mock() sub.
 my $m = mock({
     'ACME::Widget' => {
         do_thing => [
            expects => [ $arg1, $arg2 ],
            returns => [ $retval ],
         ],
         dont_do_other_thing => [
            never_called => [],
         ],
         do_multiple_things => [
            is_method => [],
            expects => [ $arg1, $arg2 ],
            returns => [ $retval ],
            expects => [ $arg3, $arg4, $arg5 ],
            returns => [ $retval2 ],
         ],
     },
     'ACME::ImprovedWidget' => {
         ...
     },
 });

=head1 DESCRIPTION

Test::MockPackages is a package for mocking other packages as well as ensuring those packages are being used correctly.

Say we have a Weather class that can return the current degrees in Fahrenheit. In order to do this it uses another class, Weather::Fetcher which
makes an external call. When we want to write a unit test for Weather, we want to mock the functionality of Weather::Fetcher.

Here is the sample code for our Weather class:

 package Weather;
 use Moose;
 use Weather::Fetcher;
 sub degrees_f {
     my ( $self, $zip_code ) = @_;

     my $data = eval { Weather::Fetcher::fetch_weather( $zip_code ) };
     if ( !$data ) {
         return;
     }

     return $data->{temp_f} . "°F";
 }

And here's how we may choose to test this class. In the C<success> subtest, we use the mock() helper subroutine, and in the C<failure> method we use the OOP approach. Both provide identical functionality.

 use Test::More;
 use Test::MockPackages qw(mock);
 subtest 'degrees_f' => sub {
     subtest 'success' => sub {
         my $m = mock({
             'Weather::Fetcher' => {
                 fetch_weather => [
                    expects => [ '14202' ],
                    returns => [ { temp_f => 80 } ],
                 ],
             },
         });

         isa_ok( my $weather = Weather->new, 'Weather' );
         is( $weather->degrees_f( 14202 ), '80°F', 'correct temperature returned' );
     };

     subtest 'failure' => sub {
         my $m = Test::MockPackages->new();
         $m->pkg( 'Weather::Fetcher' )
           ->mock( 'fetch_weather' )
           ->expects( '14202' )
           ->returns();

         my $weather = Weather->new;
         is( $weather->degrees_f( 14202 ), undef, 'no temperature returned' );
     };
 };
 done_testing();

When we run our tests, you can see that Test::MockPackages validates the following for us: 1. the subroutine is called with the correct arguments, 2. the subroutine was called the correct number of times. Lastly, Test::MockPackages allows us to have this mocked subroutine return a consistent value.

         ok 1 - The object isa Weather
         ok 2 - Weather::Fetcher::fetch_weather expects is correct
         ok 3 - correct temperature returned
         ok 4 - Weather::Fetcher::fetch_weather called 1 time
         1..4
     ok 1 - success
         ok 1 - Weather::Fetcher::fetch_weather expects is correct
         ok 2 - no temperature returned
         ok 3 - Weather::Fetcher::fetch_weather called 1 time
         1..3
     ok 2 - failure
     1..2
 ok 1 - degrees_f
 1..1

For more information on how to properly configure your mocks, see L<Test::MockPackages::Mock>.

=head2 IMPORTANT NOTE

When the Test::MockPackages object is destroyed, it performs some final verifications. Therefore, it is important that the object is destroyed before done_testing() is called, or before the completion of the script execution. If your tests are contained within a block (e.g. a subtest, do block, etc) you typically don't need to worry about this. If all of your tests are in the top level package or test scope, you may want to undef your object at the end.

Example where we don't have to explicitly destroy our object:

 subtest 'my test' => sub {
     my $m = mock({ ... });

     # do tests
 }; # in this example, $m will be destroyed at the end of the subtest and that's OK.

 done_testing();

Example where we would have to explicitly destroy our object:

 my $m = mock({ ... });
 # do tests
 undef $m;
 done_testing();

=head1 CONSTRUCTOR

=head2 new( )

Instantiates and returns a new Test::MockPackages object.

You can instantiate multiple Test::MockPackages objects, but it's not recommended you mock the same subroutine/method within the same scope.

 my $m = Test::MockPackages->new();
 $m->pkg('ACME::Widget')->mock('do_thing')->never_called();

 if ( ... ) {
     my $m2 = Test::MockPackages->new();
     $m2->pkg('ACME::Widget')->mock('do_thing')->called(2); # ok
 }

 my $m3 = Test::MockPackages->new();
 $m3->pkg('ACME::Widget')->mock('do_thing')->called(3);        # not ok
 $m3->pkg('ACME::Widget')->mock('do_thing_2')->never_called(); # ok

Both this package, and L<Test::MockPackages::Package> are light-weight packages intended to maintain scope of your mocked subroutines and methods. The bulk of your mocking will take place on L<Test::MockPackages::Mock> objects. See that package for more information.

=head1 METHODS

=head2 pkg( Str $pkg_name ) : Test::MockPackages::Package

Instantiates a new L<Test::MockPackages::Package> object using for C<$pkg_name>. Repeated calls to this method with the same C<$pkg_name> will return the same object.

Return value: A L<Test::MockPackages::Package> object.

=head1 EXPORTED SUBROUTINES

=head2 mock( HashRef $configuration ) : Test::MockPackages

C<mock()> is an exportable subroutine (not exported by default) that allows you to quickly configure your mocks in one call. Behind the scenes, it converts your C<$configuration> to standard OOP calls to the L<Test::MockPackages>, L<Test::MockPackages::Package>, and L<Test::MockPackages::Mock> packages.

C<$configuration> expects the following structure:

 {
     $package_name => {
         $sub_or_method_name => [
            $option => [ 'arg1', ... ],
         ],
     }
     ...
 }

C<$package_name> is the name of your package. This is equvalent to the call:

 $m->pkg( $package_name )
 
C<$sub_or_method_name> is the name of the subroutine or method that you'd like to mock. This is equivalent to:

 $m->pkg( $package_name )
   ->mock( $sub_or_method_name )

The value for C<$sub_or_method_name> should be an ArrayRef. This is so we can support having multiple C<expects> and C<returns>.

C<$option> is the name of one of the methods you can call in L<Test::MockPackages::Mock> (e.g. C<called>, C<never_called>, C<is_method>, C<expects>, C<returns>). The value for C<$option> should always be an ArrayRef. This is equivalent to:

 $m->pkg( $package_name )
   ->mock( $sub_or_method_name )
   ->$option( @{ [ 'arg1', ... ] } );

=head2 returns_code(&)( CodeRef $coderef ) : Test::MockPackages::Returns

Imported from L<Test::MockPackages::Returns>. See that package for more information.

=head1 SEE ALSO

=over 4

=item L<Test::MockPackages::Mock>

=item L<Test::MockPackages::Returns>

=back

=head1 AUTHOR

Written by Tom Peters <tpeters at synacor.com>.

=head1 COPYRIGHT

Copyright (c) 2016 Synacor, Inc.

=cut
