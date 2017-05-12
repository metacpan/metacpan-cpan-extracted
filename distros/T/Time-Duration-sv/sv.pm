
package Time::Duration::sv;
# Time-stamp: "2002-10-08 01:04:09 MDT"           POD is at the end.
$VERSION = '1.01';
require Exporter;
@ISA = ('Exporter');
@EXPORT = qw( later later_exact earlier earlier_exact
              ago ago_exact from_now from_now_exact
              duration duration_exact
              concise
            );
@EXPORT_OK = ('interval', @EXPORT);

use strict;
use constant DEBUG => 0;
use Time::Duration qw();
# ALL SUBS ARE PURE FUNCTIONS

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub concise ($) {
  my $string = $_[0];
  #print "in : $string\n";
  $string =~ s/,//g;
  $string =~ s/\boch\b//;
  $string =~ s/\b(dag|dagar|timme|timmar|minut|minuter|sekund|sekunder)\b/substr($1,0,1)/eg;
  $string =~s/år/å/g;
  my $save = '';
  if($string =~s/(för|om)//) {
	$save = $1;
  }
  $string =~ s/\s*(\d+)\s*/$1/g;

  return $save ? $save . " " . $string : $string;
}

sub later {
  interval(      $_[0], $_[1], '%s tidigare', '%s senare', 'just då'); }
sub later_exact {
  interval_exact($_[0], $_[1], '%s tidigare', '%s senare', 'just då'); }
sub earlier {
  interval(      $_[0], $_[1], '%s senare', '%s tidigare', 'just då'); }
sub earlier_exact {
  interval_exact($_[0], $_[1], '%s senare', '%s tidigare', 'just då'); }
sub ago {
  interval(      $_[0], $_[1], 'om %s', 'för %s sen', 'just nu'); }
sub ago_exact {
  interval_exact($_[0], $_[1], 'för %s sen', '%s ago', 'just nu'); }
sub from_now {
  interval(      $_[0], $_[1], 'för %s sen', 'om %s', 'just nu'); }
sub from_now_exact {
  interval_exact($_[0], $_[1], 'för %s sen', 'om %s', 'just nu'); }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub duration_exact {
  my $span = $_[0];   # interval in seconds
  my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
  return '0 sekunder' unless $span;
  _render('%s',
          Time::Duration::_separate(abs $span));
}

sub duration {
    my $span = $_[0];   # interval in seconds
    my $precision = int($_[1] || 0) || 2;  # precision (default: 2)
    return '0 sekunder' unless $span;
  _render('%s',
          Time::Duration::_approximate($precision,
                       Time::Duration::_separate(abs $span)));
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
my %env2sv = (
	second => ['sekund', 'sekunder'],
	minute => ['minut', 'minuter'],
	hour   => ['timme', 'timmar'],
	day    => ['dag','dagar'],
	year   => ['år','år'],

); 


sub _render {
  # Make it into English
	use Data::Dumper;

  my $direction = shift @_;
  my @wheel = map
  {
      (  $_->[1] == 0) ? ()  # zero wheels
	  : $_->[1] . ' ' . $env2sv{ $_->[0] }[ $_->[1] == 1 ? 0 : 1 ]
      }
  @_;

  return "just now" unless @wheel; # sanity
  my $result;
  if(@wheel == 1) {
      $result = $wheel[0];
  } elsif(@wheel == 2) {
      $result = "$wheel[0] och $wheel[1]";
  } else {
      $wheel[-1] = "och $wheel[-1]";
      $result = join q{, }, @wheel;
  }
  return sprintf($direction, $result);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1;

__END__

=head1 NAME

Time::Duration::sv - rounded or exact Swedish expression of durations

=head1 SYNOPSIS

Example use in a program that ends by noting its runtime:

  my $start_time = time();
  use Time::Duration::sv;
  
  # then things that take all that time, and then ends:
  print "Runtime ", duration(time() - $start_time), ".\n";

Example use in a program that reports age of a file:

  use Time::Duration::sv;
  my $file = 'that_file';
  my $age = $^T - (stat($file))[9];  # 9 = modtime
  print "$file was modified ", ago($age);

=head1 DESCRIPTION

This module provides functions for expressing durations in rounded or exact
terms.


=head1 SEE ALSO

L<Time::Duration|Time::Duration>, the English original, for a complete
manual.

=head1 COPYRIGHT AND DISCLAIMER

Copyright 2002, Arthur Bergman C<abergman@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

Large parts of the code is Copyright 2002 Sean M. Burke. 

=head1 AUTHOR

Arthur Bergman, C<abergman@cpan.org>

=cut


