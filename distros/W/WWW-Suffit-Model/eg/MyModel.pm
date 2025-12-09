package MyModel;
use strict;
use utf8;

use parent qw/WWW::Suffit::Model/;

use constant DML_ADD => <<'DML';
INSERT INTO `test`
  (`comment`)
VALUES
  (?)
DML

use constant DML_GET => <<'DML';
SELECT `id`,`comment`
FROM `test`
WHERE `id` = ?
DML

use constant DML_SET => <<'DML';
UPDATE `test`
SET `comment` = ?
WHERE `id` = ?
DML

use constant DML_DEL => <<'DML';
DELETE FROM `test`
WHERE `id` = ?
DML

use constant DML_ALL => <<'DML';
SELECT `id`,`comment`
FROM `test`
ORDER BY `id` ASC
LIMIT 100
DML

use constant DML_CNT => <<'DML';
SELECT COUNT(`id`) AS `cnt`
FROM `test`
DML

sub comment_add {
    my $self = shift;
    my %data = @_;
    return unless $self->ping;

    # Add
    $self->query(DML_ADD,
        $data{comment},
    ) or return 0;

    # Ok
    return 1;
}
sub comment_set {
    my $self = shift;
    my %data = @_;
    return 0 unless $self->ping;

    # Set by id or num
    $self->query(DML_SET,
        $data{comment},
        $data{id},
    ) or return 0;

    # Ok
    return 1;
}
sub comment_get {
    my $self = shift;
    return () unless $self->ping;
    my $id = shift || 0;

    # Get all data as table
    unless ($id) {
        my $tbl = {};
        if (my $res = $self->query(DML_ALL)) {
            $tbl = $res->hashes;
            return (@$tbl);
        }
        return (); # No data or error
    }

    # Get data
    if (my $res = $self->query(DML_GET, $id)) {
        my $r = $res->hash;
        my %rec = ();
           %rec = (%$r) if ref($r) eq 'HASH';
        # Ok
        return %rec;
    }

    # No data or error
    return ();
}
sub comment_del {
    my $self = shift;
    my $id = shift || 0;
    return 1 unless $id;
    return 0 unless $self->ping;

    # Delete
    $self->query(DML_DEL, $id) or return 0;

    # Ok
    return 1;
}
sub comment_cnt {
    my $self = shift;
    return 0 unless $self->ping;

    if (my $res = $self->query(DML_CNT)) {
        my $r = $res->hash;
        return $r->{cnt} || 0 if ref($r) eq 'HASH';
    }

    return 0;
}

1;

__DATA__

@@ schema_sqlite

-- # main
CREATE TABLE IF NOT EXISTS "test" (
  "id"          INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
  "comment"     TEXT DEFAULT NULL -- Comment
);
