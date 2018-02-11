use strict;
use warnings;

use Test::Deep;
use HTTP::Daemon;
use IO::Handle;
use LWP::UserAgent;
use Digest::MD5 qw/md5_hex/;
use WebService::CEPH::NetAmazonS3;
use POSIX ":sys_wait_h";
use Test::More;

our (@child_cb, @parent_cb, @messages_client, @messages_server);

sub test_case {
    my ($msg, $client, @servers) = @_;

    push @messages_client, $msg;
    push @messages_server, ($msg) x @servers;
    push @child_cb, @servers;
    push @parent_cb, $client;
}

##
## Test cases
##

# get_buckets_list method returns an error  "Attribute (owner_id) does not pass the type constraint because: Validation failed for 'OwnerId'"
# TODO: uncomment when method bug fixed
#test_case "get_buckets_list" => sub {
#    my ($msg, $ceph) = @_;
#    $ceph->get_buckets_list();
#    ok 1, "$msg"
#
#} => sub {
#    my ($msg, $connect, $request) = @_;
#    die unless $request->url eq '/';
#    my $resp = HTTP::Response->new(200, 'OK');
#    $resp->content(<<'XML');
#<?xml version="1.0" encoding="UTF-8"?>
#<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
#    <Owner>
#        <ID>bcaf1ffd86f461ca5fb16fd081034f</ID>
#        <DisplayName>REGRU</DisplayName>
#    </Owner>
#    <Buckets>
#        <Bucket>
#            <Name>test-vsespb-1</Name>
#            <CreationDate>2016-07-13T11:49:57.345Z</CreationDate>
#        </Bucket>
#    </Buckets>
#</ListAllMyBucketsResult>
#XML
#
#    $connect->send_response($resp);
#};


test_case "list_multipart_uploads" => sub {
    my ($msg, $ceph) = @_;

    no warnings 'redefine';
    local *WebService::CEPH::NetAmazonS3::_time = sub { 1289422113 + 5000 };
    my $uploads = $ceph->list_multipart_uploads();
    cmp_deeply $uploads, [{
        upload_id => 'XMgbGlrZSBlbHZpbmcncyBub3QgaGF2aW5nIG11Y2ggbHVjaw',
        initiated => '2010-11-10T20:48:33.000Z',
        key => 'my-divisor',
        initiated_epoch => 1289422113,
        initiated_age_seconds => 5000,
    }];
    ok 1, "$msg";
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket?uploads';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->content(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListMultipartUploadsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Bucket>bucket</Bucket>
  <KeyMarker></KeyMarker>
  <UploadIdMarker></UploadIdMarker>
  <NextKeyMarker>my-movie.m2ts</NextKeyMarker>
  <NextUploadIdMarker>YW55IGlkZWEgd2h5IGVsdmluZydzIHVwbG9hZCBmYWlsZWQ</NextUploadIdMarker>
  <MaxUploads>3</MaxUploads>
  <IsTruncated>true</IsTruncated>
  <Upload>
    <Key>my-divisor</Key>
    <UploadId>XMgbGlrZSBlbHZpbmcncyBub3QgaGF2aW5nIG11Y2ggbHVjaw</UploadId>
    <Initiator>
      <ID>arn:aws:iam::111122223333:user/user1-11111a31-17b5-4fb7-9df5-b111111f13de</ID>
      <DisplayName>user1-11111a31-17b5-4fb7-9df5-b111111f13de</DisplayName>
    </Initiator>
    <Owner>
      <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
      <DisplayName>OwnerDisplayName</DisplayName>
    </Owner>
    <StorageClass>STANDARD</StorageClass>
    <Initiated>2010-11-10T20:48:33.000Z</Initiated>
  </Upload>
</ListMultipartUploadsResult>
XML

    $connect->send_response($resp);
};


test_case "delete_multipart_upload" => sub {
    my ($msg, $ceph) = @_;
    $ceph->delete_multipart_upload('key', 'upload_id');
    ok 1, "$msg"

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/key?uploadId=upload_id';
    my $resp = HTTP::Response->new(204, 'OK');

    $connect->send_response($resp);
};

# upload_single_request

test_case "Upload single request" => sub {
    my ($msg, $ceph) = @_;
    $ceph->upload_single_request('my key', 'myvalue');
    ok 1, "$msg"

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/my%20key';
    die unless $request->header('Content-MD5') eq '1ySnE1zn0lk8JfxSEtQSWg==';
    die unless $request->header('X-Amz-Meta-Md5') eq 'd724a7135ce7d2593c25fc5212d4125a';
    die unless $request->header('Content-type') eq 'binary/octet-stream';
    die unless $request->content eq 'myvalue';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex($request->content));
    $connect->send_response($resp);
};

test_case "Upload single request" => sub {
    my ($msg, $ceph) = @_;
    $ceph->upload_single_request('my key', 'myvalue', 'text/plain');
    ok 1, "$msg"

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/my%20key';
    die unless $request->header('Content-MD5') eq '1ySnE1zn0lk8JfxSEtQSWg==';
    die unless $request->header('X-Amz-Meta-Md5') eq 'd724a7135ce7d2593c25fc5212d4125a';
    die unless $request->header('Content-type') eq 'text/plain';
    die unless $request->content eq 'myvalue';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex($request->content));
    $connect->send_response($resp);
};


# https://forums.aws.amazon.com/thread.jspa?threadID=55746
test_case "Work with plus in URL" => sub {
    my ($msg, $ceph) = @_;
    $ceph->upload_single_request('my+key', 'myvalue');
    ok 1, "$msg"

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/my%2Bkey';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex($request->content));
    $connect->send_response($resp);
};

test_case "Upload zero-size file" => sub {
    my ($msg, $ceph) = @_;
    $ceph->upload_single_request('mykey', '');
    ok 1, "$msg"

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex(''));
    $connect->send_response($resp);
};

test_case "Upload single request with broken md5" => sub {
    my ($msg, $ceph) = @_;
    ok ! eval { $ceph->upload_single_request('mykey', 'myvalue'); 1 }, $msg;
    like "$@", qr/^Corrupted upload/, $msg;

} => sub {
    my ($msg, $connect, $request) = @_;
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex('notadata'));
    $connect->send_response($resp);
};

# multipart uploads

test_case "Multipart upload" => sub {
    my ($msg, $ceph) = @_;
    my $multipart_data = $ceph->initiate_multipart_upload('mykey', 'somemd5');
    $ceph->upload_part($multipart_data, 1, "P1");
    $ceph->upload_part($multipart_data, 2, "P2");
    $ceph->complete_multipart_upload($multipart_data);
} => sub {
    my ($msg, $connect, $request) = @_;
    die "Wrong md5" unless $request->header('X-Amz-Meta-Md5') eq 'somemd5';
    die $request->header('Content-type') if $request->header('Content-type');
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->content(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>testbucket</Bucket>
    <Key>mykey</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
</InitiateMultipartUploadResult>
XML

    $connect->send_response($resp);
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey?partNumber=1&uploadId=VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA';
    die unless $request->content eq 'P1';
    my $resp = HTTP::Response->new(200, 'OK');
    $connect->send_response($resp);
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey?partNumber=2&uploadId=VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA';
    die unless $request->content eq 'P2';
    my $resp = HTTP::Response->new(200, 'OK');
    $connect->send_response($resp);
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->content =~ m!<CompleteMultipartUpload>
<Part>\s*
<PartNumber>1</PartNumber>\s*
<ETag>5f2b9323c39ee3c861a7b382d205c3d3</ETag></Part>\s*
<Part><PartNumber>2</PartNumber><ETag>5890595e16cbebb8866e1842e4bd6ec7</ETag></Part></CompleteMultipartUpload>\s*
    !x;
    my $resp = HTTP::Response->new(200, 'OK');
    $connect->send_response($resp);
};

test_case "Multipart upload should work with Content-type" => sub {
    my ($msg, $ceph) = @_;
    my $multipart_data = $ceph->initiate_multipart_upload('mykey', 'somemd5', 'text/plain');
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->header('Content-type') eq 'text/plain';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->content(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Bucket>testbucket</Bucket>
    <Key>mykey</Key>
    <UploadId>VXBsb2FkIElEIGZvciA2aWWpbmcncyBteS1tb3ZpZS5tMnRzIHVwbG9hZA</UploadId>
</InitiateMultipartUploadResult>
XML
    $connect->send_response($resp);
};

# download

test_case "Download single request" => sub {
    my ($msg, $ceph) = @_;
    my ($dataref, $left, $etag, $custom_md5) = $ceph->download_with_range('mykey');
    is $$dataref, "HeyThere", $msg

} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    my $body = "HeyThere";
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex($body));
    $resp->content($body);
    $connect->send_response($resp);
};

test_case "Download zero-size file" => sub {
    my ($msg, $ceph) = @_;
    my ($dataref, $left, $etag, $custom_md5) = $ceph->download_with_range('mykey');
    is $$dataref, "", $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => md5_hex(''));
    $resp->content('');
    $connect->send_response($resp);
};

test_case "Download unexisting object" => sub {
    my ($msg, $ceph) = @_;
    my ($dataref, $left, $etag, $custom_md5) = $ceph->download_with_range('mykey');
    ok ! defined $dataref, $msg;
    ok ! defined $etag, $msg;
    ok ! defined $left, $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    my $resp = HTTP::Response->new(404, 'Not Found');
    $resp->content_type('application/xml');
    $resp->content(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<Error>
<Code>NoSuchKey</Code>
<Message>The specified key does not exist.</Message>
<Key>mykey</Key>
<RequestId>hdhjdkksd8876ahks</RequestId>
<HostId>test</HostId>
</Error>
XML
    $connect->send_response($resp);
};

test_case "Download wrong bucket" => sub {
    my ($msg, $ceph) = @_;
    ok ! eval { $ceph->download_with_range('mykey'); 1 }, $msg;
    like "$@", qr/NoSuchBucket/;
} => sub {
    my ($msg, $connect, $request) = @_;
    my $resp = HTTP::Response->new(404, 'Not Found');
    $resp->content_type('application/xml');
    $resp->content(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<Error>
<Code>NoSuchBucket</Code>
<Message>The specified bucket does not exist.</Message>
<BucketName>sdsfds</BucketName>
<RequestId>hdhjdkksd8876ahks</RequestId>
<HostId>test</HostId>
</Error>
XML
    $connect->send_response($resp);
};

# multi-segment download

test_case "multi-segment download" => sub {
    my ($msg, $ceph) = @_;
    my ($dataref, $left, $etag, $custom_md5) = $ceph->download_with_range('mykey', 2, 4);
    is $etag, md5_hex('Xy');
    is $$dataref, 'Xy';
    is $left, 10;
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    die unless $request->header('Range') eq 'bytes=2-4';
    my $resp = HTTP::Response->new(206, 'OK');
    $resp->header('Content-Range', 'bytes 2-4/15');
    $resp->header('ETag', md5_hex('Xy'));
    $resp->content('Xy');
    $connect->send_response($resp);
};

# size

test_case "Get size" => sub {
    my ($msg, $ceph) = @_;
    is $ceph->size('mykey'), 42, $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    die unless $request->method eq 'HEAD';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header('Content-Length' => 42);
    $resp->header(ETag => "54b0c58c7ce9f2a8b551351102ee0938");
    $connect->send_response($resp);
};

test_case "Get size when in zero-size object Content-Length is omited" => sub {
    my ($msg, $ceph) = @_;
    is $ceph->size('mykey'), 0;
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    die unless $request->method eq 'HEAD';
    my $resp = HTTP::Response->new(200, 'OK');
    $resp->header(ETag => "d41d8cd98f00b204e9800998ecf8427e");
    $connect->send_response($resp);
};

test_case "Get size for non existing key" => sub {
    my ($msg, $ceph) = @_;
    ok ! defined $ceph->size('mykey'), $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    my $resp = HTTP::Response->new(404, 'Not Found');
    $connect->send_response($resp);
};

test_case "Get size should trap other errors with different codes" => sub {
    my ($msg, $ceph) = @_;
    ok ! eval { $ceph->size('mykey'); 1 }, $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    my $resp = HTTP::Response->new(403, 'Permission denied');
    $connect->send_response($resp);
};


# delete

test_case "Delete object" => sub {
    my ($msg, $ceph) = @_;
    $ceph->delete('mykey');
    ok $msg;
} => sub {
    my ($msg, $connect, $request) = @_;
    die unless $request->url eq '/testbucket/mykey';
    die unless $request->method eq 'DELETE';
    my $resp = HTTP::Response->new(204, 'OK');
    $connect->send_response($resp);
};


#
# Non-HTTP tests
# TODO: can move to separate file
#

# query_string_authentication_uri

{
    my $ceph = WebService::CEPH::NetAmazonS3->new(
        protocol => 'http',
        host => 'example.com',
        bucket => 'testbucket',
        key => 'abc',
        secret => 'def'
    );
    my $expires = time+86400;
    like
        $ceph->query_string_authentication_uri('mykey', $expires),
        qr!http://example.com/testbucket/mykey\?AWSAccessKeyId=abc\&Expires=${expires}\&Signature=!;

}

#
# / Non-HTTP tests
#

##
## Test engine
##

pipe(READER, WRITER);
if (!fork) { # child
    close READER;
    WRITER->autoflush(1);
    my $d = 1 ? # HTTP
        HTTP::Daemon->new(Timeout => 20, LocalAddr => '127.0.0.1') :
        HTTP::Daemon::SSL->new(Timeout => 20, LocalAddr => '127.0.0.1'); # need certs/ dir
    $SIG{PIPE}='IGNORE';
    print WRITER "Please to meet you at: <URL:", $d->url, ">\n";

    $| = 1;

    while (my $cb = shift @child_cb) {
        my $c = $d->accept;
        my $r = $c->get_request;
        if ($r) {
            $cb->(shift(@messages_server)." (server)", $c, $r);
        }
        else {
            $c = undef;  # close connection
        }
    }
    exit;
}
else { # parent
    close WRITER;
    my $greeting = <READER>;
    $greeting =~ m!<URL:https?://([^/]+)/>! or die;
    my $base = $1;
    print "# HOST/PORT $base\n";
    for (@parent_cb) {
        my $ceph = WebService::CEPH::NetAmazonS3->new(
            protocol => 'http',
            host => $base, # documented as host, but accepts host:port
            bucket => 'testbucket',
            key => 'abc',
            secret => 'def'
        );
        local $SIG{CHLD}=sub{
            local ($!, $?, $@);
            waitpid(-1, WNOHANG);
            die "Server died $?" if $?;
        };
        $_->(shift(@messages_client). " (client)", $ceph);
    }
    wait;
}
done_testing;  # mandatory for test robustness
