use strict;
use warnings;
use Test::Spec;
use WebService::CEPH;
use File::Temp qw/tempdir/;
use Digest::MD5 qw/md5_hex/;
use File::Slurp qw/read_file/;

#
# Unit tests with mocks for WebService::CEPH, it checks all of the module's logic.
# All driver calls are mocked
#

my $tmp_dir = tempdir(CLEANUP => 1);

sub create_temp_file {
    my ($data) = @_;

    my $datafile = "$tmp_dir/data";
    open my $f, ">", $datafile or die "$!";
    print $f $data;
    close $f;
    $datafile;
}

describe CEPH => sub {
    describe constructor => sub {
        my @mandatory_params = (
                protocol => 'http',
                host => 'myhost',
                key => 'accesskey',
                secret => 'supersecret',
        );
        my @mandatory_params_with_bucket = ( @mandatory_params, bucket => undef );
        my %mandatory_params_h = @mandatory_params;
        my $driver = mock();

        it "should work" => sub {
            WebService::CEPH::NetAmazonS3->expects('new')->with(@mandatory_params_with_bucket)->returns($driver);

            my $ceph = WebService::CEPH->new(@mandatory_params);

            is ref $ceph, 'WebService::CEPH';
            cmp_deeply +{%$ceph}, {
                %mandatory_params_h,
                driver_name => 'NetAmazonS3',
                multipart_threshold => 5*1024*1024,
                multisegment_threshold => 5*1024*1024,
                driver =>  $driver,
            };
        };

        for my $param (keys %mandatory_params_h) {
            it "should confess if param $param is missing" => sub {
                my %params = %mandatory_params_h;
                delete $params{$param};
                ok ! eval { WebService::CEPH->new(%params); 1 };
                like "$@", qr/Missing $param/;
            };
        }

        it "should override driver" => sub {
            WebService::CEPH::XXX->expects('new')->with(@mandatory_params_with_bucket)->returns($driver);

            my $ceph = WebService::CEPH->new(@mandatory_params, driver_name => 'XXX');
            is $ceph->{driver_name}, 'XXX';
        };

        it "should override multipart threshold" => sub {
            my $new_threshold = 10_000_000;
            WebService::CEPH::NetAmazonS3->expects('new')->with(@mandatory_params_with_bucket)->returns($driver);

            my $ceph = WebService::CEPH->new(@mandatory_params, multipart_threshold => $new_threshold);

            is $ceph->{multipart_threshold}, $new_threshold;
        };

        it "should override multisegment threshold" => sub {
            my $new_threshold = 10_000_000;
            WebService::CEPH::NetAmazonS3->expects('new')->with(@mandatory_params_with_bucket)->returns($driver);

            my $ceph = WebService::CEPH->new(@mandatory_params,multisegment_threshold => $new_threshold);

            is $ceph->{multisegment_threshold}, $new_threshold;
        };

        it "should catch bad threshold" => sub {
            ok ! eval { WebService::CEPH->new(@mandatory_params, multipart_threshold => 5*1024*1024-1); 1 };
            like "$@", qr/should be greater or eq.*MINIMAL_MULTIPART_PART/;
        };

        it "should set optional query_string_authentication_host_replace" => sub {
            WebService::CEPH::NetAmazonS3->expects('new')->with(@mandatory_params_with_bucket)->returns($driver);
            my $ceph = WebService::CEPH->new(@mandatory_params, query_string_authentication_host_replace => 'hello');
            is $ceph->{query_string_authentication_host_replace}, 'hello';
        };

        it "should catch extra args" => sub {
            ok ! eval { WebService::CEPH->new(@mandatory_params, abc => 42); 1; };
            like "$@", qr/Unused arguments/;
            like "$@", qr/abc.*42/;
        };
    };

    describe "other methods" => sub {
        my $driver = mock();
        my $ceph = bless +{ driver => $driver, bucket => 'mybucket'}, 'WebService::CEPH';
        it "should return size" => sub {
            $driver->expects('size')->with('testkey')->returns(42);
            is $ceph->size('testkey'), 42;
        };
        it "size should confess on non-ascii data" => sub {
            $driver->expects('size')->never;
            ok ! eval { $ceph->size("key\x{b5}"); 1 };
        };
        it "should delete" => sub {
            $driver->expects('delete')->with('testkey');
            $ceph->delete('testkey');
            ok 1;
        };
        it "delete should confess on non-ascii data" => sub {
            $driver->expects('delete')->never;
            ok ! eval { $ceph->delete("key\x{b5}"); 1 };
        };
    };
    describe upload => sub {
        my ($driver, $ceph, $multipart_data, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multipart_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
            $multipart_data = mock();
            $key = 'mykey';
        };

        for my $partsdata ([qw/Aa B/], [qw/Aa Bb/], [qw/Aa Bb C/]) {
            it "multipart upload should work for @$partsdata" => sub {
                my $data_s = join('', @$partsdata);
                $driver->expects('initiate_multipart_upload')->with($key, md5_hex($data_s), undef, undef)->returns($multipart_data);
                my (@parts, @data);
                $driver->expects('upload_part')->exactly(scalar @$partsdata)->returns(sub{
                    my ($self, $md, $part_no, $chunk) = @_;
                    is $md+0, $multipart_data+0;
                    push @parts, $part_no;
                    push @data, $chunk;
                });
                $driver->expects('complete_multipart_upload')->with($multipart_data);
                $ceph->upload($key, $data_s);
                cmp_deeply [@parts], [map $_, 1..@$partsdata];
                cmp_deeply [@data], $partsdata;
            };
        }

        it "simple upload should work" => sub {
            $driver->expects('upload_single_request')->with($key, 'Aa', undef, undef);
            $ceph->upload($key, 'Aa');
            ok 1;
        };

        it "simple upload should work for less than multipart_threshold bytes" => sub {
            $driver->expects('upload_single_request')->with($key, 'A', undef, undef);
            $ceph->upload($key, 'A');
            ok 1;
        };

        it "simple upload should work for less than zero bytes" => sub {
            $driver->expects('upload_single_request')->with($key, '', undef, undef);
            $ceph->upload($key, '');
            ok 1;
        };
        it "upload should confess on non-ascii data" => sub {
            $driver->expects('upload_single_request')->never;
            ok ! eval { $ceph->upload("key\x{b5}", "a"); 1 };
        };
    };

    describe get_buckets_list => sub {
        my ($driver, $ceph, $multipart_data, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multipart_threshold => 2 }, 'WebService::CEPH';
        };

        it "should work" => sub {
            $driver->expects('get_buckets_list');
            $ceph->get_buckets_list;
            ok 1;
        };
    };

    describe list_multipart_uploads => sub {
        my ($driver, $ceph, $multipart_data, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multipart_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
        };

        it "should confess without bucket" => sub {
            undef $ceph->{bucket};
            ok ! eval { $ceph->list_multipart_uploads(); 1 };
            like "$@", qr/Bucket name is required/;
        };

        it "should work" => sub {
            $driver->expects('list_multipart_uploads');
            $ceph->list_multipart_uploads;
            ok 1;
        };
    };

    describe delete_multipart_upload => sub {
        my ($driver, $ceph, $multipart_data, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multipart_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
        };

        it "should confess without bucket" => sub {
            undef $ceph->{bucket};
            ok ! eval { $ceph->delete_multipart_upload(); 1 };
            like "$@", qr/Bucket name is required/;
        };

        it "should confess without upload id" => sub {
            ok ! eval { $ceph->delete_multipart_upload('key', undef); 1 };
            like "$@", qr/key and upload ID is required/;
        };

        it "should confess without key" => sub {
            ok ! eval { $ceph->delete_multipart_upload(undef, 'upload_id'); 1 };
            like "$@", qr/key and upload ID is required/;
        };

        it "should work" => sub {
            $driver->expects('delete_multipart_upload')->with('key', 'upload_id');
            $ceph->delete_multipart_upload('key', 'upload_id');
            ok 1;
        };
    };

    describe upload_from_file => sub {
        my ($driver, $ceph, $multipart_data, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multipart_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
            $multipart_data = mock();
            $key = 'mykey';
        };

        for my $partsdata ([qw/Aa B/], [qw/Aa Bb/], [qw/Aa Bb C/]) {
            it "multipart upload should work for @$partsdata" => sub {
                my $data_s = join('', @$partsdata);
                my $datafile = create_temp_file($data_s);

                $driver->expects('initiate_multipart_upload')->with($key, md5_hex($data_s), undef, undef)->returns($multipart_data);
                my (@parts, @data);
                $driver->expects('upload_part')->exactly(scalar @$partsdata)->returns(sub{
                    my ($self, $md, $part_no, $chunk) = @_;
                    is $md+0, $multipart_data+0;
                    push @parts, $part_no;
                    push @data, $chunk;
                });
                $driver->expects('complete_multipart_upload')->with($multipart_data);
                $ceph->upload_from_file($key, $datafile);
                cmp_deeply [@parts], [map $_, 1..@$partsdata];
                cmp_deeply [@data], $partsdata;
            };
        };

        it "multipart upload should work for filehandle" => sub {
            my $data_s = "Hello";
            my $datafile = create_temp_file($data_s);
            open my $f, "<", $datafile or die "$!";

            $driver->expects('initiate_multipart_upload')->with($key, md5_hex('Hello'), undef, undef)->returns($multipart_data);
            my (@parts, @data);
            $driver->expects('upload_part')->exactly(3)->returns(sub{
                my ($self, $md, $part_no, $chunk) = @_;
                is $md+0, $multipart_data+0;
                push @parts, $part_no;
                push @data, $chunk;
            });
            $driver->expects('complete_multipart_upload')->with($multipart_data);
            $ceph->upload_from_file($key, $f);
            cmp_deeply [@parts], [qw/1 2 3/];
            cmp_deeply [@data], [qw/He ll o/];
        };

        it "multipart upload should work for filehandle with content-type and acl" => sub {
            my $data_s = "Hello";
            my $datafile = create_temp_file($data_s);
            open my $f, "<", $datafile or die "$!";

            $driver->expects('initiate_multipart_upload')->with($key, md5_hex('Hello'), 'text/plain', 'public-read')->returns($multipart_data);
            my (@parts, @data);
            $driver->expects('upload_part')->exactly(3)->returns(sub{
                my ($self, $md, $part_no, $chunk) = @_;
                is $md+0, $multipart_data+0;
                push @parts, $part_no;
                push @data, $chunk;
            });
            $driver->expects('complete_multipart_upload')->with($multipart_data);
            $ceph->upload_from_file($key, $f, 'text/plain', 'public-read');
            cmp_deeply [@parts], [qw/1 2 3/];
            cmp_deeply [@data], [qw/He ll o/];
        };

        it "non-multipart upload should work for filehandle" => sub {
            my $data_s = "Ab";
            my $datafile = create_temp_file($data_s);

            open my $f, "<", $datafile or die "$!";

            $driver->expects('upload_single_request')->with($key, 'Ab', undef, undef);
            $ceph->upload_from_file($key, $f);
        };

        it "non-multipart upload should work for file" => sub {
            my $data_s = "Ab";
            my $datafile = create_temp_file($data_s);

            $driver->expects('upload_single_request')->with($key, 'Ab', undef, undef);
            $ceph->upload_from_file($key, $datafile);
        };
    };
    describe download => sub {
        my ($driver, $ceph, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multisegment_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
            # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
            $ceph->expects('size')->returns(1);
            # /workaround for CEPH bug
            $key = 'mykey';
        };

        for my $partsdata ([qw/A/], [qw/Aa/], [qw/Aa B/], [qw/Aa Bb/], [qw/Aa Bb C/]) {
            it "multisegment download should work for @$partsdata" => sub {
                my @parts = @$partsdata;
                my $md5 = md5_hex(join('', @parts));
                my $expect_offset = 0;
                $driver->expects('download_with_range')->exactly(scalar @$partsdata)->returns(sub{
                    my ($self, $key, $first, $last) = @_;
                    my $data = shift(@parts);
                    is $first, $expect_offset;
                    is $last, $first + $ceph->{multisegment_threshold};
                    $expect_offset += $ceph->{multisegment_threshold};
                    return (\$data, length(join('', @parts)), $md5, $md5);
                });
                is $ceph->download($key), join('', @$partsdata);
            };
        }

        it "multisegment download should crash on wrong etags" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return (\"Test", 0, "696df35ad1161afbeb6ea667e5dd5dab")
            });
            ok ! eval { $ceph->download($key); 1 };
            like "$@",
                qr/MD5 missmatch, got 0cbc6611f5540bd0809a388dc95a615b, expected 696df35ad1161afbeb6ea667e5dd5dab/;
        };

        it "multisegment download should not crash on multipart etags" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return (\"Test", 0, "696df35ad1161afbeb6ea667e5dd5dab-2861")
            });
            is $ceph->download($key), "Test";
        };

        it "multisegment download should crash on wrong custom md5" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return (\"Test", 0, "696df35ad1161afbeb6ea667e5dd5dab-2861", '42aef892dfb5a85d191e9fba6054f700')
            });
            ok ! eval { $ceph->download($key); 1 };
            like "$@",
                qr/MD5 missmatch, got 0cbc6611f5540bd0809a388dc95a615b, expected 42aef892dfb5a85d191e9fba6054f700/;
        };

        it "multisegment download should crash when etag and custom etag differs" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return (\"Test", 0, "696df35ad1161afbeb6ea667e5dd5dab", '42aef892dfb5a85d191e9fba6054f700')
            });
            ok ! eval { $ceph->download($key); 1 };
            like "$@",
                qr/ETag looks like valid md5 and x\-amz\-meta\-md5 presents but they do not match/;
        };

        it "multisegment download should return undef when object not exists" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return;
            });
            ok ! defined $ceph->download($key);
        };
        it "multisegment download should return undef if second chunk of multi segment download missed" => sub {
            $driver->expects('download_with_range')->exactly(2)->returns(sub{
                my ($self, $key, $first, $last) = @_;
                if ($first) {
                    return;
                }
                else {
                    return (\"Test", 10, "696df35ad1161afbeb6ea667e5dd5dab")
                }
            });
            ok ! defined $ceph->download($key);
        };
        it "multisegment download should confess if etag changed" => sub {
            $driver->expects('download_with_range')->exactly(2)->returns(sub{
                my ($self, $key, $first, $last) = @_;
                if ($first) {
                    return (\"Test2", 0, "1111f35ad1161afbeb6ea667e5dd5dab-2861")
                }
                else {
                    return (\"Test", 10, "696df35ad1161afbeb6ea667e5dd5dab-2861")
                }
            });
            ok ! eval { $ceph->download($key); 1; };
            like "$@", qr/File changed during download/;
        };
        it "download should confess on non-ascii data" => sub {
            $driver->expects('download_with_range')->never;
            ok ! eval { $ceph->download("key\x{b5}"); 1 };
        };
    };
    describe download_to_file => sub {
        my ($driver, $ceph, $key);

        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multisegment_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
            $key = 'mykey';
            # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
            $ceph->expects('size')->returns(1);
            # /workaround for CEPH bug
        };

        for my $partsdata ([qw/A/], [qw/Aa/], [qw/Aa B/], [qw/Aa Bb/], [qw/Aa Bb C/]) {
            it "multisegment download should work for @$partsdata" => sub {
                my $datafile = "$tmp_dir/datafile";

                my @parts = @$partsdata;
                my $md5 = md5_hex(join('', @parts));
                my $expect_offset = 0;
                $driver->expects('download_with_range')->exactly(scalar @$partsdata)->returns(sub{
                    my ($self, $key, $first, $last) = @_;
                    my $data = shift(@parts);
                    is $first, $expect_offset;
                    is $last, $first + $ceph->{multisegment_threshold};
                    $expect_offset += $ceph->{multisegment_threshold};
                    return (\$data, length(join('', @parts)), $md5, $md5);
                });
                my $data = join('', @$partsdata);
                is $ceph->download_to_file($key, $datafile), length $data;
                is read_file($datafile), $data;
            };
        }
        it "multisegment download should work for filehanlde" => sub {
            my $datafile = "$tmp_dir/datafile";
            my $data = "Ab";
            my $md5 = md5_hex('Ab');
            my $expect_offset = 0;
            open my $fh, ">", $datafile;
            my $test_string = "Hey\n";
            print $fh $test_string; # it will seek to beginning anyway
            ok length($test_string) > length($data); # so we test that file truncated
            $driver->expects('download_with_range')->returns(sub{
                my ($self, $key, $first, $last) = @_;
                return (\$data, 0, $md5, $md5);
            });
            is $ceph->download_to_file($key, $fh), 2;
            close $fh;
            is read_file($datafile), "Ab";
        };

        it "download to file should return undef when object not exists" => sub {
            $driver->expects('download_with_range')->exactly(1)->returns(sub{
                return;
            });
            ok ! defined $ceph->download_to_file($key, "$tmp_dir/datafile");
        };
    };

    # workaround for CEPH bug http://lists.ceph.com/pipermail/ceph-users-ceph.com/2016-June/010704.html
    describe "Download of zero size files" => sub {
        my ($driver, $ceph, $key, $datafile);
        before each => sub {
            $datafile = "$tmp_dir/datafile";
            $driver = mock();
            $ceph = bless +{ driver => $driver, multisegment_threshold => 2, bucket => 'mybucket' }, 'WebService::CEPH';
            $ceph->expects('size')->returns(0);
            $key = 'mykey';
        };

        it "should work for download" => sub {
            is $ceph->download($key), '';
        };
        it "should work for download_to_file" => sub {
            is $ceph->download_to_file($key, $datafile), 0;
            ok -f $datafile;
            ok !-s $datafile;
        };

    };
    # /workaround for CEPH bug

    describe query_string_authentication_uri => sub {
        my ($driver, $ceph);
        before each => sub {
            $driver = mock();
            $ceph = bless +{ driver => $driver, multisegment_threshold => 2 }, 'WebService::CEPH';
        };

        it "should work" => sub {
            $driver->expects('query_string_authentication_uri')->with(mykey => 42)->returns('myurl');
            is $ceph->query_string_authentication_uri('mykey', 42), 'myurl';
        };
        it "should fix url to host without slash" => sub {
            $ceph->{query_string_authentication_host_replace} = 'http://example.com';
            $driver->expects('query_string_authentication_uri')->with(mykey => 42)->returns('http://s3.dc1.example.com/something?more');
            is $ceph->query_string_authentication_uri('mykey', 42), 'http://example.com/something?more';
        };
        it "should fix url to host with slash" => sub {
            $ceph->{query_string_authentication_host_replace} = 'http://example.com/';
            $driver->expects('query_string_authentication_uri')->with(mykey => 42)->returns('http://s3.dc1.example.com/something?more');
            is $ceph->query_string_authentication_uri('mykey', 42), 'http://example.com/something?more';
        };
        it "should fix https url to http url" => sub {
            $ceph->{query_string_authentication_host_replace} = 'http://example.com';
            $driver->expects('query_string_authentication_uri')->with(mykey => 42)->returns('https://s3.dc1.example.com/something?more');
            is $ceph->query_string_authentication_uri('mykey', 42), 'http://example.com/something?more';
        };
    };
};

runtests unless caller;
