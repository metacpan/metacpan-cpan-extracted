use ExtUtils::MakeMaker;

@theselibs = grep {-f } glob("lib/Text/Unicode/*.*");

if ($^O eq 'MSWin32')
{
    @extras = (dist => { 
    	'TO_UNIX' => 'perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"',
    	'TARFLAGS' => '-cv --mode=774 -f'		# GNU tar: remove world-writable permissions.
    	 });
}
WriteMakefile (
        NAME => "Text::Unicode::Equivalents",
        VERSION_FROM => "lib/Text/Unicode/Equivalents.pm",
#        HTMLLIBPODS => {map {my $t = $_; $t=~s/\..*?$/.html/o; $t='blib/Html/'.$t; $_ => $t;} @theselibs},
#        HTMLSCRIPTPODS => {map {my $t=$_; $t=~s/\..*?$/.html/o; $t='blib/Html/'.$t; $_ => $t;} @scripts},
        AUTHOR => "BHALLISSY\@cpan.org",
        ABSTRACT => "Build Unicode canonically equivalent strings",
        dist => { 'TO_UNIX' => 'perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"' },
	@extras
    );
