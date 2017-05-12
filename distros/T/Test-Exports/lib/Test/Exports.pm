package Test::Exports;

=head1 NAME

Test::Exports - Test that modules export the right symbols

=head1 SYNOPSIS

    use Test::More;
    use Test::Exports;
    
    require_ok "My::Module" or BAIL_OUT "can't load module";

    import_ok "My::Module", [],             "default import OK";
    is_import qw/foo bar/, "My::Module",    "imports subs";

    new_import_pkg;

    import_ok "My::Module", ["foo"],        "named import OK";
    is_import "foo", "My::Module",          "imports foo";
    cant_ok "bar",                          "doesn't import bar";

=head1 DESCRIPTION

This module provides simple test functions for testing other modules'
C<import> methods. Testing is currently limited to checking which subs
have been imported.

In order to keep different calls to C<< ->import >> separate,
Test::Exports performs these calls from a private package. The
symbol-testing functions then test whether or not symbols are present in
this private package, ensuring none of this interferes with your test
script itself.

=head1 FUNCTIONS

These are all exported by default, as is usual with testing modules.

=cut

use warnings;
use strict;

use B;

use parent "Test::Builder::Module";

our @EXPORT = qw/
    new_import_pkg 
    import_ok import_nok
    is_import cant_ok
/;

our $VERSION = "1";

my $CLASS = __PACKAGE__;

=head2 C<new_import_pkg>

Create a new package to perform imports into. This is useful when you
want to test C<< ->import >> with different arguments: otherwise you'd
need to find some way of going back and clearing up the imports from the
last call.

This returns the name of the new package (which will look like
C<Test::Exports::TestAAAAB>) in case you need it.

=cut

my $counter = "AAAAA";
my $PKG;

sub new_import_pkg { $counter++; $PKG = "$CLASS\::Test$counter" }
new_import_pkg;

=head2 C<import_ok $module, \@args, $name>

Call C<< $module->import >> from the current testing package, passing
C<@args>, and check the call succeeded. 'Success' means not throwing an
exception: C<use> doesn't care if C<import> returns false, so neither do
we.

C<@args> defaults to the empty list; C<$name> defaults to something
sensible.

=cut

sub import_ok {
    my ($mod, $args, $msg) = @_;
    my $tb  = $CLASS->builder;

    local $" = ", ";
    $args   ||= [];
    $msg    ||= "$mod->import(@$args) succeeds";

    my $code = "package $PKG; $mod->import(\@\$args); 1";

    #$tb->diag($code);

    my $eval = eval $code;

    $tb->ok($eval, $msg) or $tb->diag(<<DIAG);
$mod->import(@$args) failed:
$@
DIAG
}

=head2 C<import_nok $module, \@args, $name>

Call C<< $module->import(@args) >> and expect it to throw an exception.
Defaults as for L</import_ok>.

=cut

sub import_nok {
    my ($mod, $args, $msg) = @_;
    my $tb  = $CLASS->builder;

    local $" = ", ";
    $args   ||= [];
    $msg    ||= "$mod->import(@$args) fails";

    my $eval = eval "package $PKG; $mod->import(\@\$args); 1";

    $tb->ok(!$eval, $msg) or $tb->diag(<<DIAG);
$mod->import(@$args) succeeded where it should have failed.
DIAG
}

=head2 C<is_import @subs, $module, $name>

For each name in C<@subs>, check that the current testing package has a
sub by that name and that it is the same as the equinominal sub in the
C<$module> package.

Neither C<$module> nor C<$name> are optional.

=cut

sub is_import {
    my $msg  = pop;
    my $from = pop;
    my $tb = $CLASS->builder;

    my @nok;

    for (@_) {
        my $to = "$PKG\::$_";

        no strict 'refs';
        unless (defined &$to) {
            push @nok, <<DIAG;
  \&$to is not defined
DIAG
            next;
        }

        \&$to == \&{"$from\::$_"} or push @nok, <<DIAG;
  \&$to is not imported correctly
DIAG
    }

    my $ok = $tb->ok(!@nok, $msg) or $tb->diag(<<DIAG);
Expected subs to be imported from $from:
DIAG
    $tb->diag($_) for @nok;
    return $ok;
}

=head2 C<cant_ok @subs, $name>

For each sub in @subs, check that a sub of that name does not exist in
the current testing package. If one is found the diagnostic will
indicate where it was originally defined, to help track down the stray
export.

=cut

sub cant_ok {
    my $msg = pop;
    my $tb  = $CLASS->builder;

    my @nok;

    for (@_) {
        my $can = $PKG->can($_);
        $can and push @nok, $_;
    }

    my $ok = $tb->ok(!@nok, $msg);
    
    for (@nok) {
        my $from = B::svref_2object($PKG->can($_))->GV->STASH->NAME;
        $tb->diag(<<DIAG);
    \&$PKG\::$_ is imported from $from
DIAG
    }

    return $ok;
}

=head1 TODO

=head2 C<is_import>

Currently this just checks that C<\&Our::Pkg::sub == \&Your::Pkg::sub>,
which means

=over 4

=item *

it is impossible to test for exports which have been renamed, and

=item *

we can't be sure the sub originally came from Your::Pkg: it may have
been exported into both packages from somewhere else.

=back

It would be good to fix at least the former.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 BUGS

Please report any bugs to <bug-Test-Exports@rt.cpan.org>.

=head1 COPYRIGHT

Copyright 2010 Ben Morrow.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
