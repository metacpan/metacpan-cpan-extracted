package lib::hiderename;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-13'; # DATE
our $DIST = 'lib-hiderename'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my @hidden_modules;

use Module::HideRename;

sub import {
    my ($class, @modules) = @_;

    for my $module (@modules) {
        $module =~ s/\.pm$//; $module =~ s!/!::!g;
        Module::HideRename::hiderename_modules(modules => [$module]);
        push @hidden_modules, $module;
    }
}

END {
    Module::HideRename::unhiderename_modules(modules => \@hidden_modules)
          if @hidden_modules;
}

1;
# ABSTRACT: Hide modules by renaming them

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::hiderename - Hide modules by renaming them

=head1 VERSION

This document describes version 0.001 of lib::hiderename (from Perl distribution lib-hiderename), released on 2020-02-13.

=head1 SYNOPSIS

 use lib::hiderename 'Foo::Bar'; # Foo/Bar.pm will be renamed to Foo/Bar_hidden.pm

 eval { require Foo::Bar }; # will fail

 # Foo/Bar_hidden.pm will be renamed back to Foo/Bar.pm

=head1 DESCRIPTION

EXPERIMENTAL.

lib::hiderename can temporarily hide modules for you, e.g. for testing purposes.
It uses L<Module::HideRename> to rename module files on the filesystem.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-hiderename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-lib-hiderename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-hiderename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<lib::filter> and L<lib::disallow>, L<Devel::Hide>, L<Test::Without::Module>

L<Module::HideRename>

L<pmhiderename> and L<pmunhiderename> from L<App::pmhiderename>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
