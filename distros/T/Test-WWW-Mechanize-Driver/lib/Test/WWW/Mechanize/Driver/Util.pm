package Test::WWW::Mechanize::Driver::Util;
use strict; use warnings;
our $VERSION = 0.2;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS;
our @EXPORT_OK = qw/ cat TRUE HAS build_uri /;
$EXPORT_TAGS{all} = \@EXPORT_OK;

use URI ();
use URI::QueryParam ();
use Scalar::Util qw/ reftype /;

=pod

=head1 NAME

Test::WWW::Mechanize::Driver::Util - Useful utilities

=head1 USAGE

=cut

=head3 build_uri

 build_uri( $uri, \%params )

Append parameters to a uri. Parameters whose values are array refs will
expand to include all values.

Example:

 my %params = ( foo => "What's up, doc?",
                b => [ 1, 2, 3 ]
              );
 my $uri = build_uri( "http://example.com/index.pl?foo=bar", \%params );
 # $uri eq "http://example.com/index.pl?foo=bar&foo=What's+up%2C+Doc%3F$b=1&b=2&b=3

=cut

sub build_uri {
  my ($u, $p) = @_;
  return $u unless $p;
  my $uri = URI->new($u);

  while (my ($k, $v) = each %$p) {
    $uri->query_param_append($k, (reftype($v) and 'ARRAY' eq reftype($v)) ? @$v : $v);
  }

  return $uri->as_string
}

#-----------------------------------------------------------------
# BEGIN             Dean::Util code version 1.046
#
#  use Dean::Util qw/ INCLUDE_POD cat TRUE HAS /;


=head3 cat

 my $stuff = cat $file;
 my $stuff = cat \$mode, $file;

Read in the entirety of a file. If requested in list context, the lines are
returned. In scalar context, the file is returned as one large string. If a
string reference C<$mode> is provided as a first argument it will be taken
as the file mode (the default is "E<lt>").

=cut

#BEGIN: cat
sub cat {
  my $mode = (ref($_[0]) eq 'SCALAR') ? ${shift()} : "<";
  my $f = (@_) ? $_[0] : $_;
  open my $F, $mode, $f or die "Can't open $f for reading: $!";
  if (wantarray) {
    my @x = <$F>; close $F; return @x;
  } else {
    local $/ = undef; my $x = <$F>; close $F; return $x;
  }
}
#END: cat


=head3 TRUE

 TRUE $hash_ref, qw| key1 arbitrarily/deep/key |;
 TRUE $hash_ref, @paths, { sep => $separator, false_pat => $pattern };

Safely test for deep key truth. Recursion happens by splitting on
C<$separator> ("/" by default, set C<$separator> to C<undef> to disable
this behavior), there is no means for escaping. Returns true only if all
keys exist and are true. Values matched by C<$pattern> (C<^(?i:false)$> by
default) as well as an empty list or empty hash will all cause 0 to be
returned. Array refs are allowed if corresponding path components are
numeric.

=cut

#BEGIN: TRUE
sub TRUE {
  my $x = shift;
  return 0 unless ref($x);
  my $o = {};
  $o = pop if @_ and 'HASH' eq ref($_[-1]);
  $$o{sep} = '/' unless exists $$o{sep};
  $$o{false_pat} = '^(?i:false)$' unless exists $$o{false_pat} and defined $$o{false_pat};
  for (@_) {
    my @x = ('ARRAY' eq ref) ? @$_ : defined($$o{sep}) ? split($$o{sep}, $_) : ($_);
    if (ref($x) eq 'ARRAY') {
      ($#{$x} >= $x[0] and $$x[$x[0]]) or return 0;
      return 0 if !ref($$x[$x[0]]) and $$x[$x[0]] =~ /$$o{false_pat}/;
      @{$$x[$x[0]]} or return 0 if ref($$x[$x[0]]) eq 'ARRAY';
      %{$$x[$x[0]]} or return 0 if ref($$x[$x[0]]) eq 'HASH';
      TRUE($$x[$x[0]], [@x[1..$#x]], $o) or return 0 if @x > 1;
    } else {
      (exists $$x{$x[0]} and $$x{$x[0]}) or return 0;
      return 0 if !ref($$x{$x[0]}) and $$x{$x[0]} =~ /$$o{false_pat}/;
      @{$$x{$x[0]}} or return 0 if ref($$x{$x[0]}) eq 'ARRAY';
      %{$$x{$x[0]}} or return 0 if ref($$x{$x[0]}) eq 'HASH';
      TRUE($$x{$x[0]}, [@x[1..$#x]], $o) or return 0 if @x > 1;
    }
  }
  return 1;
}
#END: TRUE


=head3 HAS

 HAS $hash_ref, qw| key1 arbitrarily/deep/key |;
 HAS $hash_ref, @paths, { sep => $separator };

Safely test for deep key definedness. Recursion happens by splitting on
C<$separator> ("/" by default), there is no means for escaping. Returns
true only if all keys exist and are defined. Array refs are allowed if
corresponding path components are numeric.

=cut

#BEGIN: HAS
sub HAS {
  my $x = shift;
  return 0 unless ref($x);
  my $o = {};
  $o = pop if @_ and 'HASH' eq ref($_[-1]);
  $$o{sep} = '/' unless exists $$o{sep};
  for (@_) {
    my @x = ('ARRAY' eq ref) ? @$_ : defined($$o{sep}) ? split($$o{sep}, $_) : ($_);
    if (ref($x) eq 'ARRAY') {
      ($#{$x} >= $x[0] and defined $$x[$x[0]]) or return 0;
      HAS($$x[$x[0]], [@x[1..$#x]], $o) or return 0 if @x > 1;
    } else {
      (exists $$x{$x[0]} and defined $$x{$x[0]}) or return 0;
      HAS($$x{$x[0]}, [@x[1..$#x]], $o) or return 0 if @x > 1;
    }
  }
  return 1;
}
#END: HAS

#
# END               Dean::Util code version 1.046
#-----------------------------------------------------------------

1;

=head1 AUTHOR

 Dean Serenevy
 dean@serenevy.net
 https://serenevy.net/

=head1 COPYRIGHT

This software is hereby placed into the public domain. If you use this
code, a simple comment in your code giving credit and an email letting me
know that you find it useful would be courteous but is not required.

The software is provided "as is" without warranty of any kind, either
expressed or implied including, but not limited to, the implied warranties
of merchantability and fitness for a particular purpose. In no event shall
the authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising
from, out of or in connection with the software or the use or other
dealings in the software.

=head1 SEE ALSO

perl(1).

=cut
