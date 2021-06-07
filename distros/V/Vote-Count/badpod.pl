use 5.032;
use Path::Tiny;

my $badpod = path('bad.pod')->slurp;

$badpod =~ s/\n\n\n+/\n\n/g;

say $badpod;