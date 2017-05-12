package constant::def;

use strict;
use warnings;
use constant ();

=head1 NAME

constant::def - Perl pragma to declare previously undeclared constants

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Define compile-time constant only if it wasn't previously defined elsewhere.
The main reason is to use for debugging constants, since there is no way to change the value, except by editing the source

    # common way: (redefine may be done only in source file)
    use constant DEBUG => ...;
    # or 
    BEGIN { *DEBUG = sub () { ... } }
    # or 
    sub DEBUG () { ... }

    ################

    # complex way: redefine works, if done before use of module
    # in main.pl
    BEGIN { *My::Module::Debug = sub () { 1 }; }
    use My::Module;

    # in My/Module.pm
    BEGIN { defined &DEBUG or do { my $debug = $ENV{MY_MODULE_DEBUG} || 0; *DEBUG = sub () { $debug } } }

    ################

    # using this distribution
    # redefine works, if done before use of module

    # in main.pl
    use constant::abs 'My::Module::DEBUG' => 1;
    use My::Module;

    # in My/Module.pm
    use constant::def DEBUG => $ENV{MY_MODULE_DEBUG} || 0;
    
Syntax is fully compatible with C<constant>

=cut

sub import {
    my $class = shift;
    return unless @_;
    my $pkg = caller;
    my $multiple  = ref $_[0];
    if (ref $_[0] eq 'HASH') {
        for ( keys %{$_[0]} ) {
            delete $_[0]{$_} if defined &{ $pkg . '::' . $_ }
        }
        return unless %{$_[0]};
    } else {
        if (defined $_[0]) {
            return if defined &{ $pkg . '::' . $_[0] };
        }
    }
    unshift @_,'constant';
    goto &constant::import;
}

=head1 SEE ALSO

L<constant::abs>, L<constant>

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-constant-def at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=constant-def>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of constant::def
