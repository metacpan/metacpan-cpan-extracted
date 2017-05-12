package Time::Duration::pt;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Exporter);
our @EXPORT = qw( later later_exact earlier earlier_exact
                  ago ago_exact from_now from_now_exact
                  duration duration_exact concise );
our @EXPORT_OK = ('interval', @EXPORT);

use constant DEBUG => 0;
use Time::Duration qw();

sub concise ($) { 
    my $string = $_[0];
    # print "in : $string\n";
    $string =~ tr/,//d;
    $string =~ s/\be\b//;
    $string =~ s/\b(ano|dia|hora|minuto|segundo)s?\b/substr($1,0,1)/eg;
    $string =~ s/\s*(\d+)\s*/$1/g;

    # dirty hack to restore prefixed intervals
    $string =~ s/daqui a/daqui a /; 

    return $string;
}

sub later {
    interval(      $_[0], $_[1], '%s antes', '%s depois',  'agora'); }
sub later_exact {
    interval_exact($_[0], $_[1], '%s antes', '%s depois',  'agora'); }
sub earlier {
    interval(      $_[0], $_[1], '%s depois', '%s antes',  'agora'); }
sub earlier_exact {
    interval_exact($_[0], $_[1], '%s depois', '%s antes',  'agora'); }
sub ago {
    interval(      $_[0], $_[1], 'daqui a %s', '%s atrás', 'agora'); }
sub ago_exact {
    interval_exact($_[0], $_[1], 'daqui a %s', '%s atrás', 'agora'); }
sub from_now {
    interval(      $_[0], $_[1], '%s atrás', 'daqui a %s', 'agora'); }
sub from_now_exact {
    interval_exact($_[0], $_[1], '%s atrás', 'daqui a %s', 'agora'); }



sub duration_exact {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0 segundos' unless $span;
    _render('%s',
        Time::Duration::_separate(abs $span));
}

sub duration {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0 segundos' unless $span;
    _render('%s',
        Time::Duration::_approximate($precision,
            Time::Duration::_separate(abs $span)));
}

sub interval_exact {
    my $span = $_[0];                      # interval, in seconds
                                         # precision is ignored
    my $direction = ($span <= -1) ? $_[2]  # what a neg number gets
                  : ($span >=  1) ? $_[3]  # what a pos number gets
                  : return          $_[4]; # what zero gets
    _render($direction,
        Time::Duration::_separate($span));
}

sub interval {
    my $span = $_[0];                      # interval, in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    my $direction = ($span <= -1) ? $_[2]  # what a neg number gets
                  : ($span >=  1) ? $_[3]  # what a pos number gets
                  : return          $_[4]; # what zero gets
    _render($direction,
        Time::Duration::_approximate($precision,
            Time::Duration::_separate($span)));
}

my %en2pt = (
    second => ['segundo', 'segundos'],
    minute => ['minuto' , 'minutos' ],
    hour   => ['hora'   , 'horas'   ],
    day    => ['dia'    , 'dias'    ],
    year   => ['ano'    , 'anos'    ],
);

sub _render {
    # Make it into Portuguese
    my $direction = shift @_;
    my @wheel = map
    {
        (  $_->[1] == 0) ? ()  # zero wheels
             : $_->[1] . ' ' . $en2pt{ $_->[0] }[ $_->[1] == 1 ? 0 : 1 ]
        }

    @_;

    return 'agora' unless @wheel; # sanity
    my $result;
    if(@wheel == 1) {
        $result = $wheel[0];
    } elsif(@wheel == 2) {
        $result = "$wheel[0] e $wheel[1]";
    } else {
        $wheel[-1] = "e $wheel[-1]";
        $result = join q{, }, @wheel;
    }
    return sprintf($direction, $result);
}

1;
__END__

=head1 NAME

Time::Duration::pt - describe Time duration in Portuguese

=head1 SYNOPSIS

  use Time::Duration::pt;

  my $duration = duration(time() - $start_time);

=head1 DESCRIPTION

Time::Duration::pt is a portuguese localized version of Time::Duration. It is supposed to be regionalism-agnostic (Brazil, Portugal, etc), so please file a bug if you feel sentences should be different.

=head1 AUTHOR

Breno G. de Oliveira E<lt>garu@cpan.orgE<gt>

Most of the code was taken from Time::Duration::sv by Arthur Bergman and Time::Duration by Sean M. Burke.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Time::Duration>

