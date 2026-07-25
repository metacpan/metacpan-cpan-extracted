package Wildling::ParsePattern;

use strict;
use warnings;

use Wildling::Token;

use Exporter 'import';
our @EXPORT_OK = qw(parse_pattern);

# Matches escaped tokens, tokens with {…}, or bare token characters.
my $TOKEN_PARSING_REGEX =
  qr/(\\[%@\$*#&?!-]|[%@\$*#&?!-]\{.*?\}|[%@\$*#&?!-])/;

sub parse_length_with_variants {
    my ( $part, $variants ) = @_;

    my $start_length = 1;
    my $end_length   = 1;

    if ( $part =~ /\{((\d+)-(\d+)|(\d+))\}/ ) {
        if ( defined $2 ) {
            $start_length = 0 + $2;
            $end_length   = 0 + $3;
        }
        elsif ( defined $1 ) {
            $start_length = 0 + $1;
            $end_length   = $start_length;
        }
    }

    return {
        variants    => $variants,
        startLength => $start_length,
        endLength   => $end_length,
        src         => $part,
    };
}

sub parse_length_with_string {
    my ($part) = @_;

    return undef unless $part =~ /\{'(.*)'(?:,(\d+)-(\d+))?(?:,(\d+))?\}/;

    my $string = defined $1 ? $1 : '';

    if ( defined $2 && defined $3 ) {
        return {
            string      => $string,
            startLength => 0 + $2,
            endLength   => 0 + $3,
            src         => $part,
        };
    }

    if ( defined $4 ) {
        my $length = 0 + $4;
        return {
            string      => $string,
            startLength => $length,
            endLength   => $length,
            src         => $part,
        };
    }

    return {
        string      => $string,
        startLength => 1,
        endLength   => 1,
        src         => $part,
    };
}

sub simple_tokenizer {
    my ($variants_string) = @_;
    my @variants = split //, $variants_string;
    return sub {
        my ($part) = @_;
        return Wildling::Token->new( parse_length_with_variants( $part, \@variants ) );
    };
}

sub dictionary_tokenizer {
    my ( $part, $dictionaries ) = @_;
    my $options = parse_length_with_string($part);

    if ( !defined $options
        || ( defined $options->{string}
            && length( $options->{string} )
            && !exists $dictionaries->{ $options->{string} } ) )
    {
        $options = {
            variants    => [$part],
            startLength => 1,
            endLength   => 1,
            src         => $part,
        };
    }
    else {
        my $key = defined $options->{string} ? $options->{string} : '';
        $options->{variants} = $dictionaries->{$key} || [];
    }
    return Wildling::Token->new($options);
}

sub words_tokenizer {
    my ($part) = @_;
    my $options = parse_length_with_string($part);

    if ( !defined $options ) {
        $options = {
            variants    => [$part],
            startLength => 1,
            endLength   => 1,
            src         => $part,
        };
    }
    else {
        my @variants;
        my $work_string = defined $options->{string} ? $options->{string} : '';
        my $index       = 0;
        while ( $index < length($work_string) ) {
            if ( substr( $work_string, $index, 2 ) eq '\\,' ) {
                $index += 2;
            }
            elsif ( substr( $work_string, $index, 1 ) eq ',' ) {
                push @variants, substr( $work_string, 0, $index );
                $work_string = substr( $work_string, $index + 1 );
                $index       = 0;
            }
            else {
                $index += 1;
            }
        }
        push @variants, $work_string;
        $options->{variants} = [ map { s/\\,/,/gr } @variants ];
    }

    return Wildling::Token->new($options);
}

sub part_to_token {
    my ( $part, $dictionaries ) = @_;

    my %tokenizers = (
        '#' => simple_tokenizer('0123456789'),
        '@' => simple_tokenizer('abcdefghijklmnopqrstuvwxyz'),
        '*' => simple_tokenizer('abcdefghijklmnopqrstuvwxyz0123456789'),
        '-' => simple_tokenizer(
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        ),
        '!' => simple_tokenizer('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
        '?' => simple_tokenizer('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'),
        '&' => simple_tokenizer('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
        '%' => sub { dictionary_tokenizer( $_[0], $dictionaries ) },
        '$' => \&words_tokenizer,
    );

    my $first     = length($part) ? substr( $part, 0, 1 ) : '';
    my $tokenizer = length($part) ? $tokenizers{$first} : undef;
    my $is_escaped =
         length($part) > 1
      && substr( $part, 0, 1 ) eq '\\'
      && exists $tokenizers{ substr( $part, 1, 1 ) };

    if ($tokenizer) {
        return $tokenizer->($part);
    }
    elsif ($is_escaped) {
        my $unescaped = $part;
        $unescaped =~ s/^\\//;
        return Wildling::Token->new(
            {
                variants => [$unescaped],
                src      => $part,
            }
        );
    }
    else {
        return Wildling::Token->new(
            {
                variants => [$part],
                src      => $part,
            }
        );
    }
}

sub parse_pattern {
    my ( $input_pattern, $dictionaries ) = @_;
    $dictionaries ||= {};
    my @parts = grep { length $_ } split /$TOKEN_PARSING_REGEX/, $input_pattern;
    return [ map { part_to_token( $_, $dictionaries ) } @parts ];
}

1;
