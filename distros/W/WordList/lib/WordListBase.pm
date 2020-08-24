package WordListBase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-23'; # DATE
our $DIST = 'WordList'; # DIST
our $VERSION = '0.7.6'; # VERSION

use strict 'subs', 'vars';

sub new {
    my $class = shift;

    # check for known and required parameters
    my %params = @_;
    my $param_spec = \%{"$class\::PARAMS"};
    for my $param_name (keys %params) {
        die "Unknown parameter '$param_name'" unless $param_spec->{$param_name};
    }
    for my $param_name (keys %$param_spec) {
        die "Missing required parameter '$param_name'"
            if $param_spec->{$param_name}{req} && !exists($params{$param_name});
        # apply default
        $params{$param_name} = $param_spec->{$param_name}{default}
            if !defined($params{$param_name}) &&
            exists $param_spec->{$param_name}{default};
    }

    bless {
        params => \%params,

        # we store this because applying roles to object will rebless the object
        # into some other package.
        orig_class => $class,
    }, $class;
}

1;
# ABSTRACT: WordList base class

__END__

=pod

=encoding UTF-8

=head1 NAME

WordListBase - WordList base class

=head1 VERSION

This document describes version 0.7.6 of WordListBase (from Perl distribution WordList), released on 2020-08-23.

=head1 DESCRIPTION

This base class only provides new() and nothing else.

=head1 METHODS

=head2 new

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

L<WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
