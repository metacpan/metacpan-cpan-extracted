package Weixin::Client;
use File::Temp qw/tempfile/;
sub _get_qrcode_image{
    my $self = shift;
    my $qrcode_uuid = shift;
    my $api = 'https://login.weixin.qq.com/qrcode/'; 
    my @query_string = (
        t => "webwx",
    ); 
    my $r = $self->http_get(Weixin::Util::gen_url($api . $qrcode_uuid,@query_string));
    return undef unless defined $r;
    my ($fh, $filename) = tempfile("weixin_qrcode_XXXX",SUFFIX =>".jpg",DIR => $self->{tmpdir}); 
    binmode $fh;
    print $fh $r;
    close $fh;
    console "登录二维码已经下载到本地 [ $filename ] \n";
    return $filename; 
}

1;
