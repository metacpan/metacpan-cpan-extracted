use strict;
use warnings;
use Test::Spec;
use Carp;
use WebService::CEPH::FileShadow;
use File::Temp qw/tempdir/;
use File::Slurp qw/read_file/;
use File::stat;

describe "FS Shadow" => sub {
    my $bucket = 'mybucket';
    my $tmpdir;
    before all => sub {
        $tmpdir = tempdir(CLEANUP => 1);
        mkdir("$tmpdir/$bucket") or confess;
    };

    describe "constructor" => sub {
        my @ceph_opts = qw/protocol host key secret multipart_threshold_mb multisegment_threshold_mb
        query_string_authentication_host_replace
        /;
        my @fs_opts = qw/fs_shadow_path mode/;
        my @all_opts = (@ceph_opts, @fs_opts);


        describe "should work" => sub {
            before each => sub {
                WebService::CEPH->expects('new')->returns(sub {
                    my ($self, %opts) = @_;
                    cmp_deeply \%opts, +{ map { $_ => $_ } @ceph_opts};
                    return bless \%opts, 'WebService::CEPH';
                });
            };
            it "normaly" => sub {
                my $ceph = WebService::CEPH::FileShadow->new(( map { $_ => $_ } @all_opts), mode => 's3-fs' );
                is $ceph->{'mode'}, 's3-fs';
                is $ceph->{'fs_shadow_path'}, 'fs_shadow_path/';
            };

            it "without fs_shadow_path in s3 mode" => sub {
                my $ceph = WebService::CEPH::FileShadow->new(( map { $_ => $_ } @ceph_opts), mode => 's3' );
                is $ceph->{'mode'}, 's3';
                ok ! defined $ceph->{'fs_shadow_path'};
            };
        };
        for my $mode (qw/s3-fs fs/) {
            it "should confess without fs_shadow_path in $mode mode" => sub {
                WebService::CEPH->expects('new')->never;
                ok ! eval { WebService::CEPH::FileShadow->new(( map { $_ => $_ } @ceph_opts), mode => $mode ); 1 };
                like "$@", qr/please define fs_shadow_path/;
            };
        }
    };

    describe "_filepath" => sub {
        my ($ceph);
        before each => sub {
            $ceph = bless +{ bucket => 'abc', fs_shadow_path => "$tmpdir/" }, 'WebService::CEPH::FileShadow';
        };
        it "should work" => sub {
            is $ceph->_filepath('def'), $tmpdir."/abc/def";
            ok ! -d $tmpdir."/abc/";
        };
        it "should work and create dir" => sub {
            is $ceph->_filepath('def', 1), $tmpdir."/abc/def";
            ok -d $tmpdir."/abc/";
        };
        it "should deny directory traverse" => sub {
            ok ! eval { $ceph->_filepath('../x'); 1; };
        };
        it "should deny directory traverse 2" => sub {
            ok ! eval { $ceph->_filepath('def/..'); 1; };
        };
        it "but allow slash" => sub {
            is $ceph->_filepath('def/xyz'), $tmpdir."/abc/def/xyz";
        };
        it "and allow two dots" => sub {
            is $ceph->_filepath('def..xyz'), $tmpdir."/abc/def..xyz";
        };
    };

    sub check_object_file {
        my ($object_file, $expected) = @_;
        is read_file($object_file), $expected;
        is ( (stat($object_file)->mode & 07777), (0666 & ~umask), "file should have default permissions");
    }

    describe "upload" => sub {
        my ($ceph, $object_file);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            $object_file = "$tmpdir/mybucket/mykey";
            unlink $object_file;
            !-d "$tmpdir/mybucket/" or rmdir("$tmpdir/mybucket/") or confess "expected empty dir here $!";
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload')->with('mykey', 'mydata', undef, undef)->once;
            $ceph->upload('mykey', 'mydata');
        };
        it "should work in s3 mode with content-type" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload')->with('mykey', 'mydata', 'text/plain', undef)->once;
            $ceph->upload('mykey', 'mydata', 'text/plain');
        };
        it "should work in s3 mode with acl" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload')->with('mykey', 'mydata', undef, 'public-read')->once;
            $ceph->upload('mykey', 'mydata', undef, 'public-read');
        };
        it "should work in s3 mode with content-type and acl" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload')->with('mykey', 'mydata', 'text/plain', 'public-read')->once;
            $ceph->upload('mykey', 'mydata', 'text/plain', 'public-read');
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('upload')->never;
            $ceph->upload('mykey', 'mydata');
            check_object_file($object_file, 'mydata');
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('upload')->with('mykey', 'mydata', undef, undef)->once;
            $ceph->upload('mykey', 'mydata');
            check_object_file($object_file, 'mydata');
        };
    };

    describe "upload_from_file" => sub {
        my ($ceph, $localfile, $object_file);

        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            $object_file = "$tmpdir/mybucket/mykey";
            unlink $object_file;
            $localfile = "$tmpdir/localfile";
            open my $f, ">", $localfile;
            print $f "MyFileData";
            close $f;
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload_from_file')->with('mykey', $localfile, undef, undef)->once;
            $ceph->upload_from_file('mykey', $localfile);
        };
        it "should work in s3 mode with content-type" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload_from_file')->with('mykey', $localfile, 'text/plain', undef)->once;
            $ceph->upload_from_file('mykey', $localfile, 'text/plain');
        };
        it "should work in s3 mode with acl" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload_from_file')->with('mykey', $localfile, undef, 'public-read')->once;
            $ceph->upload_from_file('mykey', $localfile, undef, 'public-read');
        };
        it "should work in s3 mode with content-type and acl" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('upload_from_file')->with('mykey', $localfile, 'text/plain', 'public-read')->once;
            $ceph->upload_from_file('mykey', $localfile, 'text/plain', 'public-read');
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('upload_from_file')->never;
            $ceph->upload_from_file('mykey', $localfile);
            check_object_file($object_file, 'MyFileData');
        };
        it "should work in fs mode with filehandle" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('upload_from_file')->never;
            open my $f, "<", $localfile;
            <$f>; # read _some_ data. WebService::CEPH::FileShadow should seek to beginning.
            $ceph->upload_from_file('mykey', $f);
            check_object_file($object_file, 'MyFileData');
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('upload_from_file')->with('mykey', $localfile, undef, undef)->once;
            $ceph->upload_from_file('mykey', $localfile);
            check_object_file($object_file, 'MyFileData');
        };
    };

    describe "download" => sub {
        my ($ceph);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            my $object_file = "$tmpdir/mybucket/mykey";
            open my $f, ">", $object_file;
            print $f "MyFileData";
            close $f;
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('download')->with('mykey')->once->returns('s3data');
            is $ceph->download('mykey'), 's3data';
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('download')->never;
            is $ceph->download('mykey'), 'MyFileData';
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('download')->with('mykey')->once->returns('s3data');
            is $ceph->download('mykey'), 's3data';
        };
    };

    describe "download_to_file" => sub {
        my ($ceph, $localfile);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            $localfile = "$tmpdir/localfile";
            unlink $localfile;
            open my $f, ">", "$tmpdir/mybucket/mykey";
            print $f "MyFileData";
            close $f;
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('download_to_file')->with('mykey', $localfile)->once;
            $ceph->download_to_file('mykey', $localfile);
            ok 1;
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('download_to_file')->never;
            $ceph->download_to_file('mykey', $localfile);
            is read_file($localfile), 'MyFileData';
        };
        it "should work in fs mode with filehandle" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('download_to_file')->never;
            open my $fh, ">", $localfile;
            print $fh "HeyHeyHeyHeyHeyHeyHeyHeyHey\n"; # should be longed than "MyFileData";
            $ceph->download_to_file('mykey', $fh);
            is read_file($localfile), 'MyFileData';
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('download_to_file')->with('mykey', $localfile)->once;
            $ceph->download_to_file('mykey', $localfile);
            ok 1;
        };
    };

    describe "size" => sub {
        my ($ceph, $object_file);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            $object_file = "$tmpdir/mybucket/mykey";
            unlink $object_file;
            open my $f, ">", $object_file;
            print $f "MyFileData";
            close $f;
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('size')->with('mykey')->returns(4242);
            is $ceph->size('mykey'), 4242;
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('size')->never;
            is $ceph->size('mykey'), -s $object_file;
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('size')->with('mykey')->returns(4242);
            is $ceph->size('mykey'), 4242;
        };
    };

    describe "delete" => sub {
        my ($ceph, $object_file);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
            $object_file = "$tmpdir/mybucket/mykey";
            unlink $object_file;
            open my $f, ">", $object_file;
            print $f "MyFileData";
            close $f;
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('delete')->with('mykey')->once;
            ok -f $object_file;
            $ceph->delete('mykey');
            ok -f $object_file;
        };
        it "should work in fs mode" => sub {
            $ceph->{mode} = 'fs';
            ok -f $object_file;
            WebService::CEPH->expects('delete')->never;
            $ceph->delete('mykey');
            ok ! -f $object_file;
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('delete')->with('mykey')->once;
            ok -f $object_file;
            $ceph->delete('mykey');
            ok -f $object_file;
        };
    };
    describe "query_string_authentication_uri" => sub {
        my ($ceph);
        before each => sub {
            $ceph = bless +{ fs_shadow_path => "$tmpdir/", bucket => $bucket, }, 'WebService::CEPH::FileShadow';
        };
        it "should work in s3 mode" => sub {
            $ceph->{mode} = 's3';
            WebService::CEPH->expects('query_string_authentication_uri')->with('mykey', 11)->returns(42);
            is $ceph->query_string_authentication_uri('mykey', 11), 42;
        };
        it "should confess in fs mode" => sub {
            $ceph->{mode} = 'fs';
            WebService::CEPH->expects('query_string_authentication_uri')->never;
            ok ! eval { $ceph->query_string_authentication_uri('mykey'); 1};
        };
        it "should work in s3-fs mode" => sub {
            $ceph->{mode} = 's3-fs';
            WebService::CEPH->expects('query_string_authentication_uri')->with('mykey', 11)->returns(42);
            is $ceph->query_string_authentication_uri('mykey', 11), 42;
        };
    };
};

runtests unless caller;
1;
