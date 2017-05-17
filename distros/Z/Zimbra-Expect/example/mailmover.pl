#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long 2.25 qw(:config posix_default no_ignore_case);
use Pod::Usage 1.14;
use Zimbra::Expect::ZmProv;
use Zimbra::Expect::ZmMailbox;

# main loop
sub main(){
    # parse options
    my %opt = ();
    GetOptions(\%opt, 'help|h', 'man', 'noaction|no-action|n','all','debug',
              'verbose|v') or exit(1);
    if ($opt{help})     { pod2usage(1) }
    if ($opt{man})      { pod2usage(-exitstatus => 0, -verbose => 2, -noperldoc=>1) }
    if ($opt{noaction}) {
       $opt{verbose} = 1 ;
       warn "*** NO ACTION MODE ***\n";
    }
    my $account = shift @ARGV;
    my $from = shift @ARGV;
    my $to = shift @ARGV or pod2usage(-message=>"destination folder is missing");

    $from = "/$from";
    $to = "/$to";

    my @accounts;
    if ($account eq 'ALL'){
        @accounts = grep /\@/, split /\n/, Zimbra::Expect::ZmProv->new(noaction=>$opt{noaction},verbose=>$opt{verbose},debug=>$opt{debug})->cmd('gaa') ;
    }
    else {
        @accounts = ($account);
    }

    if ($ENV{USER} ne 'zimbra'){
       pod2usage(-message=>"$0 only works when running as user 'zimbra'");
    }

    for my $account (@accounts){
        warn ">> $account <<\n";
        my $box = Zimbra::Expect::ZmMailbox->new(verbose=>$opt{verbose},noaction=>$opt{noaction},account=>$account,debug=>$opt{debug});

        my %folder;
        for my $line (split /\n/, $box->cmd('getAllFolders')){
            $line =~ m{^\s*\S+\s+mess\s+\d+\s+\d+\s+(/.+)} && do {
                $folder{$1} = 1;
                next;
            };
        }
        if (not $folder{$from}){
            warn "  * skipping account $account. no $from folder\n";
            next;
        }
        if (not $folder{$to}){
            $box->act('renameFolder '.$from.' '.$to);
            next;
        }

        my @lines = split /\n/, $box->cmd('search --types message in:"'.$from.'"');
        my @msgs;
        while (@lines){
            my $line = shift @lines;
            $line =~ /more:\s+true/ && do {
                push @lines, split(/\n/, $box->cmd('search --next'));
                next;
            };
            $line =~ /^\s*\d+\.\s+(\d+)/ && do {
                push @msgs, $1;
            };
        }
        if (@msgs){
            $box->act('moveMessage '.join(',',@msgs).' "'.$to.'"');
        }
        else {
            warn "  * no messages found\n";
        }
        $box->act('deleteFolder "'.$from.'"');
    }
}


main;
exit 0;

1;

__END__

=head1 NAME

mailmover.pl - Zimbra Message Mover

=head1 SYNOPSIS

B<zmmsgmover> [I<options>...] I<account@domain>|B<ALL> I<src-folder> I<dst-folder>

     --man           show man-page and exit
 -h, --help          display this help and exit
     --noaction      just talk don't act
     --verbose       talk while working
     --debug         show all output before it is parsed

=head1 DESCRIPTION

Migrate messages from one folder to another. Removing the source folder
after migration.  If the destination folder does not exist, the selected
folder will simply be renamed to the new name.

The initial C</> for folder names is implide. Write C<Sent> and not C</Sent>.

This command has to be executed as the zimbra user (C<sudo su - zimbra>).

=head1 EXAMPLES

Move all messages for one account

  mailmover.pl tobi@zimbra.oetiker.ch sent-mail Sent

Move messages for all accunts on the system

  mailmover.pl ALL sent-mail Sent

=head1 COPYRIGHT

Copyright (c) 2017 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2017-05-16 to Initial Version

=cut
