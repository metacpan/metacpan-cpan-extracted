package WordList::FromFile::Word;

use strict;
use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-23'; # DATE
our $DIST = 'WordList-FromFile-Word'; # DIST
our $VERSION = '0.001'; # VERSION

our $DYNAMIC = 1;

our %PARAMS = (
    filename => {
        summary => 'Path to file',
        schema => 'filename*',
        req => 1,
    },
    unique => {
        summary => 'Whether to remove duplicates',
        schema => 'bool*',
    },
    # XXX case_insensitive
);

sub reset_iterator {
    my $self = shift;
    unless ($self->{_fh}) {
        open $self->{_fh}, "<", $self->{params}{filename}
            or die "Can't open file '$self->{params}{filename}': $!";
    }
    seek $self->{_fh}, 0, 0;
    $self->{_seen} = {};
    $self->{_word_buffer} = [];
    $self->{_iterator_idx} = 0;
}

sub first_word {
    my $self = shift;
    $self->reset_iterator;
    $self->next_word;
}

sub next_word {
    my $self = shift;

  AGAIN:

    my $word;
    if (@{ $self->{_word_buffer} }) {
        $word = shift @{ $self->{_word_buffer} };
    } else {
        return if eof $self->{_fh};

      GET_LINE:
        my $line = readline($self->{_fh});
        if (defined $line) {
            my @words = $line =~ /(\w+)/g;
            goto GET_LINE unless @words;
            $word = shift @words;
            push @{ $self->{_word_buffer} }, @words;
        } else {
            return;
        }
    }

    if ($self->{params}{unique}) {
        goto AGAIN if $self->{_seen}{$word}++;
    }

    $word;
}

1;
# ABSTRACT: Wordlist from words in file

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::FromFile::Word - Wordlist from words in file

=head1 VERSION

This document describes version 0.001 of WordList::FromFile::Word (from Perl distribution WordList-FromFile-Word), released on 2022-07-23.

=head1 SYNOPSIS

From Perl:

 use WordList::FromFile::Word;

 my $wl = WordList::FromFile::Word->new(
     filename => '/path/to/file.txt', # required
     #unique => 1, # optional, default is false
 );
 $wl->each_word(sub { ... });

From the command-line:

 % wordlist -w FromFile::Word=filename,/path/to/file.txt

=head1 DESCRIPTION

This is a dynamic wordlist to get list of words from words in file. Words are
extracted using the simple regular expression:

 /(\w+)/

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::FromFile::Word;
 my $wl = WordList::FromFile::Word->(bar => 2, foo => 1);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w FromFile::Word=foo,1,bar,2 ...

Known parameters:

=head2 filename

Required. Path to file.

=head2 unique

Whether to remove duplicates.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-FromFile-Word>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-FromFile-Word>.

=head1 SEE ALSO

L<WordList::FromFile::Line>

L<WordList>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-FromFile-Word>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
