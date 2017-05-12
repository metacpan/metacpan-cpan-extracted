# AIX

@options = qw(-DHAS_UT_EXTENSIONS -DHAS_UT_HOST -DHAS_UT_ADDR
	      -DHAS_GETUTID -DHAS_GETUTLINE -DHAS_PUTUTLINE
	      -DHAS_UTMPNAME
	      -DHAS_X_UT_EXIT -DHAS_X_UT_HOST -DHAS_X_UT_ADDR
	      -DHAS_UTMPXNAME
	     );

$self->{CCFLAGS} = join ' ', $Config{ccflags}, @options;
