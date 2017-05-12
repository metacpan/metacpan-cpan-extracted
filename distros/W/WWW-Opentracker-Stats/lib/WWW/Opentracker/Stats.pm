package WWW::Opentracker::Stats;

use 5.008008;
use strict;
use warnings;


our $VERSION = '1.11';

require Class::Accessor::Fast;
use parent qw/
    Class::Accessor::Fast
    Class::Data::Inheritable
/;

use Params::Validate qw(:all);

__PACKAGE__->mk_accessors(qw/
    _statsurl
    _useragent
    _debug
/);

our %MODES = (
    'tpbs'  => __PACKAGE__.'::Mode::TPBS',
    'peer'  => __PACKAGE__.'::Mode::Peer',
    'fscp'  => __PACKAGE__.'::Mode::Fullscrape',
    'top10' => __PACKAGE__.'::Mode::Top10',
    'tcp4'  => __PACKAGE__.'::Mode::TCP4',
    'herr'  => __PACKAGE__.'::Mode::HttpErrors',
    'udp4'  => __PACKAGE__.'::Mode::UDP4',
    'scrp'  => __PACKAGE__.'::Mode::Scrape',
    'renew' => __PACKAGE__.'::Mode::Renew',
    'torr'  => __PACKAGE__.'::Mode::Torr',
    'conn'  => __PACKAGE__.'::Mode::Conn',
);

=head1 NAME

WWW::Opentracker::Stats - Perl module for retrieve statistics from Opentracker

=head1 SYNOPSIS

    use WWW::Opentracker::Stats;

    my $ot_stats = WWW::Opentracker::Stats->new({
        'statsurl'      => 'http://localhost:6969/stats',
    });

    my $stats_ref = $ot_stats->stats(qw/tpbs peer/);

    my $tpbs_stats  = $stats_ref->{'tpbs'};

    print "Downloads:\n";
    while (my ($torrent, $tstats) = each %{ $tpbs_stats->{'files'} }) {
        print "$torrent: " . $tstats->{'downloaded'} . "\n";
    }


=head1 DESCRIPTION

Provides an easy to use interface to retrieve various statistics from
"opentracker", a BitTorrent tracker.

It executes HTTP requests to opentrackers web services, parses the
response and returns data structures that you can easily extract data from,
to store it in a database or display it on the web.


=head1 METHODS

=head2 new

 Args: $class, $args

Constructor. Creates a new instance of the class.

It takes a HASH/HASHREF of arguments.
 - statsurl (mandatory)
 - useragent (optional)

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
                'default'   => undef,
            },
            'debug'     => {
                'default'   => undef,
            },
        },
    );

    $class = ref $class if ref $class;

    my $self = bless {}, $class;

    $self->_debug($p{'debug'});
    $self->_statsurl($p{'statsurl'});

    $p{'useragent'} ||= $self->default_useragent;
    $self->_useragent($p{'useragent'});

    return $self;
}


=head2 default_useragent

 Args: $self

Creates a default user agent that can be used to fetch statistics from
opentracker. See L<WWW::Opentracker::Stats::UserAgent/default> for details.

=cut

sub default_useragent {
    my ($self) = @_;

    print STDERR "Creating a new default user agent\n"
        if $self->_debug;

    use WWW::Opentracker::Stats::UserAgent;
    return WWW::Opentracker::Stats::UserAgent->default;
}


=head2 params

 Args: $self

Returns a HASHREF with properties that can be passed on to the constructor of
the statistics mode packages.

=cut

sub params {
    my ($self) = @_;

    return {
        'statsurl'  => $self->_statsurl,
        'useragent' => $self->_useragent,
        'debug'     => $self->_debug,
    };
}


sub stats {
    my ($self, @modes) = @_;

    my %all = ();
    for my $mode (@modes) {
        my $stats = $self->stats_by_mode($mode);
        $all{$mode} = $stats;
    }

    return \%all;
}

sub stats_by_mode {
    my ($self, $mode) = @_;

    my $obj = $self->get_mode($mode);

    return $obj->stats;
}

sub get_mode {
    my ($self, $mode) = @_;

    my $package = $MODES{$mode};
    die "Unavailable mode: $mode"
        unless $package;

    my $params  = $self->params;

    eval "require $package;";
    if ($@) {
        die "Failed to load $package: $@";
    }

    my $obj = $package->new($params);

    return $obj;
}


=head2 available_modes

Returns all the available modes as an array.

=cut

sub available_modes {
    return keys %MODES;
}


=head1 SEE ALSO

L<WWW::Opentracker::Stats::Mode>

Opentracker: L<< http://erdgeist.org/arts/software/opentracker/ >>.


=head1 AUTHOR

Knut-Olav Hoven, E<lt>knutolav@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
