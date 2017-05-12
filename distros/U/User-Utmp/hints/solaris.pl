# Solaris

@options = qw(-D__EXTENSIONS__
	      -DHAS_UT_EXTENSIONS
	      -DHAS_GETUTID -DHAS_GETUTLINE -DHAS_PUTUTLINE
	      -DHAS_UTMPNAME
	      -DHAS_X_UT_EXIT -DHAS_X_UT_HOST -DHAS_X_UT_SYSLEN
	      -DHAS_UTMPXNAME
	     );

$self->{CCFLAGS} = join ' ', $Config{ccflags}, @options;
