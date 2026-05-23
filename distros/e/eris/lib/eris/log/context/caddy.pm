package eris::log::context::caddy;
# ABSTRACT: Convert the caddy JSON structure to the CEE format

use Const::Fast;
use Moo;
use namespace::autoclean;
with qw(
    eris::role::context
);

our $VERSION = '0.009'; # VERSION


sub sample_messages {
    my @msgs = split /\r?\n/, <<'EOF';
Jul  4 23:37:51 app2 caddy[2140]: {"level":"info","ts":1751672271.1656768,"logger":"http.log.access.log7","msg":"handled request","request":{"remote_ip":"172.69.176.57","remote_port":"44552","client_ip":"172.69.176.57","proto":"HTTP/2.0","method":"GET","host":"skepticampdc.org","uri":"/","headers":{"User-Agent":["Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"],"Cf-Visitor":["{\"scheme\":\"https\"}"],"Cache-Control":["no-cache"],"Cf-Connecting-Ip":["43.153.204.189"],"X-Forwarded-For":["43.153.204.189"],"Pragma":["no-cache"],"Accept":["text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"],"Upgrade-Insecure-Requests":["1"],"Referer":["http://skepticampdc.org"],"X-Forwarded-Proto":["https"],"Accept-Encoding":["gzip, br"],"Accept-Language":["zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"],"Cf-Ipcountry":["SG"],"Cdn-Loop":["cloudflare; loops=1"],"Cf-Ray":["95a273e959a4561c-SIN"]},"tls":{"resumed":false,"version":772,"cipher_suite":4865,"proto":"h2","server_name":"skepticampdc.org"}},"bytes_read":0,"user_id":"","duration":0.000712397,"size":1642,"status":200,"resp_headers":{"Content-Type":["text/html; charset=utf-8"],"Last-Modified":["Mon, 27 Jul 2015 16:00:47 GMT"],"Content-Encoding":["gzip"],"Server":["Caddy"],"Alt-Svc":["h3=\":443\"; ma=2592000"],"Vary":["Accept-Encoding"],"Etag":["\"axb90e14cpvk3ea-gzip\""]}}
Jul  4 23:37:52 app2 caddy[2140]: {"level":"info","ts":1751672272.5860772,"logger":"http.log.access.log7","msg":"handled request","request":{"remote_ip":"162.158.106.254","remote_port":"28088","client_ip":"162.158.106.254","proto":"HTTP/2.0","method":"GET","host":"skepticampdc.org","uri":"/robots.txt","headers":{"Cf-Connecting-Ip":["47.128.50.166"],"X-Forwarded-For":["47.128.50.166"],"Cf-Ipcountry":["SG"],"Accept-Encoding":["gzip, br"],"User-Agent":["Mozilla/5.0 (Linux; Android 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; Bytespider; spider-feedback@bytedance.com)"],"X-Forwarded-Proto":["https"],"Cf-Ray":["95a273f24b4ff91e-SIN"],"Cf-Visitor":["{\"scheme\":\"https\"}"],"Cdn-Loop":["cloudflare; loops=1"]},"tls":{"resumed":false,"version":772,"cipher_suite":4865,"proto":"h2","server_name":"skepticampdc.org"}},"bytes_read":0,"user_id":"","duration":0.000110532,"size":13,"status":403,"resp_headers":{"Alt-Svc":["h3=\":443\"; ma=2592000"],"Connection":["close"],"Content-Type":["text/plain; charset=utf-8"],"Server":["Caddy"]}}
EOF
    return @msgs;
}


my %mapping = qw(
    method   action
    size     out_bytes
    status   status
);

sub contextualize_message {
    my ($self,$log) = @_;

    my $c = $log->context;

    my %ctx = ();
    if ( my $r = $c->{request} ) {
        $ctx{src_ip} = $r->{$_} for qw(remote_ip client_ip);
        if ( my $h = $r->{headers} ) {
            foreach my $k ( qw(X-Forwarded-For Cf-Connecting-Ip) ) {
                next unless $h->{$k};
                foreach my $v ( @{ $h->{$k} } ) {
                    $ctx{src_ip} = $v;
                }
            }
            if ( my $uas = $h->{'User-Agent'} ) {
                $ctx{prod} = $uas->[-1];
            }
        }

        $ctx{proto_app}  = $r->{proto};
        $ctx{dst} = $r->{host};
        $ctx{file} = $r->{uri};
    }

    foreach my $k ( keys %mapping ) {
        $ctx{$mapping{$k}} = $c->{$k} if length $c->{$k};
    }
    $ctx{response_ms} = 1000 * $ctx{duration} if $ctx{duration};

    $log->add_context($self->name,\%ctx) if keys %ctx;
}


1;

__END__

=pod

=head1 NAME

eris::log::context::caddy - Convert the caddy JSON structure to the CEE format

=head1 VERSION

version 0.009

=head1 CONSUMES

=over 4

=item * L<eris::role::context>

=item * L<eris::role::plugin>

=back

=head1 METHODS

=head2 contextualize_message

Converts the caddy JSON log into the CEE style of the eris schemas.

=for Pod::Coverage sample_messages

=head1 SEE ALSO

L<eris::log::contextualizer>, L<eris::role::context>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
