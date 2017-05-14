#!/usr/bin/perl

use strict;

use ExtUtils::MakeMaker;
use File::Basename qw(basename dirname);
require ExtUtils::MM_Any;
our @ISA = qw(ExtUtils::MM_Any);

WriteMakefile(NAME      => 'gestalt',
              DISTNAME  => 'gestalt',
              EXE_FILES => ['bin/gestalt'],
              # Need copious amounts of escaping for this to work. It looks rubbish.
              PM_FILTER => 'sed -e "s/\\@PREFIX\\@/`echo "$(PERLPREFIX)" | sed -e "s/\//\\\\\\\\\\\\\\\\\//g"`/g"',
              # Not sure what the min versions are. Will need to do testing on older versions
              # to find this out.
              PREREQ_PM => {'DBI'                    => 0,
                            'Template'               => 0,
                            'AppConfig'              => 0,
                            'Template::Plugin::Page' => 0
                           },
              DIR       => [
                 'DB',
                 'Dispatcher',
                 'Controller' ],
              VERSION   => '0.2.1');
package MY;

use vars qw($VERSION @ISA
            $Is_OS2 $Is_VMS $Is_Win32 $Is_Dos
            $Is_OSF $Is_IRIX  $Is_NetBSD $Is_BSD
            $Is_SunOS4 $Is_Solaris $Is_SunOS $Is_Interix
            $Verbose %pm
            %Config_Override
           );

use ExtUtils::MakeMaker qw($Verbose neatvalue);

BEGIN { 
    $Is_OS2     = $^O eq 'os2';
    $Is_Win32   = $^O eq 'MSWin32';
    $Is_Dos     = $^O eq 'dos';
    $Is_VMS     = $^O eq 'VMS';
    $Is_OSF     = $^O eq 'dec_osf';
    $Is_IRIX    = $^O eq 'irix';
    $Is_NetBSD  = $^O eq 'netbsd';
    $Is_Interix = $^O eq 'interix';
    $Is_SunOS4  = $^O eq 'sunos';
    $Is_Solaris = $^O eq 'solaris';
    $Is_SunOS   = $Is_SunOS4 || $Is_Solaris;
    $Is_BSD     = $^O =~ /^(?:free|net|open)bsd$/ or
                  $^O eq 'bsdos' or $^O eq 'interix';
}

BEGIN {
    if( $Is_VMS ) {
        # For things like vmsify()
        require VMS::Filespec;
        VMS::Filespec->import;
    }
}

use File::Basename qw(basename dirname);
require ExtUtils::MM_Any;
our @ISA = qw(ExtUtils::MM_Any);

sub postamble
{
    '
install ::
	install -d -m 0755 $(DESTDIR)$(PERLPREFIX)/share/gestalt
	install -d -m 0755 $(DESTDIR)$(PERLPREFIX)/share/gestalt/html/js
	install -d -m 0755 $(DESTDIR)$(PERLPREFIX)/share/gestalt/html/css
	install -d -m 0755 $(DESTDIR)$(PERLPREFIX)/share/gestalt/templates
	for file in AUTHORS ChangeLog Controller.pm Makefile.PL Makefile.am \
	NEWS README Row.pm Table.pm apache.conf.in appConfig.cfg.in appSpec.in \
	appStartup.pl.in bootstrap configure.in; \
	do \
		install -c -m 0644 templates/$$file $(DESTDIR)$(PERLPREFIX)/share/gestalt/ ; \
	done
	install -c -m 0644 templates/html/Makefile.am $(DESTDIR)$(PERLPREFIX)/share/gestalt/html
	for file in Makefile.am prototype.js validate.js; \
	do \
		install -c -m 0644 templates/html/js/$$file $(DESTDIR)$(PERLPREFIX)/share/gestalt/html/js ; \
	done
	for file in Makefile.am style.css; \
	do \
		install -c -m 0644 templates/html/css/$$file $(DESTDIR)$(PERLPREFIX)/share/gestalt/html/css ; \
	done
	for file in _fieldDisplay.tt2 _fieldInput.tt2 _fkeyDisplay.tt2 _fkeyInput.tt2 \
	_form.tt2 _header.tt2 _pager.tt2 create.tt2 edit.tt2 list.tt2 show.tt2 _auth.tt2 ; \
	do \
		install -c -m 0644 templates/templates/$$file $(DESTDIR)$(PERLPREFIX)/share/gestalt/templates ; \
	done

    rpm: dist
	cp $(NAME)-$(VERSION).tar.gz /usr/src/redhat/SOURCES/
	rpmbuild -ba $(NAME).spec
	cp /usr/src/redhat/SRPMS/$(NAME)-$(VERSION)-1.src.rpm .
	cp /usr/src/redhat/RPMS/noarch/$(NAME)-$(VERSION)-1.noarch.rpm .

';
}

sub installbin {
    my($self) = shift;

    return "" unless $self->{EXE_FILES} && ref $self->{EXE_FILES} eq "ARRAY";
    my @exefiles = @{$self->{EXE_FILES}};
    return "" unless @exefiles;

    @exefiles = map vmsify($_), @exefiles if $Is_VMS;

    my %fromto;
    for my $from (@exefiles) {
	my($path)= $self->catfile('$(INST_SCRIPT)', basename($from));

	local($_) = $path; # for backwards compatibility
	my $to = $self->libscan($path);
	print "libscan($from) => '$to'\n" if ($Verbose >=2);

        $to = vmsify($to) if $Is_VMS;
	$fromto{$from} = $to;
    }
    my @to   = values %fromto;

    my @m;
    push(@m, qq{
EXE_FILES = @exefiles

pure_all :: @to
	\$(NOECHO) \$(NOOP)

realclean ::
\$(INST_SCRIPT)/.exists :: \$(PERL_INC)/perl.h
	\$(NOECHO) \$(MKPATH) \$(INST_SCRIPT)
	\$(NOECHO) \$(EQUALIZE_TIMESTAMP) \$(PERL_INC)/perl.h \$(INST_SCRIPT)/.exists

	-\$(NOECHO) \$(CHMOD) \$(PERM_RWX) \$(INST_SCRIPT)

\$(INST_BIN)/.exists :: \$(PERL_INC)/perl.h
	\$(NOECHO) \$(MKPATH) \$(INST_BIN)
	\$(NOECHO) \$(EQUALIZE_TIMESTAMP) \$(PERL_INC)/perl.h \$(INST_BIN)/.exists

	-\$(NOECHO) \$(CHMOD) \$(PERM_RWX) \$(INST_BIN)

});

    # realclean can get rather large.
    push @m, map "\t$_\n", $self->split_command('$(RM_F)', @to);
    push @m, "\n";


    # A target for each exe file.
    while (my($from,$to) = each %fromto) {
	last unless defined $from;

	push @m, sprintf <<'MAKE', $to, $from, $to, $from, $to, $to, $to;
%s : %s $(FIRST_MAKEFILE) $(INST_SCRIPT)/.exists $(INST_BIN)/.exists
	$(NOECHO) $(RM_F) %s
	$(PM_FILTER) < %s > %s
	-$(NOECHO) $(CHMOD) $(PERM_RWX) %s

MAKE

    }

    join "", @m;
}

