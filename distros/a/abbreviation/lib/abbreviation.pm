package abbreviation;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

sub import {
    my($class, @pkg) = @_;
    return unless @pkg;

    for my $pkg (@pkg) {
	eval qq(require $pkg);
	die if $@ && $@ !~ /^Can't locate .*? at \(eval /; #';
	my $abbr = _abbr($pkg) or next;
	no strict 'refs';
	*{$abbr . '::'} = *{$pkg . '::'};
    }
}

sub _abbr {
    my $pkg = shift;

    # Top level => nothing
    return unless $pkg =~ /::/;

    my @pkg = split /::/, $pkg;
    my $lastone = pop @pkg;

    # Mission:
    # Foo::Bar::Baz -> F::B::Baz
    # Foo::bar::Baz -> F::b::Baz
    # FooBar::Bar::Baz -> FB::B::Baz
    # FOO::Bar -> F::Bar
    return join '::', (map {
	s/^([A-Z])[A-Z0-9]+$/$1/; # FOO -> F
	tr/A-Z0-9//cd;
	$_;
    } @pkg), $lastone;
}

1;

__END__
=head1 NAME

abbreviation - Perl pragma to abbreviate class names

=head1 SYNOPSIS

  use abbreviation qw(Very::Long::ClassName::Here);
  
  my $obj = Very::Long::ClassName::Here->new;
  my $obj = V::L::CN::Here->new;	# same

=head1 DESCRIPTION

Tired of typing long class name? use abbreviation for that.

=head1 TRICK AND CAVEAT

Dynamic package name aliasing can be implemented via:

=over 4

=item *

symbol table aliasing. (import.pm)

=item *

dynamic inheritance. (namespace.pm)

=back

Both has virtue and vice. Currently, abbreviation.pm takes the
B<former>. This may change in the future.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<import>, L<namespace>.

=cut
