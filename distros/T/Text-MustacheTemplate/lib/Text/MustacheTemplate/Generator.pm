package Text::MustacheTemplate::Generator;
use strict;
use warnings;

use Text::MustacheTemplate::Lexer qw/:types/;

sub generate_from_tokens {
    my ($class, @tokens) = @_;

    my ($open_delimiter, $close_delimiter) = do {
        my $token = shift @tokens;
        die 'first token must be delimiter' if $token->[0] != TOKEN_DELIMITER; # uncoverable branch true
        @$token[3,4];
    };

    my $buf = '';
    for my $token (@tokens) {
        my ($type) = @$token;
        if ($type == TOKEN_RAW_TEXT) { # uncoverable branch false count:4
            my (undef, undef, $text) = @$token;
            $buf .= $text;
        } elsif ($type == TOKEN_PADDING) {
            my (undef, undef, $padding) = @$token;
            $buf .= $padding;
        } elsif ($type == TOKEN_TAG) {
            if (@$token == 3) { # uncoverable branch false count:2
                my (undef, undef, $body) = @$token;
                $buf .= $open_delimiter.$body.$close_delimiter;
            } elsif (@$token == 4) {
                my (undef, undef, $tag_type, $body) = @$token;
                $buf .= $open_delimiter.$tag_type.$body;
                $buf .= '}' if $tag_type eq '{';
                $buf .= $close_delimiter;
            } else {
                die "Unknown tag token size: ".scalar(@$token); # uncoverable statement
            }
        } elsif ($type == TOKEN_DELIMITER) {
            my (undef, undef, $body, $new_open_delimiter, $new_close_delimiter) = @$token;
            $buf .= $open_delimiter.'='.$body.'='.$close_delimiter;
            ($open_delimiter, $close_delimiter) = ($new_open_delimiter, $new_close_delimiter);
        } else {
            die "Unknown token type: $type"; # uncoverable statement
        }
    }
    return $buf;
}

1;

=encoding utf-8

=head1 NAME

Text::MustacheTemplate::Generator - Template generator for Mustache templates

=head1 SYNOPSIS

    use Text::MustacheTemplate::Lexer;
    use Text::MustacheTemplate::Generator;

    my @tokens = Text::MustacheTemplate::Lexer->tokenize('Hello {{name}}!');
    my $regenerated_template = Text::MustacheTemplate::Generator->generate_from_tokens(@tokens);
    
    # Result: 'Hello {{name}}!'

=head1 DESCRIPTION

Text::MustacheTemplate::Generator can regenerate a Mustache template from tokens.
This is primarily used for lambda functions that need access to the raw template string.

This is a low-level interface for Text::MustacheTemplate.
The APIs may change without notice.

=head1 METHODS

=over 4

=item generate_from_tokens($delimiter_token, @tokens)

Regenerates a Mustache template string from lexer tokens.

Parameters:
=over 8
=item $delimiter_token - The delimiter token containing open/close delimiters
=item @tokens - Array of tokens from Text::MustacheTemplate::Lexer
=back

Returns a string containing the regenerated template.

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

