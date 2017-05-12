# $Id: Makefile.PL,v 1.20 2003/08/25 12:16:34 pajas Exp $

use strict;

use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'      => 'XML::XSH',
    'VERSION_FROM' => 'lib/XML/XSH/Functions.pm',
    'EXE_FILES' => ['xsh'],
    'PREREQ_PM' => {
		    'XML::LibXML' => 1.54,
		    'XML::LibXSLT' => 1.53,
		    'XML::LibXML::Iterator' => 0,
		    'Parse::RecDescent' => 1.94,
		    'XML::XUpdate::LibXML' => "0.4.0",
		    'XML::LibXML::XPathContext' => 0.04,
		   },
     AUTHOR       => 'Petr Pajas (pajas@matfyz.cz)',
     ABSTRACT     => 'XML Editing Shell',
     MAN3PODS     => { 'XSH.pod' => 'blib/man3/XSH.3' },
    'dist' => {
         COMPRESS  => 'gzip',
         SUFFIX    => 'gz',
	 CI        => 'cvs ci',
	 RCS_LABEL => 'cvs admin -Nv$(VERSION_SYM):',
    },
);

sub MY::postamble {

return <<'EOF';
xml:
	tools/gen_grammar.pl src/xsh_grammar.xml > lib/XML/XSH/Grammar.pm
	tools/gen_help.pl src/xsh_grammar.xml > lib/XML/XSH/Help.pm
	tools/gen_pod.pl src/xsh_grammar.xml > XSH.pod
	tools/gen_completions.pl src/xsh_grammar.xml > lib/XML/XSH/CompletionList.pm
	cd lib/XML/XSH; env LC_ALL=C LANG=C perl -MGrammar -e XML::XSH::Grammar::compile

docs: all
	pod2html --noindex --title "xsh - XML Editing Shell" < xsh > doc/xsh.html
	./xsh < tools/gen_reference.xsh
	./xsh < tools/gen_doc.xsh

winppd: ppd
	perl -i~ -pe 's/OS NAME=".*"/OS NAME="MSWin32"/; s/ARCHITECTURE NAME=".*"/ARCHITECTURE NAME="MSWin32-x86-multi-thread"/; s/CODEBASE HREF=".*"/CODEBASE HREF="XML-XSH.tar.gz"/;' XML-XSH.ppd

EOF

}

