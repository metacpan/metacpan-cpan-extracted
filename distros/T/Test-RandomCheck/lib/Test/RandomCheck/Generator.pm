package Test::RandomCheck::Generator;
use strict;
use warnings;
use Exporter qw(import);
use Test::RandomCheck::ProbMonad;
use Test::RandomCheck::Types;

our @EXPORT = qw(
    enum list integer char string concat hash_ref array_ref function
);

sub enum (@) {
    Test::RandomCheck::Types::Enum->new(
        items => [@_]
    );
}

sub list {
    goto &Test::RandomCheck::Types::List::list;
}

sub _all_integer () {
    Test::RandomCheck::Types::AllInteger->new;
}

sub integer (;$$) {
    goto &_all_integer if @_ == 0;

    my ($min, $max) = @_ >= 2 ? @_ : (0, @_);
    ($min, $max) = ($max, $min) if $min > $max;
    Test::RandomCheck::Types::Integer->new(
        min => $min, max => $max
    );
}

sub char {
    goto &Test::RandomCheck::Types::Char::char;
}

sub string (;$$) {
    my ($min, $max) = @_;
    Test::RandomCheck::Types::String->new(
        min => $min, max => $max
    );
}

sub concat (@) { 
    goto &Test::RandomCheck::Types::Product::product;
}

sub hash_ref ($$;$$) {
    my ($key_type, $value_type, $min, $max) = @_;
    Test::RandomCheck::Types::HashRef->new(
        key_type => $key_type, value_type => $value_type,
        min => $min, max => $max,
    );
}

sub array_ref ($;$$) {
    my ($type, $min, $max) = @_;
    Test::RandomCheck::Types::ArrayRef->new(
        min => $min, max => $max, type => $type
    );
}

sub function ($$) {
    my ($dom, $cod) = @_;
    Test::RandomCheck::Types::Function->new(
        dom => $dom, cod => $cod
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::RandomCheck::Generator - Tools to build a generator of random values

=head1 SYNOPSIS

  use Test::RandomCheck::Generator;

  my $data_generator = array_ref(
      hash_ref(
          string() => array_ref(elements qw(True False))
      ), 5, 10
  );
  # This generator yields values like following:
  # {
  #     'YLkOEF' => ['True'],
  #     'TwpMygm' => ['False', 'False', 'False', 'True', 'False'],
  # }

=head1 DESCRIPTION

Test::RandomCheck::Generator is a combinator to build random value generators
used by L<Test::RandomCheck>.

=head1 COMBINATORS

=over 4

=item C<<const 1, 2, 3;>>

A generator which always returns specified values.

=item C<<range 1, 6;>>

A generator which returns integer from min to max randomly.

=item C<<elements qw(true false);>>

A generator which returns an element randomly.

=item C<<list $gen, 3, 10;>>

A generator which returns a list of values by using specified $gen.
The generated list will have length from min(e.g. 3) to max(e.g. 10).

=item C<<integer;>>

=item C<<char;>>

=item C<<string 8, 12;>>

A generator which generates values of primitive types.

=item C<<concat $gen1, $gen2, $gen3;>>

A generator which generates a list of values.
The generated list has fixed length which is the # of generators.

=item C<<hash_ref $key_gen, $val_gen, 3, 5;>>

A generator which returns an hash-ref.
Keys are produced by $key_gen and values are produced by $val_gen;
$key_gen should return one string value. On the other hand, $value_gen should
return just one value, but the value doesn't have to be string.
Any types of values are O.K.

=item C<<array_ref $gen, 3, 5;>>

A generator which returns an array-ref of values by using specified $gen.
The generated array-ref will have length from min(e.g. 3) to max(e.g. 5).

=back

=head1 METHODS

=over 4

=back

=head1 SEE ALSO

L<Test::RandomCheck>

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Masahiro Honma

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
