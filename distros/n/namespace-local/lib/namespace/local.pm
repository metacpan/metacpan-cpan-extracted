package namespace::local;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.02';

=head1 NAME

namespace::local - Confine imports to the current scope

=head1 SYNOPSIS

This module allows to use imports inside a block or sub without polluting
the whole package:

    package My::Package;

    sub using_import {
        use namespace::local;
        use Foo::Bar qw(quux);
        # quux() is available here
    }

    sub no_import {
        # quux() is unknown
    }

Unlike L<namespace::clean> by which it is clearly inspired,
it is useless at the top or your module as it will erase all
functions defined below its use line.

=head1 METHOD/FUNCTIONS

None.

=head1 CAVEATS

This module is highly experimental.
The following two conditions are guaranteed to hold
at least until leaving the beta stage:

=over

=item * All symbols available before the use line will stay so
after end of scope

=item * All I<functions> imported I<from other modules> below the use line
with names consisting of words and not present in L<perlvar>
are not going to be available after end of scope.

=back

The rest is a big grey zone.

Currently the module works by saving and then restoring globs,
so variables and filehandles are also reset.
This may be changed in the future.

Additionally, it skips C<_>, C<a>, C<b>, and all numbers,
to avoid breaking things.
More exceptions MAY be added in the future (e.g. C<ARGV>).

=cut

# this was stolen from namespace::clean
use B::Hooks::EndOfScope 'on_scope_end';

# how it works:
# 1) upon use, create a copy of caller's symbol table
# 2) upon use, restore the symbol table from backup (see comments below)
# 3) upon leaving scope, restore the table again thus erasing
#    all imports that followed the use of this module

sub import {
    my $caller = caller;

    my @names = _get_syms( $caller );

    # Shallow copy of symbol table does not work for all cases,
    #     or it would've been just '%content = %{ $caller."::" }
    my %content;
    foreach my $name( @names ) {
        $content{$name} = _save_glob( $caller, $name );
    };

    # FIXME UGLY HACK
    # Immediate backup-and-restore of symbol table
    #     somehow forces binding of symbols
    #     above 'use namespace::local' line
    #     thus preventing subsequent imports from leaking upwards
    # I do not know why it works, it shouldn't.
    _erase_syms( $caller );
    foreach my $name (@names) {
        _restore_glob( $caller, $name, $content{$name} )
    };

    on_scope_end {
        _erase_syms( $caller );
        foreach my $name (@names) {
            _restore_glob( $caller, $name, $content{$name} )
        };
    };
};

# Skip some global symbols to avoid breaking unrelated things
# This list is to grow :'(
my %let_go;
foreach my $name(qw(_ a b)) {
    $let_go{$name}++;
};

# in: package name
# out: sorted & filtered list of symbols

# FIXME needs explanation
# We really need to filter because copying ALL table
#     was preventing on_scope_end from execution
#     (accedental reference count increase?..)
sub _get_syms {
    my $package = shift;

    no strict 'refs'; ## no critic
    my @list = sort grep {
        /^\w+$/ and !/^[0-9]+$/ and !$let_go{$_}
    } keys %{ $package."::" };
    return @list;
};

# In: package
# Out: (none)
# Side effect: destroys symbol table
sub _erase_syms {
    my $package = shift;

    foreach my $name( _get_syms( $package ) ) {
        no strict 'refs'; ## no critic
        delete ${ $package."::" }{$name};
    };
};

# Don't touch NAME, PACKAGE, and GLOB itself
my @TYPES = qw(SCALAR ARRAY HASH CODE IO FORMAT);

# In: package, symbol
# Out: a hash with glob content
sub _save_glob {
    my ($package, $name) = @_;
    my $copy;

    foreach my $type (@TYPES) {
        no strict 'refs'; ## no critic
        my $value = *{$package."::".$name}{$type};
        $copy->{$type} = $value if defined $value;
    };

    return $copy;
};

# In: package, symbol, hash
# Out: (none)
# Side effect: recreates *package::symbol
sub _restore_glob {
    my ($package, $name, $copy) = @_;
    # TODO better input validation needed
    die "ouch" unless ref $copy eq 'HASH';

    foreach my $type ( @TYPES ) {
        defined $copy->{$type} or next;
        no strict 'refs'; ## no critic
        *{ $package."::".$name } = $copy->{$type}
    };
};

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

This is experimental module. There certainly are bugs.
Suggestions on improvements and/or new features are wanted.

Feedback welcome at:

=over

=item * L<https://github.com/dallaylaen/namespace-local-perl/issues>

=item * L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=namespace-local>

=item * C<bug-namespace-local at rt.cpan.org>

=back

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc namespace::local

You can also look for information at:

=over

=item * github:

L<https://github.com/dallaylaen/namespace-local-perl>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=namespace-local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/namespace-local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/namespace-local>

=item * Search CPAN

L<http://search.cpan.org/dist/namespace-local/>

=back


=head1 SEE ALSO

L<namespace::clean>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of namespace::local

