# Linux

@options = qw(-DHAS_UT_EXTENSIONS -DHAS_UT_HOST -DHAS_UT_ADDR
	      -DHAS_GETUTID -DHAS_GETUTLINE -DHAS_PUTUTLINE
	      -DHAS_UTMPNAME
	      -DHAS_X_UT_EXIT -DHAS_X_UT_HOST -DHAS_X_UT_ADDR
	      -DHAS_UTMPXNAME
	     );

$self->{CCFLAGS} = join ' ', $Config{ccflags}, @options;

# GCC with optimization corrupts perl2utent() on Linux ("called object
# is not a function").  The problem seems to be with str* functions;
# the mem* functions seem to work in the same place.  Since this
# problem has only be reported on Linux it doesn't seem to be my
# fault.  Disable optimization until the problem is fixed.
$self->{OPTIMIZE} = ' ';
