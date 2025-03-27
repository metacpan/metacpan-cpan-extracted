package URI::Parse::Instagram;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-27'; # DATE
our $DIST = 'URI-Parse-Instagram'; # DIST
our $VERSION = '0.001'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(parse_instagram_url);

our %SPEC;

our $re_proto_http  = qr!(?:https?://)!i;
our $re_user        = qr/(?:[A-Za-z0-9_]+|[A-Za-z0-9_](?:\.?[A-Za-z0-9])+[A-Za-z0-9_])/;
our $re_user_strict = qr/(?:[A-Za-z0-9_]{1,30}|[A-Za-z0-9_](?:[A-Za-z0-9_]|\.(?!\.)){1,28}[A-Za-z0-9_])/;
our $re_end_or_q    = qr/(?:[?&#]|\z)/;

$SPEC{parse_instagram_url} = {
    v => 1.1,
    summary => 'Parse information from an instagram URL',
    description => <<'MARKDOWN',

Return a hash of information from an Instagram URL, or undef if URL cannot be
parsed. Can potentially return `_errors` or `_warnings` keys, each being an
array of error/warning messages.

MARKDOWN
    args => {
        url => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'hash',
    },
    result_naked => 1,
    examples => [
        {
            name => "insta/USER #1",
            args => {url=>'https://www.instagram.com/foo'},
            result => {user=>'foo'},
        },
        {
            name => "insta/USER #2",
            args => {url=>'https://www.instagram.com/foo.bar/'},
            result => {user=>'foo.bar'},
        },
        {
            name => "insta/USER #3",
            args => {url=>'https://www.instagram.com/foo_bar?igsh=blah&utm_source=qr'},
            result => {user=>'foo_bar'},
        },

        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub parse_instagram_url {
    my $url = shift;

    my $res;
    my $code_add_error = sub {
        $res->{_errors} //= [];
        push @{ $res->{_errors} }, $_[0];
    };

    # metacpan
    if ($url =~ s!\A$re_proto_http?(?:www\.)?instagram\.com/?!!i) {

        #$res->{site} = 'insta';

        if ($url =~ m!\A($re_user)/*$re_end_or_q!i) {
            $res->{user} = lc $1;
            $code_add_error->("Username too long") if length($res->{user}) > 30;
            $code_add_error->("Invalid username") unless $res->{user} =~ m!\A$re_user_strict\z!;
        } else {
            $code_add_error->("Cannot find username");
        }
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }

    $res;
}

1;
# ABSTRACT: Parse information from an instagram URL

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Parse::Instagram - Parse information from an instagram URL

=head1 VERSION

This document describes version 0.001 of URI::Parse::Instagram (from Perl distribution URI-Parse-Instagram), released on 2025-03-27.

=head1 FUNCTIONS


=head2 parse_instagram_url

Usage:

 parse_instagram_url($url) -> hash

Parse information from an instagram URL.

Examples:

=over

=item * Example #1 (instaE<sol>USER #1):

 parse_instagram_url("https://www.instagram.com/foo"); # -> { user => "foo" }

=item * Example #2 (instaE<sol>USER #2):

 parse_instagram_url("https://www.instagram.com/foo.bar/"); # -> { user => "foo.bar" }

=item * Example #3 (instaE<sol>USER #3):

 parse_instagram_url("https://www.instagram.com/foo_bar?igsh=blah&utm_source=qr");

Result:

 { user => "foo_bar" }

=item * Example #4 (unknown):

 parse_instagram_url("https://www.google.com/"); # -> undef

=back

Return a hash of information from an Instagram URL, or undef if URL cannot be
parsed. Can potentially return C<_errors> or C<_warnings> keys, each being an
array of error/warning messages.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$url>* => I<str>

(No description)


=back

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/URI-Parse-Instagram>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-URI-Parse-Instagram>.

=head1 SEE ALSO

L<Regexp::Pattern::Instagram>

L<Sah::SchemaBundle::instagram>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=URI-Parse-Instagram>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
