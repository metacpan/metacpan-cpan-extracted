use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Time::Timecode',
    AUTHOR	    => 'Skye Shaw <skye.shaw AT gmail.com>',
    LICENSE         => 'perl',
    VERSION_FROM    => 'lib/Time/Timecode.pm',
    ABSTRACT_FROM   => 'lib/Time/Timecode.pm',
    EXE_FILES => ['bin/timecode'],
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
     (META_MERGE  => {
	 resources => {
	     homepage => 'http://github.com/sshaw',
	     bugtracker => 'http://github.com/sshaw/Time-Timecode/issues',
	 }
      }) : ())
);


# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
sub MY::postamble
{
  my $self = shift;
  return if -r 'README' or ! -r $self->{VERSION_FROM};
  return<<END_MAKE;
README.pod: $self->{VERSION_FROM}
	\@perldoc -uT $self->{VERSION_FROM} > README.pod
END_MAKE
}

# Include test helpers and/or libs
sub MY::test
{
  package MY;
  my $make = shift->SUPER::test(@_);
  $make .= 'FULLPERLRUN = $(FULLPERL) -I t -I t/lib';
  return $make;
}
