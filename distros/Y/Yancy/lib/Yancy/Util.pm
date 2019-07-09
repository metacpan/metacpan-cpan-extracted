package Yancy::Util;
our $VERSION = '1.036';
# ABSTRACT: Utilities for Yancy

#pod =head1 SYNOPSIS
#pod
#pod     use Yancy::Util qw( load_backend );
#pod     my $be = load_backend( 'test://localhost', $schema );
#pod
#pod     use Yancy::Util qw( curry );
#pod     my $helper = curry( \&_helper_sub, @args );
#pod
#pod     use Yancy::Util qw( currym );
#pod     my $sub = currym( $object, 'method_name', @args );
#pod
#pod     use Yancy::Util qw( match );
#pod     if ( match( $where, $item ) ) {
#pod         say 'Matched!';
#pod     }
#pod
#pod     use Yancy::Util qw( fill_brackets );
#pod     my $value = fill_brackets( $template, $item );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module contains utility functions for Yancy.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>
#pod
#pod =cut

use Mojo::Base '-strict';
use Exporter 'import';
use List::Util qw( any first );
use Mojo::Loader qw( load_class );
use Scalar::Util qw( blessed );
use Mojo::JSON::Pointer;
use Mojo::JSON qw( to_json );
use Mojo::Util qw( xml_escape );
use Carp qw( carp );

our @EXPORT_OK = qw( load_backend curry currym copy_inline_refs match derp fill_brackets
    is_type order_by );

#pod =sub load_backend
#pod
#pod     my $backend = load_backend( $backend_url, $schema );
#pod     my $backend = load_backend( { $backend_name => $arg }, $schema );
#pod
#pod Get a Yancy backend from the given backend URL, or from a hash reference
#pod with a backend name and optional argument. The C<$schema> hash is
#pod the configured JSON schema for this backend.
#pod
#pod A backend URL should begin with a name followed by a colon. The first
#pod letter of the name will be capitalized, and used to build a class name
#pod in the C<Yancy::Backend> namespace.
#pod
#pod The C<$backend_name> should be the name of a module in the
#pod C<Yancy::Backend> namespace. The C<$arg> is handled by the backend
#pod module. Read your backend module's documentation for details.
#pod
#pod See L<Yancy::Help::Config/Database Backend> for information about
#pod backend URLs and L<Yancy::Backend> for more information about backend
#pod objects.
#pod
#pod =cut

sub load_backend {
    my ( $config, $schema ) = @_;
    my ( $type, $arg );
    if ( !ref $config ) {
        ( $type ) = $config =~ m{^([^:]+)};
        $arg = $config;
    }
    else {
        ( $type, $arg ) = %{ $config };
    }
    my $class = 'Yancy::Backend::' . ucfirst $type;
    if ( my $e = load_class( $class ) ) {
        die ref $e ? "Could not load class $class: $e" : "Could not find class $class";
    }
    return $class->new( $arg, $schema );
}

#pod =sub curry
#pod
#pod     my $curried_sub = curry( $sub, @args );
#pod
#pod Return a new subref that, when called, will call the passed-in subref with
#pod the passed-in C<@args> first.
#pod
#pod For example:
#pod
#pod     my $add = sub {
#pod         my ( $lop, $rop ) = @_;
#pod         return $lop + $rop;
#pod     };
#pod     my $add_four = curry( $add, 4 );
#pod     say $add_four->( 1 ); # 5
#pod     say $add_four->( 2 ); # 6
#pod     say $add_four->( 3 ); # 7
#pod
#pod This is more-accurately called L<partial
#pod application|https://en.wikipedia.org/wiki/Partial_application>, but
#pod C<curry> is shorter.
#pod
#pod =cut

sub curry {
    my ( $sub, @args ) = @_;
    return sub { $sub->( @args, @_ ) };
}

#pod =sub currym
#pod
#pod     my $curried_sub = currym( $obj, $method, @args );
#pod
#pod Return a subref that, when called, will call given C<$method> on the
#pod given C<$obj> with any passed-in C<@args> first.
#pod
#pod See L</curry> for an example.
#pod
#pod =cut

sub currym {
    my ( $obj, $meth, @args ) = @_;
    my $sub = $obj->can( $meth )
        || die sprintf q{Can't curry method "%s" on object of type "%s": Method is not implemented},
            $meth, blessed( $obj );
    return curry( $sub, $obj, @args );
}

#pod =sub copy_inline_refs
#pod
#pod     my $subschema = copy_inline_refs( $schema, '/user' );
#pod
#pod Given:
#pod
#pod =over
#pod
#pod =item a "source" JSON schema (will not be mutated)
#pod
#pod =item a JSON Pointer into the source schema, from which to be copied
#pod
#pod =back
#pod
#pod will return another, copied standalone JSON schema, with any C<$ref>
#pod either copied in, or if previously encountered, with a C<$ref> to the
#pod new location.
#pod
#pod =cut

sub copy_inline_refs {
    my ( $schema, $pointer, $usschema, $uspointer, $refmap ) = @_;
    $usschema //= Mojo::JSON::Pointer->new( $schema )->get( $pointer );
    $uspointer //= '';
    $refmap ||= {};
    return { '$ref' => $refmap->{ $uspointer } } if $refmap->{ $uspointer };
    $refmap->{ $pointer } = "#$uspointer"
        unless ref $usschema eq 'HASH' and $usschema->{'$ref'};
    return $usschema
        unless ref $usschema eq 'ARRAY' or ref $usschema eq 'HASH';
    my $counter = 0;
    return [ map copy_inline_refs(
        $schema,
        $pointer.'/'.$counter++,
        $_,
        $uspointer.'/'.$counter++,
        $refmap,
    ), @$usschema ] if ref $usschema eq 'ARRAY';
    # HASH
    my $ref = $usschema->{'$ref'};
    return { map { $_ => copy_inline_refs(
        $schema,
        $pointer.'/'.$_,
        $usschema->{ $_ },
        $uspointer.'/'.$_,
        $refmap,
    ) } sort keys %$usschema } if !$ref;
    $ref =~ s:^#::;
    return { '$ref' => $refmap->{ $ref } } if $refmap->{ $ref };
    copy_inline_refs(
        $schema,
        $ref,
        Mojo::JSON::Pointer->new( $schema )->get( $ref ),
        $uspointer,
        $refmap,
    );
}

#pod =sub match
#pod
#pod     my $bool = match( $where, $item );
#pod
#pod Test if the given C<$item> matches the given L<SQL::Abstract> C<$where>
#pod data structure. See L<SQL::Abstract/WHERE CLAUSES> for the full syntax.
#pod
#pod Not all of SQL::Abstract's syntax is supported yet, so patches are welcome.
#pod
#pod =cut

sub match {
    my ( $match, $item ) = @_;

    my %test;
    for my $key ( keys %$match ) {
        if ( $key =~ /^-(not_)?bool/ ) {
            my $want_false = $1;
            $key = $match->{ $key }; # the actual field
            $test{ $key } = sub {
                my ( $value, $key ) = @_;
                return $want_false ? !$value : !!$value;
            };
        }
        elsif ( !ref $match->{ $key } ) {
            $test{ $key } = $match->{ $key };
        }
        elsif ( ref $match->{ $key } eq 'HASH' ) {
            if ( my $value = $match->{ $key }{ -like } || $match->{ $key }{ like } ) {
                $value = quotemeta $value;
                $value =~ s/(?<!\\)\\%/.*/g;
                $test{ $key } = qr{^$value$};
            }
            elsif ( exists $match->{ $key }{ '!=' } ) {
                my $expect = $match->{ $key }{ '!=' };
                $test{ $key } = sub {
                    my ( $got, $key ) = @_;
                    if ( !defined $expect ) {
                        return defined $got;
                    }
                    return $got ne $expect;
                };
            }
            else {
                die "Unimplemented query type: " . to_json( $match->{ $key } );
            }
        }
        elsif ( ref $match->{ $key } eq 'ARRAY' ) {
            my @tests = @{ $match->{ $key } };
            # Array is an 'OR' combiner
            $test{ $key } = sub {
                my ( $value, $key ) = @_;
                my $sub_item = { $key => $value };
                return any { match( { $key => $_ }, $sub_item ) } @tests;
            };
        }
        else {
            die "Unimplemented match ref type: " . to_json( $match->{ $key } );
        }
    }

    my $passes
        = grep {
            !defined $test{ $_ } ? !defined $item->{ $_ }
            : ref $test{ $_ } eq 'Regexp' ? $item->{ $_ } =~ $test{ $_ }
            : ref $test{ $_ } eq 'CODE' ? $test{ $_ }->( $item->{ $_ }, $_ )
            : $item->{ $_ } eq $test{ $_ }
        }
        keys %test;

    return $passes == keys %test;
}

#pod =sub order_by
#pod
#pod     my $ordered_array = order_by( $order_by, $unordered_array );
#pod
#pod Order the given arrayref by the given L<SQL::Abstract> order-by clause.
#pod
#pod =cut

sub order_by {
    my ( $order_by, $unordered ) = @_;
    # Array of [ (-asc/-desc), (field) ]
    my @sort_items;

    if ( ref $order_by eq 'ARRAY' ) {
        @sort_items = map { [ ref $_ ? %$_ : ( -asc => $_ ) ] } @$order_by;
    }
    elsif ( ref $order_by eq 'HASH' ) {
        @sort_items = [ %$order_by ];
    }
    else {
        @sort_items = [ -asc => $order_by ];
    }

    my @ordered = sort {
            for my $item ( @sort_items ) {
                my $cmp = $item->[0] eq '-asc'
                    ? ($a->{ $item->[1] }//'') cmp ($b->{ $item->[1] }//'')
                    : ($b->{ $item->[1] }//'') cmp ($a->{ $item->[1] }//'')
                    ;
                return $cmp || next;
            }
        }
        @$unordered;

    return \@ordered;
}

#pod =sub fill_brackets
#pod
#pod     my $string = fill_brackets( $template, $item );
#pod
#pod This routine will fill in the given template string with the values from
#pod the given C<$item> hashref. The template contains field names within curly braces.
#pod Values in the C<$item> hashref will be escaped with L<Mojo::Util/xml_escape>.
#pod
#pod     my $item = {
#pod         name => 'Doug Bell',
#pod         email => 'doug@example.com',
#pod         quote => 'I <3 Perl',
#pod     };
#pod
#pod     # Doug Bell <doug@example.com>
#pod     fill_brackets( '{name} <{email}>', $item );
#pod
#pod     # I &lt;3 Perl
#pod     fill_brackets( '{quote}', $item );
#pod
#pod =cut

sub fill_brackets {
    my ( $template, $item ) = @_;
    return scalar $template =~ s/(?<!\\)\{\s*([^\s\}]+)\s*\}/xml_escape $item->{$1}/reg;
}

#pod =sub is_type
#pod
#pod     my $bool = is_type( $schema->{properties}{myprop}{type}, 'boolean' );
#pod
#pod Returns true if the given JSON schema type value (which can be a string or
#pod an array of strings) contains the given value, allowing the given type for
#pod the property.
#pod
#pod     # true
#pod     is_type( 'boolean', 'boolean' );
#pod     is_type( [qw( boolean null )], 'boolean' );
#pod     # false
#pod     is_type( 'string', 'boolean' );
#pod     is_type( [qw( string null )], 'boolean' );
#pod
#pod =cut

sub is_type {
    my ( $type, $is_type ) = @_;
    return unless $type;
    return ref $type eq 'ARRAY'
        ? !!grep { $_ eq $is_type } @$type
        : $type eq $is_type;
}

#pod =sub derp
#pod
#pod     derp "This feature is deprecated in file '%s'", $file;
#pod
#pod Print out a deprecation message as a warning. A message will only be
#pod printed once for each set of arguments from each caller.
#pod
#pod =cut

our @CARP_NOT = qw(
    Yancy::Controller::Yancy Yancy::Controller::Yancy::MultiTenant
    Mojolicious::Plugin::Yancy Mojolicious::Plugins Mojolicious
    Mojo::Server Yancy::Plugin::Editor Yancy::Plugin::Auth
    Mojolicious::Renderer Yancy::Plugin::Auth::Token
    Yancy::Plugin::Auth::Password
);
our %DERPED;
sub derp(@) {
    my @args = @_;
    my $key = to_json [ caller, @args ];
    return if $DERPED{ $key };
    if ( $args[0] !~ /\.$/ ) {
        $args[0] .= '.';
    }
    carp sprintf( $args[0], @args[1..$#args] );
    $DERPED{ $key } = 1;
}

1;

__END__

=pod

=head1 NAME

Yancy::Util - Utilities for Yancy

=head1 VERSION

version 1.036

=head1 SYNOPSIS

    use Yancy::Util qw( load_backend );
    my $be = load_backend( 'test://localhost', $schema );

    use Yancy::Util qw( curry );
    my $helper = curry( \&_helper_sub, @args );

    use Yancy::Util qw( currym );
    my $sub = currym( $object, 'method_name', @args );

    use Yancy::Util qw( match );
    if ( match( $where, $item ) ) {
        say 'Matched!';
    }

    use Yancy::Util qw( fill_brackets );
    my $value = fill_brackets( $template, $item );

=head1 DESCRIPTION

This module contains utility functions for Yancy.

=head1 SUBROUTINES

=head2 load_backend

    my $backend = load_backend( $backend_url, $schema );
    my $backend = load_backend( { $backend_name => $arg }, $schema );

Get a Yancy backend from the given backend URL, or from a hash reference
with a backend name and optional argument. The C<$schema> hash is
the configured JSON schema for this backend.

A backend URL should begin with a name followed by a colon. The first
letter of the name will be capitalized, and used to build a class name
in the C<Yancy::Backend> namespace.

The C<$backend_name> should be the name of a module in the
C<Yancy::Backend> namespace. The C<$arg> is handled by the backend
module. Read your backend module's documentation for details.

See L<Yancy::Help::Config/Database Backend> for information about
backend URLs and L<Yancy::Backend> for more information about backend
objects.

=head2 curry

    my $curried_sub = curry( $sub, @args );

Return a new subref that, when called, will call the passed-in subref with
the passed-in C<@args> first.

For example:

    my $add = sub {
        my ( $lop, $rop ) = @_;
        return $lop + $rop;
    };
    my $add_four = curry( $add, 4 );
    say $add_four->( 1 ); # 5
    say $add_four->( 2 ); # 6
    say $add_four->( 3 ); # 7

This is more-accurately called L<partial
application|https://en.wikipedia.org/wiki/Partial_application>, but
C<curry> is shorter.

=head2 currym

    my $curried_sub = currym( $obj, $method, @args );

Return a subref that, when called, will call given C<$method> on the
given C<$obj> with any passed-in C<@args> first.

See L</curry> for an example.

=head2 copy_inline_refs

    my $subschema = copy_inline_refs( $schema, '/user' );

Given:

=over

=item a "source" JSON schema (will not be mutated)

=item a JSON Pointer into the source schema, from which to be copied

=back

will return another, copied standalone JSON schema, with any C<$ref>
either copied in, or if previously encountered, with a C<$ref> to the
new location.

=head2 match

    my $bool = match( $where, $item );

Test if the given C<$item> matches the given L<SQL::Abstract> C<$where>
data structure. See L<SQL::Abstract/WHERE CLAUSES> for the full syntax.

Not all of SQL::Abstract's syntax is supported yet, so patches are welcome.

=head2 order_by

    my $ordered_array = order_by( $order_by, $unordered_array );

Order the given arrayref by the given L<SQL::Abstract> order-by clause.

=head2 fill_brackets

    my $string = fill_brackets( $template, $item );

This routine will fill in the given template string with the values from
the given C<$item> hashref. The template contains field names within curly braces.
Values in the C<$item> hashref will be escaped with L<Mojo::Util/xml_escape>.

    my $item = {
        name => 'Doug Bell',
        email => 'doug@example.com',
        quote => 'I <3 Perl',
    };

    # Doug Bell <doug@example.com>
    fill_brackets( '{name} <{email}>', $item );

    # I &lt;3 Perl
    fill_brackets( '{quote}', $item );

=head2 is_type

    my $bool = is_type( $schema->{properties}{myprop}{type}, 'boolean' );

Returns true if the given JSON schema type value (which can be a string or
an array of strings) contains the given value, allowing the given type for
the property.

    # true
    is_type( 'boolean', 'boolean' );
    is_type( [qw( boolean null )], 'boolean' );
    # false
    is_type( 'string', 'boolean' );
    is_type( [qw( string null )], 'boolean' );

=head2 derp

    derp "This feature is deprecated in file '%s'", $file;

Print out a deprecation message as a warning. A message will only be
printed once for each set of arguments from each caller.

=head1 SEE ALSO

L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
