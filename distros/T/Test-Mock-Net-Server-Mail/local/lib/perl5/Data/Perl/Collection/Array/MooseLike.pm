package Data::Perl::Collection::Array::MooseLike;
$Data::Perl::Collection::Array::MooseLike::VERSION = '0.001008';
# ABSTRACT: Collection::Array subclass that simulates Moose's native traits.

use strictures 1;

use Role::Tiny::With;
use Class::Method::Modifiers;

with 'Data::Perl::Role::Collection::Array';

around 'splice' => sub {
    my $orig = shift;
    my @res = $orig->(@_);

    # support both class instance method invocation style
    @res = blessed($res[0]) && $res[0]->isa('Data::Perl::Collection::Array') ? $res[0]->flatten : @res;

    wantarray ? @res : $res[-1];
};

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Collection::Array::MooseLike - Collection::Array subclass that simulates Moose's native traits.

=head1 VERSION

version 0.001008

=head1 SYNOPSIS

  use Data::Perl::Collection::Array::MooseLike;

  my $array = Data::Perl::Collection::Array::MooseLike->new(qw/a b c d/);

  my $scalar_context = $array->splice(0, 2); # removes and returns b

  my @list_context = $array->splice(0, 2); # returns and removes (b, c)

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with an array. All
methods are written to emulate/match existing behavior that exists with Moose's
native traits.

=head1 DIFFERENCES IN FUNCTIONALITY

=over 4

=item B<splice($args, ...)>

Just like Perl's builtin splice. In scalar context, this returns the last
element removed, or undef if no elements were removed. In list context, this
returns all the elements removed from the array.

This method requires at least one argument.

=back

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<Data::Perl::Role::Collection::Array>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

