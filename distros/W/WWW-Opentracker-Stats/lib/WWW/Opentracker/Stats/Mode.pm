package WWW::Opentracker::Stats::Mode;

use strict;
use warnings;

require Class::Accessor::Fast;
use parent qw/
    Class::Accessor::Fast
    Class::Data::Inheritable
/;

use Carp;
use Params::Validate qw(:all);


__PACKAGE__->mk_classdata('_format');
__PACKAGE__->mk_classdata('_mode');

__PACKAGE__->mk_accessors(qw/
    _statsurl
    _useragent
    _debug
/);


=head1 NAME

WWW::Opentracker::Stats::Mode - Base module for the different modes

=head1 SYNOPSIS

    use WWW::Opentracker::Stats::Mode::TPBS;
    my $tpbs = WWW::Opentracker::Stats::Mode::TPBS->new(
        {
            'statsurl'  => 'http://localhost:6969/stats',
        }
    );

    my $stats   = $tpbs->stats();
    printf "%d torrents served", scalar @{$stats->{'files'}};


=head1 DESCRIPTION

Provides accessability for fetching and parsing the statistics from Opentracker.

=head1 METHODS

=head2 new

 Args: $class, $args

Constructor. Creates a new instance of the class.
This constructor is also used by all sub statistics packages.

It takes a HASH/HASHREF of arguments.
 - statsurl (mandatory)
 - useragent (mandatory)

=cut

sub new {
    my $class = shift;

    my %p = validate(@_,
        {
            'statsurl'  => {
                'type'      => SCALAR,
            },
            'useragent' => {
                'isa'       => 'LWP::UserAgent',
            },
            'debug'     => {
                'default'   => undef,
            },
        },
    );

    $class = ref $class if ref $class;

    my $self = bless {}, $class;

    $self->_statsurl($p{'statsurl'});
    $self->_useragent($p{'useragent'});
    $self->_debug($p{'debug'});

    $self->_require_impl;

    return $self;
}


=head2 stats

 Args: $self

Fetches statistics from the opentracker server over a HTTP channel,
decodes the content in the HTTP response and returns the statistics data
structure.

It caches the statistics for the entire lifetime of the object.
If something is found in the cache,
it is returned instead of contacting the server.

=cut

sub stats {
    my ($self) = @_;

    return $self->_stats if defined $self->_stats;

    my $payload = $self->fetch;
    my $stats   = $self->parse_stats($payload);

    $self->_stats($stats);

    return $stats;
}


=head2 parse_stats

 Args: $self, $payload

Returns the payload unchanged.

WARNING This method should really, really be implemented by a subclass.
It should return a HASHREF with a sane structure of the statistics data.

=cut

sub parse_stats {
    my ($self, $payload) = @_;

    warn "You should override this method in the subclass. This method should return a HASHREF";

    return $payload;
}


=head2 fetch

 Args: $self

Makes a HTTP request to the opentracker statistics service
using the implementation (sub) class' mode and format settings.

Returns the content of the response unless there was an error.
Dies on errors.

=cut

sub fetch {
    my ($self) = @_;

    my $ua  = $self->_useragent;
    my $url = $self->url;

    print STDERR "Retrieving stats from url: $url\n"
        if $self->_debug;

    my $response = $ua->get($url);

    if ($response->is_success) {
        return $response->decoded_content(charset => 'none');
    }
    else {
        die $response->status_line;
    }
}


=head2 url

 Args: $self

Assembles the URL to the opentracker statistics based on the statsurl,
format and mode.

Returns the URL as a string.

=cut

sub url {
    my ($self) = @_;

    my $url     = sprintf(
        '%s?format=%s&mode=%s',
        $self->_statsurl,
        $self->_format,
        $self->_mode
    );

    return $url;
}


=head2 parse_thousands

 Args: $self, $number

Parses a string that represents a number with a thousands delimiter.

=cut

sub parse_thousands {
    my ($self, $number) = @_;

    $number =~ s{[\'\.]}{}g;

    return $number;
}


=head2 _require_impl

 Private method

 Args: $self

Croaks from the perspect of the caller two steps up the call stack if the
method is not called from a subclass implementation.

=cut

sub _require_impl {
    my ($self) = @_;

    return unless ref $self eq __PACKAGE__;

    local $Carp::CarpLevel = 2;
    croak "You can not use this package directly. Use a subclass.";
}


=head1 AUTHOR

Knut-Olav Hoven, E<lt>knutolav@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
