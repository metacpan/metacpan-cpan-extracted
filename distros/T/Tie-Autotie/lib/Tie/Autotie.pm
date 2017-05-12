package Tie::Autotie;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.03;


sub import {
  my ($class, $pkg, $use_args, $tie_args) = @_;

  $use_args ||= [];
  $tie_args ||= [];

  eval "use $pkg \@\$use_args; 1;";

  no strict 'refs';
  no warnings 'redefine';

  *{$pkg . "::AUTOTIE_STORE"} = \&{$pkg . "::STORE"};
  *{$pkg . "::STORE"} = sub {
    my ($self, $key, $value) = @_;

    if (ref $value) {
      if (UNIVERSAL::isa($value, 'SCALAR') and $pkg->can('TIESCALAR')) {
        tie $$value, $pkg, @$tie_args;
      }
      elsif (UNIVERSAL::isa($value, 'ARRAY') and $pkg->can('TIEARRAY')) {
        tie @$value, $pkg, @$tie_args;
      }
      elsif (UNIVERSAL::isa($value, 'HASH') and $pkg->can('TIEHASH')) {
        tie %$value, $pkg, @$tie_args;
      }
    }

    $self->AUTOTIE_STORE($key, $value);
  };
}
  

1;

__END__

=head1 NAME

Tie::Autotie - Automatically ties underlying references

=head1 SYNOPSIS

  use Tie::Autotie
    'Tie::Module',      # the module to autotie
    [ 'use', 'args' ],  # arguments to 'use Tie::Module'
    [ 'tie', 'args' ];  # arguments to tie() for Tie::Module

  # then use Tie::Module as usual

=head1 DESCRIPTION

This module allows you to automatically tie data structures contained in
a tied data structure.  As an example:

  use Tie::Autotie 'Tie::IxHash';

  tie my(%hash), 'Tie::IxHash';

  $hash{jeff}{age} = 22;
  $hash{jeff}{lang} = 'Perl';
  $hash{jeff}{brothers} = 3;
  $hash{jeff}{sisters} = 4;

  $hash{kristin}{age} = 22;
  $hash{kristin}{lang} = 'Latin';
  $hash{kristin}{brothers} = 1;
  $hash{kristin}{sisters} = 0;

  for my $who (keys %hash) {
    print "$who:\n";
    for my $what (keys %{ $hash{$who} }) {
      print "  $what = $hash{$who}{$what}\n";
    }
  }

This program outputs:

  jeff:
    age = 22
    lang = Perl
    brothers = 3
    sisters = 4
  kristin:
    age = 22
    lang = Latin
    brothers = 1
    sisters = 0

You can see that the keys of %hash are returned in the order in which they
were created, I<as well> as the keys of the sub-hashes.

=head1 BUGS

=over 4

=item * A non-autotied layer

It only works if each layer is being autotied.  As soon as there's a layer
that is not being autotied, all layers inside it will also be ignored:

  use Tie::Autotie 'Tie::IxHash';
  
  tie my(%hash), 'Tie::IxHash';
  
  $hash{a}{b} = 1;  # %{ $hash{a} } is autotied
  $hash{a}{c} = 2;  # so keys %{ $hash{a} } returns ('b', 'c')
  
  $hash{d}[0]{a}{y} = 3;  # %{ $hash{d} } is autotied, but Tie::IxHash has
  $hash{d}[0]{a}{x} = 4;  # no control over $hash{d}[0], so $hash{d}[0]{a}
                          # is not autotied

At the moment, there's no way to get around this.  Please stick to using
data structures that your tying module can handle.

=item * Assigning a reference

In the Tie::IxHash example, you cannot do:

  $hash{jeff} = {
    age => 22,
    lang => 'Perl',
    brothers => 3,
    sisters => 4,
  };

because that creates a hash reference, not an object of Tie::IxHash.
This hash reference ends up being destroyed anyway, and replaced with a
Tie::IxHash object that points to an empty hash.

=head1 AUTHOR

Jeff C<japhy> Pinyan, E<lt>japhy@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
