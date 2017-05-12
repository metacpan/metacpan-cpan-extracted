package Time::Duration::Patch::Millisecond;

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our $VERSION = '0.03'; # VERSION

my $mod_version = qr/^1\./;

sub concise($) {
    my $string = shift;

    $string =~ s/\b(millisecond)s?\b/ms/g;

    # begin from T::D
    $string =~ tr/,//d;
    $string =~ s/\band\b//;
    $string =~ s/\b(year|day|hour|minute|second)s?\b/substr($1,0,1)/eg;
    $string =~ s/\s*(\d+)\s*/$1/g;
    # end from T::D

    return $string;
}

sub _separate {
    my $ctx       = shift;
    my $remainder = abs($_[0]);
    my $frac      = $remainder - int($remainder);
    my @wheel     = $ctx->{orig}->($remainder);
    if ($frac) {
        push @wheel, ['millisecond', sprintf("%0.f", $frac*1000), 1000];
    }
    @wheel;
}

# this is just like in T::D, except <= -1 and > 1 are replaced with < 0 and > 0.
sub interval_exact {
  my $span = $_[0];                      # interval, in seconds
                                         # precision is ignored
  my $direction = ($span <   0) ? $_[2]  # what a neg number gets
                : ($span >   0) ? $_[3]  # what a pos number gets
                : return          $_[4]; # what zero gets
  Time::Duration::_render($direction,
          Time::Duration::_separate($span));
}

# this is just like in T::D, except <= -1 and > 1 are replaced with < 0 and > 0.
sub interval {
  my $span = $_[0];                      # interval, in seconds
  my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
  my $direction = ($span <   0) ? $_[2]  # what a neg number gets
                : ($span >   0) ? $_[3]  # what a pos number gets
                : return          $_[4]; # what zero gets
  Time::Duration::_render($direction,
          Time::Duration::_approximate($precision,
                       Time::Duration::_separate($span)));
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'wrap',
                mod_version => $mod_version,
                sub_name => '_separate',
                code => \&_separate,
            },
            {
                action => 'replace', # wrap causes prototype mismatch
                mod_version => $mod_version,
                sub_name => 'concise',
                code => \&concise,
            },
            {
                action => 'replace',
                mod_version => $mod_version,
                sub_name => 'interval_exact',
                code => \&interval_exact,
            },
            {
                action => 'replace',
                mod_version => $mod_version,
                sub_name => 'interval',
                code => \&interval,
            },
        ],
    };
}

1;
# ABSTRACT: (DEPRECATED) Make Time::Duration support milliseconds


__END__
=pod

=head1 NAME

Time::Duration::Patch::Millisecond - (DEPRECATED) Make Time::Duration support milliseconds

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 # patch first before importing! otherwise you'll get unpatched version of
 # concise(), interval(), and other routines.
 use Time::Duration::Patch::Millisecond;

 use Time::Duration;

 say ago(0.3); # => 300 milliseconds ago
 say concise(duration(2.03)); # => 2s30ms

=head1 DESCRIPTION

This module contains patch for L<Time::Duration> to support milliseconds. I am
also in the process of asking Time::Duration's maintainer whether he/she wants
to merge this into Time::Duration. See RT#81960. B<UPDATE 2013-04-17:>
Time::Duration 1.1 is now released which contains millisecond support. Therefore
this patch is now declared deprecated.

Locale modules like L<Time::Duration::id> or L<Time::Duration::fr> might want to
translate 'millisecond(s)' and provide its concise version as well.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Time::Duration>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

