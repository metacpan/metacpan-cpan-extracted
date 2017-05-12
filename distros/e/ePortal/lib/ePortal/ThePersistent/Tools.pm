#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------


package ePortal::ThePersistent::Tools;
    our $VERSION = '4.5';

    # Export section
    our @EXPORT = qw/
            &table_exists &column_exists &index_exists &column_type
            &table_size
            &DO_SQL
            /;
    require Exporter;
    use base qw/Exporter/;

    use ePortal::Global;

############################################################################
sub table_exists    {   #08/03/01 1:54
############################################################################
    my $dbh = shift;
    my $table = shift;

    if (!$dbh or !$table) {
        die "Usage: table_exists(dbh,table_name)\n";
    }

    my $found;
    my $sth = $dbh->prepare("show tables like '$table'");
    $table = lc $table;
    $sth->execute();
    while(my @ary = $sth->fetchrow_array) {
        $found = 1 if lc($ary[0]) eq $table;
    }
    $sth->finish;
    return $found;

# $dbh->table_info;
#
#TABLE_CAT: Table catalog identifier. This field is NULL (undef) if not
#applicable to the data source, which is usually the case. This field is
#empty if not applicable to the table.

#TABLE_SCHEM: The name of the schema containing the TABLE_NAME value. This
#field is NULL (undef) if not applicable to data source, and empty if not
#applicable to the table.

#TABLE_NAME: Name of the table (or view, synonym, etc).

#TABLE_TYPE: One of the following: ``TABLE'', ``VIEW'', ``SYSTEM TABLE'',
#``GLOBAL TEMPORARY'', ``LOCAL TEMPORARY'', ``ALIAS'', ``SYNONYM'' or a type
#identifier that is specific to the data source.

#REMARKS: A description of the table. May be NULL (undef).
}##table_exists


############################################################################
# Returns current data_length in scalar context
# Returns (data_length, Max_data_length) in list context
############################################################################
sub table_size  {   #10/01/2003 4:56
############################################################################
    my $dbh = shift;
    my $table = shift;

    if (!$dbh or !$table) {
        die "Usage: table_size(dbh,table_name)\n";
    }

    my @ary = $dbh->selectrow_array("show table status like '$table'");
    return wantarray ? ($ary[5], $ary[6]) : $ary[5];
}##table_size

# show table status like 'tablename'
#  show table status like 'user';
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+
#| Name | Type   | Row_format | Rows | Avg_row_length | Data_length | Max_data_length | Index_length | Data_free | Auto_increment | Create_time         | Update_time         | Check_time | Create_options | Comment                     |
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+
#| user | MyISAM | Dynamic    |    9 |             59 |         532 |      4294967295 |         2048 |         0 |           NULL | 2003-09-11 13:46:19 | 2003-09-11 13:46:19 | NULL       |                | Users and global privileges |
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+


#mysql> desc MsgForum;
#+-------------+--------------+------+-----+---------+----------------+
#| Field       | Type         | Null | Key | Default | Extra          |
#+-------------+--------------+------+-----+---------+----------------+
#| id          | int(11)      |      | PRI | NULL    | auto_increment |
#| titleurl    | decimal(2,0) |      |     | 0       |                |
#| title       | varchar(255) | YES  |     | NULL    |                |
#| nickname    | varchar(255) | YES  |     | NULL    |                |
#| memo        | varchar(255) | YES  |     | NULL    |                |
#| keepdays    | decimal(9,0) | YES  |     | NULL    |                |
#| uid         | varchar(64)  | YES  |     | NULL    |                |
#| xacl_read   | varchar(64)  | YES  |     | NULL    |                |
#| xacl_post   | varchar(64)  | YES  |     | NULL    |                |
#| xacl_reply  | varchar(64)  | YES  |     | NULL    |                |
#| xacl_edit   | varchar(64)  | YES  |     | NULL    |                |
#| xacl_delete | varchar(64)  | YES  |     | NULL    |                |
#+-------------+--------------+------+-----+---------+----------------+

############################################################################
sub column_exists   {   #08/03/01 2:20
############################################################################
    my $dbh = shift;
    my $table = shift;
    my $column = lc shift;

    if (!$dbh or !$table or !$column) {
        die "Usage: column_exists(dbh,table_name,column_name)\n";
    }

    my $found;
    my $sth = $dbh->prepare("DESC $table");
    $sth->execute;
    while(my @ary = $sth->fetchrow_array) {
        $found = 1 if lc($ary[0]) eq $column;
    }
    $sth->finish;
    return $found;
}##column_exists


############################################################################
sub column_type {   #14.12.2002 16:09
############################################################################
    my $dbh = shift;
    my $table = shift;
    my $column = lc shift;

    if (!$dbh or !$table or !$column) {
        die "Usage: column_type(dbh,table_name,column_name)\n";
    }

    my $ctype;
    my $sth = $dbh->prepare("DESC $table");
    $sth->execute;
    while(my @ary = $sth->fetchrow_array) {
        if (lc($ary[0]) eq $column) {
            $ctype = $ary[1] . ' ' . $ary[5]; # type_extra
                                              # extra is used for autoincrement
        }
    }
    $sth->finish;
    return $ctype;
}##column_exists




############################################################################
sub index_exists {  #08/03/01 1:54
############################################################################
    my $dbh = shift;
    my $table = shift;
    my $index = shift;

    if (!$dbh or !$table or !$index) {
        die "Usage: index_exists(dbh,table_name,index_name)\n";
    }

    my $found;
    my $sth = $dbh->prepare("SHOW INDEX FROM $table");
    $sth->execute;
    while(my @ary = $sth->fetchrow_array) {
        $found = 1 if $ary[2] eq $index;
    }
    $sth->finish;
    return $found;

# mysql> show index from OffPhones.Client;
#+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+---------+
#| Table  | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Comment |
#+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+---------+
#| Client |          0 | PRIMARY  |            1 | ID          | A         |        3665 |     NULL | NULL   |         |
#| Client |          1 | DEPT_ID  |            1 | DEPT_ID     | A         |         458 |     NULL | NULL   |         |
#| Client |          1 | DEPT_ID  |            2 | RANK        | A         |        1221 |     NULL | NULL   |         |
#| Client |          1 | DEPT_ID  |            3 | POSITION    | A         |        3665 |     NULL | NULL   |         |
#+--------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+---------+

}##index_exists




############################################################################
sub DO_SQL  {   #04/26/02 4:02
############################################################################
    my $dbh = shift;
    my $sql = shift;

    my $result = $dbh->do($sql);
    return if ($result);

    print STDERR "Cannot execute SQL:\n\n$sql\n\n $DBI::errstr\n"
        if ! $result;

    print "Press ENTER to continue or Ctrl-C to break";
    <STDIN>;

    return $result;
}##DO_SQL




1;
