require 'Win32/ProcFarm/Child.pl';

&init;
while(1) {
  &main_loop;
}

sub dir {
  my($string) = @_;

  sleep(5);
  return `dir $string`;
}
