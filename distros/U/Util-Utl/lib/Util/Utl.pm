package Util::Utl;
BEGIN {
  $Util::Utl::VERSION = '0.0011';
}
# ABSTRACT: Scalar::Util, List::Util, List::MoreUtils, String::Util & more (via one subroutine)

use strict;
use warnings;

use Package::Pkg;
use Carp qw/ croak confess /;

sub import {
    my $package = caller;
    pkg->install( code => sub { __PACKAGE__ }, into => $package, as => 'utl' );
}

sub empty { return not ( defined $_[1] and length $_[1] ) }
sub blank { return not ( defined $_[1] and $_[1] =~ m/\S/ ) }

sub first {
    my $self = shift;
    goto &List::Util::first if ref $_[0] eq 'CODE';
    unshift @_, $self;
    goto &_first_hash if ref $_[1] eq 'HASH';
    confess "Invalid invocation: first (@_)";
}

sub _first_hash {
    my $self = shift;
    my $hash = shift;
    my @query = @_;
    my $options = {};
    $options = pop @query if ref $query[-1] eq 'HASH';

    my $test = $options->{ test };
    my $exclusive = $options->{ exclusive };

    my @found;
    for my $key ( @query ) {
        if ( exists $hash->{ $key } ) {
            if ( $test ) {
                local $_ = $hash->{ $key };
                next if not $test->( $_, $key, $hash );
            }
            push @found, $key;
            last if not $exclusive;
        }
    }

    if ( $exclusive && @found > 1 ) {
        if ( ref $exclusive eq 'CODE' ) {
            return $exclusive->( $hash, @found );
        }
        else {
            croak "first: Found non-exclusive keys (@found) in hash\n";
        }
    }

    return if $options->{ empty } && !@found;

    return undef if !@found;

    return $hash->{ $found[0] };
}

{
    my $install = sub {
        my $package = shift;
        eval "require $package;" or die $@;
        my @export = @_;
        @export = eval "\@${package}::EXPORT_OK" if not @export;
        for my $method ( @export ) {
            next if __PACKAGE__->can( $method );
            no strict 'refs';
            *$method = eval qq/sub { shift; goto &${package}::$method };/;
        }
    };

    $install->( 'List::Util' );
    $install->( 'List::MoreUtils' );
    $install->( 'Scalar::Util' );
    $install->( 'String::Util' );
}

1;



=pod

=head1 NAME

Util::Utl - Scalar::Util, List::Util, List::MoreUtils, String::Util & more (via one subroutine)

=head1 VERSION

version 0.0011

=head1 SYNOPSIS

    use Util::Utl;

    utl->first( { ... }, ... )

    if ( utl->blessed( ... ) ) {
    }

    if ( utl->looks_like_number( ... ) ) {
    }

=head1 DESCRIPTION

Util::Utl exports a single subroutine C<utl> which provides access to:

L<Scalar::Util>

L<List::Util>

L<List::MoreUtils>

L<String::Util>

=head1 USAGE

Util::Utl also provides some additional functionality

Each function here is accessed in the same way:

    utl->$name( ... )

=head2 empty( $value )

Returns true if $value is undefined or has 0-length

=head2 blank( $value )

Returns true if $value is undefined or is composed only of whitespace (\s)

=head2 first( $code, ... )

L<List::Util>::first

=head2 first( $hash, @query, $options )

    %hash = ( a => 1, b => 2, c => 3 )
    ... = utl->first( \%hash, qw/ z a b / ) # Returns 1

For each name in C<@query>, test C<$hash> to see if it exists. Returns the value of
the first entry found

Returns undef if none exist

$options (a HASH reference) are:

    exclusive       True to throw an exception if more than 1 of query is present
                    in $hash

                        %hash = ( a => 1, b => 2, c => 3 )

                        ... = utl->first( \%hash, qw/ a b /, { exclusive => 1 } )
                        # Throws an exception (die)

                        ... = utl->first( \%hash, qw/ a z /, { exclusive => 1 } )
                        # Does not throw an exception 

    test            A subroutine for testing whether a value should be included or not. Can be
                    used to skip over undefined or empty values

                        %hash = ( a => undef, b => '', c => 1 )

                        ... = utl->first( \%hash, qw/ a b c /, { test => sub { defined } } )
                        # Returns ''

    empty           True to return an empty list instead of undef if none are found

                        %hash = ( a => 1 )
                        
                        ... = utl->first( \%hash, qw/ z x y / )
                        # Returns undef

                        ... = utl->first( \%hash, qw/ z x y /, { empty => 1 } )
                        # Returns ()

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

