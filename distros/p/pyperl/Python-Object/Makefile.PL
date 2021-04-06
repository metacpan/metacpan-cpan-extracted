use ExtUtils::MakeMaker;

my $python = $ENV{PYTHON} || 'python';
chomp(my $pyinc = `$python -c 'from distutils.sysconfig import get_config_var; print("-I" + get_config_var("INCLUDEPY"))'`);
chomp(my $pylib = `$python -c 'from distutils.sysconfig import get_config_var; print(get_config_var("BLDLIBRARY"))'`);
chomp(my $pysitelib = `$python -c 'from distutils.sysconfig import get_python_lib; print(get_python_lib(1))'`);


my @define;
my @libs;

push(@define, "MULTI_PERL") if -f "../MULTI_PERL";

push(@libs, $pylib);

if (-f "../BOOT_FROM_PERL") {
    push(@define, "BOOT_FROM_PERL");
    push(@extra, OBJECT => "Object.o $pysitelib/perl.so");
}

if ($^O eq 'MSWin32') {
    my $pylib;
    for (15,16,20) {
	$pylib = "$pyinc\\..\\libs\\python$_.lib";
	last if -f $pylib;
    }
    push(@libs, "\"$pylib\"", "..\\perlpyd.lib");
}

if (@define) {
    push(@extra, DEFINE => join(" ", map "-D$_", @define));
}
if (@libs) {
    if ($^O eq 'MSWin32') {
	push(@extra, LIBS => join(" ", @libs));
    } else {
	push(@extra, LIBS => \@libs);
    }
}

WriteMakefile(
    NAME	 => 'Python::Object',
    VERSION_FROM => 'Object.pm',
    INC          => $pyinc,
    @extra,
    dist         => { COMPRESS => 'xz -9f', SUFFIX => 'xz', },
);
