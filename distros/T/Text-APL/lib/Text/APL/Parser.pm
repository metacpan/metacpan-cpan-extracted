package Text::APL::Parser;

use strict;
use warnings;

use base 'Text::APL::Base';

sub _BUILD {
    my $self = shift;

    $self->{start_token} ||= '<%';
    $self->{end_token}   ||= '%>';

    $self->{line_token} ||= '%';

    $self->{leftover_token} = $self->_build_leftover_pattern;

    return $self;
}

sub parse {
    my $self = shift;
    my ($input) = @_;

    my $TOKEN_START = qr/$self->{start_token}/;
    my $TOKEN_END   = qr/$self->{end_token}/;
    my $TOKEN       = qr/$TOKEN_START(==?)? [ ] (.*?) \s* $TOKEN_END/xms;

    my $LINE_TOKEN_START = qr/^ \s* $self->{line_token} /xms;
    my $LINE_TOKEN       = qr/$LINE_TOKEN_START(==?)? \s* ([^\n]*)/xms;

    my $LEFTOVER_TOKEN = $self->{leftover_token};

    if (!defined $input) {
        return [] unless defined $self->{buffer};

        my $buffer = delete $self->{buffer};
        return [$buffer =~ m/$LINE_TOKEN/xms
            ? $self->_build_line_token($1, $2)
            : $self->_build_text($buffer)
        ];
    }

    if (defined $self->{buffer}) {
        $input = delete($self->{buffer}) . $input;
    }

    my $tape = [];

    pos $input = 0;
    while (pos $input < length $input) {
        if ($input =~ m/\G $TOKEN/gcxms) {
            push @$tape, $self->_build_token($1, $2);
        }
        elsif ($input =~ m/\G $LINE_TOKEN \n/gcxms) {
            push @$tape, $self->_build_line_token($1, $2);
        }
        elsif ($input =~ m/\G (.+?) (?=$TOKEN_START | $LINE_TOKEN_START)/gcxms) {
            push @$tape, $self->_build_text($1);
        }
        else {
            if ($input =~ m/( (?:$TOKEN_START | $LINE_TOKEN_START) .* )/gcxms) {
                $self->{buffer} = $1;
            }
            elsif ($input =~ m/( $LEFTOVER_TOKEN ) $/gcxms) {
                $self->{buffer} = $1;
            }

            my $value = substr($input, pos($input));

            if (defined $value && $value ne '') {
                push @$tape, $self->_build_text($value);
            }

            last;
        }
    }

    $tape;
}

sub _build_token {
    my $self = shift;
    my ($modifier, $value) = @_;

    my $token = {type => defined $modifier ? 'expr' : 'exec', value => $value};
    $token->{as_is} = 1 if defined $modifier && length $modifier == 2;

    return $token;
}

sub _build_line_token {
    my $self = shift;
    my ($modifier, $value) = @_;

    my $token = {type => defined $modifier ? 'expr' : 'exec', value => $value, line => 1};
    $token->{as_is} = 1 if defined $modifier && length $modifier == 2;

    return $token;
}

sub _build_text {
    my $self =shift;
    my ($value) = @_;

    return {type => 'text', value => $value};
}

sub _build_leftover_pattern {
    my $self = shift;

    my @token = split //, $self->{start_token};

    my $pattern = '';
    $pattern .= '(?:' . $_ for @token;
    $pattern .= ')?' for @token;
    $pattern =~ s{\?$}{};

    return qr/$pattern/;
}

1;
__END__

=pod

=head1 NAME

Text::APL::Parser - parser

=head1 DESCRIPTION

The actual parser. Parses template into a token tree.

=head1 ATTRIBUTES

=head2 C<start_token>

C<<%> by default.

=head2 C<end_token>

C<%>> by default.

=head2 C<line_token>

C<%> by default.

=head1 METHODS

=head2 C<parse>

Parsers string into a token tree.

=cut
