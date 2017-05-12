use ExtUtils::MakeMaker;

sub ecl_config {
    my $args = shift;

    open(ECLCONFIG, "ecl-config $args|")
	or do {
	    warn "can't run \"ecl-config $args|\" - $!\n";
	    exit 0;
	};
    my $res = join '', <ECLCONFIG>;
    $res =~ s/[\r\n]+$//;
    do {
        warn "can't get output from ecl-config";
	exit 0;
    } if $res eq '';
    return $res;
}

my $ecl_cflags = ecl_config("--cflags");
my $ecl_ldflags = ecl_config("--libs");                             
if ($^O eq 'MSWin32' and $ecl_ldflags=~/\/LIBPATH:(\S+)/i){$ecl_ldflags="-L$1 ecl.lib"}

sub DynaLoader::mod2fname {$_[0]->[-1].'1'} # we have 'ecl1.dll' to avoid confusion (or to bring one)


WriteMakefile(
    NAME          => 'ecl',
    VERSION_FROM  => 'lib/ecl.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/ecl.pm', # retrieve abstract from module
    AUTHOR        => 'Vadim Konovalov <vkon@cpan.org>',
    LIBS          => ["$ecl_ldflags"],
    # DEFINE        => '-DECL_UNICODE',
    INC           => "$ecl_cflags", # e.g., '-I. -I/usr/include/other'
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
