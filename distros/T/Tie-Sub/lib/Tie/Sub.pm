package Tie::Sub; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '1.001';

use Carp qw(confess);
use Params::Validate qw(:all);

## no critic (ArgUnpacking)

sub TIEHASH {
    my ($class, $code_ref) = validate_pos(
        @_,
        {type => SCALAR},
        {type => CODEREF, optional => 1},
    );

    my $scalar;
    my $self = bless \$scalar, $class;
    if ($code_ref) {
        $self->config($code_ref);
    }

    return $self;
}

# configure
sub config {
    # object, parameter
    my ($self, $code_ref) = validate_pos(
        @_,
        {isa  => __PACKAGE__},
        {type => CODEREF, optional => 1},
    );

    my $previous_code_ref = ${$self};
    if ($code_ref) {
        ${$self} = $code_ref;
    }

    return $previous_code_ref;
}

# execute the code reference
sub FETCH {
    # object, key
    my ($self, $key) = validate_pos(
        @_,
        {isa  => __PACKAGE__},
        {type => SCALAR | ARRAYREF},
    );

    ${$self} or confess 'Call of method "config" is necessary';

    # Several parameters to the subroutine will submit as reference on an array.
    return ${$self}->(
        ref $key eq 'ARRAY'
        ? @{$key}
        : $key
    );
}

# $Id$

1;

__END__

=head1 NAME

Tie::Sub - Tying a subroutine, function or method to a hash

=head1 VERSION

1.001

=head1 SYNOPSIS

=head2 initialize

    use strict;
    use warnings;

    use Tie::Sub;

    tie my %subroutine, 'Tie::Sub', sub { ... };

or initialize late

    tie my %subroutine, 'Tie::Sub';
    ( tied %subroutine )->config( sub { ... } );

or initialize late too

    my $object = tie my %subroutine, 'Tie::Sub';
    $object->config( sub { ... } );

=head2 interpolate subroutines in a string

=head3 usage like function (only 1 return parameter)

    use strict;
    use warnings;

    use Tie::Sub;

    tie my %sprintf_04d, 'Tie::Sub', sub { sprintf '%04d', shift };

    # The hash key and return value are both scalars.
    print "See $sprintf_04d{4}, not $sprintf_04d{5} digits.";

    __END__

    Output:

    See 0004, not 0005 digits.

or more flexible

    use strict;
    use warnings;

    use Tie::Sub;

    tie my %sprintf, 'Tie::Sub', sub { sprintf shift, shift };

    # The hash key is an array reference, the return value is a scalar.
    print "See $sprintf{ [ '%04d', 4 ] } digits.";

    __END__

    Output:

    See 0004 digits.

=head3 usage like subroutine

    use strict;
    use warnings;

    use Tie::Sub;
    use English qw($LIST_SEPARATOR);

    tie my %sprintf_multi, 'Tie::Sub', sub {
        return
            ! @_
            ? q{}
            : @_ > 1
            ? [ map { sprintf "%04d\n", $_ } @_ ]
            : sprintf "%04d\n", shift;
    };

    # The hash key and the return value ar both scalars or array references.
    {
        use English qw($LIST_SEPARATOR);
        local $LIST_SEPARATOR = q{};
        print <<"EOT";
    See the following lines
    scalar
    $sprintf_multi{10}
    arrayref
    @{ $sprintf_multi{ [ 20 .. 22 ] } }
    and be lucky.
    EOT
    }

    __END__

    Output:

    See the following lines
    scalar
    0010

    arrayref
    0020
    0021
    0022

    and be lucky.

=head3 usage like method

    use strict;
    use warnings;

    use Tie::Sub;
    use CGI;

    my $cgi = CGI->new;
    tie my %cgi, 'Tie::Sub', sub {
        my ($method, @params) = @_;

        my @result = $cgi->$method(@params);

        return
            ! @result
            ? ()
            : @result > 1
            ? \@result
            : $result[0];
    };

    # Hash key and return value are both array references.
    print <<"EOT";
    Hello $cgi{ [ param => 'firstname' ] } $cgi{ [ param => 'lastname' ] }!
    EOT

    __END__

    Output if "http://.../noname.pl?firstname=Steffen&lastname=Winkler":

    Hello Steffen Winkler!

=head2 Read configuration

    my $config = ( tied %subroutine )->config;

=head2 Write configuration

    my $config = ( tied %subroutine )->config( sub{ yourcode } );

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

Subroutines don't have interpreted into strings.
The module ties a subroutine to a hash.
The subroutine is executed at fetch hash.
At long last this is the same, only the notation is shorter.

Alternative to

    " ... ${\ subroutine('abc') } ... "
    # or
    " ... @{[ subroutine('abc') ]} ... "
    # or
    '...' . subroutine('abc') . '...'

write

    " ... $subroutine{abc} ... "


Sometimes the subroutine expects more than 1 parameter.
Then submit a reference on an array as 'hash key'.
The tied subroutine will get the parameters always as list.

Use any reference to give back more then 1 return value.
The caller get back this reference.
There is no way to return a list.

=head1 SUBROUTINES/METHODS

=head2 method TIEHASH

    use Tie::Sub;
    my $object = tie my %subroutine, 'Tie::Sub', sub { yourcode };

'TIEHASH' ties your hash and set options defaults.

=head2 method config

'config' stores your own subroutine

You can get back the previous code reference
or use the method config in void context.
When you configure the first subroutine,
the method will give back undef.

    $previous_coderef = ( tied %subroutine )->config( sub { yourcode } );

The method calls croak if you have a parameter
and this parameter is not a reference of 'CODE'.

=head2 method FETCH

Give your parameter as key of your tied hash.
This key can be a string or an array reference when you have more then one.
'FETCH' will run your tied subroutine
and give back the returns of your subroutine.
Think about, return value can't be a list, but reference of such things.

    ... = $subroutine{param};

=head1 DIAGNOSTICS

All methods can croak at false parameters.

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<Params::Validate|Params::Validate>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Tie::Hash|Tie::Hash>

L<http://perl.plover.com/Identity/|http://perl.plover.com/Identity/>

L<http://perl.plover.com/Interpolation/|http://perl.plover.com/Interpolation/>

L<Interpolation|Interpolation> # contains much things

L<Tie::Function|Tie::Function> # maybe there is a problem near '$;' in your Arguments

L<Tie::LazyFunction|Tie::LazyFunction>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005 - 2012,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
