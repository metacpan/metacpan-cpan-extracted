package WordList::Tables;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'WordList-Tables'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use parent qw(WordList);

our $DYNAMIC = 1;

our %PARAMS = (
    table => {
        summary => 'Tables::* module name without the prefix, e.g. Locale::US::States '.
            'for Tables::Locale::US::States',
        schema => 'perl::tables::modname_with_optional_args*',
        req => 1,
    },
    column => {
        summary => 'Column name to retrieve from the table',
        schema => 'str*',
        req => 1,
    },
);

sub new {
    require Module::Load::Util;

    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_table} = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"Tables"}, $self->{params}{table});
    my @columns = $self->{_table}->get_column_names;
    my $found;
    for my $i (0..$#columns) {
        if ($self->{params}{column} =~ /\A[0-9]+\z/ && $self->{params}{column} == $i ||
                $self->{params}{column} eq $columns[$i]) {
            $self->{_colidx} = $i;
            $found++;
            last;
        }
    }
    die "Unknown column '$self->{params}{column}' in table $self->{param}{table}, ".
        "available columns are: ".join(", ", @columns) unless $found;
    $self;
}

sub next_word {
    my $self = shift;
    my $row = $self->{_table}->get_row_arrayref;
    return unless $row;
    $row->[ $self->{_colidx} ];
}

sub reset_iterator {
    my $self = shift;
    $self->{_table}->reset_iterator;
}

1;
# ABSTRACT: Wordlist from a column of table from Tables::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::Tables - Wordlist from a column of table from Tables::* module

=head1 VERSION

This document describes version 0.003 of WordList::Tables (from Perl distribution WordList-Tables), released on 2020-11-10.

=head1 SYNOPSIS

 use WordList::Tables;

 my $wl = WordList::Tables->new(table => 'Locale::US::States', column => 'name');
 say $wl->first_word; # Alaska

On the command-line, using the L<wordlist> CLI:

 % wordlist -w Tables=table,Locale::US::States,column,name
 Alaska
 Alabama
 ...

 % wordlist -w Tables=table,Locale::US::States,column,code
 AK
 AL
 ...

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from a
column of table from Tables::* module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Tables>.

=head1 SOURCE

Source repository is at L<https://github.com/repos/perl-WordList-Tables>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Tables>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tables> and C<Tables::*> modules

L<WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
