package lc_time;
use v5.10.1;
use warnings;
use strict;

our $VERSION = '0.15';

require Encode;

use parent 'Exporter';
use POSIX qw/ setlocale LC_TIME LC_CTYPE LC_ALL /;
use constant MY_LC_TIME => $^O eq 'MSWin32' ? LC_ALL : LC_TIME;

our @EXPORT = qw/ strftime /;

=head1 NAME

lc_time - Lexical pragma for strftime.

=head1 SYNOPSIS

    {
        use lc_time 'nl_NL';
        printf "Today in nl: %s\n", strftime("%d %b %Y", localtime());

        # or on Windows
        use lc_time 'Russian_Russia';
        printf "Today in ru: %s\n", strftime("%A %d %B %Y", localtime());
    }

=head1 DESCRIPTION

This pragma switches the locale LC_TIME (or LC_ALL on windows) during the
C<strftime()> call and returns a decoded() string. C<strftime()> is exported by
default.

=begin private

=head2 lc_time->import()

Set the hints-hash key B<pragma_LC_TIME> to the locale passed.

=end private

=cut

sub import {
    my $self = shift;
    my ($locale) = @_;

    my ($pkg) = caller(0);
    __PACKAGE__->export_to_level(1, $pkg, @EXPORT);

    $^H{pragma_LC_TIME} = $locale;
}

=begin private

=head2 lc_time->unimport()

Clear the hints-hash key B<pragma_LC_TIME>.

=end private

=cut

sub unimport {
    $^H{pragma_LC_TIME} = undef;
}

=head2 strftime($template, @localtime)

This is a wrapper around C<POSIX::strftime()> that checks the hints-hash key
b<pragma_LC_TIME>, and temporarily sets the locale LC_TIME to this value.
This affects the '%a', '%A', '%b' and '%B' template conversion specifications.

=cut

sub strftime {
    my ($pattern, @arguments) = @_;
    my $ctrl_h = (caller 0)[10];

    my ($lctime_is, $lctime_was);
    if (my $lctime = $ctrl_h->{pragma_LC_TIME} ) {
        $lctime_was = setlocale(MY_LC_TIME);
        $lctime_is = setlocale(MY_LC_TIME, $lctime)
            or die "Cannot set LC_TIME to '$lctime'\n";
    }

    my $strftime = POSIX::strftime($pattern, @arguments);

    if ($lctime_was) {
        setlocale(MY_LC_TIME, $lctime_was);
    }

    my $encoding = _get_locale_encoding($lctime_is);
    return $encoding ? Encode::decode($encoding, $strftime) : $strftime;
}

sub _get_locale_encoding {
    my $lc_time = shift;
    eval 'require I18N::Langinfo;';
    my $has_i18n_langinfo = !$@;

    if (!$lc_time) {
        return $has_i18n_langinfo
            ? I18N::Langinfo::langinfo(I18N::Langinfo::CODESET())
            : '';
    }

    my $encoding;
    if ($has_i18n_langinfo) {
        my $tmp = setlocale(LC_CTYPE);
        setlocale(LC_CTYPE, $lc_time);
        $encoding = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());
        setlocale(LC_CTYPE, $tmp);
    }

    $encoding ||= _guess_locale_encoding($lc_time);
    if (($] > 5.021001) && ($encoding =~ /utf-?8/i)) {
        # changed by 9717af6d049902fc887c412facb2d15e785ef1a4
        # that patch decodes only if it's a UTF-8 locale.
        $encoding = '';
    }
    return $encoding
}

sub _guess_locale_encoding {
    my $lc_time = shift;

    (my $encoding = $lc_time) =~ s/.+?(?:\.|$)//;
    if ($encoding =~ /^[0-9]+$/) { # Windows cp...
        $encoding = "cp$encoding";
    }
    if (!$encoding && $^O eq 'darwin') {
        $encoding = 'UTF-8';
    }
    return $encoding;
}

1;

=head1 COPYRIGHT

(c) MMXIII - Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
