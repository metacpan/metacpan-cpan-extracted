package Twitter::API::Role::RequestArgs;
# ABSTRACT: API request method helpers
$Twitter::API::Role::RequestArgs::VERSION = '0.0113';
use 5.14.1;
use warnings;
use Carp;
use Moo::Role;
use Ref::Util qw/is_arrayref is_hashref/;
use namespace::clean;

requires 'request';

#pod =method request_with_id
#pod
#pod Transforms an argument list with a required C<screen_name> or C<user_id>,
#pod optionally passed as a leading, positional argument, a hashref argument.
#pod
#pod If a hashref follows the optional plain scalar, the user_id or screen_name is
#pod added to it. Otherwise a new hashref is created and inserted into C<@_>.
#pod
#pod If the optional plain scalar argument is missing, and there is hashref of
#pod arguments, or if the hashref does not contain the key C<screen_name> or
#pod C<user_id>, request_with_id croaks.
#pod
#pod Examples:
#pod
#pod     $self->request_with_id(get => 'some/endpoint', 'foo');
#pod     # is transformed to:
#pod     $self->request(get => 'some/endpoint', { screen_name => 'foo' });
#pod
#pod     $self->request_with_id(get => 'some/endpoint', 8575429);
#pod     # is transfromed to:
#pod     $self->request(get => 'some/endpoint', { user_id => 8675429 });
#pod
#pod     $self->request_with_id(get => 'some/endpoint', {
#pod         screen_name => 'semifor',
#pod     });
#pod     # is transformed to:
#pod     $self->request(get => 'some/endpoint', { screen_name => 'semifor' });
#pod
#pod     $self->request_with_id(get => 'some/endpoint', {
#pod         foo => 'bar',
#pod     }); ### croaks ###
#pod
#pod =cut

# if there is a positional arg, it's an :ID (screen_name or user_id)
sub request_with_id {
    splice @_, 1, 0, [];
    push @{$_[1]}, ':ID' if @_ > 4 && !is_hashref($_[4]);
    goto $_[0]->can('request_with_pos_args');
}

#pod =method request_with_pos_args
#pod
#pod Transforms a list of required arguments, optionally provided positionally in a
#pod determined order, into a hashref of named arguments. If a hashref follows the
#pod positional arguments, the named arguments are added to it. Otherwise, a new
#pod hashref in inserted into C<@_>.
#pod
#pod Zero or more of the required arguments may be provided positionally, as long as
#pod the appear in the specified order. I any of the required arguments are not
#pod provided positionally, they must be provided in the hashref or
#pod request_with_pos_args croaks.
#pod
#pod The positional name C<:ID> is treated specially. It is transformed to
#pod C<user_id> if the value it represents contains only digits. Otherwise, it is
#pod transformed to C<screen_name>.
#pod
#pod Examples:
#pod
#pod     $self->request_with_pos_args(
#pod         [ 'id', 'name' ], get => 'some/endpoint',
#pod         '007', 'Bond'
#pod     );
#pod     # is transformed to:
#pod     $self->request(get => 'some/endpoint', {
#pod         id   => '007',
#pod         name => 'Bond',
#pod     });
#pod
#pod     $self->request_with_pos_args(
#pod         [ 'id', 'name' ], get => 'some/endpoint',
#pod         '007', { name => 'Bond' }
#pod     );
#pod     # is also transformed to:
#pod     $self->request(get => 'some/endpoint', {
#pod         id   => '007',
#pod         name => 'Bond',
#pod     });
#pod
#pod     $self->request_with_pos_args(
#pod         [ ':ID', 'status' ], get => 'some/endpoint',
#pod         'alice', 'down the rabbit hole'
#pod     );
#pod     # is transformed to:
#pod     $self->request(get => 'some/endpoint', {
#pod         sreen_name => 'alice',
#pod         status     => 'down the rabbit hole',
#pod     });
#pod
#pod =cut

sub request_with_pos_args {
    my $self = shift;

    $self->request($self->normalize_pos_args(@_));
}

#pod =method normalize_pos_args
#pod
#pod Helper method for C<request_with_pos_args>. Takes the same arguments described in
#pod C<request_with_pos_args> above, and returns a list of arguments ready for a
#pod call to C<request>.
#pod
#pod Individual methods in L<Twitter::API::Trait::ApiMethods> use
#pod C<normalize_pos_args> if they need to do further processing on the args hashref
#pod before calling C<request>.
#pod
#pod =cut

sub normalize_pos_args {
    my $self        = shift;
    my @pos_names   = shift;
    my $http_method = shift;
    my $path        = shift;
    my %args;

    # names can be a single value or an arrayref
    @pos_names = @{ $pos_names[0] } if is_arrayref($pos_names[0]);

    # gather positional arguments and name them
    while ( @pos_names ) {
        last if @_ == 0 || is_hashref($_[0]);
        $args{shift @pos_names} = shift;
    }

    # get the optional, following args hashref and expand it
    my %args_hash; %args_hash = %{ shift() } if is_hashref($_[0]);

    # extract any required args if we still have names
    while ( my $name = shift @pos_names ) {
        if ( $name eq ':ID' ) {
            $name = exists $args_hash{screen_name} ? 'screen_name' : 'user_id';
            croak 'missing required screen_name or user_id'
                unless exists $args_hash{$name};
        }
        croak "missing required '$name' arg" unless exists $args_hash{$name};
        $args{$name} = delete $args_hash{$name};
    }

    # name the :ID value (if any) based on its value
    if ( my $id = delete $args{':ID'} ) {
        $args{$id =~/\D/ ? 'screen_name' : 'user_id'} = $id;
    }

    # merge in the remaining optional values
    for my $name ( keys %args_hash ) {
        croak "'$name' specified in both positional and named args"
            if exists $args{$name};
        $args{$name} = $args_hash{$name};
    }

    return ($http_method, $path, \%args, @_);
}

#pod =method flatten_list_args([ $key | \@keys ], \%args)
#pod
#pod Some Twitter API arguments take a list of values as a string of comma separated
#pod items. To allow callers to pass an array reference of items instead, this
#pod method is used to flatten array references to strings. The key or keys identify
#pod which values to flatten in the C<\%args> hash reference, if they exist.
#pod
#pod =cut

sub flatten_list_args {
    my ( $self, $keys, $args ) = @_;

    for my $key ( is_arrayref($keys) ? @$keys : $keys ) {
        if ( my $value = $args->{$key} ) {
            $args->{$key} = join ',' => @$value if is_arrayref($value);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Role::RequestArgs - API request method helpers

=head1 VERSION

version 0.0113

=head1 SYNOPSIS

    package MyApiMethods;
    use Moo::Role;

    sub timeline {
        shift->request_with_id(get => 'statuses/user_timeline, @_);
    }

Then, in your application code:

    use Twitter::API;

    my $client = Twitter::API->new_with_traits(
        traits => '+MyApiMethods',
        %othe_new_options,
    );

    my $statuses = $client->timeline('semifor');

    # equvalent to:
    my $statuses = $client->get('statuses/user_timeline', {
        screen_name => 'semifor',
    });

=head1 DESCRIPTION

Helper methods for implementers of custom traits for creating concise Twitter
API methods. Used in L<Twitter::API::Trait::ApiMethods>.

=head1 METHODS

=head2 request_with_id

Transforms an argument list with a required C<screen_name> or C<user_id>,
optionally passed as a leading, positional argument, a hashref argument.

If a hashref follows the optional plain scalar, the user_id or screen_name is
added to it. Otherwise a new hashref is created and inserted into C<@_>.

If the optional plain scalar argument is missing, and there is hashref of
arguments, or if the hashref does not contain the key C<screen_name> or
C<user_id>, request_with_id croaks.

Examples:

    $self->request_with_id(get => 'some/endpoint', 'foo');
    # is transformed to:
    $self->request(get => 'some/endpoint', { screen_name => 'foo' });

    $self->request_with_id(get => 'some/endpoint', 8575429);
    # is transfromed to:
    $self->request(get => 'some/endpoint', { user_id => 8675429 });

    $self->request_with_id(get => 'some/endpoint', {
        screen_name => 'semifor',
    });
    # is transformed to:
    $self->request(get => 'some/endpoint', { screen_name => 'semifor' });

    $self->request_with_id(get => 'some/endpoint', {
        foo => 'bar',
    }); ### croaks ###

=head2 request_with_pos_args

Transforms a list of required arguments, optionally provided positionally in a
determined order, into a hashref of named arguments. If a hashref follows the
positional arguments, the named arguments are added to it. Otherwise, a new
hashref in inserted into C<@_>.

Zero or more of the required arguments may be provided positionally, as long as
the appear in the specified order. I any of the required arguments are not
provided positionally, they must be provided in the hashref or
request_with_pos_args croaks.

The positional name C<:ID> is treated specially. It is transformed to
C<user_id> if the value it represents contains only digits. Otherwise, it is
transformed to C<screen_name>.

Examples:

    $self->request_with_pos_args(
        [ 'id', 'name' ], get => 'some/endpoint',
        '007', 'Bond'
    );
    # is transformed to:
    $self->request(get => 'some/endpoint', {
        id   => '007',
        name => 'Bond',
    });

    $self->request_with_pos_args(
        [ 'id', 'name' ], get => 'some/endpoint',
        '007', { name => 'Bond' }
    );
    # is also transformed to:
    $self->request(get => 'some/endpoint', {
        id   => '007',
        name => 'Bond',
    });

    $self->request_with_pos_args(
        [ ':ID', 'status' ], get => 'some/endpoint',
        'alice', 'down the rabbit hole'
    );
    # is transformed to:
    $self->request(get => 'some/endpoint', {
        sreen_name => 'alice',
        status     => 'down the rabbit hole',
    });

=head2 normalize_pos_args

Helper method for C<request_with_pos_args>. Takes the same arguments described in
C<request_with_pos_args> above, and returns a list of arguments ready for a
call to C<request>.

Individual methods in L<Twitter::API::Trait::ApiMethods> use
C<normalize_pos_args> if they need to do further processing on the args hashref
before calling C<request>.

=head2 flatten_list_args([ $key | \@keys ], \%args)

Some Twitter API arguments take a list of values as a string of comma separated
items. To allow callers to pass an array reference of items instead, this
method is used to flatten array references to strings. The key or keys identify
which values to flatten in the C<\%args> hash reference, if they exist.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
