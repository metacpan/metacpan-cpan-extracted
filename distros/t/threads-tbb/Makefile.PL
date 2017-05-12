use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use FindBin qw($Bin);
use File::Find;

if (not $Config{useithreads} or $Config{use5005threads} ) {
	print STDERR "Can't use threads::lite without threading support";
	exit 0;
}

my $CC = 'g++';

my (@clean, @OBJECT, @LD_FROM, %XS, %PM);
{
    my @xs;
    my @pm;
    find(sub {
	     !m{^\.} && m{\.xs$} && push @xs, $File::Find::name;
	     !m{^\.} && m{\.p(m|od)$} && push @pm, $File::Find::name;
	 }, "lib");
    for my $xs (@xs) {
        (my $c = $xs) =~ s/\.xs$/.c/i;
        (my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;
	#$o =~ s{.*/}{};

        $XS{$xs} = $c;
        push @OBJECT, $o;
	#$o =~ s{.*/}{};
	push @LD_FROM, $o;
        push @clean, $o;
    }

    for my $c (<src/*.cc>) {
        (my $o = $c) =~ s/\.cc$/\$(OBJ_EXT)/i;
        push @OBJECT, $o;
	#$o =~ s{.*/}{};
	push @LD_FROM, $o;
        push @clean, $o;
    }
    for my $pm ( @pm ) {
	my $inst = $pm;
	$inst =~ s{^lib/threads}{\$(INST_LIBDIR)};
	$PM{$pm} = $inst;
    }
}
WriteMakefile(
    NAME              => 'threads::tbb',
    VERSION_FROM      => 'lib/threads/tbb.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.01',
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/threads/tbb.pod',
    AUTHOR         => 'Sam Vilain <sam.vilain@openparallel.com>',
    LIBS              => ['-ltbb'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-Isrc', # e.g., '-I. -I/usr/include/other'
    XSOPT             => '-C++ -hiertype',
    TYPEMAPS          => ["$Bin/src/typemap.xsc"],
    CC                => $CC,
    LD                => '$(CC)',
    CCFLAGS           => '-o $@',
    LDFROM => join (q{ }, @LD_FROM),
        clean  => { FILES => join(q{ }, @clean) },
        OBJECT => join (q{ }, @OBJECT),
        XS     => \%XS,
    PM => \%PM,
    depend => { '$(OBJECT)' => join(" ", glob "src/*.h") },
);

