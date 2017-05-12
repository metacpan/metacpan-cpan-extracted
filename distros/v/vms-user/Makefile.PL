use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'VMS::User',
    'VERSION_FROM'	=> 'User.pm', # finds $VERSION
);

package MY;
sub c_o {
  my $self = shift;
  local($_) = $self->SUPER::c_o(@_);
  s/\.c$/\.c \+ SYS\$LIBRARY\:SYS\$LIB\_C\/LIBRARY/m; # Add our library to the end
  $_;
}
sub xs_o {
  my $self = shift;
  local($_) = $self->SUPER::xs_o(@_);
  s/^(\s\$\(CCC.*\.c)$/$1 \+ SYS\$LIBRARY\:SYS\$LIB\_C\/LIBRARY/m;
  $_;
}
