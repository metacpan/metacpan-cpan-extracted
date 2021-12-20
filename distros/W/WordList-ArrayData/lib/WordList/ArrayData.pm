package WordList::ArrayData;

use strict;
use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::EachFromFirstNextReset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'WordList-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

our $DYNAMIC = 1;

our %PARAMS = (
    arraydata => {
        summary => 'ArrayData module name with optional args, e.g. "Number::Prime::First1000", "DBI=dsn,DBI:SQLite:dbname=/path/to/foo"',
        schema => 'perl::arraydata::modname_with_optional_args',
        req => 1,
    },
);

sub new {
    require Module::Load::Util;

    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_arraydata} = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"ArrayData"}, $self->{params}{arraydata});
    $self;
}

sub reset_iterator {
    my $self = shift;
    $self->{_arraydata}->reset_iterator;
}

sub first_word {
    my $self = shift;
    if ($self->{_arraydata}->has_next_item) {
        $self->{_arraydata}->get_next_item;
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

sub next_word {
    my $self = shift;
    if ($self->{_arraydata}->has_next_item) {
        $self->{_arraydata}->get_next_item;
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

1;
# ABSTRACT: Wordlist from any ArrayData::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::ArrayData - Wordlist from any ArrayData::* module

=head1 VERSION

This document describes version 0.001 of WordList::ArrayData (from Perl distribution WordList-ArrayData), released on 2021-12-01.

=head1 SYNOPSIS

From Perl:

 use WordList::ArrayData;

 my $wl = WordList::ArrayData->new(arraydata => 'Number::Prime::First1000');
 $wl->each_word(sub { ... });

From the command-line:

 % wordlist -w ArrayData=arraydata,Number::Prime::First1000

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from an
ArrayData::* module. This module is a bridge between WordList and ArrayData.

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::ArrayData;
 my $wl = WordList::ArrayData->(bar => 2, foo => 1);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w ArrayData=foo,1,bar,2 ...

Known parameters:

=head2 arraydata

Required. ArrayData module name with optional args, e.g. "Number::Prime::First1000", "DBI=dsn,DBI:SQLite:dbname=E<sol>pathE<sol>toE<sol>foo".

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ArrayData>.

=head1 SEE ALSO

L<ArrayData::WordList>

L<WordList>

L<ArrayData>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
