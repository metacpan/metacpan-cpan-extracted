require 5.005002;
use strict;
eval { require warnings; };
use ExtUtils::MakeMaker;
use Config;

my @hdr = qw(ansidecl.h config.h cppdefault.h cpphash.h cpplib.h
	global.h hashtable.h hwint.h intl.h libiberty.h line-map.h
	mbchar.h mkdeps.h obstack.h safe-ctype.h splay-tree.h
	symcat.h system.h);
my @base = qw(CPP concat cppdefault cpperror cppexp cppfiles cpphash
	cppinit cpplex cpplib cppmacro cppmain cpptrad hashtable hex
	interface lbasename line-map mbchar mkdeps obstack safe-ctype
	splay-tree);
my @src = map { "$_.c"} @base;
my @obj = map { "$_.o"} @base;

# We require this or the Makefile won't reference it.
do "typemap.PL" or die "Failed to generate typemap: $!";

my $cflags = q[-DHAVE_CONFIG_H];
$cflags .= q[ -Wall -g -O0] if -d 'old';	# Maintainer/gcc stuff

WriteMakefile(
	NAME			=> 'Text::CPP',
	VERSION_FROM	=> 'CPP.pm',
    ABSTRACT_FROM	=> "CPP.pm",
	AUTHOR			=> 'Shevek <cpan@anarres.org>',
	PREREQ_PM		=> { },
	INC				=> "-I.",
	TYPEMAPS		=> [ qw(typemap) ],
	OBJECT			=> "@obj",
	C				=> \@src,
	H				=> \@hdr,
	OPTIMIZE		=> $cflags,
	clean			=> { FILES => "config.h typemap" },
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux dep readme

CPP.c : typemap

aux : readme dep

readme : CPP.pm
	perldoc -t CPP.pm > README

dep : $(C_FILES) $(H_FILES)
	$(RM_F) .depend
	$(CC) -MM $(INC) -isystem $(PERL_INC) $(CCFLAGS) $(C_FILES) >> .depend

EON
	return $old . $new;
}
