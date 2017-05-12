# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use 5.008001;

use strict;
use warnings;

use Test::More tests => 15;

BEGIN {
  use_ok('XML::Encoding');
}

my @prefixes = ();
my $pops = 0;
my @rnginfo = ();

sub pushpfx {
  my ($byte) = @_;

  push(@prefixes, $byte);
  undef;
}

sub poppfx {
  $pops++;
  undef;
}

sub range {
  my ($byte, $uni, $len) = @_;

  push(@rnginfo, @_);
  undef;
}

my $doc =<<'End_of_doc;';
<encmap name="foo" expat="yes">
  <range byte='xa0' uni='x3000' len='6'/>
  <prefix byte='x81'>
    <ch byte='x41' uni='x0753'/>
    <range byte='x50' uni='x0400' len='32'/>
  </prefix>
</encmap>
End_of_doc;

my @exprng = (0xa0, 0x3000, 6, 0x41, 0x0753, 1, 0x50, 0x0400, 32);

my $p = new XML::Encoding(PushPrefixFcn => \&pushpfx,
			  PopPrefixFcn  => \&poppfx,
			  RangeSetFcn   => \&range);

my $name = $p->parse($doc);

is($name, 'foo');
is($prefixes[0], 0x81);
is($pops, scalar @prefixes);
cmp_ok(scalar @rnginfo, '<=', @exprng);

foreach (0 .. $#exprng) {
  is($rnginfo[$_], $exprng[$_]);
}

$doc =~ s/='32'/='200'/;

# Don't use an eval {} here to trap the parse() error
# because it causes a crash under perl-5.6.x
{
local $SIG{__DIE__} = sub {
  my $err = $_[0];
  ok($err and $err =~ /^Len plus byte > 256/);
  exit;
};
$p->parse($doc);
}

ok(0);
