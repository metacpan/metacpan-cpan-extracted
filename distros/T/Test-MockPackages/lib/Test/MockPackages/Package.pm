package Test::MockPackages::Package;
use strict;
use warnings;
use utf8;

our $VERSION = '1.00';

use Carp qw(croak);
use English qw(-no_match_vars);
use Test::MockPackages::Mock();

sub new {
    my ( $pkg, $package_name ) = @ARG;

    if ( !$package_name || ref( $package_name ) ) {
        croak( '$package_name is required and must be a SCALAR' );
    }

    return bless {
        _package_name => $package_name,
        _mocks        => {},
    }, $pkg;
}

sub mock {
    my ( $self, $name ) = @ARG;

    if ( !$name || ref( $name ) ) {
        croak( '$name is required and must be a SCALAR' );
    }

    if ( my $mock = $self->{_mocks}{$name} ) {
        return $mock;
    }

    return $self->{_mocks}{$name} = Test::MockPackages::Mock->new( $self->{_package_name}, $name );
}

sub DESTROY {
    my ( $self ) = @ARG;

    # ensures that objects are destroyed in a consistent order.
    for my $key ( sort keys %{ $self->{_mocks} } ) {
        delete $self->{_mocks}{$key};
    }
}

1;

__END__

=head1 NAME

Test::MockPackages::Package - Helper package for mocking subroutines and methods on a given package.

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

 my $m = Test::MockPackages::Package->new('ACME::Widget');
   ->mock( 'do_thing' )
   ->expects( $arg1, $arg2 )
   ->returns( $retval );

=head1 CONSTRUCTOR

=head2 new( )

Instantiates and returns a new Test::MockPackages::Package object.

Both this package, and L<Test::MockPackages> are light-weight packages intended to maintain scope of your mocked subroutines and methods. The bulk of your mocking will take place on L<Test::MockPackages::Mock> objects. See that package for more information.

=head1 METHODS

=head2 mock( Str $name ) : Test::MockPackages::Mock

Instantiates a new L<Test::MockPackages::Mock> object using for subroutine or method named C<$name>. Repeated calls to this method with the same C<$name> will return the same object.

Return value: A L<Test::MockPackages::Mock> object.

=head1 SEE ALSO

=over 4

=item L<Test::MockPackages::Mock>

=back

=head1 AUTHOR

Written by Tom Peters <tpeters at synacor.com>.

=head1 COPYRIGHT

Copyright (c) 2016 Synacor, Inc.

=cut
