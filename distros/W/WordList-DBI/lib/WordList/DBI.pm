package WordList::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'WordList-DBI'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use parent qw(WordList);

our $NO_STATS = 1;
our $SORT = 'custom';
our $DYNAMIC = 2; # it can be 1 or 2, depending on the query

our %PARAMS = (
    dbh => {
        summary => 'Either dbh or dsn+user+password need to be specified',
        schema => 'obj*',
    },
    dsn => {
        summary => 'Either dbh or dsn+user+password need to be specified',
        schema => 'str*',
    },
    user => {
        summary => 'Either dbh or dsn+user+password need to be specified',
        schema => 'obj*',
    },
    password => {
        summary => 'Either dbh or dsn+user+password need to be specified',
        schema => 'str*',
    },
    query => {
        schema => 'str*',
        req => 1,
    },
    query_pick => {
        schema => 'str*',
    },
);

sub _connect {
    my $self = shift;
    if ($self->{params}{dbh}) {
        $self->{_dbh} = $self->{params}{dbh};
    } else {
        require DBI;
        $self->{_dbh} = DBI->connect(
            $self->{params}{dsn},
            $self->{params}{user}, $self->{params}{password},
            {RaiseError=>1});
    }
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_connect;
    $self;
}

sub reset_iterator {
    my $self = shift;
    $self->{_sth} = $self->{_dbh}->prepare($self->{params}{query});
    $self->{_sth}->execute;
}

sub next_word {
    my $self = shift;
    my ($word) = $self->{_sth}->fetchrow_array;
    $word;
}

sub pick {
    my ($self, $num, $allow_duplicates) = @_;
    $num = 1 unless defined $num;
    unless (defined $self->{query_pick}) {
        return $self->SUPER::pick($num, $allow_duplicates);
    }
    my $sth = $self->{_dbh}->prepare($self->{params}{query_pick});
    $sth->execute;
    my @words;
    while (defined(my ($word) = $sth->fetchrow_array)) {
        push @words, $word;
        last if @words >= $num;
    }
    @words;
}

1;
# ABSTRACT: Wordlist that get its list from a DBI query

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::DBI - Wordlist that get its list from a DBI query

=head1 VERSION

This document describes version 0.001 of WordList::DBI (from Perl distribution WordList-DBI), released on 2020-05-24.

=head1 SYNOPSIS

 use WordList::DBI;

 my $wl = WordList::DBI->new(
     dbh => $dbh,
     query => 'SELECT word FROM table ORDER BY word',
     # query_pick => 'SELECT word FROM table ORDER BY RAND()', # optional
 );
 $wl->each_word(sub { ... });

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from a DBI query.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-DBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-DBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
