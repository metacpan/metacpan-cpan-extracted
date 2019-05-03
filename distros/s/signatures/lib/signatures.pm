use strict;
use warnings;
package signatures; # git description: v0.13-13-gf19ea86
# ABSTRACT: Subroutine signatures with no source filter

our $VERSION = '0.14';

use XSLoader;
use B::Hooks::Parser 0.12;
use B::Hooks::OP::Check 0.17;
use B::Hooks::OP::PPAddr 0.03;
use B::Hooks::EndOfScope 0.08 ();

XSLoader::load(
    __PACKAGE__,
    $VERSION,
);

{
    my %pkgs;

    sub import {
        my ($class) = @_;
        my $caller = caller();
        $pkgs{$caller} = $class->setup_for($caller);
        return;
    }

    sub unimport {
        my ($class) = @_;
        my $caller = caller();
        $class->teardown_for(delete $pkgs{$caller});
        return;
    }
}

sub setup_for {
    my ($class, $caller) = @_;
    my $ret = $class->setup($caller);

    $^H{"${class}::enabled"} = 1;

    my $old_warn = $SIG{__WARN__};
    $SIG{__WARN__} = sub {
        if ($_[0] !~ /^(?:(?:Illegal character in prototype)|(?:Prototype after '.')) for /) {
            $old_warn ? $old_warn->(@_) : warn @_;
        }
    };

    my $unregister;
    {
        my $called = 0;
        $unregister = sub {
            return if $called++;
            $class->teardown_for([$ret, $unregister]);
            $SIG{__WARN__} = $old_warn;
        };
    }

    &B::Hooks::EndOfScope::on_scope_end($unregister);

    return [$ret, $unregister];
}

sub teardown_for {
    my ($class, $data) = @_;
    delete $^H{"${class}::enabled"};
    $class->teardown($data->[0]);
    $data->[1]->();
    return;
}

sub callback {
    my ($class, $offset, $proto) = @_;
    my $inject = $class->proto_unwrap($proto);
    $class->inject($offset, $inject);
    return;
}

sub proto_unwrap {
    my ($class, $proto) = @_;
    return '' unless length $proto;
    return "my ($proto) = \@_;";
}

sub inject {
    my ($class, $offset, $inject) = @_;
    my $linestr = B::Hooks::Parser::get_linestr();
    substr($linestr, $offset + 1, 0) = $inject;
    B::Hooks::Parser::set_linestr($linestr);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

signatures - Subroutine signatures with no source filter

=head1 VERSION

version 0.14

=head1 SYNOPSIS

    use signatures;

    sub foo ($bar, $baz) {
        return $bar + $baz;
    }

=head1 DESCRIPTION

With this module, we can specify subroutine signatures and have variables
automatically defined within the subroutine.

For example, you can write

    sub square ($num) {
        return $num * $num;
    }

and it will be automatically turned into the following at compile time:

    sub square {
        my ($num) = @_;
        return $num * $num;
    }

Note that, although the syntax is very similar, the signatures provided by this
module are not to be confused with the prototypes described in L<perlsub>. All
this module does is extracting items of @_ and assigning them to the variables
in the parameter list. No argument validation is done at runtime.

The signature definition needs to be on a single line only.

If you want to combine sub signatures with regular prototypes a C<proto>
attribute exists:

    sub foo ($bar, $baz) : proto($$) { ... }

=head1 METHODS

If you want subroutine signatures doing something that this module doesn't
provide, like argument validation, typechecking and similar, you can subclass
it and override the following methods.

=head2 proto_unwrap ($prototype)

Turns the extracted C<$prototype> into code.

The default implementation returns C<< my (${prototype}) = @_; >> or an empty
string, if no prototype is given.

=head2 inject ($offset, $code)

Inserts a C<$code> string into the line perl currently parses at the given
C<$offset>. This is only called by the C<callback> method.

=head2 callback ($offset, $prototype)

This gets called as soon as a sub definition with a prototype is
encountered. Arguments are the C<$offset> within the current line perl
is parsing and extracted C<$prototype>.

The default implementation calls C<proto_unwrap> with the prototype and passes
the returned value and the offset to C<inject>.

=for Pod::Coverage setup setup_for teardown teardown_for

=head1 LIMITATIONS

=over 4

=item prototypes aren't checked for validity yet

You won't get a warning for invalid prototypes using the C<proto> attribute,
like you normally would with warnings enabled.

=item you shouldn't alter $SIG{__WARN__} at compile time

After this module is loaded you shouldn't make any changes to C<$SIG{__WARN__}>
during compile time. Changing it before the module is loaded or at runtime is
fine.

=back

=head1 SEE ALSO

=over 4

=item *

L<Method::Signatures>

=item *

L<MooseX::Method::Signatures>

=item *

L<Sub::Signatures>

=item *

L<Attribute::Signature>

=item *

L<Perl6::Subs>

=item *

L<Perl6::Parameters>

=back

=head1 THANKS

=for stopwords Moritz Lenz Steffen Schwigon

Moritz Lenz and Steffen Schwigon for documentation review and
improvement.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=signatures>
(or L<bug-signatures@rt.cpan.org|mailto:bug-signatures@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Peter Martini Father Chrysostomos Alex Kapranoff Steffen Schwigon Alexandr Ciornii Dave Mitchell

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Peter Martini <PeterCMartini@GMail.com>

=item *

Father Chrysostomos <sprout@cpan.org>

=item *

Alex Kapranoff <alex@kapranoff.ru>

=item *

Steffen Schwigon <ss5@renormalist.net>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Dave Mitchell <davem@iabyn.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
