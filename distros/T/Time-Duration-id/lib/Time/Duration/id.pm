package Time::Duration::id;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.04'; # VERSION

use base qw(Exporter);

our @EXPORT = qw(
                    later  later_exact  earlier  earlier_exact
                    ago  ago_exact  from_now  from_now_exact
                    duration  duration_exact  concise
            );
our @EXPORT_OK = ("interval", @EXPORT);

use constant DEBUG => 0;
use Time::Duration ();

my %en2id = (
    #picosecond  => ["nanodetik" , "pd"],
    #nanosecond  => ["nanodetik" , "nd"],
    #microsecond => ["mikrodetik", "μd"],
    millisecond => ["milidetik" , "md"],
    second      => ["detik"     , "d" ],
    minute      => ["menit"     , "m" ],
    hour        => ["jam"       , "j" ],
    day         => ["hari"      , "h" ],
    year        => ["tahun"     , "t" ],
);

my %short   = map { $_->[0] => $_->[1] } values %en2id;
my $comp_re = join "|", map { $_->[0] } values %en2id;


sub concise ($) {
    my $string = $_[0];

    #print "in : $string\n";
    $string =~ tr/,//d;
    $string =~ s/\bdan\b//;
    $string =~ s/\b($comp_re)s?\b/$short{$1}/g;
    $string =~ s/\s*(\d+)\s*/$1/g;

    return $string;
}

sub later {
    interval(      $_[0], $_[1], "%s lalu", "%s lagi", "sekarang");
}

sub later_exact {
    interval_exact($_[0], $_[1], "%s lalu", "%s lagi", "sekarang");
}

sub earlier {
    interval(      $_[0], $_[1], "%s lagi", "%s lalu", "sekarang");
}

sub earlier_exact {
    interval_exact($_[0], $_[1], "%s lagi", "%s lalu", "sekarang");
}

sub ago {
    interval(      $_[0], $_[1], '%s lagi', '%s lalu', "sekarang");
}

sub ago_exact {
    interval_exact($_[0], $_[1], '%s lagi', '%s lalu', "sekarang");
}

sub from_now {
    interval(      $_[0], $_[1], '%s lalu', '%s lagi', "sekarang");
}

sub from_now_exact {
    interval_exact($_[0], $_[1], '%s lalu', '%s lagi', "sekarang");
}


sub duration_exact {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0 detik' unless $span;
    _render('%s',
        Time::Duration::_separate(abs $span));
}

sub duration {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0 detik' unless $span;
    _render('%s',
        Time::Duration::_approximate($precision,
            Time::Duration::_separate(abs $span)));
}


sub interval_exact {
    my $span = $_[0];                       # interval, in seconds
                                            # precision is ignored
    my $direction = ($span <= -1) ? $_[2]   # what a neg number gets
                  : ($span >=  1) ? $_[3]   # what a pos number gets
                  : return          $_[4];  # what zero gets
    _render($direction,
        Time::Duration::_separate($span));
}

sub interval {
    my $span = $_[0];                       # interval, in seconds
    my $precision = int($_[1] || 0) || 2;   # precision (default: 2)
    my $direction = ($span <= -1) ? $_[2]   # what a neg number gets
                  : ($span >=  1) ? $_[3]   # what a pos number gets
                  : return          $_[4];  # what zero gets
    _render($direction,
        Time::Duration::_approximate($precision,
            Time::Duration::_separate($span)));
}


sub _render {
    # Make it into Indonesian
    my $direction = shift @_;
    my @wheel = map {
        ( $_->[1] == 0 ) ? ()  # zero wheels
            : $_->[1] . " " . $en2id{ $_->[0] }[0]
        } @_;

    return "baru saja" unless @wheel; # sanity

    my $result;
    if (@wheel == 1) {
        $result = $wheel[0];
    }
    elsif (@wheel == 2) {
        $result = "$wheel[0] $wheel[1]";
    }
    else {
        #$wheel[-1] = "dan $wheel[-1]";
        $result = join q{, }, @wheel;
    }

    return sprintf($direction, $result);
}


1;
# ABSTRACT: Describe time duration in Indonesian


__END__
=pod

=head1 NAME

Time::Duration::id - Describe time duration in Indonesian

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Time::Duration::id;
 my $duration = duration(310); # => "5 menit 10 detik"

 $Time::Duration::MILLISECOND = 1;
 $duration = duration(3.1); # => "3 detik 100 milidetik"

=head1 DESCRIPTION

C<Time::Duration::id> is a localized version of C<Time::Duration>.

=for Pod::Coverage .+

=head1 FUNCTIONS

See L<Time::Duration>.

=head1 CREDITS

The code was first copied from L<Time::Duration::fr> by Sébastien
Aperghis-Tramoni.

=head1 SEE ALSO

L<Time::Duration>, L<Time::Duration::Locale>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

