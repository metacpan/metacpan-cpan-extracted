package Text::Gitignore;
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(match_gitignore build_gitignore_matcher);
our $VERSION   = "0.02";

sub match_gitignore {
    my ( $patterns, @paths ) = @_;

    my $matcher = build_gitignore_matcher($patterns);

    my @matched;
    for my $path (@paths) {
        push @matched, $path if $matcher->($path);
    }

    return @matched;
}

sub build_gitignore_matcher {
    my ($patterns) = @_;

    $patterns = [$patterns] unless ref $patterns eq 'ARRAY';
    $patterns = [ grep { !/^#/ } @$patterns ];

    # Escaped comments and trailing spaces
    for my $pattern (@$patterns) {
        $pattern =~ s{(?!\\)\s+$}{};
        $pattern =~ s{^\\#}{#};
    }

    # Empty lines
    $patterns = [ grep { length $_ } @$patterns ];

    my $build_pattern = sub {
        my ($pattern) = @_;

        $pattern = quotemeta $pattern;

        $pattern =~ s{\\\*\\\*\\/}{.*}g;
        $pattern =~ s{\\\*\\\*}{.*}g;
        $pattern =~ s{\\\*}{[^/]*}g;
        $pattern =~ s{\\\?}{[^/]}g;
        $pattern =~ s{^\\\/}{^};
        $pattern =~ s{\\\[(.*?)\\\]}{
            '[' . do { my $c = $1; $c =~ s{^\\!}{} ? '^' : '' }
              . do { my $c = $1; $c =~ s/\\\-/\-/; $c }
              . ']'
        }eg;

        $pattern .= '$' unless $pattern =~ m{\/$};

        return $pattern;
    };

    my @patterns_re;
    foreach my $pattern (@$patterns) {
        if ( $pattern =~ m/^!/ ) {
            my $re = $build_pattern->(substr $pattern, 1);

            push @patterns_re,
              {
                re       => $re,
                negative => 1
              };
        }
        else {

            # Transform escaped negation to normal path
            $pattern =~ s{^\\!}{!};

            push @patterns_re, { re => $build_pattern->($pattern) };
        }
    }

    my @negatives = grep { /^!/ } @$patterns;

    return sub {
        my $path = shift;

        my $match = 0;

        foreach my $pattern (@patterns_re) {
            my $re = $pattern->{re};

            next if $match && !$pattern->{negative};

            if ( $pattern->{negative} ) {
                if ( $path =~ m/$re/ ) {
                    $match = 0;
                }
            }
            else {
                $match = !!( $path =~ m/$re/ );

                if ( $match && !@negatives ) {
                    return $match;
                }
            }
        }

        return $match;
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Gitignore - Match .gitignore patterns

=head1 SYNOPSIS

    use Text::Gitignore qw(match_gitignore build_gitignore_matcher);

    my @matched_files = match_gitignore(['pattern1', 'pattern2/*'], @files);

    # Precompile patterns
    my $matcher = build_gitignore_matcher(['*.js']);

    if ($matcher->('foo.js')) {

        # Matched
    }

=head1 DESCRIPTION

Text::Gitignore matches C<.gitignore> patterns. It combines L<Text::Glob> and
L<File::FnMatch> functionality with several C<.gitignore>-specific tweaks.

=head1 EXPORTED FUNCTIONS

=head2 C<match_gitignore>

    my @matched_files = match_gitignore(['pattern1', 'pattern2/*'], @files);

Returns matched paths (if any). Accepts a string (slurped file for example), or an array reference

=head2 C<build_gitignore_matcher>

    # Precompile patterns
    my $matcher = build_gitignore_matcher(['*.js']);

    if ($matcher->('foo.js')) {

        # Matched
    }

Returns a code reference. The produced function accepts a single file as a first parameter and returns true when it was
matched.

=head1 LICENSE

Originally developed for L<https://kritika.io>.

Copyright (C) Viacheslav Tykhanovskyi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CREDITS

Flavio Poletti

=head1 AUTHOR

Viacheslav Tykhanovskyi E<lt>viacheslav.t@gmail.comE<gt>

=cut

