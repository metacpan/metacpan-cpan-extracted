=pod

=head1 NAME

Flail::Exec::Cmd::addressbook - Flail "addressbook" command

=head1 VERSION

  Time-stamp: <2006-12-03 11:04:46 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::addressbook;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::addressbook;
use strict;
use Carp;
use Flail::Utils;
use Flail::AddressBook qw(:all);
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_addressbook);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );
 
sub flail_addressbook {
    if ($::NoAddressBook) {
        print "no address book.\n";
        return;
    }
    my $subcmd = shift(@_);
    if ($subcmd =~ /^add$/i) {
        my $key = shift(@_);
        my $val = "@_";
        addressbook_add($key, $val, 0);
    } elsif ($subcmd =~ /^show$/i) {
        if ("@_" =~ /^\"(.*)\"/) {
            @_ = ( $1 );
        }
        foreach my $key (@_) {
            my $val = $::ADDRESSBOOK{$key};
            if ($val) {
                print "  $key: $val\n";
            } else {
                print "  $key not in addressbook\n";
            }
        }
        return;
    } elsif ($subcmd =~ /^list$/i) {
        if ("@_" =~ /^\"(.*)\"/) {
            @_ = ( $1 );
        }
        my $re = "@_";
        my @keys = sort keys %::ADDRESSBOOK;
        if (!scalar(@keys)) {
            print "Addressbook is empty.\n";
            return;
        }
        print "Addressbook has ", scalar(@keys), " entries:\n";
        foreach my $key (@keys) {
            my $val = $::ADDRESSBOOK{$key};
            print "  $key: $val\n" if (($re eq "") ||
                                       ($key =~ /$re/i) || ($val =~ /$re/i));
        }
        return;
    } elsif ($subcmd =~ /^del$/i) {
        if ("@_" =~ /^\"(.*)\"/) {
            @_ = ( $1 );
        }
        foreach my $key (@_) {
            addressbook_delete($key);
        }
    } elsif ($subcmd =~ /^import$/i) {
        foreach my $file (@_) {
            if ($file =~ /\.ldif$/) {
                print "Importing LDIF file: $file\n";
                addressbook_import_ldif($file);
            } elsif ($file =~ /\.csv$/) {
                print "Importing CSV file: $file\n";
                addressbook_import_csv($file);
            } else {
                print "I'm not sure what kind of file $file is...\n";
                print "I support LDIF and CSV; please rename it to one of those\n";
            }
        }
    } elsif ($subcmd =~ /^take$/i) {
        if (!defined($::FOLDER)) {
            print "no current folder\n";
            return;
        }
        my $label = shift(@_) || "cur";
        my $force = shift(@_) || undef;
        $force = 1 if defined($force);
        Flail::Exec::flail_eval("map $label { take_addrs($force); }"); # sick, but effective
    } else {
        if (($subcmd eq '') || ($subcmd =~ /^help$/i)) {
            print "Addressbook subcommands:\n";
            print "  add nick mail  - add an entry that maps nick -> mail\n";
            print "  import file... - import LDIF-format file(s)\n";
            print "  show nick...   - show specific entries\n";
            print "  list [regexp]  - list whole addressbook, or matching entries\n";
            print "  take [tag]     - take addresses from the current message\n";
            print "                   or from all messages with the given tag\n";
            print "  del nick...    - delete entries\n";
        } else {
            print "Addressbook: bad cmd $subcmd; one of add,import,show,list,del\n";
        }
        return;
    }
    addressbook_checkpoint();
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
