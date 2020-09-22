package Acme::MetaSyntactic::test_wlb_meta;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-23'; # DATE
our $DIST = 'WordListBase-MetaSyntactic'; # DIST
our $VERSION = '0.007'; # VERSION

use parent qw(Acme::MetaSyntactic::MultiList);
__PACKAGE__->init;

1;
# ABSTRACT: A dummy theme to test WordListBase::MetaSyntactic

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::test_wlb_meta - A dummy theme to test WordListBase::MetaSyntactic

=head1 VERSION

This document describes version 0.007 of Acme::MetaSyntactic::test_wlb_meta (from Perl distribution WordListBase-MetaSyntactic), released on 2020-05-23.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=test_wlb_meta -le 'print metaname'
 test_wlb_meta

 % metasyn test_wlb_meta | shuf | head -n2

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordListBase-MetaSyntactic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordListBase-MetaSyntactic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordListBase-MetaSyntactic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordListBase::MetaSyntactic>

L<WordList>

L<Acme::MetaSyntactic>

Other C<WordList::MetaSyntactic::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# default
:all
# names names
a b c d e f g h i j k l m n o p q r s t u v w x y z
