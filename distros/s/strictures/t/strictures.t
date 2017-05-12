BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }

sub _eval { eval $_[0] }

use strict;
use warnings;
use Test::More qw(no_plan);

sub capture_hints {
  my $code = shift;
  $code .= q{
    ;
    my @h;
    BEGIN { @h = ( $^H, ${^WARNING_BITS} ) }
    @h;
  };
  my ($hints, $warning_bits) = _eval $code or die $@;
  # ignore lexicalized hints
  $hints &= ~ 0x20000;
  $warning_bits = unpack "H*", $warning_bits
    if defined $warning_bits;
  return ($hints, $warning_bits);
}

sub compare_hints {
  my ($code_want, $code_got, $name) = @_;
  my ($want_hints, $want_warnings) = capture_hints $code_want;
  my ($hints, $warnings) = capture_hints $code_got;
  is($hints,    $want_hints, "Hints correct for $name");
  is($warnings, $want_warnings,  "Warnings correct for $name");
}

compare_hints q{
  use strict;
  use warnings FATAL => 'all';
},
q{
  use strictures 1;
},
  'version 1';

compare_hints q{
  use strict;
  use warnings 'all';
  use warnings FATAL => @strictures::WARNING_CATEGORIES;
  no warnings FATAL => @strictures::V2_NONFATAL;
  use warnings @strictures::V2_NONFATAL;
  no warnings @strictures::V2_DISABLE;
},
q{
  use strictures 2;
},
  'version 2';

my $v;
eval { $v = strictures->VERSION; 1 } or diag $@;
is $v, $strictures::VERSION, '->VERSION returns version correctly';

my $next = int $strictures::VERSION + 1;
eval qq{ use strictures $next; };

like $@, qr/strictures version $next required/,
  "Can't use strictures $next (this is version $v)";

eval qq{ use strictures {version => $next}; };

like $@, qr/Major version specified as $next - not supported/,
  "Can't use strictures version option $next (this is version $v)";

eval qq{ use strictures {version => undef}; };

like $@, qr/Major version specified as undef - not supported/,
  "Can't use strictures version option undef";

eval qq{ use strictures $strictures::VERSION; };

is $@, '',
  "Can use current strictures version";
