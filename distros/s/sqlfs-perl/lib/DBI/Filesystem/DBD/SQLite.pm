package DBI::Filesystem::DBD::SQLite;

use strict;
use warnings;
use base 'DBI::Filesystem';
use File::Temp;

# this method provides a DSN used by ./Build test
sub test_dsn {
    my $self = shift;
    our $tmpdir  = File::Temp->newdir();
    my $testfile = "$tmpdir/filesystem.sql";
    my $dsn      = "dbi:SQLite:dbname=$testfile";
}

#sub blocksize   { return 16384 }
sub flushblocks { return   256 }

# called after database handle is first created to do extra preparation on it
sub _dbh_init {
    my $self = shift;
    my $dbh = shift;
    $dbh->do('PRAGMA synchronous = OFF');
}

sub _metadata_table_def {
    return <<END;
create table metadata (
    inode        integer      primary key autoincrement,
    mode         int(10)      not null,
    uid          int(10)      not null,
    gid          int(10)      not null,
    rdev         int(10)      default 0,
    links        int(10)      default 0,
    inuse        int(10)      default 0,
    size         bigint       default 0,
    mtime        integer,
    ctime        integer,
    atime        integer
)
END
}

sub _path_table_def {
    return <<END;
create table path (
    inode        int(10)      not null,
    name         varchar(255) not null,
    parent       int(10)
);
    create unique index ipath on path (parent,name)
END
}

sub _extents_table_def {
    return <<END;
create table extents (
    inode        int(10),
    block        int(10),
    contents     blob
);
    create unique index iblock on extents (inode,block)
END
}

sub _xattr_table_def {
    my $self = shift;
    return <<END;
create table xattr (
    inode integer,
    name  varchar(255),
    value varchar(65536)
    );
    create unique index ixattr on xattr (inode,name)
END
}


sub _get_unix_timestamp_sql {
    my $self  = shift;
    my $field = shift;
    return $field;
}

sub _now_sql {
    return "strftime('%s','now')";
}

sub _update_utime_sql {
    return "update metadata set atime=?,mtime=? where inode=?";
}

sub _update_schema_from_1_to_2 {
    my $self = shift;
    my $dbh  = $self->dbh;
    $dbh->do('alter table metadata rename to metadata_old');
    $dbh->do($self->_metadata_table_def);
    $dbh->do($self->_variables_table_def);
    $dbh->do('insert into metadata  select * from metadata_old');
    $dbh->do('drop table metadata_old');
}

1;

