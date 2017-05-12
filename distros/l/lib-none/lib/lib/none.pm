package lib::none;

our $VERSION = '0.02'; # VERSION

sub import {
    @INC = ();
}

1;
# ABSTRACT: Empty @INC

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::none - Empty @INC

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 % perl -Mlib::none yourscript.pl

 # To load some modules first before emptying @INC
 % perl -Mstrict -Mwarnings -Mlib::none yourscript.pl

=head1 DESCRIPTION

This pragma is used to test a script under a condition of empty C<@INC>, for
example: fatpacked script.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/lib-none>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-noinc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=lib-none>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
