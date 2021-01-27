package WordList::ColorName::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-26'; # DATE
our $DIST = 'WordList-ColorName-Any'; # DIST
our $VERSION = '0.003'; # VERSION

use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FirstNextResetFromEach';

use Sah::PSchema 'get_schema';

our $DYNAMIC = 1;

our %PARAMS = (
    scheme => {
        summary => 'Graphics::ColorNames scheme name, e.g. "WWW" '.
            'for Graphics::ColorNames::WWW',
        schema => get_schema('perl::modname', {ns_prefix=>'Graphics::ColorNames'}, {req=>1}),
        req => 1,
    },
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $mod = "Graphics::ColorNames::$self->{params}{scheme}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $res = &{"$mod\::NamesRgbTable"}();
    $self->{_names} = [sort keys %$res];
    $self;
}

sub each_word {
    my ($self, $code) = @_;

    for (@{ $self->{_names} }) {
        no warnings 'numeric';
        my $ret = $code->($_);
        return if defined $ret && $ret == -2;
    }
}

1;
# ABSTRACT: Wordlist from any Graphics::ColorNames::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::ColorName::Any - Wordlist from any Graphics::ColorNames::* module

=head1 VERSION

This document describes version 0.003 of WordList::ColorName::Any (from Perl distribution WordList-ColorName-Any), released on 2020-12-26.

=head1 SYNOPSIS

From Perl:

 use WordList::ColorName::Any;

 my $wl = WordList::ColorName::Any->new(scheme => 'WWW');
 $wl->each_word(sub { ... });

From the command-line:

 % wordlist -w ColorName::Any=scheme,WWW

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from a
Graphics::ColorNames::* module.

=head1 WORDLIST PARAMETERS


This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use WordList::ColorName::Any;
 my $wl = WordList::ColorName::Any->(bar => 2, foo => 1);


When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

 % wordlist -w ColorName::Any=foo,1,bar,2 ...

Known parameters:

=head2 scheme

Required. Graphics::ColorNames scheme name, e.g. "WWW" for Graphics::ColorNames::WWW.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ColorName-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ColorName-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-WordList-ColorName-Any/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Graphics::ColorNames>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
