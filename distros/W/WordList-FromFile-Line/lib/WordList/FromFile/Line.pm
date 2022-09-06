package WordList::FromFile::Line;

use strict;
use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-23'; # DATE
our $DIST = 'WordList-FromFile-Line'; # DIST
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
    $self->{_iterator_idx} = 0;
}

sub first_word {
    my $self = shift;
    $self->reset_iterator;
    $self->next_word;
}

sub next_word {
    my $self = shift;

    if (eof $self->{_fh}) {
        return;
    }

  AGAIN:
    my $word = readline($self->{_fh});
    if (defined $word) {
        chomp $word;
        if ($self->{params}{unique}) {
            goto AGAIN if $self->{_seen}{$word}++;
        }
        return $word;
    } else {
        return;
    }
}

1;
# ABSTRACT: Wordlist from lines of file

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::FromFile::Line - Wordlist from lines of file

=head1 VERSION

This document describes version 0.001 of WordList::FromFile::Line (from Perl distribution WordList-FromFile-Line), released on 2022-07-23.

=head1 SYNOPSIS

From Perl:

 use WordList::FromFile::Line;

 my $wl = WordList::FromFile::Line->new(
     filename => '/path/to/file.txt', # required
     #unique => 1, # optional, default is false
 );
 $wl->each_word(sub { ... });

From the command-line:

 % wordlist -w FromFile::Line=filename,/path/to/file.txt

=head1 DESCRIPTION

This is a dynamic wordlist to get list of words from lines of file.

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::FromFile::Line;
 my $wl = WordList::FromFile::Line->(bar => 2, foo => 1);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w FromFile::Line=foo,1,bar,2 ...

Known parameters:

=head2 filename

Required. Path to file.

=head2 unique

Whether to remove duplicates.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-FromFile-Line>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-FromFile-Line>.

=head1 SEE ALSO

L<WordList::Special::Stdin>

L<WordList::FromFile::Word>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-FromFile-Line>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
