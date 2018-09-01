package decorators::providers::for_providers;
# ABSTRACT: A set of decorators to help write other decorators

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub CreateMethod { () }
sub WrapMethod   { () }
sub TagMethod    { () }

sub Decorator    { () }

1;

__END__

=pod

=head1 NAME

decorators::providers::for_providers - A set of decorators to help write other decorators

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use decorators ':for_providers';

=head1 DESCRIPTION

This is a decorator provider which contains some useful decorators
for people who are writing decorator providers.

=head1 DECORATORS

=head2 Decorator

This is a C<TagMethod> meant to mark a subroutine as a Decorator. This
decorator much be attached to a subroutine if you want it to be considered
as a decorator by the system.

=head2 CreateMethod

This means that the decorator handler will create the method exclusivily.
This means the method must be a bodyless method. Ideally there is only one
C<CreateMethod> decorator attached to the method and it is the first one
that is executed. If this is not the case, the decorator will likely fail
to be applied.

=head2 WrapMethod

This means that the decorator handle will override, or wrap, the method.
This means the method must exist already.

=head2 TagMethod

This means that the decorator is really just a tag added to the method.
These typically will be processed at runtime through introspection, so
can simply be no-op subroutines. As with C<WrapMethod> this means the
method must exist already.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
