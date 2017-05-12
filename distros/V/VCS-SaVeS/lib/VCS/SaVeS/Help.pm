package VCS::SaVeS::Help;

sub general {<<END;

  SaVeS is the Standalone Version System

  "svs" is the primary command line tool for SaVeS

  For more detailed help, try:
    svs help usage                # svs command usage
    svs help overview             # Overview of svs and SaVeS XXX
    svs help basics               # Basic svs usage XXX
    svs help commands             # List of all svs commands
    svs help <command-name>       # Complete description of an svs command
    svs help switches             # Command line switches for svs XXX

END
}

sub usage {
    <<USAGE;

usage: svs [generic-switches] command [command-switches] [command-arguments]

SEE:
    svs help
    perldoc svs
    perldoc saves

USAGE
}

sub commands {<<END
Use 'svs help <command-name>' for complete help on a specific command.

add      - Add files to the MANIFEST
archive  - Create an archive of the repository XXX
break    - Mark directory as a SaVeS breakpoint
config   - Change configuration options XXX
delete   - Delete the revision history a file from the repository
diff     - Show differences between file revisions
export   - Export a repository to another VCS (such as CVS) XXX
find     - Find repository files based on certain criteria
help     - Get help about the SaVeS system and svs commands
history  - Show the revision history of a file
import   - Create a new repository
log      - Show a view of the SaVeS log XXX
manifest - List or change the contents of the .saves/MANIFEST
merge    - Merge a nested repository into the current one XXX
message  - Change the message of a file revision XXX
remove   - Remove a file from the MANIFEST
restore  - Restore file(s) to a certain revision
save     - Checkin a new revision of files
status   - Show the current status of files
tag      - Mark a set of revisions with a symbolic tag XXX
undo     - Attempt to undo a change XXX
split    - Turn a subdirectory of the repository into its own repository XXX

END
}

sub add { grep_pod(); }
sub archive { grep_pod(); }
sub break { grep_pod(); }
sub config { grep_pod(); }
sub delete { grep_pod(); }
sub diff { grep_pod(); }
sub export { grep_pod(); }
sub find { grep_pod(); }
sub help { grep_pod(); }
sub history { grep_pod(); }
sub import { grep_pod(); }
sub log { grep_pod(); }
sub manifest { grep_pod(); }
sub merge { grep_pod(); }
sub message { grep_pod(); }
sub remove { grep_pod(); }
sub restore { grep_pod(); }
sub save { grep_pod(); }
sub status { grep_pod(); }
sub tag { grep_pod(); }
sub undo { grep_pod(); }
sub split { grep_pod(); }

sub grep_pod {
    my $svs_bin = '';
    for $path (split /[:;]/, $ENV{PATH}) {
        $svs_bin = "$path/svs", last
          if -f "$path/svs";
    }    
    die "Can't find svs binary\n"
      unless $svs_bin;
    open SVSBIN, $svs_bin
      or die $!;
    (my $command = (caller(1))[3]) =~ s/.*::(\w+?)_?$/$1/;
    local $/;
    my $pod = <SVSBIN>;
    close SVSBIN;
    $pod =~ /^(=head2\s$command.*?)^=(?:head|cut)/ms
      or die "Can't find pod section for '$command'\n";
    my $cmd_pod = $1;
    open POD, "> /tmp/$command-help.pod"
      or die $!; 
    print POD $cmd_pod;
    close POD;
    open POD2TEXT, "pod2text /tmp/$command-help.pod |"
      or die "Can't run pod2text on this system\n";
    my $cmd_text = <POD2TEXT>;
    close POD2TEXT;
    return $cmd_text;
}

sub AUTOLOAD {
    (my $section = $VCS::SaVeS::Help::AUTOLOAD) =~ s/.*:://;
    die "'$section' is an invalid 'svs help' option\n";
}

1;
