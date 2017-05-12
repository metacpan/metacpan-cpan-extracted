# $Id: Makefile.PL,v 2.7 2007-01-02 22:03:23 pajas Exp $

use strict;

use ExtUtils::MakeMaker;

$| = 1;

WriteMakefile(
    'NAME'      => 'XML::XSH2',
    'VERSION_FROM' => 'lib/XML/XSH2.pm',
    'EXE_FILES' => ['xsh'],
    'PREREQ_PM' => {
                    'URI' => 0,
		    'IO::Scalar' => 0,
		    'XML::LibXML::Common' => "0.13",
		    'XML::LibXML' => "1.60",
		    'XML::LibXSLT' => "1.60",
		    'XML::LibXML::Iterator' => 0,
		    'Parse::RecDescent' => "1.94",
		    'XML::XUpdate::LibXML' => "0.6.0",
		    'XML::LibXML::XPathContext' => "0.07",
		    'XML::SAX::Writer' => "0.44",
		    'XML::Filter::DOMFilter::LibXML' => "0.03",
		    'Term::ReadLine' => 0,
		    'Term::ReadLine::Perl' => 0,
		   },
     AUTHOR       => 'Petr Pajas (pajas@matfyz.cz)',
     ABSTRACT     => 'XML Editing Shell',
     MAN3PODS     => {
		      'XSH2.pod' => 'blib/man3/XSH2.3',
		       'lib/XML/XSH2.pm' => 'blib/man3/XML::XSH2.3',
                       'lib/XML/XSH2/XPathToXML.pm' => 'blib/man3/XML::XSH2::XPathToXML.3',
                       'lib/XML/XSH2/Inline.pm' => 'blib/man3/XML::XSH2::Inline.3',
                       'lib/XML/XSH2/Compile.pm' => 'blib/man3/XML::XSH2::Compile.3'
		     },
    depend => {
                distdir => 'hide',
              },
    'dist' => {
         COMPRESS  => 'gzip',
         SUFFIX    => 'gz',
	 CI        => 'cvs ci',
	 RCS_LABEL => 'cvs admin -Nv$(VERSION_SYM):',
    },
    macro => {
         TARFLAGS => '--format=ustar -cvf'
    },
);

sub MY::postamble {

return <<'EOF';
svn:    cvs

cvs:    xml
	rm -f Makefile
	@echo
	@echo "Please, re-run 'perl Makefile.PL' and 'make'"
	@echo

hide:
	$(PERL) tools/hide_packages.pl lib/XML/XSH2/Parser.pm "XML::XSH2::"

XSH2.pod: xml

xml:
	$(PERL) tools/gen_grammar.pl src/xsh_grammar.xml > lib/XML/XSH2/Grammar.pm
	$(PERL) tools/gen_commands.pl src/xsh_grammar.xml > lib/XML/XSH2/Commands.pm
	$(PERL) tools/gen_help.pl src/xsh_grammar.xml > lib/XML/XSH2/Help.pm
	$(PERL) tools/gen_pod.pl src/xsh_grammar.xml > XSH2.pod
	$(PERL) tools/gen_completions.pl src/xsh_grammar.xml > lib/XML/XSH2/CompletionList.pm
	$(PERL) -e "chdir q(lib/XML/XSH2); require Grammar; XML::XSH2::Grammar::compile()"
	$(MAKE) hide
	$(PERL) -c lib/XML/XSH2/Parser.pm

grammar:
	$(PERL) -e "chdir q(lib/XML/XSH2); require Grammar; XML::XSH2::Grammar::compile()"
	$(PERL) -c lib/XML/XSH2/Parser.pm

docs: all
	podselect xsh > xsh.pod
	pod2html --noindex --title "XSH2" --podroot=. --podpath=. --libpods=xsh < XSH2.pod > doc/XSH2.html
	pod2html --noindex --title "xsh - XML Editing Shell" --podroot=.  --podpath=. --libpods=XSH2 < xsh > doc/xsh.html
	$(PERL) ./xsh -l tools/gen_reference.xsh
	$(PERL) ./xsh -l tools/gen_doc.xsh

winppd: ppd
	$(PERL) -i~ -pe 's/OS NAME=".*"/OS NAME="MSWin32"/; s/ARCHITECTURE NAME=".*"/ARCHITECTURE NAME="MSWin32-x86-multi-thread"/; s/CODEBASE HREF=".*"/CODEBASE HREF="XML-XSH2.tar.gz"/;' XML-XSH2.ppd

# used to update version numbers in all modules
version:
	$(PERL) tools/update_version.pl $(VERSION_FROM) xsh $(TO_INST_PM)

EOF

}

