=pod

=head1 NAME

Flail::Exec::Cmd::get - Flail "get" command

=head1 VERSION

  Time-stamp: <2006-12-03 11:04:41 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::get;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::get;
use strict;
use Carp;
use Flail::Utils qw(:all);
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_get);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );
 
sub flail_get {
    if ($_[0] eq "imap") {
        $::CheckType = shift(@_);
    } elsif ($_[0] eq "pop3") {
        $::CheckType = shift(@_);
    } elsif ($_[0] eq "spool") {
        $::CheckType = shift(@_);
    }
    if ($::CheckType eq "imap") {
        get_imap(@_);
        reopen_current_folder();
#    run_message_hooks($NewLabel, $IncomingFolder, 1) if $NewLabel;
    } elsif ($::CheckType eq "pop3") {
        get_pop3(@_);
        reopen_current_folder();
#    run_message_hooks($NewLabel, $IncomingFolder, 1) if $NewLabel;
    } elsif ($::CheckType eq "spool") {
        get_spool(@_);
        reopen_current_folder();
    } else {
        print "don't know how to get new mail\n";
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
