package Moose::Autobox::Code;
# ABSTRACT: the Code role
use Moose::Role 'with';
use Moose::Autobox;
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Ref';

sub curry {
    my ($f, @a) = @_;
    return sub { $f->(@a, @_) }
}

sub rcurry {
    my ($f, @a) = @_;
    return sub { $f->(@_, @a) }
}

sub compose {
    my ($f, $f2, @rest) = @_;
    return $f if !$f2;
    return (sub { $f2->($f->(@_)) })->compose(@rest);
}

sub disjoin {
    my ($f, $f2) = @_;
    return sub { $f->(@_) || $f2->(@_) }
}

sub conjoin {
    my ($f, $f2) = @_;
    return sub { $f->(@_) && $f2->(@_) }
}

# fixed point combinators

sub u {
    my $f = shift;
    sub { $f->($f, @_) };
}

sub y {
    my $f = shift;
    (sub { my $h = shift; sub { $f->(($h->u)->())->(@_) } }->u)->();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Code - the Code role

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  my $adder = sub { $_[0] + $_[1] };
  my $add_2 = $adder->curry(2);

  $add_2->(2); # returns 4

  # create a recursive subroutine
  # using the Y combinator
  *factorial = sub {
      my $f = shift;
      sub {
          my $n = shift;
          return 1 if $n < 2;
          return $n * $f->($n - 1);
      }
  }->y;

  factorial(10) # returns 3628800

=head1 DESCRIPTION

This is a role to describe operations on the Code type.

=head1 METHODS

=over 4

=item C<curry (@values)>

=item C<rcurry (@values)>

=item C<conjoin (\&sub)>

=item C<disjoin (\&sub)>

=item C<compose (@subs)>

This will take a list of C<@subs> and compose them all into a single
subroutine where the output of one sub will be the input of another.

=item C<y>

=for :stopwords combinator

This implements the Y combinator.

=item C<u>

This implements the U combinator.

=back

=over 4

=item C<meta>

=back

=head1 SEE ALSO

=over 4

=item L<http://en.wikipedia.org/wiki/Fixed_point_combinator>

=item L<http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/20469>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
