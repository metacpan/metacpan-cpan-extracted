# NetBSD
@options = qw(-DHAS_UT_HOST -DHAS_UTMPNAME
	      -DHAS_UTMPX -DHAS_X_UT_EXIT -DHAS_X_UT_HOST -DHAS_UTMPXNAME);

$self->{CCFLAGS} = join ' ', $Config{ccflags}, @options;
