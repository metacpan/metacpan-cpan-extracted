package WWW::FastPass;

use 5.008008;
use strict;
use warnings;

use Digest::SHA1 qw(sha1_base64);
use Net::OAuth;

our $VERSION = '0.05';

use constant SCRIPT_FRAGMENT => <<EOF;
<script type="text/javascript">
    var GSFN;
    if(GSFN == undefined) { GSFN = {}; }

    (function(){
        add_js = function(jsid, url) {
            var head = document.getElementsByTagName("head")[0];
            script = document.createElement('script');
            script.id = jsid;
            script.type = 'text/javascript';
            script.src = url;
            head.appendChild(script);
        }

        add_js("fastpass_common", 
               document.location.protocol + 
                   "//getsatisfaction.com/javascripts/fastpass.js");

        if (window.onload) { 
            var old_load = window.onload; 
        }
        window.onload = function() {
            if (old_load) old_load();
            add_js("fastpass", "%s");
        }
    })()
</script>
EOF

sub url
{
    my ($key, $secret, $email, $name, $uid, $is_secure, $extra_fields) = @_;

    my $request_url =
        (($is_secure) ? 'https' : 'http').'://getsatisfaction.com/fastpass';

    my %extra_params = (
        name  => $name,
        email => $email,
        uid   => $uid,
        (defined $extra_fields) ? %{$extra_fields} : ()
    );

    my $request = Net::OAuth->request("consumer")->new(
        version          => '1.0',
        consumer_key     => $key,
        consumer_secret  => $secret,
        request_url      => $request_url,
        request_method   => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp        => time(),
        nonce            => sha1_base64(time() . $$ . rand()),
        callback         => 'oob',
        extra_params     => \%extra_params
    );
    
    $request->sign();

    return $request->to_url();
}

sub script
{
    return sprintf SCRIPT_FRAGMENT(), url(@_);
}

1;
__END__

=head1 NAME

WWW::FastPass - Get Satisfaction FastPass functions

=head1 SYNOPSIS

  use WWW::FastPass;

  my $url = WWW::FastPass::url($key, $secret,
                               $user_email,
                               $user_name,
                               $user_uid);

=head1 DESCRIPTION

This is a very simple wrapper around L<Net::OAuth> for
constructing URLs for use with Get Satisfaction's
(L<http://getsatisfaction.com>) FastPass service. It provides the same
functions as the example libraries on the FastPass implementation page
(L<http://getsatisfaction.com/developers/fastpass-implementation>).

=head1 PUBLIC FUNCTIONS

=over 4

=item B<url>

Takes five mandatory arguments and two optional arguments:
C<consumer_key>, C<consumer_secret>, C<user_email>, C<user_name>,
C<user_uid>, C<is_secure> and C<extra_fields>. C<consumer_key> and
C<consumer_secret> are available on the Admin/FastPass page, once you
have logged in to Get Satisfaction. C<user_uid> must uniquely identify
the relevant user, and must not change while the user account exists
in the system. C<is_secure> defaults to false - if true, the C<https>
Get Satisfaction domain will be used when constructing the FastPass
URL. C<extra_fields> is an optional hashref of user data, which data
will be present in the returned URL.

Returns a FastPass URL (as a string) that can in turn be used as the
C<fastpass> argument when constructing your community site's URL.

=item B<script>

Takes the same arguments as L<url>. Returns a HTML script fragment -
once executed, this will add extra C<script> tags to the C<head>
section of the page, that will in turn allow you to use the
C<GSFN.goto_gsfn> JavaScript function to create links to your Get
Satisfaction community. Alternatively, you can use the value returned
by L<url> as the C<src> attribute of a C<script> tag, and that will
have the same effect. See the FastPass implementation page for more
details.

=back

=head1 ACKNOWLEDGMENTS

This module is basically a direct port of the libraries available for
download on the FastPass implementation page.

=head1 AUTHOR

Tom Harrison, E<lt>tomh5908@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012 by Tom Harrison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
