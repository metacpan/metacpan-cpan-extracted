
  use LibZip::Scan ;

BEGIN {  
  @lib = qw(
  lib::http
  );
  
  my %use ;
  foreach my $lib_i ( @lib ) {
    next if $use{$lib_i} || $lib_i !~ /^[\w:]+$/ ;
    eval("use $lib_i ();\n");
    print "$@\n" if $@ ;
    $use{$lib_i} = 1 ;
  }

}  

  

