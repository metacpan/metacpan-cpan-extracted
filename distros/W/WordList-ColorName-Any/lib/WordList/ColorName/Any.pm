package WordList::ColorName::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-07-10'; # DATE
our $DIST = 'WordList-ColorName-Any'; # DIST
our $VERSION = '0.002'; # VERSION

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

This document describes version 0.002 of WordList::ColorName::Any (from Perl distribution WordList-ColorName-Any), released on 2020-07-10.

=head1 SYNOPSIS

 use WordList::ColorName::Any;

 my $wl = WordList::ColorName::Any->new(scheme => 'WWW');
 $wl->each_word(sub { ... });

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from a
Graphics::ColorNames::* module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ColorName-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ColorName-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ColorName-Any>

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
