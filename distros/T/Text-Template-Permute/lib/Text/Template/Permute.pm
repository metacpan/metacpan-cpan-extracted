package Text::Template::Permute;

use 5.010001;
use strict;
use warnings;

use Permute::Unnamed ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-21'; # DATE
our $DIST = 'Text-Template-Permute'; # DIST
our $VERSION = '0.004'; # VERSION

sub new {
    my $class = shift;

    bless {}, $class;
}

sub _process_directive {
    my $self = shift;
    my $directive = shift;

    my ($command, $opts, $args) = $directive =~ /\A(\w+)\s*([^:]*)\s*:\s*(.+)\z/s
        or die "Invalid directive syntax '$directive', please use COMMAND[OPTIONS]: ...";
    #use DD; dd {command=>$command, opts=>$opts, args=>$args};
    if ($command eq 'comment') {
        return ();
    } elsif ($command eq 'permute') {
        $args =~ s!/\*.*?\*/!!g;
        my @items = split /\|/, $args;
        push @{ $self->{_permute_args} }, \@items;
        my $i = $self->{_permute_idx}++;
        return (sub { $self->{_permute_items}[$_[0]][$i] });
    } elsif ($command eq 'pick') {
        $args =~ s!/\*.*?\*/!!g;
        my @choices = split /\|/, $args;
       if ($opts eq 'once') {
           return ($choices[rand @choices]);
        } else {
            return (sub { $choices[rand @choices] });
        }
    } else {
        die "Unknown command '$command'";
    }
}

sub template {
    my $self = shift;

    if (@_) {
        my $template = shift;
        $self->{template} = $template;
        $self->{_permute_args} = [];
        $self->{_var_array} = [];
        $self->{_var_idx} = {};
        $self->{_idx} = 0;
        $self->{_template_parts} = [];
        $self->{_permute_idx} = 0;
        $template =~ s{(    # 1. whole match
            \{\{(.*?)\}\} | # 2.   directive
            (?:[^\{]+) |    # -.   normal text
            (?:[\{\}]+)     # -.   normal text
        )
        }{
            if (defined $2) {
                push @{ $self->{_template_parts} }, $self->_process_directive($2);
            } else {
                push @{ $self->{_template_parts} }, $1;
            }

        }egsx;
    }
    return $self->{template};
}

sub _fill {
    my $self = shift;
    my $i = shift;
    my @res;
    for my $part (@{ $self->{_template_parts} }) {
        if (ref $part) {
            push @res, $part->($i);
        } else {
            push @res, $part;
        }
    }
    join "", @res;
}

sub var {
    my $self = shift;

    my $name = shift;
    my $val;
    if (exists $self->{_var_idx}{$name}) {
        $val = $self->{vars}{$name};
    } else {
        die "Variable '$name' not mentioned in template";
    }
    if (@_) {
        $val = shift;
        $self->{vars}{$name} = $val;
        $self->{_var_array}[ $self->{_var_idx}{$name} - 1] = $val;
    }
    $val;
}

sub process {
    #no warnings 'uninitialized';

    my $self = shift;

    # generate the permutations of args
    $self->{_permute_items} = [];
    if (@{ $self->{_permute_args} }) {
        $self->{_permute_items} = Permute::Unnamed::permute_unnamed(@{ $self->{_permute_args} });
    } else {
        push @{ $self->{_permute_items} }, [];
    }
    #use DD; dd $self->{_permute_items};

    # generate the permutations of text
    my @res;
    for my $i (0 .. $#{ $self->{_permute_items} }) {
        push @res, $self->_fill($i);
    }

    @res;
}

1;
# ABSTRACT: Template for generating permutation of text

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Permute - Template for generating permutation of text

=head1 VERSION

This document describes version 0.004 of Text::Template::Permute (from Perl distribution Text-Template-Permute), released on 2026-02-21.

=head1 SYNOPSIS

 use Text::Template::Permute;

 my $td = Text::Template::Permute->new(
 );

 $td->template(<<'TEMPLATE');
 Create an image of the boy and animal together.
 {{comment: pose}}{{pick: The boy is standing, holding the animal|The boy is sitting, the animal is standing on the boy's lap}}.
 {{comment: clothing}}{{permute: |Change the boy's clothes to random children clothing.}}
 {{comment: size clue}}The animal is only as large as the boy's hand.
 {{comment: style, mood}}Make sure style is 3d cartoon.
 Horizontal angle: {{pick once: front view|three quarter view}}.
 Plain white background.
 TEMPLATE

 my @res = $td->process;

=head1 DESCRIPTION

This module can produce an array of permuted text from a single template. A
template is text which contains zero or more directives in the form of:

 {{COMMAND[ OPTIONS ]:[ARGS]}}

Known commands:

=over

=item * comment

Directives will be ignored and regarded as an empty string.

=item * permute

Permute the text items separated by C<|>.

Comment in the form of C</* ... */> is allowed which will be removed first
before splitting the items.

Example:

 Good {{permute: morning|afternoon|night}}, Mr Smith!
 It is {{permute: so nice|very nice}} to meet you.

=item * pick

Available option: C<once>.

Pick one of alternative text separated by C<|>.

Comment in the form of C</* ... */> is allowed which will be removed first
before splitting the alternatives.

Example:

 Hello, {{pick: Mr|Mrs}} Smith!

The C<once> option makes the alternative picked once and will be the same in all
permutations.

=back

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Template-Permute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Template-Permute>.

=head1 SEE ALSO

L<Text::Glob::Expand>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Template-Permute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
