use 5.012;
use strict;
use warnings;

my %exports;
my @export_ok;
my %enums;
my $curenum = '';

while (<>) {
  chomp;
  s!^\s+!!g;
  s!,\s*$!!g;
  if ( m!^\#(.*)! ) {
    $curenum = $_;
    $curenum =~ s!\#!!;
    next;
  }
  my @enums = split ' ';
  $enums[1] = '=>';
  push @{ $enums{ $curenum } }, \@enums;
  push @export_ok, $enums[0];
  push @{ $exports{ $curenum } }, $enums[0];
}

foreach my $type ( sort keys %enums ) {
  say "#$type";
  foreach my $enum ( @{ $enums{ $type } } ) {
    say "use constant " . join( ' ', @{ $enum } ) . ';';
  }
}

say '';

use Data::Dumper;
local $Data::Dumper::Indent=1;
say Dumper( \@export_ok );
say Dumper( \%exports );

say "  $_" for @export_ok;
