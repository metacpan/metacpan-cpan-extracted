package onkeypatch;

our $DATE = '2017-07-18'; # DATE
our $VERSION = '0.001'; # VERSION

use parent qw(monkeypatch);

1;
# ABSTRACT: Monkeypatch your Perl code on the command-line

__END__

=pod

=encoding UTF-8

=head1 NAME

onkeypatch - Monkeypatch your Perl code on the command-line

=head1 VERSION

This document describes version 0.001 of onkeypatch (from Perl distribution monkeypatch), released on 2017-07-18.

=head1 SYNOPSIS

On the command-line:

 % perl -Monkeypatch=Your::Package::foo,delete yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,add,'some code' yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,replace,'some code' yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,add_or_replace,'some code' yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,wrap,'my $ctx = shift; some code; $ctx->{orig}(@_)' yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,before,'some code' yourscript.pl ...
 % perl -Monkeypatch=Your::Package::foo,after,'some code' yourscript.pl ...

=head1 DESCRIPTION

This is basically just a convenient way to use L<Monkey::Patch::Action> from the
command-line.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/monkeypatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-monkeypatch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=monkeypatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Monkey::Patch::Action>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
