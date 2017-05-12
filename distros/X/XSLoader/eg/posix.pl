# This example shows how to load the POSIX object module.
# As no version is specified in the XSLoader::load() and in the bootstrap()
# calls, this example will work with any version. Also note that we use 
# __PACKAGE__ instead of hard-coding the name of the package;

package POSIX;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__);
    1
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap(__PACKAGE__);
};
