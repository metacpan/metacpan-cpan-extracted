=pod

=head1 NAME

Flail::Exec::Cmd::copy - Flail "copy" command

=head1 VERSION

  Time-stamp: <2006-12-03 11:11:12 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::copy;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::copy;
use strict;
use Carp;
use Flail::Utils qw(say);
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_copy);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );
 
sub flail_copy {
    if ($#_ < 1) {
        print "need at least two arguments\n";
        return;
    }
    if (defined($::FOLDER)) {
        my $target = pop(@_);
        my $fn = $::FolderDir . "/" . $target;
        my $ncp = 0;
        sys("touch $fn") if (!(-f $fn));
        my $tfolder = new Mail::Folder('AUTODETECT', $fn, Create => 1,
                                       DefaultFolderType => 'Mbox');
        if (!$tfolder) {
            print "could not open or create target folder $target\n";
            return;
        }
        my @tmp;
        eval { @tmp = parse_range("@_"); };
        if ($@) {
            warn("range expression bad: $@\n");
            return;
        }
        @_ = @tmp;
        say("cp: range => @tmp");
        foreach my $i (@tmp) {
            my $msg = $::FOLDER->get_message($i);
            if (!$msg) {
                print "could not get message $i in $::FOLDER_NAME\n";
            } else {
                $tfolder->append_message($msg);
                $::FOLDER->add_label($i, "filed");
                print "copied message $i\n" unless $::Quiet;
                $ncp++;
            }
        }
        $tfolder->sync();
        $tfolder->close();
        print "copied $ncp messages from $::FOLDER_NAME to $target\n" unless $::Quiet;
    } else {
        print "no folder open\n";
    }
}

1;

__END__

=pod

=head1 AUTHOR

  attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

  (C) 2002-2006 by attila <attila@stalphonsos.com>.  all rights reserved.

  This code is released under a BSD license.  See the LICENSE file
  that came with the package.

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
