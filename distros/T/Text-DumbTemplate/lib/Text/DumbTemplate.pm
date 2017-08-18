package Text::DumbTemplate;

our $DATE = '2017-08-16'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

sub new {
    my $class = shift;

    bless {}, $class;
}

sub template {
    my $self = shift;

    if (@_) {
        my $template = shift;
        $self->{template} = $template;
        $self->{_var_array} = [];
        $self->{_var_idx} = {};
        $self->{_idx} = 0;
        $template =~ s{\[%=\s*(\w+)\s*%\]|(%)}
                      { if (defined $1) {
                          if (defined $self->{_var_idx}{$1}) {
                              "%$self->{_var_idx}{$1}\$s";
                          } else {
                              $self->{_var_idx}{$1} = ++$self->{_idx};
                              "%$self->{_idx}\$s";
                          }
                      } else { "%%" } }egs;
        $self->{_compiled} = $template;
    }
    return $self->{template};
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
    sprintf $self->{_compiled}, @{$self->{_var_array}};
}

1;
# ABSTRACT: Yet another template system, this one's dumb but fast

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::DumbTemplate - Yet another template system, this one's dumb but fast

=head1 VERSION

This document describes version 0.002 of Text::DumbTemplate (from Perl distribution Text-DumbTemplate), released on 2017-08-16.

=head1 SYNOPSIS

 use Text::DumbTemplate;

 my $td = Text::DumbTemplate->new(
 );

 $td->template(<<'_');
 Hello, good [%= greeting %]!
 My name is [%= name %].
 I am [%= age %] year(s) old.
 Nice to meet you.
 _

 $td->var(greeting => 'morning');
 $td->var(name => 'Ujang');
 $td->var(age => 25);

 print $td->process;

=head1 DESCRIPTION

B<EARLY, EXPERIMENTAL, PROOF OF CONCEPT>.

This is a very simple template module. One thing that's unique about this module
is: it compiles template to a C<sprintf> format instead of Perl subroutines. The
upside: it's blazing fast (e.g. several times faster than L<Template::Compiled>
for small/simple template).

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-DumbTemplate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-DumbTemplate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-DumbTemplate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::sprintfn>

L<Text::Table::Tiny> which also harness the power of C<sprintf> to draw text
tables.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
