#
# Copyleft (l) 2000-2017 Thomas v.D. <tlinden@cpan.org>.
#
# leo may be
# used and distributed under the terms of the GNU General Public License.
# All other brand and product names are trademarks, registered trademarks
# or service marks of their respective holders.

package WWW::Dict::Leo::Org;
$WWW::Dict::Leo::Org::VERSION = "2.02";

use strict;
use warnings;
use English '-no_match_vars';
use Carp::Heavy;
use Carp;
use IO::Socket::SSL;
use MIME::Base64;
use XML::Simple;
use Encode;

sub debug;

sub new {
  my ($class, %param) = @_;
  my $type = ref( $class ) || $class;

  my %settings        = (
                         "-Host"           => "dict.leo.org",
                         "-Port"           => 443,
                         "-UserAgent"      => "Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0",
                         "-Proxy"          => "",
                         "-ProxyUser"      => "",
                         "-ProxyPass"      => "",
                         "-Debug"          => 0,
                         "-Language"       => "en",           # en2de, de2fr, fr2de, de2es, es2de
                         "data"            => {}, # the results
                         "section"         => [],
                         "title"           => "",
                         "segments"        => [],
                         "Maxsize"         => 0,
                         "Linecount"       => 0,
                        );

  foreach my $key (keys %param) {
    $settings{$key} = $param{$key}; # override defaults
  }

  my $self = \%settings;
  bless $self, $type;

  return $self;
}

sub translate {
  my($this, $term) = @_;

  if (! $term) {
    croak "No term to translate given!";
  }

  my $linecount = 0;
  my $maxsize   = 0;
  my @match     = ();

  #
  # form var transitions for searchLoc(=translation direction) and lp(=language)
  my %lang = ( speak => "ende" );

  my @langs = qw(en es ru pt fr pl ch it);
  if ($this->{"-Language"}) {
    # en | fr | ru2en | de2pl etc
    # de2, 2de, de are not part of lang spec
    if (! grep { $this->{"-Language"} =~ /$_/ } @langs) {
      croak "Unsupported language: " . $this->{"-Language"};
    }
    my $spec = $this->{"-Language"};
    my $l;
    if ($spec =~ /(..)2de/) {
      $l = $1;
      $this->{"-Language"} = -1;
      $lang{speak} = "${l}de";
    }
    elsif ($spec =~ /de2(..)/) {
      $l = $1;
      $this->{"-Language"} = 1;
      $lang{speak} = "${l}de";
    }
    else {
      $lang{speak} =  $this->{"-Language"} . 'de';
      $this->{"-Language"} = 0;
    }
  }

  # add language
  my @form;
  push @form, "lp=$lang{speak}";

  #
  # process whitespaces
  #
  my $query = $term;
  $query =~ s/\s\s*/ /g;
  $query =~ s/\s/\+/g;
  push @form, "search=$query";

  #
  # make the query cgi'ish
  #
  my $form = join "&", @form;

  # store for result caching
  $this->{Form} = $form;

  #
  # check for proxy settings and use it if exists
  # otherwise use direct connection
  #
  my ($url, $site);
  my $ip = $this->{"-Host"};
  my $port = $this->{"-Port"};
  my $proxy_user = $this->{"-ProxyUser"};
  my $proxy_pass = $this->{"-ProxyPass"};

  if ($this->{"-Proxy"}) {
    my $proxy = $this->{"-Proxy"};
    $proxy =~  s/^http:\/\///i;
    if ($proxy =~ /^(.+):(.+)\@(.*)$/) {
      # proxy user account
      $proxy_user = $1;
      $proxy_pass = $2;
      $proxy      = $3;
      $this->debug( "proxy_user: $proxy_user");
    }
    my($host, $pport) = split /:/, $proxy;
    if ($pport) {
      $url = "http://$ip:$port/dictQuery/m-vocab/$lang{speak}/query.xml";
      $port = $pport;
    }
    else {
      $port = 80;
    }
    $ip = $host;
    $this->debug( "connecting to proxy:", $ip, $port);
  }
  else {
    $this->debug( "connecting to site:", $ip, "port", $port);
    $url = "/dictQuery/m-vocab/$lang{speak}/query.xml";
  }

  my $conn = new IO::Socket::SSL(
                                 #Proto    => "tcp",
                                  PeerAddr => $ip,
                                 PeerPort => $port,
                                 SSL_verify_mode => SSL_VERIFY_NONE
                                 ) or die "Unable to connect to $ip:$port: $!\n";
  $conn->autoflush(1);

  $this->debug( "GET $url?$form HTTP/1.0");
  print $conn "GET $url?$form HTTP/1.0\r\n";

  # be nice, simulate Konqueror.
  print $conn 
    qq($this->{"-UserAgent"}
Host: $this->{"-Host"}:$this->{"-Port"}
Accept: text/*;q=1.0, image/png;q=1.0, image/jpeg;q=1.0, image/gif;q=1.0, image/*;q=0.8, */*;q=0.5
Accept-Charset: iso-8859-1;q=1.0, *;q=0.9, utf-8;q=0.8
Accept-Language: en_US, en\r\n);

  if ($this->{"-Proxy"} and $proxy_user) {
    # authenticate
    # construct the auth header
    my $coded = encode_base64("$proxy_user:$proxy_pass");
    $this->debug( "Proxy-Authorization: Basic $coded");
    print $conn "Proxy-Authorization: Basic $coded\r\n";
  }

  # finish the request
  print $conn "\r\n";

  #
  # parse dict.leo.org output
  #
  $site = "";
  my $got_headers = 0;
  while (<$conn>) {
    if ($got_headers) {
      $site .= $_;
    }
    elsif (/^\r?$/) {
      $got_headers = 1;
    }
    elsif ($_ !~ /HTTP\/1\.(0|1) 200 OK/i) {
      if (/HTTP\/1\.(0|1) (\d+) /i) {
        # got HTTP error
        my $err = $2;
        if ($err == 407) {
          croak "proxy auth required or access denied!\n";
          close $conn;
          return ();
        }
        else {
          croak "got HTTP error $err!\n";
          close $conn;
          return ();
        }
      }
    }
  }

  close $conn or die "Connection failed: $!\n";
  $this->debug( "connection: done");

  $this->{Linecount} = 0;
  $this->{Maxsize} = 0;

  # parse the XML
  my $xml = new XML::Simple;
  my $data = $xml->XMLin($site,
    ForceArray => [ 'section', 'entry' ],
    ForceContent => 1,
    KeyAttr => { side => 'lang' }
  );

  my (@matches, $from_lang, $to_lang);
  $from_lang = substr $lang{speak}, 0, 2;
  $to_lang   = substr $lang{speak}, 2, 2;

  foreach my $section (@{$data->{sectionlist}->{section}}) {
    my @entries;
    foreach my $entry (@{$section->{entry}}) {

      my $left   = $this->parse_word($entry->{side}->{$from_lang}->{words}->{word});
      my $right  = $this->parse_word($entry->{side}->{$to_lang}->{words}->{word});

      push @entries, { left => $left, right => $right };
      if ($this->{Maxsize} < length($left)) {
        $this->{Maxsize} = length($left);
      }
      $this->{Linecount}++;
    }
    push @matches, {
                    title => encode('UTF-8', $section->{sctTitle}),
                    data => \@entries
                   };
  }

  return @matches;
}

# parse all the <word>s and build a string
sub parse_word {
  my ($this, $word) = @_;
  if (ref $word eq "HASH") {
    if ($word->{content}) {
      return encode('UTF-8', $word->{content});
    }
    elsif ($word->{cc}) {
      # chinese simplified, traditional and pinyin
      return encode('UTF-8', $word->{cc}->{cs}->{content} . "[" .
                    $word->{cc}->{ct}->{content} . "] " .
                    $word->{cc}->{pa}->{content});
    }
  }
  elsif (ref $word eq "ARRAY") {
    # FIXME: include alternatives, if any
    return encode('UTF-8', @{$word}[-1]->{content});
  }
  else {
    return encode('UTF-8', $word);
  }
}

sub grapheme_length {
  my($this, $str) = @_;
  my $count = 0;
  while ($str =~ /\X/g) { $count++ };
  return $count;
}

sub maxsize {
  my($this) = @_;
  return $this->{Maxsize};
}

sub lines {
  my($this) = @_;
  return $this->{Linecount};
}

sub form {
  my($this) = @_;
  return $this->{Form};
}

sub debug {
  my($this, @msg) = @_;
  if ($this->{"-Debug"}) {
    print STDERR "%DEBUG: " . join(" ", @msg) . "\n";
  }
}


1;

=encoding ISO8859-1

=head1 NAME

WWW::Dict::Leo::Org - Interface module to dictionary dict.leo.org

=head1 SYNOPSIS

 use WWW::Dict::Leo::Org;
 my $leo = new WWW::Dict::Leo::Org();
 my @matches = $leo->translate($term);

=head1 DESCRIPTION

B<WWW::Dict::Leo::Org> is a module which connects to the website
B<dict.leo.org> and translates the given term. It returns an array
of hashes. Each hash contains a left side and a right side of the
result entry.

=head1 OPTIONS

B<new()> has several parameters, which can be supplied as a hash.

All parameters are optional.

=over

=item I<-Host>

The hostname of the dict website to use. For the moment only dict.leo.org
is supported, which is also the default - therefore changing the
hostname would not make much sense.

=item I<-Port>

The tcp port to use for connecting, the default is 80, you shouldn't
change it.

=item I<-UserAgent>

The user-agent to send to dict.leo.org site. Currently this is the
default:

 Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9

=item I<-Proxy>

Fully qualified proxy server. Specify as you would do in the well
known environment variable B<http_proxy>, example:

 -Proxy => "http://192.168.1.1:3128"

=item I<-ProxyUser> I<-ProxyPass>

If your proxy requires authentication, use these parameters
to specify the credentials.

=item I<-Debug>

If enabled (set to 1), prints a lot of debug information to
stderr, normally only required for developers or to
report bugs (see below).

=back

Parameters to control behavior of dict.leo.org:

=over

=item I<-Language>

Translation direction. Please note that dict.leo.org always translates
either to or from german.

The following languages are supported: english, polish, spanish, portuguese
russian and chinese.

You can  specify only the country  code, or append B<de2>  in order to
force translation to german, or  preprend B<de2> in order to translate
to the other language.

Valid examples:

 ru     to or from russian
 de2pl  to polish
 es2de  spanish to german

Valid country codes:

 en    english
 es    spanish
 fr    french
 ru    russian
 pt    portuguese
 pl    polish
 ch    chinese

Default: B<en>.

=back

=head1 METHODS

=head2 translate($term)

Use this method after initialization to connect to dict.leo.org
and translate the given term. It returns an array of hashes containing
the actual results.

 use WWW::Dict::Leo::Org;
 use Data::Dumper;
 my $leo = new WWW::Dict::Leo::Org();
 my @matches = $leo->translate("test");
 print Dumper(\@matches);

which prints:

 $VAR1 = [
         {
          'data' => [
                     {
                      'left' => 'check',
                      'right' => 'der Test'
                     },
                     {
                      'left' => 'quiz (Amer.)',
                      'right' => 'der Test    [Schule]'
                     ],
                     'title' => 'Unmittelbare Treffer'
                   },
          {
           'data' => [
                      {
                       'left' => 'to fail a test',
                       'right' => 'einen Test nicht bestehen'
                      },
                      {
                       'left' => 'to test',
                       'right' => 'Tests macheneinen Test machen'
                      }
                     ],
           'title' => 'Verben und Verbzusammensetzungen'
          },
          'data' => [
                     {
                      'left' => 'testing  adj.',
                      'right' => 'im Test'
                     }
                    ],
          'title' => 'Wendungen und Ausdrücke'
         }
        ];


You might take a look at the B<leo> script how to process
this data.

=head2 maxsize()

Returns the size of the largest returned term (left side).

=head2 lines()

Returns the number of translation results.

=head2 form()

Returns the submitted form uri.

=head1 SEE ALSO

L<leo>

=head1 COPYRIGHT

WWW::Dict::Leo::Org - Copyright (c) 2007-2017 by Thomas v.D.

L<http://dict.leo.org/> -
Copyright (c) 1995-2016 LEO Dictionary Team.

=head1 AUTHOR

Thomas v.D. <tlinden@cpan.org>

=head1 HOW TO REPORT BUGS

Use L<rt.cpan.org> to report bugs, select the queue for B<WWW::Dict::Leo::Org>.

Please don't forget to add debugging output!

=head1 VERSION

  2.01

=cut
