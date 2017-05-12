#! /usr/bin/perl -w
use strict;
use Data::Dumper;

# $Id$
##### syncer_ftpclient.t
#
# Here we try to test the actual syncing process from ftp
# This is done by overriding all the used Net::FTP handlers
# and provide a fake FTP mechanism through them
# For this there is the 't/ftppub' directory with:
#     't/ftppub/perl-current' contains a source-tree
#     't/ftppub/perl-current-diffs' contains a few fake diffs
# Now that we have controlable FTP (if you have Net::FTP), 
# we can concentrate on doing the untargz and patch stuff
#
#####

use vars qw( $FTP_FAIL );
$FTP_FAIL = 0;
use File::Spec::Functions;
use File::Basename;
use Cwd;
my $extra_lib;
BEGIN {
    $extra_lib = File::Spec->rel2abs( dirname( $0 ), cwd() );
    print "Using '$extra_lib' as extra \@INC\n";
}
use lib $extra_lib;
use TestLib;

use Test::More;

BEGIN {
    eval { require Net::FTP; };
    $@ and plan( skip_all => "No 'Net::FTP' found!\n" . 
                             "!!!You will not be able to smoke from " .
                             "FTP-archive without it!!!" );
    plan tests => 12;
}

# Can we get away with redefining the Net::FTP stuff?

BEGIN { $^W = 0; } # no warnings 'redefine';
sub Net::FTP::new {
    bless {
        root => File::Spec->catdir( $extra_lib, 'ftppub' ),
        cwd  => File::Spec->catdir( $extra_lib, 'ftppub' ),
    }, 'Net::FTP';
}
sub Net::FTP::login { return 1 }
sub Net::FTP::binary { return 1 }
sub Net::FTP::quit {return 1 }
sub Net::FTP::cwd { 
    my $self = shift;
    my $dir = shift;
    if ( $dir eq '/' ) {
        $self->{cwd} = $self->{root};
    } elsif ( $dir =~ s|^/|| ) {
        $self->{cwd} = File::Spec->catdir( $self->{root}, split m|[/]|, $dir );
    } else {
        $self->{cwd} = File::Spec->catdir( $self->{cwd}, split m|/|, $dir );
    }
#    print "# [NF][cwd $dir] $self->{cwd}\n";
}
sub Net::FTP::pwd {
    my $self = shift;
    File::Spec->abs2rel( $self->{cwd}, $self->{root} );
}
sub Net::FTP::ls { 
    my $self = shift;
    local *DLDIR;
    opendir DLDIR, $self->{cwd} or return ( );
    return map {
        my $fname = $_;
        $^O eq 'VMS' and $fname =~ s/\.(?:DIR)?$//i;
        $fname;
    } grep ! /.svn\b/  => readdir DLDIR;
}
sub Net::FTP::dir {
    my $self = shift;
    my @list = $self->ls;
    my @entries = map {
        my @info = stat File::Spec->catfile( $self->{cwd}, $_ );
        my $fmode = $info[2];
        my @smode = qw( --- --x -w- -wx r-- r-x rw- rwx );
        my( $i, $lslmode ) = ( 0, "" );
        for ( $i = 0; $i < 3; $i++ ) {
            $lslmode = $smode[ $fmode & 07 ] . $lslmode;
            $fmode = $fmode >> 3;
        }
        $lslmode = (-d _ ? "d" : "-" ) . $lslmode;
        my @date = localtime $info[9];
        my $fmnth = sprintf "%03d%02d", @date[5,4];
        my $lmnth = sprintf "%03d%02d", (localtime)[5,4];

        $date[4] = [qw( Jan Feb Mar Apr May Jun
                        Jul Aug Sep Oct Nov Dec )]->[$date[4]];
        $date[5] += 1900;
        my $lsldate;
        if ( $lmnth - $fmnth > 6 ) {
            $lsldate = sprintf "%s %2d %5d", @date[4,3,5];
        } else {
            $lsldate = sprintf "%s %2d %02d:%02d", @date[4,3,2,1];
        }
#        printf "%s  1 %-8s %-8s %10d %12s %s\n", $lslmode, 'ftp', 'ftp',
#                                                 $info[7], $lsldate, $_;
        sprintf "%s  1 %-8s %-8s %10d %12s %s", $lslmode, 'ftp', 'ftp',
                                                 $info[7], $lsldate, $_;
    } @list; 
}
sub Net::FTP::size {
    my $self = shift;
    my $file = File::Spec->catfile( $self->{cwd}, shift );
    return -s $file;
}
sub Net::FTP::mdtm {
    my $self = shift;
    ( stat File::Spec->catfile( $self->{cwd}, shift ))[9];
}
sub Net::FTP::get {
    my $self = shift;
    return if $FTP_FAIL;
    my $source = shift;
    my $file = File::Spec->catfile( $self->{cwd}, $source );
    my $dest = shift || $source;
    local( *SRC, *DST );

    if ( open SRC, "< $file" ) {
        binmode SRC;
        if ( open DST, "> $dest" ) {
            binmode DST;
            print  DST do { local $/; <SRC> };
            close DST;
        } else {
            die "Can't write '$dest': $!";
        }
    } else {
        die "Can't read '$file': $!";
    }
    return $dest;
}
sub Net::FTP::DESTROY { }
BEGIN { $^W = 1; }

# Now begin testing
use_ok      'Test::Smoke::Syncer';
require_ok 'Test::Smoke::SourceTree';

{
    my $stree = catdir $extra_lib, 'perl-59x';
    my $sync = Test::Smoke::Syncer->new( ftp => { v => $ENV{SMOKE_VERBOSE},
       ftphost => 'localhost',
       ftpsdir => '/perl-current',
       ftpcdir => '/perl-current-diffs',
       ddir    => $stree,
    } );

    isa_ok $sync, 'Test::Smoke::Syncer::FTP';
    isa_ok $sync, 'Test::Smoke::Syncer::Base';

    my $plevel = $sync->sync;

    is $plevel, '20005', "Patchlevel ok";

    {
        my $tree = Test::Smoke::SourceTree->new( $stree );
        my $mc = $tree->check_MANIFEST;
    
        is scalar keys %$mc, 0, "No files in manicheck" or
            diag Dumper $mc;
    }

    local *NEWFILE;
    my $newfile = catfile $stree, 'newfile.txt';
    open NEWFILE, "> $newfile";
    print NEWFILE "This will be removed on resync\n";
    close NEWFILE;

    ok -f $newfile, "extra file($newfile)";
    $plevel = $sync->sync;
    is $plevel, '20005', "Patchlevel ok (resync)";

    {
        my $tree = Test::Smoke::SourceTree->new( $stree );
        my $mc = $tree->check_MANIFEST;
    
        is scalar keys %$mc, 0, "No files in manicheck (resync)" or
            diag Dumper $mc;
    }

    ok rmtree( $stree ), "Clean-up";

    $FTP_FAIL = 1;
    $plevel = $sync->sync;
    is $plevel, undef, "no sync on failing FTP";
    
    ok rmtree( $stree ), "Clean-up";
}
