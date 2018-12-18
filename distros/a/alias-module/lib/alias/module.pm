package alias::module;

our $DATE = '2018-12-15'; # DATE
our $VERSION = '0.002'; # VERSION


sub import {
    my $class = shift;
    my $noreq = $_[0] eq '-norequire' ? shift : 0;
    my $orig  = shift;

    my $caller = caller();

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

This document describes version 0.002 of alias::module (from Perl distribution alias-module), released on 2018-12-15.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=alias-module>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Package::Alias>

L<abbreviation>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
