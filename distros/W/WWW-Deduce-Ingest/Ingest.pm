# -*- perl -*-

# Copyright (c) 2019
# Author: Jeff Weisberg
# Created: 2019-Jul-22 16:07 (EDT)
# Function: Deduce Ingest API

package WWW::Deduce::Ingest;
use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;
use Digest::SHA 'sha1_hex', 'sha256_hex';
use Digest::MD5 'md5_hex';

use strict;

our $VERSION      = '1.1';

my $COLLECT_URL  = '//lore.deduce.com/p/collect';
my $EVENT_URL     = 'https://event.deduce.com/p/event';  # always https
my $VERHASH       = substr(sha1_hex("perl/$VERSION"), 0, 16);
my $TIMEOUT       = 2;

my $limit;
my $lastt;


sub new {
    my $class  = shift;
    my $site   = shift;
    my $apikey = shift;
    my $opts   = shift || {};

    return bless {
        site        => $site,
        apikey      => $apikey,
        collect_url => $COLLECT_URL,
        event_url   => $EVENT_URL,
        %$opts,
    }, $class;
}

sub html {
    my $me    = shift;
    my $email = shift;
    my $opts  = shift;

    my $data = { site => $me->{site}, vers => $VERHASH };
    $data->{testmode} = JSON::true if $opts->{testmode} || $me->{testmode};

    if( email_valid($email) ){
        $email = trim_space($email);

        $data->{ehlm5} = md5_hex(lc $email);
        $data->{ehum5} = md5_hex(uc $email);
        $data->{ehls1} = sha1_hex(lc $email);
        $data->{ehus1} = sha1_hex(uc $email);
        $data->{ehls2} = sha256_hex(lc $email);
        $data->{ehus2} = sha256_hex(uc $email);
    }

    my $url = $opts->{url};
    unless( $url ){
        if( $opts->{use_ssl} ){
            $url = 'https:' . $me->{collect_url};
        }elsif( exists  $opts->{use_ssl} ){
            $url = 'http:' . $me->{collect_url};
        }else{
            $url = $me->{collect_url};
        }
    }

    my $json = to_json($data, {utf8 => 1, pretty => 1});

    my $html = <<EOS;
<script type="text/javascript">
var dd_info = $json
</script>
<script type="text/javascript" src="$url" async></script>
EOS
;

    return $html;

}


# return undef on success, else an error message

sub events {
    my $me   = shift;
    my $evts = shift;
    my $opts = shift;

    return if limited();

    my $site    = $me->{site};
    my $apikey  = $me->{apikey};
    my $url     = $opts->{url}     || $me->{event_url};
    my $timeout = $opts->{timeout} || ($TIMEOUT + @$evts/10);

    my $post = { site => $site, apikey => $apikey, vers => $VERHASH };
    $post->{backfill} = JSON::true if $opts->{backfill};
    $post->{testmode} = JSON::true if $opts->{testmode} || $me->{testmode};
    $post->{events} = [ map { fixup_evt($_) } @$evts ];

    # print STDERR to_json($post);

    # https post
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/json');
    $req->content( to_json($post) );

    my $ua = LWP::UserAgent->new(timeout => $timeout);
    my $res = $ua->request($req);

    if( $res->code() == 200 ){
        adjust_ok();
        return ;
    }

    adjust_fail();
    return $res->code() . " " . $res->content();
}

sub event {
    my $me         = shift;
    my $email      = shift;
    my $ip         = shift;
    my $event      = shift;
    my $additional = shift;
    my $opts       = shift;

    return "invalid email" unless email_valid($email);

    my %event;
    %event = %$additional if $additional;
    $event{email} = $email;
    $event{ip} = $ip;
    $event{event} = $event;

    $me->events( [\%event], $opts);
}

# hash + delete plaintext email, email_prev, cc
sub fixup_evt {
    my $e = shift;

    my %e = %$e;
    my $email = $e{email};

    if( email_valid($email) ){
        $email = lc trim_space($email);
        $e{ehls1} = sha1_hex($email);
        delete $e{email};

        unless( exists $e{email_provider} ){
            $e{email_provider} = (split /\@/, $email)[1];
        }
    }

    if( email_valid($e{email_prev}) ){
        $e{ehls1_prev} = sha1_hex(lc trim_space($e{email_prev}));
        delete $e{email_prev};
    }

    if( $e{cc} ){
        my $cc = $e{cc};
        $cc =~ s/[^0-9]//;
        $e{ccs1} = sha1_hex($cc);
        delete $e{cc};
    }

    return \%e;
}

sub trim_space {
    my $s = shift;

    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub email_valid {
    my $e = shift;

    return $e =~ /.+\@.+\..+/;
}

# rate limit events if they are failing
sub limited {

    my $t = time();
    $limit ||= 0;
    $lastt ||= $t;
    my $dt = $t - $lastt;
    $lastt = $t;

    $limit *= 0.999 ** $dt;

    return rand(100) < $limit;
}
sub adjust_ok {
    $limit -= 5;
    $limit = 0 if $limit < 0;
}
sub adjust_fail {
    $limit = (9 * $limit + 100) / 10;
    $limit = 100 if $limit > 100;
}

=head1 NAME

WWW::Deduce::Ingest - an interface to Deduce Ingestion

=head1 SYNOPSIS

  use WWW:Deduce::Ingest;

  my $d = WWW::Deduce::Ingest->new( 'my site id', 'my secret api key' );

  # output html widget
  print $d->html('email@example.com');

  # send an event
  my $err = $d->event( 'email@example.com', '192.0.2.3', 'eventname', { ... }, $opts );
  print STDERR "uh oh! $err\n" if $err;


=head1 INTERFACE

=head2 new( site, apikey )

Create a new object. You need to pass in the site id and api key
that were assigned to you by Deduce.

=head2 html( email, opts )

Generate HTML to place on your web page.

=over

=item C<email>

The user's email address.
It will be processed and hashed, not used directly.

=back


=head2 event(email, client_ip, eventtype, additional, opts)

When something interesting happens on your site, tell Deduce.

=over

=item C<email>

The user's email address.
It will be processed and hashed, not used directly.


=item C<client_ip>

the user's IP address in dotted quad format (IPv4), or coloned octopus (IPv6).
can often be found in $ENV{REMOTE_ADDR}.

=item C<eventtype>

the event type.
Consult with Deduce support to determine the event types.

=item C<additional>

a hashref of event data to send.
Consult with Deduce support to determine data to send.

if you pass in 'email_prev' or 'cc' fields, they will be automatically
processed and hashed, not send directly.

=item C<returns>

if there is an error, the error message will be returned.
on success, nothing.

=back

=head2 events(evts, opts)

You can send several related events, by sending an array of event data.

=over

=item C<evts>

an array of event data (hashrefs).

the events must contain valid email, ip, and event fields.

any email, email_prev, and cc fields will automatically be processed and hashed.

=item C<returns>

if there is an error, the error message will be returned.
on success, nothing.

=back

=head1 BUGS

There are no known bugs in the module.

=head1 SEE ALSO

    http://www.deduce.com/

=head1 LICENSE

This software may be copied and distributed under the terms
found in the Perl "Artistic License".

A copy of the "Artistic License" may be found in the standard
Perl distribution.

=cut

1;
