## flail, A command-line MUA in Perl

use ExtUtils::MakeMaker;
eval(`grep VERSION= flail0.pl|sed -e 's,VERSION=,flail_VERSION=,'`);

print STDERR "Welcome to flail $flail_VERSION\n\n";

WriteMakefile(
    AUTHOR => 'Sean Levy <snl@cluefactory.com>',
    ABSTRACT => 'Command-line MUA in Perl',
    NAME => 'flail',
    VERSION_FROM => 'flail0.pl',
    EXE_FILES => [ 'flail', 'spamfish' ],
    PREREQ_PM => {
	'IO::File' => 0,
	'IO::String' => 0,
	'Term::ReadLine' => 0,
	'Mail::Folder' => 0,
	'Mail::Header' => 0,
	'Mail::Internet' => 0,
	'Term::ANSIColor' => 0,
	'Term::ReadKey' => 0,
	'Time::Local' => 0,
	'Time::ParseDate' => 0,
	'Mail::POP3Client' => 0,
	'Mail::IMAPClient' => 0,
	'Mail::Util' => 0,
	'Net::SMTP' => 0,
	'Proc::Simple' => 0,
	'Proc::SyncExec' => 0,
	'Symbol' => 0,
    },
    PM => {
	'SecretPipe.pm' => '$(INST_LIBDIR)/SecretPipe.pm',
    }
);
sub MY::postamble {
    print STDERR "To install completely:\n";
    print STDERR "    \$ make\n    \$ sudo make install\n";
    print STDERR "\nDon't forget to read the README and the POD.\n";
    print STDERR "Examples will be installed somehwere like /usr/local/share/examples/flail\nThey are also in the eg/ subdirectory of this distribution.\n\nEat your veggies.\n\n";
    return <<__MyTaRgEt__;
OPENSSLCMD?=openssl
MD5CMD?=\$(OPENSSLCMD) dgst -md5
SHA1CMD?=\$(OPENSSLCMD) dgst -sha1
RIPEMD160CMD?=\$(OPENSSLCMD) dgst -ripemd160
GPGCMD?=gpg
GPGKEYID?=0x4FFCBB9C
RELEASEDIR?=\$\$HOME/release
RELEASETARBALL?=\$(NAME)-\$(VERSION).tar.gz
RELEASEFILES?=\$(RELEASETARBALL) \$(NAME)-\$(VERSION).tar.gz.md5 \$(NAME)-\$(VERSION).tar.gz.sha1 \$(NAME)-\$(VERSION).tar.gz.ripemd160 \$(NAME)-\$(VERSION).tar.gz.asc
RELEASETARGETS?=dist md5 sha1 ripemd160 asc
RM?=/bin/rm
SHAREDIR?=\$(PREFIX)/share
EXAMPLEDIR?=\$(SHAREDIR)/examples/\$(NAME)
EXAMPLES?=eg
MKDIR_P?=mkdir -p

flail: flail0.pl
	\$(CP) flail0.pl flail
	chmod +x flail

spamfish: spamfish.pl
	\$(CP) spamfish.pl spamfish
	chmod +x spamfish

clean::
	\$(RM) -f *.flc *.bak *~ .tec* flail spamfish

force-releasefiles: cleanrelease releasefiles

distclean:: cleanrelease

install :: \$(EXAMPLEDIR)
	\$(CP) dot.flailrc \$(EXAMPLEDIR)
	(cd \$(EXAMPLES); \$(TAR) cf - `grep eg/ ../MANIFEST | sed -e 's|eg/||'`) | (cd \$(EXAMPLEDIR); \$(TAR) xf -)

\$(EXAMPLEDIR) :
	\$(MKDIR_P) \$(EXAMPLEDIR)

cleanrelease:
	-\$(RM) -f \$(RELEASEFILES)

releasefiles: \$(RELEASETARGETS)

release: releasefiles
	\@-[ -d \$(RELEASEDIR) ] && \$(MV) \$(RELEASEFILES) \$(RELEASEDIR)
	\@echo Moved release files to \$(RELEASEDIR): \$(RELEASEFILES)

md5: \$(RELEASETARBALL)
	\$(MD5CMD) \$(NAME)-\$(VERSION).tar.gz > \$(NAME)-\$(VERSION).tar.gz.md5

sha1: \$(RELEASETARBALL)
	\$(SHA1CMD) \$(NAME)-\$(VERSION).tar.gz > \$(NAME)-\$(VERSION).tar.gz.sha1

ripemd160: \$(RELEASETARBALL)
	\$(RIPEMD160CMD) \$(NAME)-\$(VERSION).tar.gz > \$(NAME)-\$(VERSION).tar.gz.ripemd160

asc: \$(RELEASETARBALL)
	\$(GPGCMD) --sign --default-key \$(GPGKEYID) --detach --armor \$(NAME)-\$(VERSION).tar.gz
__MyTaRgEt__
}
