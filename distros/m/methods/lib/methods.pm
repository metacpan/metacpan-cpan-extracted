package methods;
use 5.008;
our $VERSION = '0.12';

use true;
use namespace::sweep;
use Method::Signatures::Simple;
our @ISA = 'Method::Signatures::Simple';

method import {
    my $want_invoker;
    if (@_ and $_[0] eq '-invoker') {
        $want_invoker = shift;
    }

    true->import;
    namespace::sweep->import( -cleanee => scalar(caller) );
    Method::Signatures::Simple->import( @_, into => scalar(caller) );

    if ($want_invoker) {
        require invoker;
        unshift @_, 'invoker';
        goto &invoker::import;
    }
}

__END__

=encoding utf8

=head1 NAME

methods - Provide method syntax and sweep namespaces

=head1 SYNOPSIS

    use methods;

    # with signature
    method foo($bar, %opts) {
       $self->bar(reverse $bar) if $opts{rev};
    }

    # attributes
    method foo : lvalue { $self->{foo} }

    # change invocant name
    method foo ($class: $bar) { $class->bar($bar) }

    # "1;" no longer required here

With L<invoker> support:

    use methods-invoker;
    method foo() {
       $->bar(); # Write "$self->method" as "$->method"
    }

=head1 DESCRIPTION

This module uses L<Method::Signatures::Simple> to provide named and
anonymous methods with parameters, except with a shorter module name.

It also imports L<namespace::sweep> so the C<method> helper function
(as well as any imported helper functions) won't become methods in the
importing module.

Finally, it also imports L<true> so there's no need to put C<1;> in the
end of the importing module anymore.

=head1 OPTIONS

If the first argument on the C<use> line is C<-invoker>, then it also
imports L<invoker> automatically so one can write C<< $self->method >> 
as C<< $->method >>.

Other arguments are passed verbatim into L<Method::Signatures::Simple>'s
C<import> function.

=head1 SEE ALSO

L<invoker>, L<signatures>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<methods>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
