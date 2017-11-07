package Win32::Packer;

use strict;
use warnings;

require Path::Tiny;

seek DATA, 0, 0;
my $line_n;
while (<DATA>) {
    if (/^__DATA__$/) {
        $line_n = $.;
        last
    }
}

my $file = Path::Tiny::path($INC{'Win32/Packer/WrapperCCode.pm'})->realpath->stringify;
$file =~ s/(["\\])/\\$1/g;

our $wrapper_c_code = do {
    local $/;
    qq(#line $line_n "$file"\n) . <DATA>
};

1;

__DATA__

#include <EXTERN.h>
#include <perl.h>

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
static void xs_init(pTHX) {
    char *file = __FILE__;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

static void
fatal_error(char *msg) {
    fprintf(stderr, "%s: %s", msg, GetLastError());
    exit(1);
}

int main(int argc, char **argv, char **env) {

    PerlInterpreter *my_perl;
    const char loader_name[] = "load.pl";

    char module_path[MAX_PATH + 1];
    char long_module_path[MAX_PATH + 1];
    char prog_path[MAX_PATH + 1];
    char short_path[MAX_PATH + 1];
    char loader_path[MAX_PATH + 1];
    char *filepart;

    DWORD size = GetModuleFileNameA(NULL, module_path, MAX_PATH);
    if (size <= 0) fatal_error("Unable to retrieve program name");

    size = GetFullPathNameA(module_path, MAX_PATH, long_module_path, &filepart);
    if (size <= 0) fatal_error("Unable to retrieve full program path");
    fprintf(stderr, "long_module_path: %s\n", long_module_path);

    size = filepart - long_module_path;
    memcpy(prog_path, long_module_path, size);
    prog_path[size] = '\0';
    fprintf(stderr, "prog_path: %s\n", prog_path);

    size = GetShortPathNameA(prog_path, short_path, MAX_PATH);
    if (size <= 0) fatal_error("Unable to retrieve short program path");
    fprintf(stderr, "short_path: %s\n", short_path);

    if (size + sizeof(loader_name) + 1 > MAX_PATH) {
        SetLastError(ERROR_BUFFER_OVERFLOW);
        fatal_error("Unable to retrieve loader name");
    }

    strcpy(loader_path, short_path);
    strcat(loader_path, loader_name);
    fprintf(stderr, "loader_path: %s\n", loader_path);

    char **pargv = calloc(argc + 2, sizeof(char*));
    if (!pargv) fatal_error("Unable to allocate memory");

    pargv[0] = argv[0];
    pargv[1] = loader_path;

    int i;
    for (i = 1; i < argc; i++) pargv[i + 1] = argv[i];

    int pargc = argc + 1;

    for (i = 0; i < pargc; i++) {
        fprintf(stderr, "arg[%d]: %s\n", i, pargv[i]);
    }

    fprintf(stderr, "Launching perl!\n"); fflush(stderr);

    PERL_SYS_INIT3(&pargc, &pargv, &env);
    my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;

    fprintf(stderr, "Parsing loader!\n"); fflush(stderr);
    int rc = perl_parse(my_perl, xs_init, pargc, pargv, NULL);

    fprintf(stderr, "rc: %d\n", rc);

    fprintf(stderr, "Running loader!\n"); fflush(stderr);
    rc = perl_run(my_perl);
    fprintf(stderr, "rc: %d\n", rc);

    fprintf(stderr, "Destroying!\n"); fflush(stderr);
    perl_destruct(my_perl);
    perl_free(my_perl);
}
