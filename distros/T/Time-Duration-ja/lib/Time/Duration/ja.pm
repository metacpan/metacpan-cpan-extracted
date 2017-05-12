package Time::Duration::ja;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(Exporter);
our @EXPORT = qw( later later_exact earlier earlier_exact
                  ago ago_exact from_now from_now_exact
                  duration duration_exact concise );
our @EXPORT_OK = ('interval', @EXPORT);

use constant DEBUG => 0;
use Time::Duration qw();
use utf8;

sub concise ($) { $_[0] }

sub later {
  interval(      $_[0], $_[1], '%s前', '%s後', '現在'); }
sub later_exact {
  interval_exact($_[0], $_[1], '%s前', '%s後', '現在'); }
sub earlier {
  interval(      $_[0], $_[1], '%s後', '%s前', '現在'); }
sub earlier_exact {
  interval_exact($_[0], $_[1], '%s後', '%s前', '現在'); }

sub ago       { &earlier }
sub ago_exact { &earlier_exact }
sub from_now  { &later }
sub from_now_exact { &later_exact }

sub duration_exact {
  my $span = $_[0];   # interval in seconds
  my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
  return '0秒' unless $span;
  _render('%s',
          Time::Duration::_separate(abs $span));
}

sub duration {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0秒' unless $span;
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

my %en2ja = (
    second => '秒',
    minute => '分',
    hour   => '時間',
    day    => '日',
    year   => '年',
);

sub _render {
  # Make it into English
  my $direction = shift @_;
  my @wheel = map
  {
      (  $_->[1] == 0) ? ()  # zero wheels
          : $_->[1] . $en2ja{ $_->[0] }
      }
  @_;
    use Data::Dumper;
#  warn Dumper $direction, \@wheel;

  return "現在" unless @wheel; # sanity
  return sprintf($direction, join '', @wheel);
}

1;
__END__

=for stopwords encodings

=head1 NAME

Time::Duration::ja - describe Time duration in Japanese

=head1 SYNOPSIS

  use Time::Duration::ja;

  my $duration = duration(time() - $start_time);

=head1 DESCRIPTION

Time::Duration::ja is a localized version of Time::Duration.

=head1 UNICODE

All the functions defined in Time::Duration::ja returns string as
Unicode flagged. You should use L<Encode> or L<encoding> to convert to
your native encodings.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Most of the code are taken from Time::Duration::sv by Arthur Bergman and Time::Duration by Sean M. Burke.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Time::Duration>

=cut
