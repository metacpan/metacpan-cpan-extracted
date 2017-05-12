package Yukki::Web::Plugin::SyntaxHighlight;
{
  $Yukki::Web::Plugin::SyntaxHighlight::VERSION = '0.140290';
}
use v5.12;
use Moose;

extends 'Yukki::Web::Plugin';

# ABSTRACT: add syntax highlighting to wiki pages

use Syntax::Highlight::Engine::Kate;
use Syntax::Highlight::Engine::Kate::All;


has format_helpers => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    required    => 1,
    default     => sub { +{
        'highlight'      => 'highlight_syntax',
        'highlight-div'  => 'highlight_syntax',
        'highlight-span' => 'highlight_syntax',
    } },
);

with 'Yukki::Web::Plugin::Role::FormatHelper';


sub highlight_syntax {
    my ($self, $params) = @_;

    my $arg = $params->{arg};
    my ($language, $text) = split /:/, $arg, 2;

    my $engine = Syntax::Highlight::Engine::Kate->new(
        language => $language,
        substitutions => {
            "<"  => "&#x3c;",
            ">"  => "&#x3e;",
            "&"  => "&#x26;",
            " "  => "&#xa0;",
            "\t" => "&#xa0;&#xa0;&#xa0;&#xa0;",
            "\n" => "<br/>\n",
        },
        format_table => {
            Alert        => [q[<span class="syntax-alert">],         q[</span>]],
            BaseN        => [q[<span class="syntax-base-n">],        q[</span>]],
            BString      => [q[<span class="syntax-b-string">],      q[</span>]],
            Char         => [q[<span class="syntax-char">],          q[</span>]],
            Comment      => [q[<span class="syntax-comment">],       q[</span>]],
            DataType     => [q[<span class="syntax-data-type">],     q[</span>]],
            DecVal       => [q[<span class="syntax-dec-val">],       q[</span>]],
            Error        => [q[<span class="syntax-error">],         q[</span>]],
            Float        => [q[<span class="syntax-float">],         q[</span>]],
            Function     => [q[<span class="syntax-function">],      q[</span>]],
            IString      => [q[<span class="syntax-i-string">],      q[</span>]],
            Keyword      => [q[<span class="syntax-keyword">],       q[</span>]],
            Normal       => [q[],                                    q[]       ],
            Operator     => [q[<span class="syntax-operator">],      q[</span>]],
            Others       => [q[<span class="syntax-others">],        q[</span>]],
            RegionMarker => [q[<span class="syntax-region-marker">], q[</span>]], 
            Reserved     => [q[<span class="syntax-reserved">],      q[</span>]],
            String       => [q[<span class="syntax-string">],        q[</span>]],
            Variable     => [q[<span class="syntax-variable">],      q[</span>]],
            Warning      => [q[<span class="syntax-warning">],       q[</span>]],
        },
    );

    my $highlighted_text = $engine->highlightText($text);

    if ($params->{helper_name} =~ /highlight-(div|span)/) {
        my $element = $1;
        $highlighted_text 
            = qq[<$element class="syntax-highlight language-$language">]
            . $engine->highlightText($text)
            . qq[</$element>];
    }

    warn "$highlighted_text\n";

    return $highlighted_text;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::SyntaxHighlight - add syntax highlighting to wiki pages

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  <div>{{highlight:Perl:
  use v5.14;
  use Moose;

  has something => ( is => 'ro' );
  }}</div>

  <span>{{highlight:JavaScript:window.location.hash = '#foo'}}</span>

  {{highlight-div:Perl:
  use v5.14;
  use Moose;

  has something => ( is => 'ro' );
  }}

  {{highlight-span:JavaScript:window.location.hash = '#foo'}}

=head1 DESCRIPTION

Performs syntax highlighting of text. This is able to highlight all the file types listed here with teh L<Syntax::Highlight::Engine::Kate> module:

=over

=item *

L<https://metacpan.org/module/Syntax::Highlight::Engine::Kate#PLUGINS>

=back

=head1 ATTRIBUTES

=head2 format_helpers

Sets up the "highlight" helper.

=head1 METHODS

=head2 highlight_syntax

This is used to format the double-curly brace C<< {{highlight:...}} >>. Do not use.

=head2 highlight_syntax_asis

This is used to format the double-curly brace C<< {{highlight-asis:...}} >>. Do not use.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
