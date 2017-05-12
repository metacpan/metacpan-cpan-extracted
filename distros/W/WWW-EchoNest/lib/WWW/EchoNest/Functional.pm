
package WWW::EchoNest::Functional;

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest;
BEGIN { our $VERSION = $WWW::EchoNest::VERSION; }

BEGIN {
    our @EXPORT = ();
    our @EXPORT_OK =
        (
         # Utilities, builtin-aliases, etc.
         'identity',
         'defined',

         # Hash processors
         'keep',
         'update',
         'default',
         'pass',

         # List processors
         'all',
         'any',

         # Method Generators
         'make_stupid_accessor',
         'make_simple_accessor',
         'make_getters_and_setters',
         'stupid_get_attr',
         'simple_get_attr',
         'editorial_get_attr',
         'numerical_get_attr',
        );
}
use parent qw( Exporter );

# Keep all the entries of a hash whose value tests true in a given subroutine,
# with an optional array ref to restrict the set of keys we are looking for.
# Returns a HASH-ref.
# See &WWW::EchoNest::Song::search for usage of this function.
sub keep {
    my($hashref, $sref, $arrayref) = @_;
    my(%ret, %key_for, $restrict_keys);

    if (@$arrayref > 0) {
        %key_for = map { $_ => 1 } @$arrayref;
        $restrict_keys = 1;
    }
    while ( my($k, $v) = each %$hashref ) {
        if ($restrict_keys) {
            if ($key_for{$k}) {
                $ret{$k} = $v    if $sref->($v);
            } else {
                $ret{$k} = $v;
            }
        } else {
            $ret{$k} = $v    if $sref->($v);
        }
    }

    return \%ret;
}

# Make sure that all the entries in hashref2 are in hashref1.
# This will overwrite any keys from hashref2 that already exist in hashref1.
sub update {
    croak 'First arg must be a HASH-ref'  if ! UNIVERSAL::isa( $_[0], 'HASH' );
    croak 'Second arg must be a HASH-ref' if ! UNIVERSAL::isa( $_[1], 'HASH' );
    $_[0]->{$_} = $_[1]->{$_} for (keys %{ $_[1] });
}

# Set default values of entries of a hash that aren't defined.
sub default {
    my $hash_ref_1    = $_[0];     # Hash
    my $hash_ref_2    = $_[1];     # Default entries
    
    for my $k (keys %$hash_ref_2) {
        $hash_ref_1->{$k} //= $hash_ref_2->{$k};
    }
}

# ARGS:
# 1 - HASH-ref whose values will be tested by the corresponding subroutines
#     from...
# 2 - HASH-ref
# 3 - CODE-ref to a list-processing function used to operate over the
#     values-list generated from the first two arguments
#
# RETURNS:
# - List of boolean values corresponding to the values returned by the
#   subroutines for each key
sub pass {
    my %args             = @_;
    my $hash_ref         = $args{q/hash/};
    my $code_refs        = $args{q/code/};
    my $list_proc_ref    = $args{q/list_proc/}     // \&all;
    # Any hash will pass if there is no test code!
    return 1 if ! (defined($code_refs) && defined($hash_ref));
    
    my @tested_values = ();
    for my $k (keys %$hash_ref) {
        my $code_ref = $code_refs->{$k} // \&identity;
        push @tested_values, $code_ref->( $hash_ref->{$k} );
    }
    return $list_proc_ref->( @tested_values );
}


# Filter a hash with a user-specified function.
# If the user doesn't supply a function, filter will return a hash
# consisting of all entries from the input hash that had defined values.
# sub filter (&%) {
#     my($sref, %h) = @_;
#     $sref //= \&defined;
#     my %result;
#     while( my($k, $v) = each %$href) {
#         $result{$k} = $v if $sref->($k, $v);
#     }
#     return \%result;
# }


########################################################################
#
# List processing functions
# (Taken straight from the List::Util perldoc)
#
sub all { $_ || return 0 for @_; 1 }
sub any { $_ && return 1 for @_; 0 }



########################################################################
#
# Functions for generating accessors
#
sub make_stupid_accessor {
    # Generates an accessor method that assumes the object is a
    # blessed HASH-ref, and returns the value of said hash using
    # the parameter name as a key.
    no strict 'refs';
    my($pkg) = caller();
    
    for my $attr_name (@_) {
        *{ $pkg . '::get_' . $attr_name } = sub {
            return $_[0]->{$attr_name};
        };
    }
}

sub make_simple_accessor {
    # Generates an accessor method that assumes the object is a
    # blessed HASH-ref.
    no strict 'refs';

    # First arg is a HASH-ref that expects
    # (1) An 'attributes' entry that points to an anonymous list of
    #     attribute names;
    # (2) A 'response_key' entry that determines the key to use
    #     when fetching a response from get_attribute;
    #
    # This sub will return the first item from a list that has the specified
    # attribute name.
    #
    my $attributes_hash_ref    = $_[0];
    my $attributes_ref         = $attributes_hash_ref->{attributes};
    my $response_key           = $attributes_hash_ref->{response_key};
    my($pkg)                   = caller();
    
    for my $attr_name (@$attributes_ref) {
        *{ $pkg . '::get_' . $attr_name } = sub {
            use JSON;
            my $self           = $_[0];
            my $args_ref       = $_[1];
	    
            # Caching default to true
            my $use_cached     = $args_ref->{cache} // 1;
            my $cached_val     = $self->{$attr_name};

            if ( not ($use_cached and defined($cached_val)) ) {
                my $response = $self->get_attribute(
                                                    {
                                                     method => 'profile',
                                                     bucket => $attr_name,
                                                    },
                                                   );
                my $list_ref = $response->{$response_key};
                my $attr_value_href = first { defined($_->{$attr_name}) }
                    @$list_ref;
                my $attr_value = $attr_value_href->{$attr_name};
                
                $self->{$attr_name} = $attr_value if defined($attr_value);
                return $attr_value;
            } else {
                return $cached_val;
            }

            return;
        };
    }
}


# Used by WWW::EchoNest::Artist
# These subs need better names!
sub stupid_get_attr {
    use WWW::EchoNest::Result::List;
    my($self, $args_href, $attribute) = @_;

    my $cache      = $args_href->{cache}     // 1;
    my $start      = $args_href->{start}     // 0;
    my $results    = $args_href->{results}   // 15;
    my $cached_val = $self->{$attribute};

    # Possibly return the cached value
    return $cached_val
        if $cache and $cached_val and $start == 0 and $results == 15;

    # Get a new value for the attribute
    my $response = $self->get_attribute
        (
         {
          method    => $attribute,
          start     => $start,
          results   => $results,
         }
        );
    my $new_value = WWW::EchoNest::Result::List->new
        (
         $response->{$attribute},
         start   => 0,
         total   => $response->{total},
        );

    # Cache the new value and return it
    $self->{$attribute} = $new_value if $start == 0 and $results == 15;
    return $new_value;
}

sub simple_get_attr {
    use WWW::EchoNest::Result::List;
    my($self, $args_href, $attribute) = @_;

    my $cache      = $args_href->{cache}     // 1;
    my $start      = $args_href->{start}     // 0;
    my $results    = $args_href->{results}   // 15;
    my $license    = $args_href->{license};
    my $cached_val = $self->{$attribute};

    # Possibly return the cached value
    return $cached_val
        if $cache and $cached_val and $start == 0 and $results == 15
            and not defined( $license );

    # Get a new value for the attribute
    my $response = $self->get_attribute
        (
         {
          method    => $attribute,
          start     => $start,
          results   => $results,
          license   => $license,
         }
        );
    my $new_value = WWW::EchoNest::Result::List->new
        (
         $response->{$attribute},
         start   => 0,
         total   => $response->{total},
        );

    # Cache the new value and return it
    $self->{$attribute} = $new_value
        if $start == 0 and $results == 15 and not defined( $license );
    return $new_value;
}

sub editorial_get_attr {
    use WWW::EchoNest::Result::List;
    my($self, $args_href, $attribute) = @_;

    my $cache            = $args_href->{cache}            // 1;
    my $start            = $args_href->{start}            // 0;
    my $results          = $args_href->{results}          // 15;
    my $high_relevance   = $args_href->{high_relevance}   // 0;
    my $cached_val       = $self->{$attribute};

    # Possibly return the cached value
    return $cached_val
        if $cache and $cached_val and $start == 0 and $results == 15
            and not $high_relevance;

    $high_relevance = $high_relevance ? 'true' : 'false';

    # Get a new value for the attribute
    my $response = $self->get_attribute
        (
         {
          method          => $attribute,
          start           => $start,
          results         => $results,
          high_relevance  => $high_relevance,
         }
        );
    my $new_value = WWW::EchoNest::Result::List->new
        (
         $response->{$attribute},
         start   => 0,
         total   => $response->{total},
        );

    # Cache the new value and return it
    $self->{$attribute} = $new_value if $start == 0 and $results == 15;
    return $new_value;
}

sub numerical_get_attr {
    my($self, $args_href, $attribute) = @_;

    my $cache            = $args_href->{cache}            // 1;
    my $cached_val       = $self->{$attribute};

    # Possibly return the cached value
    return $cached_val if $cache and $cached_val;

    # Get a new value for the attribute
    my $response  = $self->get_attribute( { method => $attribute } );
    my $new_value = $response->{artist}{$attribute};

    # Cache the new value and return it
    $self->{$attribute} = $new_value;
    return $new_value;
}

    
# Used by Config ######################################################
#
sub make_getters_and_setters {
    no strict 'refs';

    foreach my $field (@_) {
        my $fieldname = lc $field;
        my($pkg)      = caller();

        # Getter
        *{"$pkg\::get_$fieldname"} = sub {
            return $_[0]->{ $field };
        };

        # Setter
        *{"$pkg\::set_$fieldname"} = sub {
            $_[0]->{ $field } = $_[1];
        };
    }
}

1;

__END__

=head1 NAME

WWW::EchoNest::Functional
For internal use only!

=head1 VERSION

Version 0.0.1

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
