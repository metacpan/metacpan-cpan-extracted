@rem = '--*-PERL-*--';
@rem = '
@echo off
rem setlocal
set ARGS=
:loop
if .%1==. goto endloop
set ARGS=%ARGS% %1
shift
goto loop
:endloop
rem ***** This assumes PERL is in the PATH *****
perl.exe -w -S ln32.bat %ARGS%
goto endofperl
@rem ';

# ln32: A Win32 Command Line Link Utility.
# Version: 1.01
# by Aldo Calpini <dada@perl.it>

use Win32::Shortcut;

$resolve = 1;
&parse_arguments;

foreach $SHORTCUT (@SHORTCUTS) {
    print "\n$SHORTCUT:\n" if not $quiet;
    $changed = 0;
    $LINK = new Win32::Shortcut($SHORTCUT);

    if($LINK) {

        $LINK->{'Description'}=$new_Description, $changed=1 if $new_Description;
        $LINK->{'ShowCmd'}=$new_ShowCmd, $changed=1 if $new_ShowCmd;
        $LINK->{'Path'}=$new_Path, $changed=1 if $new_Path;
        $LINK->{'Arguments'}=$new_Arguments, $changed=1 if $new_Arguments;
        $LINK->{'WorkingDirectory'}=$new_WorkingDirectory, $changed=1 if $new_WorkingDirectory;
    
        if(!-f $LINK->{'Path'}) {
            print "*** WARNING: link is unresolved!\n" if not $quiet;
            if($resolve) {
                $new = $LINK->Resolve();
                if(!-f $new) {
                    print "*** WARNING WARNING: link cannot be resolved!\n" if not $quiet;
                } else {
                    print "    Link resolved to \"$new\"\n" if not $quiet;
                    $LINK->{'Path'} = $new;
                    $changed = 1;
                }
            }
            print "\n" if not $quiet;
        }

        if($changed == 1) {
            $LINK->Save();
        }

        if(not $quiet) {
            print "    Target:      $LINK->{'Path'} $LINK->{'Arguments'}\n";
          # print "    Target(8.3): $LINK->{'ShortPath'}\n";
            print "    Start In:    $LINK->{'WorkingDirectory'}\n";
            print "    Description: $LINK->{'Description'}\n";
            print "    Run:         ";
            if($LINK->{'ShowCmd'} == 1) {
                print "Normal Window\n";
            } elsif($LINK->{'ShowCmd'} == 3) {
                print "Maximized\n";
            } elsif($LINK->{'ShowCmd'} == 7) {
                print "Minimized\n";
            } else {
                print "Normal ($LINK->{'ShowCmd'}\?)\n";
            }
            print "    Icon:        $LINK->{'IconLocation'} ";
            print "($LINK->{'IconNumber'})" if $LINK->{'IconNumber'};
            print "\n";
        }  
        $LINK->Close();
    } else {
        print STDERR "\nERROR!\n";
    }
    undef $LINK;
}


sub parse_arguments {
    my $f;
    while ($f=shift(@ARGV)) {
        if($f eq "-p") {
            $new_Path=shift(@ARGV);
        } elsif($f eq "-a") {
            $new_Arguments=shift(@ARGV);
        } elsif($f eq "-d") {
            $new_Description=shift(@ARGV);
        } elsif($f eq "-s") {
            $next_arg=shift(@ARGV);
            if($next_arg=~/^n/i) {
                $new_ShowCmd=1;
            } elsif($next_arg=~/^ma/i) {
                $new_ShowCmd=3;
            } elsif($next_arg=~/^mi/i) {
                $new_ShowCmd=7;
            }
        } elsif($f eq "-w") {
            $new_WorkingDirectory=shift(@ARGV);
        } elsif($f eq "-q") {
            $quiet=1;
        } elsif($f eq "-h") {
            &usage;
            exit;
        } elsif($f eq "-nr") {
            $resolve=0;
        } else {
            push(@SHORTCUTS,$f);
        }
    }
    if($#SHORTCUTS==-1) {
        &usage;
        exit;
    }
}

sub usage {
    print <<USAGE_END;

ln32: A Win32 Command Line Link Utility.

SYNTAX: ln32 [options] file_name(s)

[options] is one or more of the following:
  -a <new>       : set the arguments of the link to <new>
  -d <new>       : set the description of the link to <new>
  -p <new>       : set the path (target) of the link to <new>
  -s n[ormal]    : set the show command of the link to Normal
  -s ma[ximized] : set the show command ot the link to Maximized
  -s mi[nimized] : set the show command ot the link to Maximized
  -q             : act quietly (no screen output)
  -nr            : don't attempt to resolve broken links
  -h             : show this help page

Version: 1.01
by Aldo Calpini <dada\@perl.it>

USAGE_END
}

__END__
:endofperl
