package DBI::Filesystem::DBD::mysql;

use base 'DBI::Filesystem';

# this provides a DSN used during automatic testing by ./Build test
sub test_dsn {
    return "dbi:mysql:dbname=test;user=anonymous";
}

sub _metadata_table_def {
    return <<END;
create table metadata (
    inode        int(10)      auto_increment primary key,
    mode         int(10)      not null,
    uid          int(10)      not null,
    gid          int(10)      not null,
    rdev         int(10)      default 0,
    links        int(10)      default 0,
    inuse        int(10)      default 0,
    size         bigint       default 0,
    mtime        timestamp    default 0,
    ctime        timestamp    default 0,
    atime        timestamp    default 0
) ENGINE=INNODB
END
}

sub _path_table_def {
    return <<END;
create table path (
    parent       int(10),
    name         varchar(255) not null,
    inode        int(10)      not null,
    unique index ipath (parent,name)
) ENGINE=INNODB
END
}

sub _extents_table_def {
    return <<END;
create table extents (
    inode        int(10),
    block        int(10),
    contents     blob,
    unique index iblock (inode,block)
) ENGINE=MYISAM
END
}

sub _xattr_table_def {
    my $self = shift;
    return <<END;
create table xattr (
    inode integer,
    name  varchar(255),
    value varchar(65536),
    unique index ixattr (inode,name)
) ENGINE=INNODB
END
}

# mysql-specific optimization
sub _write_blocks {
    my $self = shift;
    my ($inode,$blocks,$blksize) = @_;

    my $dbh = $self->dbh;
    my ($size) = $dbh->selectrow_array("select size from metadata where inode=$inode");
    my $hwm      = $size;  # high water mark ;-)

    my $tuples = join ',',('(?,?,?)')x(keys %$blocks);
    eval {
	$dbh->begin_work;
	my $sth = $dbh->prepare_cached(<<END) or die $dbh->errstr;
replace into extents (inode,block,contents) values $tuples
END
;
	my @bind = map {($inode,$_,$blocks->{$_})} keys %$blocks;
	$sth->execute(@bind);
	for my $block (keys %$blocks) {
	    my $a   = $block * $blksize + length($blocks->{$block});
	    $hwm    = $a if $a > $hwm;
	}
	$sth->finish;
	my $now = $self->_now_sql;
	$dbh->do("update metadata set size=$hwm,mtime=$now where inode=$inode");
	$dbh->commit();
    };

    if ($@) {
	eval{$dbh->rollback()};
	warn "write failed with $@";
	return;
    }

    1;
}

sub _get_unix_timestamp_sql {
    my $self  = shift;
    my $field = shift;
    return "unix_timestamp($field)";
}

sub _now_sql {
    return 'now()';
}

sub _update_utime_sql {
    return "update metadata set atime=from_unixtime(?),mtime=from_unixtime(?) where inode=?";
}

1;

