package Time::Duration::es;
use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Exporter);
our @EXPORT = qw( later later_exact earlier earlier_exact
                  ago ago_exact from_now from_now_exact
                  duration duration_exact concise );
our @EXPORT_OK = ('interval', @EXPORT);

use Time::Duration qw();

our $MILLISECOND = 0;

sub concise ($) {
    my $string = $_[0];
    $string =~ tr/,//d;
    $string =~ s/\by\b//;
    $string =~ s/\b(año|día|hora|minuto|segundo)s?\b/substr($1,0,1)/eg;
    $string =~ s/\b(milisegundo)s?\b/ms/g;
    $string =~ s/\s*(\d+)\s*/$1/g;

    # dirty hack to restore prefixed intervals
    $string =~ s/en([0-9])/en $1/; # en matches momento
    $string =~ s/hace/hace /;

    return $string;
}

sub later {                    # ' earlier', ' later', 'right then'
    interval(      $_[0], $_[1], '%s antes', '%s después',  'al momento'); }
sub later_exact {              # ' earlier', ' later', 'right then'
    interval_exact($_[0], $_[1], '%s antes', '%s después',  'al momento'); }
sub earlier {                  # ' later', ' earlier', 'right then'
    interval(      $_[0], $_[1], '%s después', '%s antes',  'al momento'); }
sub earlier_exact {            # ' later', ' earlier', 'right then'
    interval_exact($_[0], $_[1], '%s después', '%s antes',  'al momento'); }
sub ago {                      # ' from now', ' ago', 'right now'
    interval(      $_[0], $_[1], 'en %s', 'hace %s', 'ahora'); }
sub ago_exact {                # ' from now', ' ago', 'right now'
    interval_exact($_[0], $_[1], 'en %s', 'hace %s', 'ahora'); }
sub from_now {                 # ' ago', ' from now', 'right now'
    interval(      $_[0], $_[1], 'hace %s', 'en %s', 'ahora'); }
sub from_now_exact {           # ' ago', ' from now', 'right now'
    interval_exact($_[0], $_[1], 'hace %s', 'en %s', 'ahora'); }

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

my %en2es = (
    second => ['segundo', 'segundos'],
    minute => ['minuto' , 'minutos' ],
    hour   => ['hora'   , 'horas'   ],
    day    => ['día'    , 'días'    ],
    year   => ['año'    , 'años'    ],
);

sub _render {
    # Make it into Spanish
    my $direction = shift @_;
    my @wheel = map
    {
        (  $_->[1] == 0) ? ()  # zero wheels
             : $_->[1] . ' ' . $en2es{ $_->[0] }[ $_->[1] == 1 ? 0 : 1 ]
        }

    @_;

    return 'ahora' unless @wheel; # sanity
    my $result;
    if(@wheel == 1) {
        $result = $wheel[0];
    } elsif(@wheel == 2) {
        $result = "$wheel[0] y $wheel[1]";
    } else {
        $wheel[-1] = "y $wheel[-1]";
        $result = join q{, }, @wheel;
    }
    return sprintf($direction, $result);
}

1;
__END__

=head1 NAME

Time::Duration::es - describe time duration in Spanish

=head1 SYNOPSIS

  use Time::Duration::es;

  my $duration = duration(time() - $start_time);


=head1 DESCRIPTION

Time::Duration::es is a Spanish localized version of Time::Duration.
Check L<Time::Duration> for all the functions.

=head1 AUTHOR

Paulo A Ferreira E<lt>biafra@cpan.orgE<gt>

All code was taken from L<Time::Duration::pt> by Breno G. de Oliveira which most
of its code was taken from L<Time::Duration::sv> by Arthur Bergman and
L<Time::Duration> by Sean M. Burke.

Thanks to Diana Castro and Joao Medicis for the spanish revision/translation.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Time::Duration> and L<Time::Duration::Locale>

