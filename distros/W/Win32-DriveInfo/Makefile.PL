use 5.004;

# Win32->UNIX CRLF converter for MakeMaker
# then usual 'make dist' will convert all ascii files to UNIX format
# (I suppose only .dll files might be binary here)
$PREOP =<<'EOP';
$(FULLPERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) \
  -e "$$dir = $$ARGV[0];use File::Find;" \
  -e "find(\&process, $$dir); sub process { return if -d || /\.dll$$/i;" \
  -e "open(I,$$_) || die \"to_unix: can't read file `$$_'\n\";" \
  -e "@file = <I>; close I;chmod 0666, $$_;" \
  -e "open(O,\">$$_\") || die \"to_unix: can't write file `$$_'\n\";" \
  -e "binmode O;print O map { s/\r\n/\n/;$$_ } @file; close O; }" $*
EOP

use ExtUtils::MakeMaker;
WriteMakefile(
    "NAME"		=> "Win32::DriveInfo",
    "DISTNAME"		=> "Win32-DriveInfo",
    "VERSION_FROM"	=> "DriveInfo.pm",
    "PREREQ_PM"		=> { "Win32::API" => 0 },
    ($] < 5.005 ? () :
      (
	"ABSTRACT"	=> "drives on Win32 systems",
	"AUTHOR"	=> "Mike Blazer <blazer\@mail.nevalink.ru>",
    )),
    "dist"		=> { COMPRESS => 'gzip -9frN', SUFFIX => 'gz',
	($^O eq "MSWin32" ? (PREOP => $PREOP) : ())},
    "clean"		=> { FILES => "pod2* *.html" },
);

sub MY::postamble {
    my $postamble =<<'END';

html: DriveInfo.pm
	pod2html --netscape --noindex DriveInfo.pm > DriveInfo.pm.html
END

    $postamble;
}

