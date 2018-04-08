package WordList::Namespace;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.4.1'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(is_actual_wordlist_module);

our %WordList_Modules = (
);

our %WordList_Namespaces = (
    'WordList::Char'            => 1,
    'WordList::Dynamic'         => 1,
    'WordList::MetaSyntactic'   => 1,
    'WordList::Number'          => 1,
    'WordList::Password'        => 1,
    'WordList::Phrase'          => 1,
);

our $WordList_Namespaces_RE = join(
    '|', map {quotemeta} sort {length($b) <=> length($a)}
        keys %WordList_Namespaces);
$WordList_Namespaces_RE =
    qr/\A(?:$WordList_Namespaces_RE)(?:::|\z)/;

our %Non_WordList_Modules = (
    'WordList'                  => 1,
    'WordList::MetaSyntactic'   => 1, # base class for WordList::MetaSyntactic::*
    'WordList::Namespace'       => 1, # us!
);

our %Non_WordList_Namespaces = (
    'WordList::Bloom'           => 1, # to store bloom filters
    'WordList::Mod'             => 1, # mods
);

our $Non_WordList_Namespaces_RE = join(
    '|', map {quotemeta} sort {length($b) <=> length($a)}
        keys %Non_WordList_Namespaces);
$Non_WordList_Namespaces_RE =
    qr/\A(?:$Non_WordList_Namespaces_RE)(?:::|\z)/;

sub is_actual_wordlist_module {
    my $mod = shift;

    $mod =~ /\AWordList::/ or return 0;
    $WordList_Modules{$mod} and return 3;
    $Non_WordList_Modules{$mod} and return 0;
    $mod =~ $WordList_Namespaces_RE and return 2;
    $mod =~ $Non_WordList_Namespaces_RE and return 0;
    1;
}

1;
# ABSTRACT: Catalog of WordList::* namespaces

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Namespace - Catalog of WordList::* namespaces

=head1 VERSION

This document describes version 0.4.1 of WordList::Namespace (from Perl distribution WordList), released on 2018-04-03.

=head1 SYNOPSIS

 use WordList::Namespace;

 my $wl = WordList::Namespace->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

This module might be useful if you want to know exactly which C<WordList::*>
modules actually contain a word list and which contain something else. Initially
all C<WordList::*> were actual wordlists, but some modules under this namespace
end up being used for something else.

=head1 FUNCTIONS

=head2 is_actual_wordlist_module

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some modules that are known to use this module: L<App::wordlist>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
