package Vivaldi::Util::Profile;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-19'; # DATE
our $DIST = 'Vivaldi-Util-Profile'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

use Exporter 'import';
our @EXPORT_OK = qw(list_vivaldi_profiles);

our %SPEC;

$SPEC{list_vivaldi_profiles} = {
    v => 1.1,
    summary => 'List available Vivaldi profiles',
    description => <<'_',

This utility will search for profile directories under ~/.config/vivaldi/.

_
    args => {
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_vivaldi_profiles {
    require Chrome::Util::Profile;

    Chrome::Util::Profile::list_chrome_profiles(
        _chrome_dir => "$ENV{HOME}/.config/vivaldi",
        @_,
    );
}

1;
# ABSTRACT: List available Vivaldi profiles

__END__

=pod

=encoding UTF-8

=head1 NAME

Vivaldi::Util::Profile - List available Vivaldi profiles

=head1 VERSION

This document describes version 0.001 of Vivaldi::Util::Profile (from Perl distribution Vivaldi-Util-Profile), released on 2020-04-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 list_vivaldi_profiles

Usage:

 list_vivaldi_profiles(%args) -> [status, msg, payload, meta]

List available Vivaldi profiles.

This utility will search for profile directories under ~/.config/vivaldi/.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Vivaldi-Util-Profile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Vivaldi-Util-Profile>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Vivaldi-Util-Profile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Vivaldi::Util::*> modules.

L<Firefox::Util::Profile>

L<Chrome::Util::Profile>

L<Opera::Util::Profile>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
