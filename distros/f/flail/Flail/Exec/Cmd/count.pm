=pod

=head1 NAME

Flail::Exec::Cmd::count - Flail "count" command

=head1 VERSION

  Time-stamp: <2006-12-03 11:04:43 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::count;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::count;
use strict;
use Carp;
use Flail::Utils;
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_count);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );
 
sub flail_count {
    if (!defined($::FOLDER)) {
        print "no folder currently open\n";
        return;
    }
    my $do_list = 0;
    if (defined($_[0])) {
        if ($_[0] =~ /^-list$/) {
            shift(@_);
            $do_list = 1;
        }
    }
    if (!defined($_[0])) {
        push(@_, "marked");
    }
    foreach my $label (@_) {
        my @msgs = $::FOLDER->select_label($label);
        print "$label: ", scalar @msgs, " messages";
        print ": @msgs" if $do_list;
        print "\n";
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
