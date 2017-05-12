@rem = '--*-Perl-*--';
@rem = '
@echo off
perl.exe install.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';

#   Real::Encode Install Program
#   by Kevin Meltzer <kmeltz@cris.com>

$MODULE    = "Real::Encode";
$VERSION   = "0.05";
$PM        = "Encode.pm";
$FIRSTNAME = "Encode";
$POD	   = "encode.html";


print "\n   $MODULE version $VERSION Install Program\n".
        "   by Kevin Meltzer <kmeltz\@cris.com>\n\n";

use Config;

$PERLLIB     = $Config{'privlib'};
$SITELIB     = $Config{'sitelib'};
$SITEARCHLIB = $Config{'sitearch'};

CheckDir($SITELIB);
CheckDir($SITELIB."\\Real");

print "Copying $PM to $SITELIB\\Real...\n";
`copy $PM "$SITELIB\\Real"`;

print "Copying $POD to $SITELIB\\Real...\n";
`copy $POD "$SITELIB\\Real"`;


# manually append installation 
# information to perllocal.pod
# (what a bad trick... :-)

open( DOC_INSTALL, ">> $PERLLIB/perllocal.pod");

print DOC_INSTALL "=head2 ", scalar(localtime), ": C<Module> L<$MODULE>\n\n".
                  "=over 4\n\n".
                  "=item *\n\n".
                  "C<installed into: $SITELIB>\n\n".
                  "=item *\n\n".
                  "C<LINKTYPE: dynamic>\n\n".
                  "=item *\n\n".
                  "C<VERSION: $VERSION>\n\n".
                  "=item *\n\n".
                  "C<EXE_FILES: >\n\n".
                  "=back\n\n";

close(DOC_INSTALL);

print "Installation complete.\n\n";
print "Reminder: This module is still in BETA. Send me any comments, suggestions, bugs, fixes, etc.\nCheers.\n";

sub CheckDir {
    my($dir) = @_;
    if(! -d $dir) {
        print "Creating directory $dir...\n";
        mkdir($dir, 0) or die "ERROR: ($!)\n";
    }
}    

__END__
:endofperl
