# NAME

Test::Mock::Net::FTP - Mock Object for Net::FTP

# SYNOPSIS

    use strict;
    use warnings;

    use Test::More;
    use Test::Mock::Net::FTP;

    Test::Mock::Net::FTP::mock_prepare(
        'somehost.example.com' => {
            'user1'=> {
                password => 'secret',
                dir      => ['./ftpserver', '/ftproot'],
                override => { 
                    ls => sub {
                        return qw(aaa bbb ccc);
                    },
                },
            },
        }
    );
    my $ftp = Test::Mock::Net::FTP->new('somehost.example.com');
    $ftp->login('user1', 'secret');
    $ftp->cwd('datadir');
    $ftp->get('file1');
    my @files = $ftp->ls();# => ('aaa', 'bbb', 'ccc');
    $ftp->quit();
    # or
    use Test::Mock::Net::FTP qw(intercept);
    some_method_using_ftp();

# DESCRIPTION

Test::Mock::Net::FTP is Mock Object for Net::FTP. This module behave like FTP server, but only use local filesystem.(not using socket).

# NOTICE

- 
This module is implemented all Net::FTP's methods, but some methods are 'do nothing' currently. These methods behavior may be changed in future release.
- 
This module works in only Unix-like systems(does not work in MS-Windows).
- 
Some errors are not reproduced in this module.
- 
If you don't like default implementation of methods in this module, you can use override (or RT to me :-)

# METHODS

## `mock_prepare( %params )`

prepare FTP server in your local filesystem.

## `mock_pwd()`

mock's current directory

## `mock_physical_root()`

mock's physical root directory

## `mock_connection_mode()`

return current connection mode (port or pasv)

## `mock_port_no()`

return current port no

## `mock_transfer_mode()`

return current transfer mode(ascii or binary)

## `mock_command_history()`

return command history

    my $ftp = Test::Mock::Net::FTP->new('somehost');
    $ftp->login('somehost', 'passwd');
    $ftp->ls('dir1');
    my @history = $ftp->mock_command_history();
    # =>  ( ['login', 'somehost', 'passwd'], ['ls', 'dir1']);

## `mock_clear_command_history()`

clear command history

## `new( $host, %options )`

create new instance

## `login( $user, $password )`

login mock FTP server. this method IS NOT allowed to be overridden.

## `authorize( [$auth, [$resp]] )`

authorize.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_authorize( [$auth, [$resp]] )`

default implementation for authorize. this method should be used in overridden method.

## `site( @args )`

execute SITE command. 
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_site( @args )`

default implementation for site. this method should be used in overridden method.

## `ascii()`

enter ascii mode.
mock\_transfer\_mode() returns 'ascii'.
this method is allowed to be overridden.

## `mock_default_ascii()`

default implementation for ascii. this method should be used in overridden method.

## `binary()`

enter binary mode.
mock\_transfer\_mode() returns 'binary'.
this method is allowed to be overridden.

## `mock_default_binary()`

default implementation for binary. this method should be used in overridden method.

## `rename($oldname, $newname)`

rename remote file.
this method is allowed to be overridden.

## `mock_default_rename($oldname, $newname)`

default implementation for rename. this method should be used in overridden method.

## `delete( $filename )`

delete remote file.
this method is allowed to be overridden.

## `mock_default_delete( $filename )`

default implementation for delete. this method should be used in overridden method.

## `cwd( $dir )`

change (mock) server current directory
this method is allowed to be overridden.

## `mock_default_cwd( $dir )`

default implementation for cwd. this method should be used in overridden method.

## `cdup()`

change (mock) server directory to parent
this method is allowed to be overridden.

## `mock_default_cdup()`

default implementation for cdup. this method should be used in overridden method.

## `pwd()`

return (mock) server current directory
this method is allowed to be overridden.

## `mock_default_pwd()`

default implementation for pwd. this method should be used in overridden method.

## `restart( $where )`

restart. currently do\_nothing
this method is allowed to be overridden.

## `mock_default_restart( $where )`

default implementation for restart. this method should be used in overridden method.

## `rmdir( $dirname, $recursive_bool )`

rmdir to remove (mock) server. when $recursive\_bool is true, dir is recursively removed.
this method is allowed to be overridden.

## `mock_default_rmdir( $dirname, $recursive_bool )`

default implementation for rmdir. this method should be used in overridden method.

## `mkdir( $dirname, $recursive_bool )`

mkdir to remove (mock) server. when $recursive\_bool is true, dir is recursively create.
this method is allowed to be overridden.

## `mock_default_mkdir( $dirname, $recursive_bool )`

default implementation for mkdir. this method should be used in overridden method.

## `alloc( $size, [$record_size] )`

alloc. 
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_alloc( $size, [$record_size] )`

default implementation for alloc. this method should be used in overridden method.

## `ls( [$dir] )`

list file(s) in server directory.
this method is allowed to be overridden.

## `mock_default_ls( [$dir] )`

default implementation for ls. this method should be used in overridden method.

## `dir( [$dir] )`

list file(s) with detail information(ex. filesize) in server directory.
this method is allowed to be overridden.

## `mock_default_dir( [$dir] )`

default implementation for dir. this method should be used in overridden method.

## `get( $remote_file, [$local_file] )`

get file from mock FTP server
this method is allowed to be overridden.

## mock\_default\_get( $remote\_file, \[$local\_file\] )

default implementation for get. this method should be used in overridden method.

## `put( $local_file, [$remote_file] )`

put a file to mock FTP server
this method is allowed to be overridden.

## `mock_default_put( $local_file, [$remote_file] )`

default implementation for put. this method should be used in overridden method.

## `put_unique( $local_file, [$remote_file] )`

same as put() but if same file exists in server. rename to unique filename
(in this module, simply add suffix .1(.2, .3...). and suffix is limited to 1024)
this method is allowed to be overridden.

## `mock_default_put_unique( $local_file, [$remote_file] )`

default implementation for put\_unique. this method should be used in overridden method.

## `append( $local_file, [$remote_file] )`

put a file to mock FTP server. if file already exists, append file contents in server file.
this method is allowed to be overridden.

## `mock_default_append( $local_file, [$remote_file] )`

default implementation for append. this method should be used in overridden method.

## `unique_name()`

return unique filename when put\_unique() called.
this method is allowed to be overridden.

## `mock_default_unique_name()`

default implementation for unique\_name. this method should be used in overridden method.

## `mdtm( $file )`

returns file modification time in remote (mock) server.
this method is allowed to be overridden.

## `mock_default_mdtm()`

default implementation for mdtm. this method should be used in overridden method.

## `size( $file )`

returns filesize in remote (mock) server.
this method is allowed to be overridden.

## `mock_default_size( $file )`

default implementation for size. this method should be used in overridden method.

## `supported( $cmd )`

supported. 
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_supported( $cmd )`

default implementation for supported. this method should be used in overridden method.

## `hash( [$filehandle_glob_ref], [$bytes_per_hash_mark] )`

hash.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_hash( [$filehandle_glob_ref], [$bytes_per_hash_mark] )`

default implementation for hash. this method should be used in overridden method.

## `feature( $cmd )`

feature. currently returns list of $cmd.
this method is allowed to be overridden.

## `mock_default_feature( $cmd )`

default implementation for feature. this method should be used in overridden method.

## `nlst( [$dir] )`

nlst.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_nlst( [$dir] )`

default implementation for nlst. this method should be used in overridden method.

## `list( [$dir] )`

list.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_list( [$dir] )`

default implementation for list. this method should be used in overridden method.

## `retr( $file )`

retr.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_retr($file)`

default implementation for retr. this method should be used in overridden method.

## `stor( $file )`

stor.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_stor( $file )`

default implementation for stor. this method should be used in overridden method.

## `stou( $file )`

stou. currently do\_nothing.

## `mock_default_stou( $file )`

default implementation for stor. this method should be used in overridden method.

## `appe( $file )`

appe.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_appe( $file )`

default implementation for appe. this method should be used in overridden method.

## `port( $port_no )`

specify data connection to port-mode.

after called this method, mock\_connection\_mode() returns 'port' and 
mock\_port\_no() returns specified $port\_no.

this method is allowed to be overridden.

## `mock_default_port( $port_no )`

default implementation for port. this method should be used in overridden method.

## `pasv()`

specify data connection to passive-mode.
after called this method, mock\_connection\_mode() returns 'pasv' and
mock\_port\_no() returns ''

this method is allowed to be overridden.

## `mock_default_pasv()`

default implementation for pasv. this method should be used in overridden method.

## `pasv_xfer( $src_file, $dest_server, [$dest_file] )`

pasv\_xfer.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_pasv_xfer( $src_file, $dest_server, [$dest_file] )`

default implementation for psv\_xfer. this method should be used in overridden method.

## `pasv_xfer_unique( $src_file, $dest_server, [$dest_file] )`

pasv\_xfer\_unique.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_pasv_xfer_unique( $src_file, $dest_server, [$dest_file] )`

default implementation for psv\_xfer\_unique. this method should be used in overridden method.

## `pasv_wait( $non_pasv_server )`

pasv\_wait.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_pasv_wait( $non_pasv_server )`

default implementation for pasv\_wait. this method should be used in overridden method.

## `abort()`

abort.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_abort()`

default implementation for abort. this method should be used in overridden method.

## `quit()`

quit.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_quit()`

default implementation for quit. this method should be used in overridden method.

## `quot( $cmd, @args )`

quot.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_quot( $cmd, @args )`

default implementation for quot. this method should be used in overridden method.

## `close()`

close connection mock FTP server.
default implementation is 'do nothing'. this method is allowed to be overridden.

## `mock_default_close()`

default implementation for close. this method should be used in overridden method.

## `message()`

return messages from mock FTP server
this method is allowed to be overridden.

## `mock_default_message()`

default implementation for message. this method should be used in overridden method.

# AUTHOR

Takuya Tsuchida &lt;tsucchi at cpan.org>

# SEE ALSO

[Net::FTP](https://metacpan.org/pod/Net::FTP)

# REPOSITORY

[http://github.com/tsucchi/Test-Mock-Net-FTP](http://github.com/tsucchi/Test-Mock-Net-FTP)

# COPYRIGHT AND LICENSE

Copyright (c) 2009-2011 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
