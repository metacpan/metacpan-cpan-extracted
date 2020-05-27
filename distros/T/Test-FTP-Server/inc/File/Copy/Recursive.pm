#line 1
package File::Copy::Recursive;

use strict;

BEGIN {
    # Keep older versions of Perl from trying to use lexical warnings
    $INC{'warnings.pm'} = "fake warnings entry for < 5.6 perl ($])" if $] < 5.006;
}
use warnings;

use Carp;
use File::Copy;
use File::Spec;    #not really needed because File::Copy already gets it, but for good measure :)
use Cwd ();

use vars qw(
  @ISA      @EXPORT_OK $VERSION  $MaxDepth $KeepMode $CPRFComp $CopyLink
  $PFSCheck $RemvBase $NoFtlPth  $ForcePth $CopyLoop $RMTrgFil $RMTrgDir
  $CondCopy $BdTrgWrn $SkipFlop  $DirPerms
);

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(fcopy rcopy dircopy fmove rmove dirmove pathmk pathrm pathempty pathrmdir rcopy_glob rmove_glob);

$VERSION = '0.45';

$MaxDepth = 0;
$KeepMode = 1;
$CPRFComp = 0;
$CopyLink = eval { local $SIG{'__DIE__'}; symlink '', ''; 1 } || 0;
$PFSCheck = 1;
$RemvBase = 0;
$NoFtlPth = 0;
$ForcePth = 0;
$CopyLoop = 0;
$RMTrgFil = 0;
$RMTrgDir = 0;
$CondCopy = {};
$BdTrgWrn = 0;
$SkipFlop = 0;
$DirPerms = 0777;

my $samecheck = sub {
    return 1 if $^O eq 'MSWin32';    # need better way to check for this on winders...
    return if @_ != 2 || !defined $_[0] || !defined $_[1];
    return if $_[0] eq $_[1];

    my $one = '';
    if ($PFSCheck) {
        $one = join( '-', ( stat $_[0] )[ 0, 1 ] ) || '';
        my $two = join( '-', ( stat $_[1] )[ 0, 1 ] ) || '';
        if ( $one eq $two && $one ) {
            carp "$_[0] and $_[1] are identical";
            return;
        }
    }

    if ( -d $_[0] && !$CopyLoop ) {
        $one = join( '-', ( stat $_[0] )[ 0, 1 ] ) if !$one;
        my $abs = File::Spec->rel2abs( $_[1] );
        my @pth = File::Spec->splitdir($abs);
        while (@pth) {
            if ( $pth[-1] eq '..' ) {    # cheaper than Cwd::realpath() plus we don't want to resolve symlinks at this point, right?
                pop @pth;
                pop @pth unless -l File::Spec->catdir(@pth);
                next;
            }
            my $cur = File::Spec->catdir(@pth);
            last if !$cur;               # probably not necessary, but nice to have just in case :)
            my $two = join( '-', ( stat $cur )[ 0, 1 ] ) || '';
            if ( $one eq $two && $one ) {

                # $! = 62; # Too many levels of symbolic links
                carp "Caught Deep Recursion Condition: $_[0] contains $_[1]";
                return;
            }

            pop @pth;
        }
    }

    return 1;
};

my $glob = sub {
    my ( $do, $src_glob, @args ) = @_;

    local $CPRFComp = 1;
    require File::Glob;

    my @rt;
    for my $path ( File::Glob::bsd_glob($src_glob) ) {
        my @call = [ $do->( $path, @args ) ] or return;
        push @rt, \@call;
    }

    return @rt;
};

my $move = sub {
    my $fl = shift;
    my @x;
    if ($fl) {
        @x = fcopy(@_) or return;
    }
    else {
        @x = dircopy(@_) or return;
    }
    if (@x) {
        if ($fl) {
            unlink $_[0] or return;
        }
        else {
            pathrmdir( $_[0] ) or return;
        }
        if ($RemvBase) {
            my ( $volm, $path ) = File::Spec->splitpath( $_[0] );
            pathrm( File::Spec->catpath( $volm, $path, '' ), $ForcePth, $NoFtlPth ) or return;
        }
    }
    return wantarray ? @x : $x[0];
};

my $ok_todo_asper_condcopy = sub {
    my $org  = shift;
    my $copy = 1;
    if ( exists $CondCopy->{$org} ) {
        if ( $CondCopy->{$org}{'md5'} ) {

        }
        if ($copy) {

        }
    }
    return $copy;
};

sub fcopy {
    $samecheck->(@_) or return;
    if ( $RMTrgFil && ( -d $_[1] || -e $_[1] ) ) {
        my $trg = $_[1];
        if ( -d $trg ) {
            my @trgx = File::Spec->splitpath( $_[0] );
            $trg = File::Spec->catfile( $_[1], $trgx[$#trgx] );
        }
        $samecheck->( $_[0], $trg ) or return;
        if ( -e $trg ) {
            if ( $RMTrgFil == 1 ) {
                unlink $trg or carp "\$RMTrgFil failed: $!";
            }
            else {
                unlink $trg or return;
            }
        }
    }
    my ( $volm, $path ) = File::Spec->splitpath( $_[1] );
    if ( $path && !-d $path ) {
        pathmk( File::Spec->catpath( $volm, $path, '' ), $NoFtlPth );
    }
    if ( -l $_[0] && $CopyLink ) {
        my $target = readlink( shift() );
        ($target) = $target =~ m/(.*)/;    # mass-untaint is OK since we have to allow what the file system does
        carp "Copying a symlink ($_[0]) whose target does not exist"
          if !-e $target && $BdTrgWrn;
        my $new = shift();
        unlink $new if -l $new;
        symlink( $target, $new ) or return;
    }
    elsif ( -d $_[0] && -f $_[1] ) {
        return;
    }
    else {
        return if -d $_[0];                # address File::Copy::copy() bug outlined in https://rt.perl.org/Public/Bug/Display.html?id=132866
        copy(@_) or return;

        my @base_file = File::Spec->splitpath( $_[0] );
        my $mode_trg = -d $_[1] ? File::Spec->catfile( $_[1], $base_file[$#base_file] ) : $_[1];

        chmod scalar( ( stat( $_[0] ) )[2] ), $mode_trg if $KeepMode;
    }
    return wantarray ? ( 1, 0, 0 ) : 1;    # use 0's incase they do math on them and in case rcopy() is called in list context = no uninit val warnings
}

sub rcopy {
    if ( -l $_[0] && $CopyLink ) {
        goto &fcopy;
    }

    goto &dircopy if -d $_[0] || substr( $_[0], ( 1 * -1 ), 1 ) eq '*';
    goto &fcopy;
}

sub rcopy_glob {
    $glob->( \&rcopy, @_ );
}

sub dircopy {
    if ( $RMTrgDir && -d $_[1] ) {
        if ( $RMTrgDir == 1 ) {
            pathrmdir( $_[1] ) or carp "\$RMTrgDir failed: $!";
        }
        else {
            pathrmdir( $_[1] ) or return;
        }
    }
    my $globstar = 0;
    my $_zero    = $_[0];
    my $_one     = $_[1];
    if ( substr( $_zero, ( 1 * -1 ), 1 ) eq '*' ) {
        $globstar = 1;
        $_zero = substr( $_zero, 0, ( length($_zero) - 1 ) );
    }

    $samecheck->( $_zero, $_[1] ) or return;
    if ( !-d $_zero || ( -e $_[1] && !-d $_[1] ) ) {
        $! = 20;
        return;
    }

    if ( !-d $_[1] ) {
        pathmk( $_[1], $NoFtlPth ) or return;
    }
    else {
        if ( $CPRFComp && !$globstar ) {
            my @parts = File::Spec->splitdir($_zero);
            while ( $parts[$#parts] eq '' ) { pop @parts; }
            $_one = File::Spec->catdir( $_[1], $parts[$#parts] );
        }
    }
    my $baseend = $_one;
    my $level   = 0;
    my $filen   = 0;
    my $dirn    = 0;

    my $recurs;    #must be my()ed before sub {} since it calls itself
    $recurs = sub {
        my ( $str, $end, $buf ) = @_;
        $filen++ if $end eq $baseend;
        $dirn++  if $end eq $baseend;

        $DirPerms = oct($DirPerms) if substr( $DirPerms, 0, 1 ) eq '0';
        mkdir( $end, $DirPerms ) or return if !-d $end;
        if ( $MaxDepth && $MaxDepth =~ m/^\d+$/ && $level >= $MaxDepth ) {
            chmod scalar( ( stat($str) )[2] ), $end if $KeepMode;
            return ( $filen, $dirn, $level ) if wantarray;
            return $filen;
        }

        $level++;

        my @files;
        if ( $] < 5.006 ) {
            opendir( STR_DH, $str ) or return;
            @files = grep( $_ ne '.' && $_ ne '..', readdir(STR_DH) );
            closedir STR_DH;
        }
        else {
            opendir( my $str_dh, $str ) or return;
            @files = grep( $_ ne '.' && $_ ne '..', readdir($str_dh) );
            closedir $str_dh;
        }

        for my $file (@files) {
            my ($file_ut) = $file =~ m{ (.*) }xms;
            my $org = File::Spec->catfile( $str, $file_ut );
            my $new = File::Spec->catfile( $end, $file_ut );
            if ( -l $org && $CopyLink ) {
                my $target = readlink($org);
                ($target) = $target =~ m/(.*)/;    # mass-untaint is OK since we have to allow what the file system does
                carp "Copying a symlink ($org) whose target does not exist"
                  if !-e $target && $BdTrgWrn;
                unlink $new if -l $new;
                symlink( $target, $new ) or return;
            }
            elsif ( -d $org ) {
                my $rc;
                if ( !-w $org && $KeepMode ) {
                    local $KeepMode = 0;
                    $rc = $recurs->( $org, $new, $buf ) if defined $buf;
                    $rc = $recurs->( $org, $new ) if !defined $buf;
                    chmod scalar( ( stat($org) )[2] ), $new;
                }
                else {
                    $rc = $recurs->( $org, $new, $buf ) if defined $buf;
                    $rc = $recurs->( $org, $new ) if !defined $buf;
                }
                if ( !$rc ) {
                    if ($SkipFlop) {
                        next;
                    }
                    else {
                        return;
                    }
                }
                $filen++;
                $dirn++;
            }
            else {
                if ( $ok_todo_asper_condcopy->($org) ) {
                    if ($SkipFlop) {
                        fcopy( $org, $new, $buf ) or next if defined $buf;
                        fcopy( $org, $new ) or next if !defined $buf;
                    }
                    else {
                        fcopy( $org, $new, $buf ) or return if defined $buf;
                        fcopy( $org, $new ) or return if !defined $buf;
                    }
                    chmod scalar( ( stat($org) )[2] ), $new if $KeepMode;
                    $filen++;
                }
            }
        }
        $level--;
        chmod scalar( ( stat($str) )[2] ), $end if $KeepMode;
        1;

    };

    $recurs->( $_zero, $_one, $_[2] ) or return;
    return wantarray ? ( $filen, $dirn, $level ) : $filen;
}

sub fmove { $move->( 1, @_ ) }

sub rmove {
    if ( -l $_[0] && $CopyLink ) {
        goto &fmove;
    }

    goto &dirmove if -d $_[0] || substr( $_[0], ( 1 * -1 ), 1 ) eq '*';
    goto &fmove;
}

sub rmove_glob {
    $glob->( \&rmove, @_ );
}

sub dirmove { $move->( 0, @_ ) }

sub pathmk {
    my ( $vol, $dir, $file ) = File::Spec->splitpath( shift() );
    my $nofatal = shift;

    $DirPerms = oct($DirPerms) if substr( $DirPerms, 0, 1 ) eq '0';

    if ( defined($dir) ) {
        my (@dirs) = File::Spec->splitdir($dir);

        for ( my $i = 0; $i < scalar(@dirs); $i++ ) {
            my $newdir = File::Spec->catdir( @dirs[ 0 .. $i ] );
            my $newpth = File::Spec->catpath( $vol, $newdir, "" );

            mkdir( $newpth, $DirPerms ) or return if !-d $newpth && !$nofatal;
            mkdir( $newpth, $DirPerms ) if !-d $newpth && $nofatal;
        }
    }

    if ( defined($file) ) {
        my $newpth = File::Spec->catpath( $vol, $dir, $file );

        mkdir( $newpth, $DirPerms ) or return if !-d $newpth && !$nofatal;
        mkdir( $newpth, $DirPerms ) if !-d $newpth && $nofatal;
    }

    1;
}

sub pathempty {
    my $pth = shift;

    my ( $orig_dev, $orig_ino ) = ( lstat $pth )[ 0, 1 ];
    return 2 if !-d _ || !defined($orig_dev) || ( $^O ne 'MSWin32' && !$orig_ino );    #stat.inode is 0 on Windows

    my $starting_point = Cwd::cwd();
    my ( $starting_dev, $starting_ino ) = ( lstat $starting_point )[ 0, 1 ];
    chdir($pth) or Carp::croak("Failed to change directory to “$pth”: $!");
    $pth = '.';
    _bail_if_changed( $pth, $orig_dev, $orig_ino );

    my @names;
    my $pth_dh;
    if ( $] < 5.006 ) {
        opendir( PTH_DH, $pth ) or return;
        @names = grep !/^\.\.?$/, readdir(PTH_DH);
        closedir PTH_DH;
    }
    else {
        opendir( $pth_dh, $pth ) or return;
        @names = grep !/^\.\.?$/, readdir($pth_dh);
        closedir $pth_dh;
    }
    _bail_if_changed( $pth, $orig_dev, $orig_ino );

    for my $name (@names) {
        my ($name_ut) = $name =~ m{ (.*) }xms;
        my $flpth = File::Spec->catdir( $pth, $name_ut );

        if ( -l $flpth ) {
            _bail_if_changed( $pth, $orig_dev, $orig_ino );
            unlink $flpth or return;
        }
        elsif ( -d $flpth ) {
            _bail_if_changed( $pth, $orig_dev, $orig_ino );
            pathrmdir($flpth) or return;
        }
        else {
            _bail_if_changed( $pth, $orig_dev, $orig_ino );
            unlink $flpth or return;
        }
    }

    chdir($starting_point) or Carp::croak("Failed to change directory to “$starting_point”: $!");
    _bail_if_changed( ".", $starting_dev, $starting_ino );

    return 1;
}

sub pathrm {
    my ( $path, $force, $nofail ) = @_;

    my ( $orig_dev, $orig_ino ) = ( lstat $path )[ 0, 1 ];
    return 2 if !-d _ || !defined($orig_dev) || !$orig_ino;

    # Manual test (I hate this function :/):
    #    sudo mkdir /foo && perl -MFile::Copy::Recursive=pathrm -le 'print pathrm("/foo",1)' && sudo rm -rf /foo
    if ( $force && File::Spec->file_name_is_absolute($path) ) {
        Carp::croak("pathrm() w/ force on abspath is not allowed");
    }

    my @pth = File::Spec->splitdir($path);

    my %fs_check;
    my $aggregate_path;
    for my $part (@pth) {
        $aggregate_path = defined $aggregate_path ? File::Spec->catdir( $aggregate_path, $part ) : $part;
        $fs_check{$aggregate_path} = [ ( lstat $aggregate_path )[ 0, 1 ] ];
    }

    while (@pth) {
        my $cur = File::Spec->catdir(@pth);
        last if !$cur;    # necessary ???

        if ($force) {
            _bail_if_changed( $cur, $fs_check{$cur}->[0], $fs_check{$cur}->[1] );
            if ( !pathempty($cur) ) {
                return unless $nofail;
            }
        }
        _bail_if_changed( $cur, $fs_check{$cur}->[0], $fs_check{$cur}->[1] );
        if ($nofail) {
            rmdir $cur;
        }
        else {
            rmdir $cur or return;
        }
        pop @pth;
    }

    return 1;
}

sub pathrmdir {
    my $dir = shift;
    if ( -e $dir ) {
        return if !-d $dir;
    }
    else {
        return 2;
    }

    my ( $orig_dev, $orig_ino ) = ( lstat $dir )[ 0, 1 ];
    return 2 if !defined($orig_dev) || ( $^O ne 'MSWin32' && !$orig_ino );

    pathempty($dir) or return;
    _bail_if_changed( $dir, $orig_dev, $orig_ino );
    rmdir $dir or return;

    return 1;
}

sub _bail_if_changed {
    my ( $path, $orig_dev, $orig_ino ) = @_;

    my ( $cur_dev, $cur_ino ) = ( lstat $path )[ 0, 1 ];

    if ( !defined $cur_dev || !defined $cur_ino ) {
        $cur_dev ||= "undef(path went away?)";
        $cur_ino ||= "undef(path went away?)";
    }
    else {
        $path = Cwd::abs_path($path);
    }

    if ( $orig_dev ne $cur_dev || $orig_ino ne $cur_ino ) {
        local $Carp::CarpLevel += 1;
        Carp::croak("directory $path changed: expected dev=$orig_dev ino=$orig_ino, actual dev=$cur_dev ino=$cur_ino, aborting");
    }
}

1;

__END__

#line 808
