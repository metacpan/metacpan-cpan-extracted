package Text::Safer;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-14'; # DATE
our $DIST = 'Text-Safer'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(encode_safer);

sub encode_safer {
    my ($text, $encoding, $encoding_args) = @_;
    $encoding //= "alphanum_kebab_nodashend_lc";
    $encoding_args //= {};

    my $module = "Text::Safer::$encoding";
    (my $module_pm = "$module.pm") =~ s!::!/!g;
    require $module_pm;

    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    &{"$module\::encode_safer"}($text, $encoding_args);
}

1;
# ABSTRACT: Convert text with one of several available methods, usually to a safer/more restricted encoding, e.g. for filenames

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Safer - Convert text with one of several available methods, usually to a safer/more restricted encoding, e.g. for filenames

=head1 VERSION

This document describes version 0.003 of Text::Safer (from Perl distribution Text-Safer), released on 2025-06-14.

=head1 SYNOPSIS

 use Text::Safer qw(encode_safer);

 my $safer1 = encode_safer("Foo bar. baz!!!");                       # "foo-bar-baz", default encoding is "alphanum_kebab_nodashend_lc"
 my $safer2 = encode_safer("Foo bar!!!", "alphanum_snake");          # "Foo_bar_"
 my $safer3 = encode_safer("Foo bar!!!", "alphanum_snake", {lc=>1}); # "foo_bar_"

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 encode_safer

Usage:

 my $result = encode_safer($text [ , $encoding [ , \%encoding_args ] ]);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Safer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Safer>.

=head1 SEE ALSO

CLI interface: L<safer> from L<App::safer>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Safer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
