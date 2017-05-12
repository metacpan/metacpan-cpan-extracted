package DBI::Filesystem::DBD::Pg;

use strict;
use warnings;
use base 'DBI::Filesystem';
use DBD::Pg 'PG_BYTEA';

# this provides a DSN used during automatic testing by ./Build test
sub test_dsn {
    return "dbi:Pg:dbname=postgres";
}

# called after database handle is first created to do extra preparation on it
sub _dbh_init {
    my ($self,$dbh) = @_;
    $dbh->do('set client_min_messages to WARNING');
}

sub _metadata_table_def {
    return <<END;
create table metadata (
    inode        serial       primary key,
    mode         integer      not null,
    uid          integer      not null,
    gid          integer      not null,
    rdev         integer      default 0,
    links        integer      default 0,
    inuse        integer      default 0,
    size         bigint       default 0,
    mtime        timestamp,
    ctime        timestamp,
    atime        timestamp
)
END
}

sub _path_table_def {
    return <<END;
create table path (
    inode        integer      not null,
    name         varchar(255) not null,
    parent       integer
);
    create unique index ipath on path (parent,name)
END
}

sub _extents_table_def {
    return <<END;
create table extents (
    inode        integer,
    block        integer,
    contents     bytea
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
    return "extract(epoch from $field)";
}

sub _now_sql {
    return "'now'";
}

sub _update_utime_sql {
    return "update metadata set atime=to_timestamp(?),mtime=to_timestamp(?) where inode=?";
}

sub _write_blocks {
    my $self = shift;
    my ($inode,$blocks,$blksize) = @_;

    my $dbh = $self->dbh;
    my ($size) = $dbh->selectrow_array("select size from metadata where inode=$inode");
    my $hwm      = $size;  # high water mark ;-)

    eval {
	$dbh->begin_work;
	my $insert = $dbh->prepare_cached(<<END) or die $dbh->errstr;
insert into extents (inode,block,contents) values (?,?,?)
END
;
	$insert->bind_param(3,undef,{pg_type=>PG_BYTEA});

	my $update = $dbh->prepare_cached(<<END) or die $dbh->errstr;
update extents set contents=? where inode=? and block=?
END
;
	$update->bind_param(1,undef,{pg_type=>PG_BYTEA});


	for my $block (keys %$blocks) {
	    my $data = $blocks->{$block};
	    $update->execute($data,$inode,$block);
	    $insert->execute($inode,$block,$data) unless $update->rows;
	    my $a   = $block * $blksize + length($data);
	    $hwm    = $a if $a > $hwm;
	}
	$insert->finish;
	$update->finish;
	my $now = $self->_now_sql;
	$dbh->do("update metadata set size=$hwm,mtime=$now where inode=$inode");
	$dbh->commit();
    };

    if ($@) {
	my $msg = $@;
	eval{$dbh->rollback()};
	warn $msg;
	die "write failed with $msg";
    }

    1;
}

sub last_inserted_inode {
    my $self = shift;
    my $dbh  = shift;
    return $dbh->last_insert_id(undef,undef,'metadata','inode');
}

sub set_schema_version {
    my $self = shift;
    my $version = shift;
    my $dbh = $self->dbh;
    eval {
	$dbh->begin_work;
	$dbh->do("delete from sqlfs_vars where name='schema_version'");
	$dbh->do("insert into sqlfs_vars (name,value) values ('schema_version','$version')");
	$dbh->commit;
    };
    if ($@) {
	warn $@;
	eval {$dbh->rollback()};
    }
}

sub setxattr {
    my $self = shift;
    my ($path,$xname,$xval,$xflags) = @_;
    if (!$xflags) {
	my $inode = $self->path2inode($path);
	my $dbh = $self->dbh;
	eval {
	    my $name = $dbh->quote($xname);
	    $dbh->begin_work;
	    $dbh->do("delete from xattr where name=$name and inode=$inode");
	    my $sth = $dbh->prepare_cached("insert into xattr(inode,name,value) values (?,?,?)");
	    $sth->execute($inode,$xname,$xval);
	    $sth->finish;
	    $dbh->commit();
	};
	if ($@) {
	    my $msg = $@;
	    eval {$dbh->rollback()};
	    die "could not update attribute because: $msg";
	}
	return 0;
    }

    # we get here when we have a definite insert/update operation to perform
    return $self->SUPER::setxattr(@_);
}

sub _update_schema_from_1_to_2 {
    my $self = shift;
    my $dbh  = $self->dbh;
    $dbh->do('alter table metadata rename column length to size');
    $dbh->do($self->_variables_table_def);
}
1;

