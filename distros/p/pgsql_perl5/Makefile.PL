
# $Id: Makefile.PL,v 1.15 2000/04/04 19:08:46 mergl Exp $

use ExtUtils::MakeMaker;
use Config;
use strict;

print "Configuring Pg\n";
print "Remember to actually read the README file !\n";

my $POSTGRES_INCLUDE;
my $POSTGRES_LIB;

if ((!$ENV{POSTGRES_INCLUDE} or !$ENV{POSTGRES_LIB}) and !$ENV{POSTGRES_HOME}) {
    die "please set environment variables POSTGRES_INCLUDE and POSTGRES_LIB !\n";
} elsif ((!$ENV{POSTGRES_INCLUDE} or !$ENV{POSTGRES_LIB}) and $ENV{POSTGRES_HOME}) {
    $POSTGRES_INCLUDE = "$ENV{POSTGRES_HOME}/include";
    $POSTGRES_LIB     = "$ENV{POSTGRES_HOME}/lib";
} else {
    $POSTGRES_INCLUDE = "$ENV{POSTGRES_INCLUDE}";
    $POSTGRES_LIB     = "$ENV{POSTGRES_LIB}";
}

my %opts = (
    NAME         => 'Pg',
    VERSION_FROM => 'Pg.pm',
    INC          => "-I$POSTGRES_INCLUDE",
    OBJECT       => "Pg\$(OBJ_EXT)",
    LIBS         => ["-L$POSTGRES_LIB -lpq"],
);

my $os = $^O;
print "OS: $os\n";
my $osvers = $Config{osvers};
if ($os eq 'hpux') {
    if ($osvers < 10) {
        print "Warning: Forced to build static not dynamic on $os $osvers.\a\n";
        $opts{LINKTYPE} = 'static';
    }
}

if ($Config{dlsrc} =~ /dl_none/) {
    $opts{LINKTYPE} = 'static';
}


WriteMakefile(%opts);

exit(0);

# end of Makefile.PL
