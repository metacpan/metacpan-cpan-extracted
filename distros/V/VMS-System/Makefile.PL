use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'VMS::System',
    'AUTHOR'    => 'Dan Sugalski <dan@sidhe.org>, Craig A. Berry <craigberry@mac.com>',
    'VERSION_FROM' => 'System.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'System.pm',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other'
);

package MY;
sub c_o {
  my $self = shift;
  local($_) = $self->SUPER::c_o(@_);
  s/\.c$/\.c \+ SYS\$LIBRARY\:SYS\$LIB\_C\/LIBRARY/m; # Add our library to the end
  $_;
}
