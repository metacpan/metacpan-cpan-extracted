use strict;
use warnings;
use Test::More;
use DynaLoader ();
use FindBin;
use File::Spec;

require Tk::Zinc;

my ($index) = grep { $DynaLoader::dl_modules[$_] eq 'Tk::Zinc' }
    0 .. $#DynaLoader::dl_modules;
BAIL_OUT('Cannot find the loaded Tk::Zinc library') unless defined $index;
my $library = $DynaLoader::dl_librefs[$index];

ok(DynaLoader::dl_find_symbol($library, 'boot_Tk__Zinc'),
   'Perl bootstrap symbol is exported');

# Check the public functions and variables from every bundled GLEW header,
# including the platform-specific namespaces. They must stay module-local.
my %symbols;
for my $header (qw(glew.h wglew.h glxew.h eglew.h)) {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'third_party',
                                   'glew', 'include', 'GL', $header);
    open(my $fh, '<', $path) or BAIL_OUT("Cannot read $path: $!");
    while (<$fh>) {
        if (/^(?:GLEWAPI|\w+_(?:FUN|VAR)_EXPORT)\s+.*?\b((?:__)?(?:glew|wglew|glxew|eglew)\w+)\s*[;(]/i) {
            $symbols{$1} = 1;
        }
    }
    close($fh) or BAIL_OUT("Cannot close $path: $!");
}
ok(scalar(keys %symbols) > 1000, 'Read bundled GLEW symbol declarations');
my @leaked = grep { DynaLoader::dl_find_symbol($library, $_) }
    sort keys %symbols;
is_deeply(\@leaked, [], 'Bundled GLEW symbols are not dynamically exported');

done_testing();
