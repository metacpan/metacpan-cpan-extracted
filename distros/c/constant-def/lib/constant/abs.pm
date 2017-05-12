package constant::abs;

use strict;
use warnings;
use constant ();

BEGIN { defined &DEBUG or *DEBUG = sub () { 0 } }

=head1 NAME

constant::abs - Perl pragma to declare previously constants using absolute name

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Define compile-time constant using full package name.
The main reason is to use for forward definition of debugging constants.
Created as an addition for C<constant::def>

    # complex way
    # in main.pl
    BEGIN { *My::Module::Debug = sub () { 1 }; }
    use My::Module;

    ################

    # using this distribution
    # in main.pl
    use constant::abs 'My::Module::DEBUG' => 1;
    use My::Module;

Syntax is fully compatible with C<constant>

=cut

sub import {
    my $class = shift;
    return unless @_;
    my $pkg = caller;
    my %const;
    if (ref $_[0] eq 'HASH') {
        %const = map { $_ => [ $_[0]->{$_} ] } keys %{$_[0]};
    } else {
        %const = ( $_[0] => [ @_ ? @_[1..$#_] : () ] );
    }
    for ( keys %const ) {
        my ($pkg,$name) = $_ =~ m{^(?:(.+?)::|)([^:]+)$};
        my @val = @{ $const{$_} };
        $pkg ||= 'main';
        DEBUG and warn "Abs definition for $pkg : $name = @val";
        eval qq{
            package $pkg;
            constant::import( constant => \$name, \@val );
        };
        if (local $_ = $@) {
            s{at \(eval \d+\) line \d+\s*$}{};
            require Carp;
            Carp::croak($_);
        }
        warn if $@;
    }
    return;
}


=head1 SEE ALSO

L<constant::def>, L<constant>

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of constant::abs
