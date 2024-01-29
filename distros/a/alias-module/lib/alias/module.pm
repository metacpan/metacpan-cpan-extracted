## no critic: TestingAndDebugging::RequireUseStrict
package alias::module;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-30'; # DATE
our $DIST = 'alias-module'; # DIST
our $VERSION = '0.003'; # VERSION

sub import {
    my $class = shift;
    my $noreq = $_[0] eq '-norequire' ? shift : 0;
    my $orig  = shift;

    defined $orig or die "Please specify package to alias from";

    my $caller = caller();

    if ($caller eq $orig) {
        warn "Aliasing from the same package '$caller', probably a typo?";
    }

    unless ($noreq) {
        (my $orig_pm = "$orig.pm") =~ s!::!/!g;
        require $orig_pm;
    }
    *{$caller . "::"} = \*{$orig . "::"};
}

1;
# ABSTRACT: Alias one module as another

__END__

=pod

=encoding UTF-8

=head1 NAME

alias::module - Alias one module as another

=head1 VERSION

This document describes version 0.003 of alias::module (from Perl distribution alias-module), released on 2023-09-30.

=head1 SYNOPSIS

 package Your::Alias::Name;
 use alias::module 'Some::Real::Module::Name';

To avoid require()-ing:

 use alias::module '-norequire', 'Some::Real::Module::Name';

=head1 DESCRIPTION

This module aliases one module name to another.

 package Your::Alias::Name;
 use alias::module 'Some::Real::Module::Name';

is equivalent to:

 package Your::Alias::Name;
 BEGIN {
     $Package::Alias::BRAVE = 1;
     require Some::Real::Module::Name;
 }
 use Package::Alias 'Your::Alias::Name' => 'Some::Real::Module::Name';

except that this module does not use L<Package::Alias> and is simpler. It is
useful if you want to let users access a module's functionality under a
different (usually shorter) name.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/alias-module>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-alias-module>.

=head1 SEE ALSO

L<Package::Alias>

L<abbreviation>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=alias-module>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
