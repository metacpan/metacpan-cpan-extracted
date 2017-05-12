=pod

=head1 NAME

Flail::Exec::Cmd::forward - Flail "forward" command

=head1 VERSION

  Time-stamp: <2006-12-03 10:45:26 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::forward;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::forward;
use strict;
use Carp;
use Flail::Utils;
use Mail::Internet;
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_forward);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );
 
sub flail_forward {
    my $cur = get_cur_msg();
    my $as = hack_as($::OPT->{as});
    $as = $::FromAddress unless $as;
    if (!defined($cur)) {
        print "no current message to forward\n";
        return;
    }
    my $cur_hdr = $cur->head();
    my $cur_subj = $cur_hdr->get("Subject");
    chomp($cur_subj);
    my $forw_body_str = ("-" x 20) . " Forwarded message follows\n\n";
    $forw_body_str .= $cur->as_string();
    my @lines = split("\n", $forw_body_str);
    my $i = 0;
    while ($i <= $#lines) {
        $lines[$i] .= "\n";
        ++$i;
    }
    my $hdr = new Mail::Header;
    $hdr->add("From", $as);
    $hdr->add("Subject", "[Fwd: $cur_subj]");
    my $forw = new Mail::Internet(Header => $hdr, Body => \@lines);
    send_internal($cur, $forw, $as, @_);
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
