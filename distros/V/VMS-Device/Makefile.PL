use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'VMS::Device',
    'ABSTRACT_FROM' => 'Device.pm',
    'VERSION_FROM' => 'Device.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);

package MY;
sub c_o {
  my $self = shift;
  local($_) = $self->SUPER::c_o(@_);
  s/^(\s\$\(CCC.*\.c)/$1 \+ SYS\$LIBRARY\:SYS\$LIB\_C\/LIBRARY/m;
  $_;
}
sub xs_o {
  my $self = shift;
  local($_) = $self->SUPER::xs_o(@_);
  s/^(\s\$\(CCC.*\.c)/$1 \+ SYS\$LIBRARY\:SYS\$LIB\_C\/LIBRARY/m;
  $_;
}
