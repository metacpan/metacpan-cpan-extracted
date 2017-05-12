use ExtUtils::MakeMaker;

chomp(my $pyinc = `python ./pyinc.py`);

print "Picking up pyton include files from \"$pyinc\"\n";

my @define;
my @libs;

push(@define, "MULTI_PERL") if -f "../MULTI_PERL";

if (-f "../BOOT_FROM_PERL") {
    push(@define, "BOOT_FROM_PERL");

    # XXX need to find the location of python.a, and this
    # is obviously not the right way...
    my $pylib = $pyinc;
    $pylib =~ s/include/lib/;
    $pylib =~ m,/(python[^/]+)$, || die;
    $pylib .= "/config";
    push(@libs, "-L$pylib -l$1");

    push(@extra, OBJECT => "Object.o /local/python/1.5.2-thr/lib/python1.5/site-packages/perl.so");
}

if ($^O eq 'MSWin32') {
    my $pylib;
    for (15,16,20) {
	$pylib = "$pyinc\\..\\libs\\python$_.lib";
	last if -f $pylib;
    }
    push(@libs, "\"$pylib\"", "..\\perlpyd.lib");
    push(@extra,
	 FUNCLIST => [qw(boot_Python__Object newPerlPyObject_noinc newPerlPyObject_inc)],
	 );
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
    INC          => "-I\"$pyinc\"",
    @extra,
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
