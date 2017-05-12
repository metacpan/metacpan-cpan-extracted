use strict;
use warnings;
package Test::JSON::Entails;
{
  $Test::JSON::Entails::VERSION = '0.2';
}
#ABSTRACT: Test whether one JSON or Perl structure entails/subsumes another


use base 'Test::Builder::Module';
our @EXPORT = qw(entails subsumes);

use Carp;
use JSON::Any;
use Scalar::Util qw(reftype);

my $JSON = JSON::Any->new;

sub entails ($$;$) {
    my ($input, $entailed, $test_name) = @_;
    my $test = __PACKAGE__->builder;

    croak "usage: entails(input,entailed,test_name)"
      unless defined $input && defined $entailed;

    my @objects;
    foreach my $item ( [ input => $input ], [ entailed => $entailed ] ) {
        my $object = $item->[1];
        unless ( ref $object ) {
            $object= eval { $JSON->decode( $object ) };
            if ( my $error = $@ ) {
                $test->ok( 0, $test_name );
                $test->diag("$item->[0] was not valid JSON");
                return;
            }
        }
        if ( reftype $object ne 'HASH' ) {
            $test->ok( 0, $test_name );
            $test->diag("$item->[0] was not JSON object or HASH reference");
            return;
        }
        push @objects, $object;
    }
    
    ($input, $entailed) = @objects;

    my $error = _hash_entails( @objects, "/" );
    if ($error) {
        $test->ok(0, $test_name);
        $test->diag($error);
    } else {
        $test->ok(1, $test_name);
    }
}

sub _hash_entails {
    my ($input, $entailed, $path) = @_;

    foreach my $k ( keys %$entailed ) {
        if (!exists $input->{$k}) {
            return "missing $path$k";
        }
        my $error =_deep_entails( $input->{$k}, $entailed->{$k}, $path.$k );
        return $error if $error;
    }

    return;
}

*subsumes = *entails;

sub _array_entails {
    my ($got, $expect, $path) = @_;

    # TODO: compare unordered?
    my $g = scalar @$got;
    my $e = scalar @$expect;

    if ($e > $g) {
        return "$path\[" . ($e - $g + 1) . '] missing';
    }
    
    for(my $i=0; $i<$e; $i++) {
        my $error = _deep_entails( $got->[$i], $expect->[$i], "$path\[".($i+1)."]" );
        return $error if $error;
    }

    return;
}

sub _deep_entails {
    my ($got, $expect, $path) = @_;

    my $type   = lc(reftype($expect) || "scalar");
    my $intype = lc(reftype($got) || "scalar");

    if ($intype ne $type) {
        return "$path must be $type, found $intype";
    }

    my $error;
    if ($type eq 'scalar') {
        # TODO: comparision may be overloaded, do we want to use _unoverload_str instead?
        if ( $got ne $expect ) {
            return "$path differ:\n         got: '$got'\n    expected: '$expect'";
        }
    } elsif ($type eq 'array') {
        $error = _array_entails( $got, $expect, $path );    
    } elsif ($type eq 'hash') {
        $error = _hash_entails( $got, $expect, "$path/" );
    }

    return $error;
}

1;


__END__
=pod

=head1 NAME

Test::JSON::Entails - Test whether one JSON or Perl structure entails/subsumes another

=head1 VERSION

version 0.2

=head1 SYNOPSIS

  use Test::JSON::Entails;

  entails $json, { foo => 1 }, "JSON contains a foo element with value 1";
  entails $json, '{}', "JSON is a valid JSON object (no array)";

  my $bar = { foo => 42, bar => 23 };
  my $foo = { foo => 42 };

  subsumes $bar => $foo, 'bar subsumes foo';  # $foo and $bar may be blessed

=head1 DESCRIPTION

Sometimes you want to compare JSON objects not for exact equivalence but for
whether one structure subsumes the other. The other way round, one structure
can be I<entailed> by another. For instance

    { "foo": 1, "bar": [ "x" ] }

is entailed by any of the following structures:

    { "foo": 1, "bar": [ "x" ], "doz": 2 }       # additional hash element
    { "foo": 1, "bar": [ "x", "y" ], "doz": 2 }  # additional array element

This module exports the testing method C<entails> and its alias C<subsumes> to
check such entailments.  You can pass, JSON strings with encoded JSON objects,
Perl hash references, and blessed hash references.

=head1 LIMITATIONS

This module does not distinguish between numbers and strings, neither between
true and 1 or false and 0. Circular references in passed objects are not
detected.

=head1 SEE ALSO

This module reuses some code from L<Test::JSON>, created by Curtis "Ovid" Poe.
If you need more granular comparision of data structures, you should better
use L<Test::Deep>.

=head1 AUTHOR

Jakob Voss

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voss.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

