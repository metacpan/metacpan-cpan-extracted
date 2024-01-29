package Text::MustacheTemplate::Lexer;
use 5.022000;
use strict;
use warnings;

use Exporter 5.57 'import';

use Carp qw/croak/;

our %EXPORT_TAGS = (
    types => [qw/TOKEN_RAW_TEXT TOKEN_PADDING TOKEN_TAG TOKEN_DELIMITER/]
);
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

our $OPEN_DELIMITER  = '{{';
our $CLOSE_DELIMITER = '}}';

my %CLOSE_DELIMITER_PREFIX = (
    '{' => '}',
    '=' => '=',
);

use constant {
    # enum
    TOKEN_RAW_TEXT  => 0,
    TOKEN_PADDING   => 1,
    TOKEN_TAG       => 2,
    TOKEN_DELIMITER => 3,
};

our $_SOURCE;
our @_TOKENS;

sub tokenize {
    my ($class, $source) = @_;

    local $OPEN_DELIMITER = $OPEN_DELIMITER;
    local $CLOSE_DELIMITER = $CLOSE_DELIMITER;
    local $_SOURCE = $source;

    my @tokens = ([TOKEN_DELIMITER, 0, undef, $OPEN_DELIMITER, $CLOSE_DELIMITER]);
    until ($_SOURCE =~ /\G\z/mgcano) {
        my $pos = pos $_SOURCE || 0;
        if ($_SOURCE =~ /\G\Q${OPEN_DELIMITER}\E([\{#\/&^!>\$<=])?/mgac) { # uncoverable branch false count:2
            push @tokens => _tokenize_tag($1, $pos);
        } elsif ($_SOURCE =~ /\G(?:(^[[:blank:]]+)|(.+?)(^[[:blank:]]+)?)(?=\Q${OPEN_DELIMITER}\E|\z)/msgac) {
            if (defined $1) {
                push @tokens => [TOKEN_PADDING, $pos, $1];
            } else {
                push @tokens => [TOKEN_RAW_TEXT, $pos, $2];
                push @tokens => [TOKEN_PADDING, $pos+length($2), $3] if defined $3;
            }
        } else {
            _error('Syntax Error: Unexpected Token', pos $_SOURCE); # uncoverable statement
        }
    }
    if (length $_SOURCE != pos $_SOURCE) { # uncoverable branch true
        _error('Syntax Error: Unexpected Token', pos $_SOURCE); # uncoverable statement
    }

    return @tokens;
}

sub _tokenize_tag {
    my ($type, $pos) = @_;

    my $prefix = defined $type ? ($CLOSE_DELIMITER_PREFIX{$type} || '') : '';
    if ($_SOURCE =~ /\G(.+?)\Q${prefix}${CLOSE_DELIMITER}\E/msgac) {
        my $body = $1;
        if (defined $type && $type eq '=') {
            my $delimiters = $body;
            $delimiters =~ s/^\s+//ano;
            $delimiters =~ s/\s+$//ano;
            if ($delimiters =~ /=/ano) {
                _error('Syntax Error: Invalid Delimiter', $pos);
            }
            my @delimiters = split /\s+/, $delimiters;
            if (@delimiters != 2) {
                _error('Syntax Error: Invalid Delimiter', $pos);
            }
            $OPEN_DELIMITER = $delimiters[0];
            $CLOSE_DELIMITER = $delimiters[1];
            return [TOKEN_DELIMITER, $pos, $body, $OPEN_DELIMITER, $CLOSE_DELIMITER];
        } else {
            return [TOKEN_TAG, $pos, $type, $body] if defined $type;
            return [TOKEN_TAG, $pos, $body];
        }
    } else {
        _error('Syntax Error: Unexpected Token', $pos);
    }
}

sub _error {                                                                                                                           
    my ($msg, $curr) = @_;

    my $src   = $_SOURCE;
    my $line  = 1;
    my $start = 0;
    while ($src =~ /$/smgco && pos $src <= $curr) {
        $start = pos $src;
        $line++;
    }
    my $end = pos $src;
    my $len = $curr - $start;
    $len-- if $len > 0;

    my $trace = join "\n",
        "${msg}: line:$line",
        substr($src, $start, $end - $start),
        (' ' x $len) . '^';
    croak $trace, "\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::MustacheTemplate::Lexer - Simple mustache template lexer

=head1 SYNOPSIS

    use Text::MustacheTemplate::Lexer;

    # change delimiters
    # local $Text::MustacheTemplate::Lexer::OPEN_DELIMITER = '<%';
    # local $Text::MustacheTemplate::Lexer::CLOSE_DELIMITER = '%>';

    my @tokens = Text::MustacheTemplate::Lexer->tokenize('* {{variable}}');

=head1 DESCRIPTION

Text::MustacheTemplate::Lexer is a simple lexer for Mustache tempalte.

This is low-level interface for Text::MustacheTemplate.
The APIs may be change without notice.

=head1 METHODS

=over 2

=item tokenize

=back

=head1 TOKENS

=over 2

=item TOKEN_RAW_TEXT

=item TOKEN_PADDING

=item TOKEN_TAG

=item TOKEN_DELIMITER

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

