# Figure out where the Python/Object.so file hides

exit if $^O eq 'MSWin32';

require DynaLoader;
@Python::Object::ISA = qw(DynaLoader);

eval {
   Python::Object->bootstrap(999999);
};


if ($@ && $@ =~ /^Can't load '([^']+)'/) {
    print "$1\n";
    exit;
}

die $@;
