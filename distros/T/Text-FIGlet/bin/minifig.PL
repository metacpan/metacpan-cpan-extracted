use strict;
$^W = 1;
require 5;

sub croak{
  warn($_[0]);
  exit 0;
}

open(MINI, $_ = '>bin/minifig.pl') || croak("Unable to create $_");
select(MINI);
print "#!$^X -w\n";

open(PM, $_ = 'lib/Text/FIGlet.pm') || croak("Could not open $_: $!");
while( <PM> ){
  last if /__END__/;
  next if /use\s+Text::FIGlet/;
  print;
}

open(PM, $_ = 'lib/Text/FIGlet/Control.pm') || croak("Could not open $_: $!");
while( <PM> ){
  last if /__END__/;
  print;
}

my $mini = <<'EOF';
  } else {
    my $fh = $self->{_fh} = *main::DATA;
    while ( <$fh> ) {
      last if /__END__/;
    }
  }
EOF
open(PM, $_ = 'lib/Text/FIGlet/Font.pm') || croak("Could not open $_: $!");
while( <PM> ){
  last if /__END__/;
  s/\|\|\s+q*.standard.//;
  s/#MAGIC minifig0/  if ( \$self->{-f} ) {/;
  s/#MAGIC minifig1/$mini/;
  print;
}

open(PM, $_ = 'bin/figlet.pl') || croak("Could not open $_: $!");
while( <PM> ){
  next if /use\s+Text::FIGlet/;
  if( /__END__/ .. 1 ){
    s/__END__/__DATA__/;
    s/figlet(?=\.pl)|standard(?=\.flf)/minifig/ig;
  }
  print;
}

print "__END__\n";
open(PM, $_ = 'share/mini.flf') || croak("Could not open $_: $!");
while( <PM> ){
  print;
}

