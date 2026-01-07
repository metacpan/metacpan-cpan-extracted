use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::Manifest;

my $VERSION = '1.0.1';

WriteMakefile(
    ABSTRACT          => 'Parse XDR (eXternal Data Representation) definitions into an AST (Abstract Syntax Tree)',
    AUTHOR            => 'Erik Huelsmann',
    LICENSE           => 'perl_5',
    EXE_FILES         => [
         'bin/xdr-parse'
    ],
    META_MERGE        => {
        "meta-spec"      => { version => 2 },
        resources        => {
            repository      => {
                type           => 'git',
                url            => 'git://github.com/ehuelsmann/XDR-Parse.git',
                web            => 'https://github.com/ehuelsmann/XDR-Parse',
            },
        },
    },
    NAME              => 'XDR::Parse',
    VERSION           => $VERSION,
    depend            => { pm_to_blib => 'pm' },
);

package MY;

sub postamble {
    return <<'MAKE_FRAG';
pm: lib/XDR/Parse.pm
	$(NOECHO) $(NOOP)

lib/XDR/Parse.pm: xdr.yp Makefile.PL
	yapp -o Parse.out -m XDR::Parse xdr.yp
	./pmfilter $(VERSION) < Parse.out > $@
	@rm Parse.out

MAKE_FRAG
}
