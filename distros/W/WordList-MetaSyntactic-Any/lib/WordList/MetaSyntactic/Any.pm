package WordList::MetaSyntactic::Any;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-04'; # DATE
our $DIST = 'WordList-MetaSyntactic-Any'; # DIST
our $VERSION = '0.001'; # VERSION

use parent qw(WordList);

use Role::Tiny::With;
with 'WordListRole::FirstNextResetFromEach';

our $DYNAMIC = 1;

our %PARAMS = (
    theme => {
        summary => 'Acme::MetaSyntactic theme name, e.g. "dangdut" '.
            'for Acme::MetaSyntactic::dangdut',
        schema => 'perl::modname*',
        req => 1,
        completion => sub {
            my %args = @_;
            require Complete::Module;
            Complete::Module::complete_module(
                word => $args{word},
                ns_prefix => 'Acme::MetaSyntactic',
            );
        },
    },
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $mod = "Acme::MetaSyntactic::$self->[2]{theme}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my @names = @{"$mod\::List"};
    unless (@names) {
        @names = map { @{ ${"$mod\::MultiList"}{$_} } }
            sort keys %{"$mod\::MultiList"};
    }
    $self->[1] = \@names;
    $self;
}

sub each_word {
    my ($self, $code) = @_;

    for (@{ $self->[1] }) {
        no warnings 'numeric';
        my $ret = $code->($_);
        return if defined $ret && $ret == -2;
    }
}

1;
# ABSTRACT: Wordlist from any Acme::MetaSyntactic::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

WordList::MetaSyntactic::Any - Wordlist from any Acme::MetaSyntactic::* module

=head1 VERSION

This document describes version 0.001 of WordList::MetaSyntactic::Any (from Perl distribution WordList-MetaSyntactic-Any), released on 2020-05-04.

=head1 SYNOPSIS

 use WordList::MetaSyntactic::Any;

 my $wl = WordList::MetaSyntactic::Any->new(theme => 'dangdut');
 $wl->each_word(sub { ... });

=head1 DESCRIPTION

This is a dynamic, parameterized wordlist to get list of words from an
Acme::MetaSyntactic::* module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-MetaSyntactic-Any>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-MetaSyntactic-Any>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-MetaSyntactic-Any>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Acme::MetaSyntactic>

Some C<Acme::MetaSyntactic::*> modules get their names from wordlist, e.g.
L<Acme::MetaSyntactic::countries>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
