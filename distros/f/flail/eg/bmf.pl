##
# bmf.pl - flail/bmf integration
#
# Time-stamp: <2007-02-27 18:11:12 attila@stalphonsos.com>
##
use vars qw($BmfProgram);
$BmfProgram = '/usr/local/bin/bmf';

sub call_bmf {
    my($args,$folder,@range) = @_;
    if (!defined($FOLDER)) {
        flail_emit("No current folder.\n");
        return;
    } else {
        @range = ($FOLDER->current_message) unless @range;
        my @tmp;
        eval { @tmp = parse_range("@range",1); };
        if ($@) {
            warn("range expression bad (@range): $@\n");
            return;
        }
        @range = @tmp;
        my @move = ();
        foreach my $msgno (@range) {
            my $msg = $FOLDER->get_message($msgno);
            if (!$msg) {
                warn("message $msgno does not exist - skipping\n") unless $Quiet;
            } else {
                open(BMF, "|$BmfProgram $args") or die(qq{could not invoke $BmfProgram $args on $msgno: $!\n});
                print BMF $msg->as_string();
                close(BMF);
                push(@move,$msgno);
            }
        }
        flail_emit("[Passed ".scalar(@move)." msgs through: $BmfProgram $args]\n") unless $Quiet;
        flail_move(@move,$folder) if (!$::OPT->{'test'} && $folder && scalar(@move));
    }
}

sub cmd_bmf_spam { call_bmf("-s",spam_folder_name(),@_); }
sub cmd_bmf_notspam { call_bmf("-n",$IncomingFolder,@_); }
sub cmd_bmf_respam { call_bmf("-S",spam_folder_name(),@_); }
sub cmd_bmf_renotspam { call_bmf("-N",$IncomingFolder,@_); }
sub cmd_bmf_test { call_bmf("-t",undef,@_); }

sub cmd_bmf {
    my @args = @_;
    my $opt = "-s";
    my $folder = latest_spam_folder();
    flail_emit("[This folder: ".$FOLDER->foldername()."]\n") unless $Quiet;
    if ($::OPT->{"re"}) {
        if ($::OPT->{"no"} || $::OPT->{"not"}) {
            $opt = "-N";
            $folder = $IncomingFolder;
        } else {
            $opt = "-S";
        }
    } elsif ($::OPT->{"no"} || $::OPT->{"not"}) {
        $opt = "-n";
        $folder = $IncomingFolder;
    } elsif ($::OPT->{"test"}) {
        $opt = "-t";
        $folder = undef;
    }
    $folder = undef
        if (defined($FOLDER) && ($folder eq $FOLDER->foldername()));
    call_bmf($opt,$folder,@args);
}

flail_defcmd1("spam",\&cmd_bmf,"bmf cmds: spam/no, spam/re, spam/no/re, spam/test (all w/noexec)");

flail_emit(" [BMF]") unless $Quiet;

1;

# Local variables:
# mode: perl
# indent-tabs-mode: nil
# tab-width: 4
# perl-indent-level: 4
# End:
