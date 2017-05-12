# -*- perl -*-

# Copyright (c) 2009 by Jeff Weisberg
# Author: Jeff Weisberg
# Created: 2009-Jun-18 12:38 (EDT)
# Function: AC Puzzle Plugin
#
# $Id: SolveMedia.pm,v 1.1 2010/09/13 18:01:06 ilia Exp $

package WWW::SolveMedia;
use Carp;
use JSON;
use LWP::UserAgent;
use Digest::SHA1 'sha1_hex';
use strict;

our $VERSION 		= '1.1';

my $AC_API_HTTP		= 'http://api.solvemedia.com';
my $AC_API_HTTPS	= 'https://api-secure.solvemedia.com';
my $AC_VFY_HTTP		= 'http://verify.solvemedia.com';
my $AC_SIGNUP_URL	= 'http://api.solvemedia.com/public/signup';

# c-key, v-key, h-key, opts
sub new {
    my $class = shift;
    my $ckey  = shift;
    my $vkey  = shift;
    my $hkey  = shift;		# optional
    my $opts  = shift || {};	# for dev/testing

    croak "usage: new(ckey, vkey, hkey, [opts])\nyou may sign up for API keys at $AC_SIGNUP_URL"
      unless $ckey && $vkey;

    return bless {
        ckey	=> $ckey,
        vkey	=> $vkey,
        hkey	=> $hkey,
        http	=> $AC_API_HTTP,
        https	=> $AC_API_HTTPS,
        verify	=> $AC_VFY_HTTP,
        %$opts,
    }, $class;
}

# error_p, ssl_p, jsopts
sub get_html {
    my $me   = shift;
    my $errp = shift;
    my $sslp = shift;
    my $opts = shift;

    my $html = "<!-- start solvemedia puzzle widget -->\n";

    if( $opts ){
        $html .= "  <script>\n    var ACPuzzleOptions = "
          . encode_json($opts)
          . ";\n  </script>\n";
    }

    my $baseurl = $sslp ? $me->{https} : $me->{http};
    my $param   = $errp ? ';error=1' : '';

    $html .= <<WIDGET;
  <script type="text/javascript"
     src="$baseurl/papi/challenge.script?k=$me->{ckey}$param">
  </script>

  <noscript>
     <iframe src="$baseurl/papi/challenge.noscript?k=$me->{ckey}$param"
         height="300" width="500" frameborder="0"></iframe><br>
     <textarea name="adcopy_challenge" rows="3" cols="40">
     </textarea>
     <input type="hidden" name="adcopy_response"
         value="manual_challenge">
  </noscript>
<!-- end solvemedia puzzle widget -->
WIDGET
    ;

    return $html;
}

# ip, challenge, answer
sub check_answer {
    my $me     = shift;
    my $ipaddr = shift;
    my $ch     = shift;
    my $ans    = shift;

    # QQQ - validate more before sending?
    return { is_valid => 0, error => 'missing challenge' } unless $ch;
    return { is_valid => 0, error => 'missing client-ip' } unless $ipaddr;

    my $ua  = LWP::UserAgent->new( agent => "SolveMedia perl/$VERSION");
    my $res =  $ua->post( "$AC_VFY_HTTP/papi/verify", {
        privatekey	=> $me->{vkey},
        remoteip	=> $ipaddr,
        challenge	=> $ch,
        response	=> $ans,
    });

    unless( $res->is_success() ){
        # QQQ - return what error?
        carp "check_answer - server error: " . $res->status_line;
        return { is_valid => 0, error => 'server error' };
    }

    my($pass, $msg, $check) = split /\n/, $res->content();
    chomp($check);

    unless( $pass eq 'true' ){
        return { is_valid => 0, error => $msg };
    }

    # validate message authenticator
    if( $me->{hkey} ){
        my $hash = sha1_hex("$pass$ch$me->{hkey}");
        unless( $hash eq $check ){
            carp "check_answer - message authentication failed. either:
1) you are using an incorrect hash-key,
2) evil hackers trying to attack the system.";
            return { is_valid => 0, error => 'message authentication check failed' };
        }
    }

    # Yay!
    return { is_valid => 1 };

}

1;

__END__

=head1 NAME

WWW::SolveMedia - an interface to the Solve Media puzzle API

=head1 SYNOPSIS

  use WWW::SolveMedia;

  my $c = WWW::SolveMedia->new( 'my challenge key',
                            'my verification key',
                            'my hash key' );

  # output widget
  print $c->get_html();

  # check answer
  my $result = $c->check_answer( $ENV{REMOTE_ADDR}, $challenge, $response );

  if( $result->{is_valid} ){
      print "Yay!";
  }else{
      print "Dang it :-(";
  }


=head1 DESCRIPTION

A Solve Media Puzzle can determine whether the user is a computer or human.
It is typically used on websites to prevent abuse and block bots.

=head1 INTERFACE

=head2 new( ckey, vkey, hkey )

Create a new object. You need to pass in your Solve Media API keys (available for free at the Solve Media website, see below).

=head2 get_html( error_p, ssl_p, widget_opts )

Generate HTML to place on your web page.

=over

=item C<error_p>

If set, this will cause the Solve Media widget to display an error message.

=item C<ssl_p>

If set, the generated html widget will use https instead of http.
You should set this to match your web page, to prevent the user's
browser from displaying a warning.

=item C<widget_opts>

Optional. A reference to a hash of options for the widget.
The Solve Media widget supports the following options:

=over

=item C<theme>

Styling theme to use. For example 'red', 'purple', 'black', 'white'.

=item C<size>

Size of the widget. 'standard', 'small', 'medium', 'large'.

=item C<lang>

Language to use. 'en', 

=back

See the Solve Media web site (below) for complete documentation on options.

=back


=head2 check_answer( client_ip, challenge, answer )

After the user has filled in and submitted the form, check the answer
to determine whether they are human. returns a hashref containing
C<is_valid> and C<error>.

=over

=item C<client_ip>

the user's IP address in dotted quad format.
can often be found in $ENV{REMOTE_ADDR}.

=item C<challenge>

the puzzle challenge-id.
can be found in the form field C<adcopy_challenge>

=item C<answer>

the user's answer.
can be found in the form field C<adcopy_response>

=item C<is_valid>

boolean result.

=item C<error>

if the user failed the test, this will contain a terse message explaining.

=back

=head1 BUGS

There are no known bugs in the module.

=head1 SEE ALSO

    http://www.solvemedia.com/

=head1 LICENSE

This software may be copied and distributed under the terms
found in the Perl "Artistic License".

A copy of the "Artistic License" may be found in the standard
Perl distribution.

=cut


