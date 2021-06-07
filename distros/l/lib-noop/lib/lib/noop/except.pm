package lib::noop::except;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-07'; # DATE
our $DIST = 'lib-noop'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;

our @excluded_mods;
our $noop_code = "1;\n";

our $hook = sub {
    my ($self, $file) = @_;

    my $mod = $file; $mod =~ s/\.pm\z//; $mod =~ s!/!::!g;

    # decline if in list of module to not noop
    return undef if grep { $_ eq $mod } @excluded_mods;

    return \$noop_code;
};

sub import {
    my $class = shift;

    @excluded_mods = @_;

    @INC = ($hook, grep { $_ ne "$hook" } @INC);
}

sub unimport {
    return unless $hook;
    @excluded_mods = ();
    @INC = grep { "$_" ne "$hook" } @INC;
}

1;
# ABSTRACT: no-op loading of all modules except some

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::noop::except - no-op loading of all modules except some

=head1 VERSION

This document describes version 0.006 of lib::noop::except (from Perl distribution lib-noop), released on 2021-06-07.

=head1 SYNOPSIS

 use lib::noop::except qw(Foo::Bar Baz);
 use Foo::Bar; # not no-op'ed
 use Qux; # no-op'ed

=head1 DESCRIPTION

Given a list of module names, it will make subsequent loading of all but those
modules a no-op. It works by installing a require hook in C<@INC> and return
"1;" as the source code for no-op'ed modules.

This makes loading a no-op'ed module a success, even though the module does not
exist on the filesystem. And the C<%INC> entry for the module will be added,
making subsequent loading of the same module a no-op too because Perl's require
will see that the entry for the module in C<%INC> already exists.

But, since the loading is a no-op operation, no code other than "1;" is executed
and if the original module contains function or package variable definition,
they will not be defined.

This pragma can be used e.g. for testing.

To cancel the effect of lib::noop::except, you can unimport it. If you then want
to actually load a module that has been no-op'ed, you have to delete its C<%INC>
entry first:

 use lib::noop::except qw(Foo);
 use Data::Dumper; # no-op'ed

 # this code will die because Data::Dumper::Dumper is not defined
 BEGIN { print Data::Dumper::Dumper([1,2,3]) }

 no lib::noop::except;
 BEGIN { delete $INC{"Data/Dumper.pm"} }
 use Data::Dumper;

 # this code now runs ok
 BEGIN { print Data::Dumper::Dumper([1,2,3]) }

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-noop>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-noop>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-noop>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::noop>

L<lib::noop::all>

L<lib::noop::all_missing>

L<lib::allow> will do sort-of the opposite: only allow loading some modules
while disallowing the others.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
