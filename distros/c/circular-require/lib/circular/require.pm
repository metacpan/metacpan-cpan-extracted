package circular::require;
our $AUTHORITY = 'cpan:DOY';
$circular::require::VERSION = '0.12';
use strict;
use warnings;

# ABSTRACT: detect circularity in use/require statements

use 5.010;
use Devel::OverrideGlobalRequire;
use Module::Runtime 'module_notional_filename';


our %loaded_from;
our $previous_file;
my @hide;

Devel::OverrideGlobalRequire::override_global_require {
    my ($require, $file) = @_;

    if (exists $loaded_from{$file}) {
        my @cycle = ($file);

        my $caller = $previous_file;

        while (defined($caller)) {
            unshift @cycle, $caller
                unless grep { /^$caller$/ } @hide;
            last if $caller eq $file;
            $caller = $loaded_from{$caller};
        }

        if (_find_enable_state()) {
            if (@cycle > 1) {
                warn "Circular require detected:\n  " . join("\n  ", @cycle) . "\n";
            }
            else {
                warn "Circular require detected in $file (from unknown file)\n";
            }
        }
    }

    local $loaded_from{$file} = $previous_file;
    local $previous_file = $file;

    $require->();
};

sub import {
    # not delete, because we want to see it being explicitly disabled
    $^H{'circular::require'} = 0;
}

sub unimport {
    my $class = shift;
    my %params = @_;

    @hide = ref($params{'-hide'}) ? @{ $params{'-hide'} } : ($params{'-hide'})
        if exists $params{'-hide'};
    @hide = map { /\.pm$/ ? $_ : module_notional_filename($_) } @hide;

    $^H{'circular::require'} = 1;
}

sub _find_enable_state {
    my $depth = 0;
    while (defined(scalar(caller(++$depth)))) {
        my $hh = (caller($depth))[10];
        next unless defined $hh;
        next unless exists $hh->{'circular::require'};
        return $hh->{'circular::require'};
    }
    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

circular::require - detect circularity in use/require statements

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  package Foo;
  use Bar;

  package Bar;
  use Foo;

  package main;
  no circular::require;
  use Foo; # warns

or

  perl -M-circular::require foo.pl

=head1 DESCRIPTION

Perl by default just ignores cycles in require statements - if Foo.pm does
C<use Bar> and Bar.pm does C<use Foo>, doing C<use Foo> elsewhere will start
loading Foo.pm, then hit the C<use> statement, start loading Bar.pm, hit the
C<use> statement, notice that Foo.pm has already started loading and ignore it,
and continue loading Bar.pm. But Foo.pm hasn't finished loading yet, so if
Bar.pm uses anything from Foo.pm (which it likely does, if it's loading it),
those won't be accessible while the body of Bar.pm is being executed. This can
lead to some very confusing errors, especially if introspection is happening at
load time (C<make_immutable> in L<Moose> classes, for example). This module
generates a warning whenever a module is skipped due to being loaded, if that
module has not finished executing.

This module works as a pragma, and typically pragmas have lexical scope.
Lexical scope doesn't make a whole lot of sense for this case though, because
the effect it's tracking isn't lexical (what does it mean to disable the pragma
inside of a cycle vs. outside of a cycle? does disabling it within a cycle
cause it to always be disabled for that cycle, or only if it's disabled at the
point where the warning would otherwise be generated? etc.), but dynamic scope
(the scope that, for instance, C<local> uses) does, and that's how this module
works. Saying C<no circular::require> enables the module for the current
dynamic scope, and C<use circular::require> disables it for the current dynamic
scope. Hopefully, this will just do what you mean.

In some situations, other modules might be handling the module loading for
you - C<use base> and C<Class::Load::load_class>, for instance. To avoid these
modules showing up as the source of cycles, you can use the C<-hide> parameter
when using this module. For example:

  no circular::require -hide => [qw(base parent Class::Load)];

or

  perl -M'-circular::require -hide => [qw(base parent Class::Load)];' foo.pl

=head1 CAVEATS

This module works by overriding C<CORE::GLOBAL::require>, and so other modules
which do this may cause issues if they aren't written properly. See
L<Devel::OverrideGlobalRequire> for more information.

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/circular-require/issues>.

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc circular::require

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/circular-require>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=circular-require>

=item * Github

L<https://github.com/doy/circular-require>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/circular-require>

=back

=for Pod::Coverage unimport

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
