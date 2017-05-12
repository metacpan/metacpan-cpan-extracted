sqlfs-perl
==========

This creates a fully functional user filesystem within in a SQL
database. It supports the MySQL, PostgreSQL and SQLite databases, and
can be extended to support any other relational database that has a
Perl DBI driver.

Most filesystem functionality is implemented, including hard and soft
links, sparse files, ownership and access modes, UNIX permission
checking and random access to binary files. Very large files (up to
multiple gigabytes) are supported without performance degradation (see
performance notes below).

Why would you use this? The main reason is that it allows you to use
DBMs functionality such as accessibility over the network, database
replication, failover, etc. In addition, the underlying
DBI::Filesystem module can be extended via subclassing to allow
additional functionality such as arbitrary access control rules,
searchable file and directory metadata, full-text indexing of file
contents, etc.

Installing DBD Drivers
======================

To install Perl drivers for the supported DBMSs, run one or more of
the following commands from the command line:

 % perl -MCPAN -e 'install DBD::mysql'      # Mysql
 % perl -MCPAN -e 'instell DBD::SQLite'     # SQLite
 % perl -MCPAN -e 'install DBD::Pg'         # PostgreSQL

Using the Module
================

Before mounting the DBMS, you must have created the database and
assigned yourself sufficient privileges to read and write to it. You
must also create an empty directory to serve as the mount point.

* A SQLite database:

This is very simple.

 # make the mount point
 $ mkdir /tmp/sqlfs

 # make an empty SQLite database (not really necessary)
 $ touch /home/myself/filesystem.sqlite

 # run the sqlfs.pl command line tool with the --initialize option
 $ sqlfs.pl dbi:SQLite:/home/lstein/filesystem.sqlite --initialize /tmp/sqlfs
 WARNING: any existing data will be overwritten. Proceed? [y/N] y

 # now start reading/writing to the filesystem
 $ echo 'hello world!' > /tmp/sqlfs/hello.txt
 $ mkdir /tmp/sqlfs/subdir
 $ mv /tmp/sqlfs/hello.txt /tmp/sqlfs/subdir
 $ ls -l /tmp/sqlfs/subdir
 total 1
 -rw-rw-r-- 1 myself myself 13 Jun  7 06:23 hello.txt
 $ cat /tmp/sqlfs/subdir/hello.txt
 Hello world!

 # unmount the filesystem when you are done
 $ sqlfs.pl -u /tmp/sqlfs

To mount the filesystem again, simply run sqlfs.pl without the
--initialize option.

* A MySql database:

You will need to use the mysqladmin tool to create the database and
grant yourself privileges on it.

 $ mysqladmin -uroot -p create filesystem
 Enter password: 

 $ mysql -uroot -p filesystem
 Enter password: 
 Welcome to the MySQL monitor.  Commands end with ; or \g.
 ...
 mysql> grant all privileges on filesystem.* to myself identified by 'foobar';
 mysql> flush privileges;
 mysql> quit

Create the mountpoint, and use the sqlfs.pl script to initialize and
mount the database as before:

 $ mkdir /tmp/sqlfs
 $ sqlfs.pl 'dbi:mysql:dbname=filesystem;user=myself;password=foobar' --initialize /tmp/sqlfs
 $ echo 'hello world!' > /tmp/sqlfs/hello.txt
 ... etc ... 

Note that this will work across the network using the extended DBI
data source syntax (see the DBD::mysql manual page):

 $ sqlfs.pl 'dbi:mysql:filesystem;host=roxy.foo.com;user=myself;password=foobar' /tmp/sqlfs

Unmount the filesystem with the -u option:

 $ sqlfs.pl -u /tmp/sqlfs

* A PostgreSQL database

Assuming that your login already has the ability to manage PostgreSQL
databases, creating the database is a one-step process:

 $ createdb filesystem

Now create the mountpoint and use sqlfs.pl to initialize and mount
it:

 $ sqlfs.pl 'dbi:Pg:dbname=filesystem' --initialize /tmp/sqlfs
 WARNING: any existing data will be overwritten. Proceed? [y/N] y
 
 $ echo 'hello world!' > /tmp/sqlfs/hello.txt
 ... etc ... 

 # unmount the filesystem when no longer needed
 # sqlfs.pl -u /tmp/sqlfs

Command-Line Tool
=================

The sqlfs.pl has a number of options listed here:

 Usage:
     % sqlfs.pl [options] dbi:<driver_name>:dbname=<name>;<other_args> <mount point>

    Options:

      --initialize                  initialize an empty filesystem
      --quiet                       don't ask for confirmation of initialization
      --allow_magic                 allow "magic" directories (see below)
      --unmount                     unmount the indicated directory
      --foreground                  remain in foreground (false)
      --nothreads                   disable threads (false)
      --debug                       enable Fuse debugging messages
      --module=<ModuleName>         Use a subclass of DBI::Filesystem

      --option=allow_other          allow other accounts to access filesystem (false)
      --option=default_permissions  enable permission checking by kernel (false)
      --option=fsname=<name>        set filesystem name (none)
      --option=use_ino              let filesystem set inode numbers (false)
      --option=direct_io            disable page cache (false)
      --option=nonempty             allow mounts over non-empty file/dir (false)
      --option=ro                   mount read-only
      -o ro,direct_io,etc           shorter version of options

      --help                        this text
      --man                         full manual page

    Options can be abbreviated to single letters.

More information can be obtained by passing the sqlfs.pl command the
--man option.

"Magic" Directories
===================

The --allow_magic option enables a form of "view" directory in which
the directory is automagically populated with the results of running a
simple (or complex) SQL query across the entire filesystem. To try
this out, create one or more directories that begin with the magic
characters "%%", and then create a dotfile within this directory named
".query".  ".query" must contain a SQL query that returns a series of
one or more inodes. These will be used to populate the directory
automagically. The query can span multiple lines, and lines that begin
with "#" will be ignored.

You must understand the simple schema used by this module to be able
to write such queries. To learn about the schema, see
L<DBI::Filesystem>.

Here is a simple example which will run on all DBMSs. It displays all
files with size greater than 2 Mb:

 select inode from metadata where size>2000000

Another example, which uses MySQL-specific date/time
math to find all .jpg files created/modified within the last day:

 select m.inode from metadata as m,path as p
     where p.name like '%.jpg'
       and (now()-interval 1 day) <= m.mtime
       and m.inode=p.inode

(The date/time math syntax is very slightly different for PostgreSQL
and considerably different for SQLite)

An example that uses extended attributes to search for all documents
authored by someone with "Lincoln" in the name:

 select m.inode from metadata as m,xattr as x
    where x.name == 'user.Author'
     and x.value like 'Lincoln%'
     and m.inode=x.inode
    
The files contained within the magic directories can be read and
written just like normal files, but cannot be removed or
renamed. Directories are excluded from magic directories. If two or
more files from different parts of the filesystem have name clashes,
the filesystem will append a number to their end to distinguish them.

System Performance
==================

Depending on the SQL storage engine, you can expect write performance
roughly 10-fold slower than on a local ext3 filesystem and roughly a
third the speed of a NFSv4 filesystem mounted across a gigabit
LAN. Read performance various considerably from storage engine to
storage engine, but even the slowest storage engine provides
sufficient bandwith to stream an HD movie. The MySQL engine appears to
be faster than ext3 for reading, which is puzzling since MySQL's
database files are on the same ext3 filesystem.

                Local ext3  NFSv4    SQLite     PostgreSQL    MySQL
                ----------  -----    ------     ----------    -----
Read  (MB/s)      78.4      60.5     12.6         35.9        98.6
Write (MB/s)     189.0      45.1     12.5          7.5        12.7

(These benchmarks were performed on a commodity intel i3 laptop @ 2.60
GHz, using a SATA II internal hard disk. The write test consisted of
copying a 99 MB binary file (a .tar.gz of a linux kernel) from a
RAM-based tmpfs to the target filesystem using dd and a blocksize of
4096. The read test consisted of copying the file back from the
filesystem into /dev/null. The filesystem was synced and kernel caches
were emptied prior to each test. Each test was run 5 times and the
median value calculated. The benchmark script can be found in the
github repository for this module, under tests/benchmark.pl).

Author and License Information
==============================

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.
