package namespace::allclean;
use strict;
use warnings;

our $VERSION = "0.01";

use B::Hooks::EndOfScope;
use namespace::clean;

sub import {
    my ($class, %args) = @_;
    my $cleanee = exists $args{-cleanee} ? $args{-cleanee} : scalar caller;

    on_scope_end {
        my $subs = namespace::clean->get_functions($cleanee);
 
        my @clean = keys %$subs;
 
        namespace::clean->clean_subroutines($cleanee, @clean);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

namespace::allclean - Avoid imports all subroutines into your namespace

=head1 SYNOPSIS

    package Foo;
    use namespace::allclean;
    sub bar { }

    # later on:
    Foo->bar; # will fail. `bar` got cleaned after compilation.

=head1 DESCRIPTION

C<namespace::allclean> will remove all subroutines at the end of
the current package's compile cycle. Functions called in the package
itself will still be bound by their name, but they won't show up
as methods on your class or instances.

This module is intended to be used when defining the interface.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly8@cpan.orgE<gt>

=cut

