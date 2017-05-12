package t::Util;
use parent qw(Exporter);
use strict;
use warnings;
use File::Path qw(remove_tree make_path);
use File::Spec::Functions qw(catfile catdir);
use Test::Mock::Net::FTP;
use Test::More;

our @EXPORT = qw( prepare_ftp
                  file_contents_ok
                  default_mock_prepare
                  all_methods_in_net_ftp
            );

sub prepare_ftp {
    my (%option) = @_;
    my $ftp = Test::Mock::Net::FTP->new('somehost.example.com', %option);
    $ftp->login('user1', 'secret');
    return $ftp;
}

sub default_mock_prepare {
    my (%override_sub) = @_;

    Test::Mock::Net::FTP::mock_prepare(
        'somehost.example.com', => {
            'user1'=> {
                password => 'secret',
                dir      => ['tmp/ftpserver', '/ftproot'],
                override => \%override_sub,
            },
        },
    );
    return prepare_ftp();
}

BEGIN {
    remove_tree 'tmp' if ( -e 'tmp' );
    make_path( catdir('tmp', 'ftpserver', 'dir1'),
               catdir('tmp', 'ftpserver', 'dir1', 'dir2'),
               catdir('tmp', 'ftpserver', 'dir1', 'dir3'),
               catdir('tmp', 'ftpserver', 'dir2') );
    default_mock_prepare();
}

END {
    remove_tree('tmp');
}


sub file_contents_ok {
    my ($filename, $expected_string) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    ok( -e $filename, "$filename exists." );

    open my $IN, '<', $filename or die "$filename: $!";
    my $contents = do { local $/; <$IN>};
    close $IN;
    is( $contents, $expected_string);
}

sub all_methods_in_net_ftp {
    return (
        'unique_name',      'size',       'mdtm',
        'message',          'cwd',        'cdup',
        'put',              'append',     'put_unique',
        'get',              'rename',     'delete',
        'mkdir',            'rmdir',      'port',
        'pasv',             'binary',     'ascii',
        'quit',             'close',      'abort',
        'site',             'hash',       'alloc',
        'nlst',             'list',       'retr',
        'stou',             'stor',       'appe',
        'quot',             'supported',  'authorize',
        'feature',          'restart',    'pasv_xfer',
        'pasv_xfer_unique', 'pasv_wait',  'ls',
        'dir',              'pwd',
    );
}

1;
