#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/ENOENT/;
use Fcntl qw/O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND/;

use Test::MockFile qw< nostrict >;

# Helper: freeze time, perform action, check which timestamps changed.
# We set known timestamps before each action, then check which ones
# advanced past the frozen values after the action.

note "-------------- WRITE UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/write', 'initial' );

    # Record initial timestamps
    my $old_atime = $mock->atime();
    my $old_mtime = $mock->mtime();
    my $old_ctime = $mock->ctime();

    # Set timestamps to a known past value so we can detect updates
    $mock->{'atime'} = 1000;
    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '>', '/ts/write' or die "open: $!";
    print $fh "hello";
    close $fh;

    isnt( $mock->mtime(), 1000, 'print updates mtime' );
    isnt( $mock->ctime(), 1000, 'print updates ctime' );
}

note "-------------- SYSWRITE UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/syswrite', 'initial' );

    $mock->{'atime'} = 1000;
    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    sysopen my $fh, '/ts/syswrite', O_WRONLY or die "sysopen: $!";
    syswrite $fh, "data", 4;
    close $fh;

    isnt( $mock->mtime(), 1000, 'syswrite updates mtime' );
    isnt( $mock->ctime(), 1000, 'syswrite updates ctime' );
}

note "-------------- READ (sysread) UPDATES atime --------------";
{
    my $mock = Test::MockFile->file( '/ts/sysread', 'content' );

    $mock->{'atime'} = 1000;
    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    sysopen my $fh, '/ts/sysread', O_RDONLY or die "sysopen: $!";
    my $buf;
    sysread $fh, $buf, 100;
    close $fh;

    isnt( $mock->atime(), 1000, 'sysread updates atime' );
    is( $mock->mtime(), 1000, 'sysread does not update mtime' );
    is( $mock->ctime(), 1000, 'sysread does not update ctime' );
}

note "-------------- READLINE UPDATES atime --------------";
{
    my $mock = Test::MockFile->file( '/ts/readline', "line1\nline2\n" );

    $mock->{'atime'} = 1000;
    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '<', '/ts/readline' or die "open: $!";
    my $line = <$fh>;
    close $fh;

    isnt( $mock->atime(), 1000, 'readline updates atime' );
    is( $mock->mtime(), 1000, 'readline does not update mtime' );
    is( $mock->ctime(), 1000, 'readline does not update ctime' );
}

note "-------------- READLINE (list context) UPDATES atime --------------";
{
    my $mock = Test::MockFile->file( '/ts/slurp', "a\nb\nc\n" );

    $mock->{'atime'} = 1000;

    open my $fh, '<', '/ts/slurp' or die "open: $!";
    my @lines = <$fh>;
    close $fh;

    isnt( $mock->atime(), 1000, 'readline in list context updates atime' );
    is( scalar @lines, 3, 'read all three lines' );
}

note "-------------- GETC UPDATES atime --------------";
{
    my $mock = Test::MockFile->file( '/ts/getc', 'XY' );

    $mock->{'atime'} = 1000;

    open my $fh, '<', '/ts/getc' or die "open: $!";
    my $c = getc($fh);
    close $fh;

    is( $c, 'X', 'getc returns first character' );
    isnt( $mock->atime(), 1000, 'getc updates atime' );
}

note "-------------- CHMOD UPDATES ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/chmod', 'data' );

    $mock->{'ctime'} = 1000;
    $mock->{'mtime'} = 1000;

    chmod 0644, '/ts/chmod';

    isnt( $mock->ctime(), 1000, 'chmod updates ctime' );
    is( $mock->mtime(), 1000, 'chmod does not update mtime' );
}

note "-------------- CHOWN UPDATES ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/chown', 'data' );

    $mock->{'ctime'} = 1000;
    $mock->{'mtime'} = 1000;

    my ($primary_gid) = split /\s/, $);
    chown $>, $primary_gid, '/ts/chown';

    isnt( $mock->ctime(), 1000, 'chown updates ctime' );
    is( $mock->mtime(), 1000, 'chown does not update mtime' );
}

note "-------------- OPEN > UPDATES mtime/ctime (truncate) --------------";
{
    my $mock = Test::MockFile->file( '/ts/trunc', 'existing content' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '>', '/ts/trunc' or die "open: $!";
    close $fh;

    isnt( $mock->mtime(), 1000, 'open > updates mtime' );
    isnt( $mock->ctime(), 1000, 'open > updates ctime' );
    is( $mock->contents(), '', 'open > truncated contents' );
}

note "-------------- SYSOPEN O_TRUNC UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/systrunc', 'existing' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    sysopen my $fh, '/ts/systrunc', O_WRONLY | O_TRUNC or die "sysopen: $!";
    close $fh;

    isnt( $mock->mtime(), 1000, 'sysopen O_TRUNC updates mtime' );
    isnt( $mock->ctime(), 1000, 'sysopen O_TRUNC updates ctime' );
}

note "-------------- SYSOPEN O_CREAT UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file('/ts/creat');

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    sysopen my $fh, '/ts/creat', O_WRONLY | O_CREAT or die "sysopen: $!";
    close $fh;

    isnt( $mock->mtime(), 1000, 'sysopen O_CREAT on new file updates mtime' );
    isnt( $mock->ctime(), 1000, 'sysopen O_CREAT on new file updates ctime' );
}

note "-------------- OPEN >> does NOT update until write --------------";
{
    my $mock = Test::MockFile->file( '/ts/append', 'data' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '>>', '/ts/append' or die "open: $!";

    # Opening in append mode alone shouldn't update timestamps
    is( $mock->mtime(), 1000, 'open >> alone does not update mtime' );
    is( $mock->ctime(), 1000, 'open >> alone does not update ctime' );

    print $fh "more";
    close $fh;

    isnt( $mock->mtime(), 1000, 'writing in append mode updates mtime' );
    isnt( $mock->ctime(), 1000, 'writing in append mode updates ctime' );
}

note "-------------- READ+WRITE updates both atime and mtime --------------";
{
    my $mock = Test::MockFile->file( '/ts/rw', 'hello' );

    $mock->{'atime'} = 1000;
    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '+<', '/ts/rw' or die "open: $!";
    my $line = <$fh>;    # read
    print $fh "world";   # write
    close $fh;

    isnt( $mock->atime(), 1000, 'read in +< mode updates atime' );
    isnt( $mock->mtime(), 1000, 'write in +< mode updates mtime' );
    isnt( $mock->ctime(), 1000, 'write in +< mode updates ctime' );
}

note "-------------- PRINTF UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/printf', '' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '>', '/ts/printf' or die "open: $!";
    printf $fh "num=%d", 42;
    close $fh;

    isnt( $mock->mtime(), 1000, 'printf updates mtime' );
    isnt( $mock->ctime(), 1000, 'printf updates ctime' );
    is( $mock->contents(), 'num=42', 'printf wrote correctly' );
}

note "-------------- TRUNCATE UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/truncpath', 'some content here' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;
    $mock->{'atime'} = 1000;

    truncate '/ts/truncpath', 5;

    isnt( $mock->mtime(), 1000, 'truncate by path updates mtime' );
    isnt( $mock->ctime(), 1000, 'truncate by path updates ctime' );
    is( $mock->contents(), 'some ', 'truncate shortened contents' );
}

note "-------------- TRUNCATE via FH UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/truncfh', 'file data here' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    open my $fh, '+<', '/ts/truncfh' or die "open: $!";
    truncate $fh, 4;
    close $fh;

    isnt( $mock->mtime(), 1000, 'truncate via fh updates mtime' );
    isnt( $mock->ctime(), 1000, 'truncate via fh updates ctime' );
    is( $mock->contents(), 'file', 'truncate via fh shortened contents' );
}

note "-------------- TRUNCATE extend UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/truncext', 'ab' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    truncate '/ts/truncext', 5;

    isnt( $mock->mtime(), 1000, 'truncate extend updates mtime' );
    isnt( $mock->ctime(), 1000, 'truncate extend updates ctime' );
    is( length( $mock->contents() ), 5, 'truncate extended to 5 bytes' );
}

note "-------------- TRUNCATE same length still UPDATES mtime/ctime --------------";
{
    my $mock = Test::MockFile->file( '/ts/truncsame', 'abc' );

    $mock->{'mtime'} = 1000;
    $mock->{'ctime'} = 1000;

    truncate '/ts/truncsame', 3;

    isnt( $mock->mtime(), 1000, 'truncate to same length updates mtime' );
    isnt( $mock->ctime(), 1000, 'truncate to same length updates ctime' );
}

note "-------------- LINK UPDATES parent dir mtime/ctime --------------";
{
    my $dir  = Test::MockFile->new_dir('/ts/linkdir');
    my $src  = Test::MockFile->file( '/ts/linkdir/source', 'data' );
    my $dest = Test::MockFile->file('/ts/linkdir/dest');

    $dir->{'mtime'} = 1000;
    $dir->{'ctime'} = 1000;

    link '/ts/linkdir/source', '/ts/linkdir/dest';

    isnt( $dir->mtime(), 1000, 'link updates parent dir mtime' );
    isnt( $dir->ctime(), 1000, 'link updates parent dir ctime' );
}

note "-------------- SYMLINK UPDATES parent dir mtime/ctime --------------";
{
    my $dir  = Test::MockFile->new_dir('/ts/symlinkdir');
    my $link = Test::MockFile->file('/ts/symlinkdir/mylink');

    $dir->{'mtime'} = 1000;
    $dir->{'ctime'} = 1000;

    symlink '/some/target', '/ts/symlinkdir/mylink';

    isnt( $dir->mtime(), 1000, 'symlink updates parent dir mtime' );
    isnt( $dir->ctime(), 1000, 'symlink updates parent dir ctime' );
}

note "-------------- RENAME UPDATES both parent dirs mtime/ctime --------------";
{
    my $old_dir = Test::MockFile->new_dir('/ts/olddir');
    my $new_dir = Test::MockFile->new_dir('/ts/newdir');
    my $file    = Test::MockFile->file( '/ts/olddir/moveme', 'content' );
    my $dest    = Test::MockFile->file('/ts/newdir/moved');

    $old_dir->{'mtime'} = 1000;
    $old_dir->{'ctime'} = 1000;
    $new_dir->{'mtime'} = 1000;
    $new_dir->{'ctime'} = 1000;

    rename '/ts/olddir/moveme', '/ts/newdir/moved';

    isnt( $old_dir->mtime(), 1000, 'rename updates old parent dir mtime' );
    isnt( $old_dir->ctime(), 1000, 'rename updates old parent dir ctime' );
    isnt( $new_dir->mtime(), 1000, 'rename updates new parent dir mtime' );
    isnt( $new_dir->ctime(), 1000, 'rename updates new parent dir ctime' );
}

note "-------------- RENAME same dir UPDATES parent dir mtime/ctime --------------";
{
    my $dir  = Test::MockFile->new_dir('/ts/samedir');
    my $old  = Test::MockFile->file( '/ts/samedir/old', 'data' );
    my $new  = Test::MockFile->file('/ts/samedir/new');

    $dir->{'mtime'} = 1000;
    $dir->{'ctime'} = 1000;

    rename '/ts/samedir/old', '/ts/samedir/new';

    isnt( $dir->mtime(), 1000, 'rename within same dir updates parent mtime' );
    isnt( $dir->ctime(), 1000, 'rename within same dir updates parent ctime' );
}

done_testing();
exit;
