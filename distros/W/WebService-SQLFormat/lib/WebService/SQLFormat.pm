package WebService::SQLFormat;
$WebService::SQLFormat::VERSION = '0.000007';
use Moo 2.002004;

use JSON::MaybeXS qw( decode_json );
use LWP::UserAgent ();
use Module::Runtime qw( use_module );
use Types::Standard qw( Bool InstanceOf Int Str );
use Types::URI qw( Uri );

has debug_level => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has identifier_case => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_identifier_case',
    documentation => q{'upper', 'lower' or 'capitalize'},
);

has keyword_case => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_keyword_case',
    documentation => q{'upper', 'lower' or 'capitalize'},
);

has reindent => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has strip_comments => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    lazy    => 1,
    builder => '_build_ua',
);

has url => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    default => 'https://sqlformat.org/api/v1/format',
);

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    return $ua unless $self->debug_level;

    use_module( 'LWP::ConsoleLogger::Easy', 0.000028 );
    LWP::ConsoleLogger::Easy::debug_ua( $ua, $self->debug_level );
    return $ua;
}

sub format_sql {
    my $self = shift;
    my $sql  = shift;

    my $res = $self->ua->post(
        $self->url,
        {
            (
                $self->_has_identifier_case
                ? ( identifier_case => $self->identifier_case )
                : ()
            ),
            (
                $self->_has_keyword_case
                ? ( keyword_case => $self->keyword_case )
                : ()
            ),
            reindent       => $self->reindent,
            sql            => $sql,
            strip_comments => $self->strip_comments,
        }
    );
    return decode_json( $res->decoded_content )->{result};
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::SQLFormat - Format SQL via the sqlformat.org API

=head1 VERSION

version 0.000007

=head1 SYNOPSIS

    use strict;
    use warnings;
    use feature qw( say );

    use WebService::SQLFormat;
    my $formatter = WebService::SQLFormat->new(
        identifier_case => 'upper',
        reindent        => 1,
    );

    my $sql = shift @ARGV;

    say $formatter->format_sql($sql);

=head2 CONSTRUCTOR OPTIONS

=over 4

=item debug_level

An integer between 0 and 8.  Used to set debugging level for
L<LWP::ConsoleLogger::Easy>.  Defaults to 0.

=item identifier_case

Case to use for SQL identifiers.  One of 'upper', 'lower' or 'capitalize'.  If
no value is supplied, identifiers will not be changed.

=item keyword_case

Case to use for SQL keywords.  One of 'upper', 'lower' or 'capitalize'.  If no
value is supplied, case will not be changed.

=item reindent( 0|1)

Re-indent supplied SQL.  Defaults to 0.

=item strip_comments( 0|1 )

Remove SQL comments.  Defaults to 0.

=item ua

You may supply your own user agent.  Must be of the L<LWP::UserAgent> family.

=item url

The API url to query.  Defaults to L<https://sqlformat.org/api/v1/format>

=back

=head2 format_sql( $raw_sql )

This method expects a scalar containing the SQL which you'd like to format.
Returns the formatted SQL.

=head1 DESCRIPTION

BETA BETA BETA.  Subject to change.

This module is a thin wrapper around L<https://sqlformat.org>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Format SQL via the sqlformat.org API

