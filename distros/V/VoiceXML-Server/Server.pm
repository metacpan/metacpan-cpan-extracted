# -*- Mode: perl; indent-tabs-mode: nil -*-

package VoiceXML::Server;

use diagnostics;
use strict;

($VoiceXML::Server::VERSION) = '$Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub _silliness {
    my $zz;
    $zz = $VoiceXML::Server::VERSION;
}
    

=head1 NAME

VoiceXML::Server -- An easy-to-use VoiceXML server class

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 use diagnostics;
 use strict;

 require VoiceXML::Server;
 my $server = VoiceXML::Server->new(avoidfirewall => 1);

 $server->Audio("Pick a number between 1 and 99.");

 my $num = int(rand(99)) + 1;

 while (1) {
     my $guess = $server->Listen(grammar => "NATURAL_NUMBER_THRU_99");
     if ($guess < $num) {
         $server->Audio("No, $guess is too low.  Try again.");
     } elsif ($guess > $num) {
         $server->Audio("No, $guess is too high.  Try again.");
     } else {
         $server->Audio("That's right, my number was $num.  OK, " .
                        "let's play again.  I'm thinking of a " .
                        "different number.");
         $num = int(rand(99)) + 1;
     }
 }

=head1 DESCRIPTION

C<VoiceXML::Server> is a class implementing a simple server for VoiceXML
applications.  It was designed in particular to work with Tellme
Studio ( http://studio.tellme.com/ ), although it should also work with
other VoiceXML products.

Using this library, you can make programs that you interact with over
the phone.  Using Tellme Studio, you can develop and debug your
program by calling a toll-free number.  You can then publish your
finished application to be a part of the main Tellme service, at
1-800-555-TELL.

Applications written using C<VoiceXML::Server> install as a CGI scripts.
However, unlike most web server software, they do not get repeatedly
executed every time the user responds to an interaction.  Instead, the
script gets invoked only once per user, and it can remember the state
of the interaction on the stack and in local variables.  This is a
much, much easier way to code than traditional web solutions provide,
as the above example should illustrate.

The disadvantage of this approach is that it can be more expensive to
support, and performance can suffer compared to hand-tuned VoiceXML code.

=head1 INSTALLATION

The trickiest part of all this is setting up Tellme Studio and an
initial application and getting things up and limping.  Once you've
done that, it's easy to tweak the application to make it do virtually
anything you can think of.

Here's the steps to get the above "guess a number" example code up and
running.

First, get yourself a webserver where you can install CGI scripts.
Learning about that is beyond the scope of this document.

Next, make sure that the version of perl on that server includes this
VoiceXML::Server module.  This is done by the usual CPAN method of
unpacking the tarball and running the following commands (you may have
to be root to do 'make install'):

    perl Makefile.PL
    make
    make test
    make install

Next, cut and paste the above example code into a file on your server.
I'll assume that file is called "guessanumber.cgi".  You may need to
change the first line to point to your perl executable.

Next, you can run the "guessanumber.cgi" executable on the command
line.  The VoiceXML::Server library will automatically detect that you are
running on the command line instead of being served from a webserver,
and will play the game in dumb terminal mode.  This is a very useful
technique for debugging the logic of your program without worrying
about all the telephony details.

When you can run guessanumber.cgi on the command line, then you know
you have all the perl setup done properly.  Next, go to
http://studio.tellme.com/ and create an account by clicking the "join
studio" link.  This is all pretty self-explainatory.

Once you're able to log into your Tellme Studio account, and have
accepted the terms of service, you need tell Studio where your
application lives.  Click on the "MyStudio" link at left of the
screen.  Log in if necessary.  Make sure the "Application URL" tab is
selected; click on it if it is not.  Then type the full URL to get to
your guessanumber.cgi script, and click the "Update" button.

At this point, you should be able to call the toll-free number listed
on that page.  Enter your Studio Developer ID and PIN on the phone,
and you should find yourself playing the "guess a number" game.

=head1 METHODS

The following methods are available:

=over 4

=cut

use HTTP::Daemon;
use HTTP::Status;
use LWP::UserAgent;
use POSIX 'setsid';

sub CheckArgs {
    my $ref = shift;
    my %ok;
    foreach my $k (@_) {
        $ok{$k} = 1;
    }
    foreach my $k (keys %$ref) {
        if (!$ok{$k}) {
            die "Illegal parameter $k";
        }
    }
}

my $theserver;                  # What a hack; takes advantage of the fact
                                # that we'll only ever have one.  Try to
                                # use as little as possible!


=item $server = VoiceXML::Server->new([name => value, ...]);

Constructs the server object.  Can take the following named arguments:

=over 4

=item minport

Specifies the smallest port number to try and use.  Defaults to 7500.

=item maxport

Specifies the biggest port number to try and use.  Defaults to 7550.

=item avoidfirewall

If set to 1 (as in the example at the top of this document), then
extra stuff will be done to avoid firewalls.  VoiceXML::Server works by
spawning off a new server process, speaking the HTTP protocol, usually
on a port between 7500 and 7550.  Sometimes firewalls will get in the
way and prevent the VoiceXML browser from reaching these ports.  If
you turn on C<avoidfirewall>, then things will always work, but there
will be a noticable performance penalty.  If at all possible, don't
use this.

If all the ports in the designated range are already being used, it
will continue to try and use a higher port number, but will turn on
the avoidfirewall behavior.  So, you can just punch a few ports
through your firewall, and have things work even if those get filled up.

=item debug

If you set debug to 1, then files will be created in /tmp containing
debugging output.  This is very useful to determine what causes
crashes or weird behaviors.  But remember, the first thing to try is
just running your program on the command line.

=back

=cut

sub new {
    my $pkg = shift;
    my $self;
    {
        my %hash;
        $self = bless(\%hash, $pkg);
    }

    $theserver = $self;

    my %args = @_;
    CheckArgs(\%args, ('minport', 'maxport', 'avoidfirewall', 'debug'));

    $self->{'outstr'} = [];
    $self->{'mode'} = "cmdline";
    if ($args{'debug'}) {
        $self->{'debug'} = 1;
        my $me = $0;
        $me =~ s@.*/([^/]*)$@$1@;
        $self->{'debugfilenamebase'} = "/tmp/$me";
    }

    if ($ENV{"QUERY_STRING"}) {

        # See if we were invoked with a "proxyfor" argument; if so, then just
        # be a firewall-dodging proxy thing.
        if ($ENV{"QUERY_STRING"} =~ /proxyfor=(\d+)\&(.*)$/) {
            DoProxyStuff($1, $2);
            exit;
        }
    }
        

    if ($ENV{'SERVER_NAME'} && $ENV{'SCRIPT_NAME'}) {
        $self->{'mode'} = "vxml";
        $self->{'origurl'} = "http://$ENV{'SERVER_NAME'}$ENV{'SCRIPT_NAME'}";
    }

    my $minport = $args{'minport'} || 7500;
    my $maxport = $args{'maxport'} || 7550;

    pipe(READPIPE, WRITEPIPE) || die "Can't create pipe";
    

    if ($self->{'mode'} eq 'cmdline') {
        return $self;
    }

    # OK, time to fork ourselves off into the background.

    if (!fork()) {
        open STDIN, '/dev/null' or DieLog("Can't read /dev/null: $!");
        open STDOUT, '>/dev/null' or DieLog("Can't write to /dev/null: $!");
        defined(my $pid = fork) or DieLog("Can't fork: $!");
        exit if $pid;
        setsid()                  or DieLog("Can't start a new session: $!");
        if ($self->{'debug'}) {
            my $stderrfilename = "$self->{'debugfilenamebase'}.stderr.$$";
            open STDERR, ">$stderrfilename"
                or DieLog("Can't make stderr go to $stderrfilename");
        } else {
            open STDERR, '>&STDOUT' or DieLog("Can't dup stdout: $!");
        }
            

        
        my $port = $minport - 1;
        while (!$self->{'daemon'}) {
            if ($port == $maxport) {
                Log("Couldn't find an unused port between $minport and $maxport");
                $args{'avoidfirewall'} = 1;
            }
            $port++;
            $self->{'daemon'} = HTTP::Daemon->new(LocalPort => $port);
        }

        if ($args{'avoidfirewall'}) {
            $self->{'myurl'} = $self->{'origurl'} . "?proxyfor=$port&";
        } else {
            $self->{'myurl'} = $self->{'daemon'}->url() . "?";
        }


        print WRITEPIPE $self->{'myurl'} . "\n";
        close(WRITEPIPE);

        # At this point, we are the real server process, and we can return
        # and start serving stuff.
        Log("Server ready; url is " . $self->{'daemon'}->url());
        $self->_waitForConnection();
        my $r = $self->{'connection'}->get_request();
        # We got the request, now (gasp) drop it on the floor and go respond
        # with our initial real page.
        return $self;
    }

    # Wait for the server process to start up and tell us its URL.
    my $url = <READPIPE>;
    close(READPIPE);
    chomp($url);
    $url = escapeHTML($url . "x=y");

    # And now tell the VoiceXML browser to reconnect to the server process.
    print qq{Cache-Control: no-cache
Content-type: text/vxml

<?xml version="1.0"?>
<!DOCTYPE vxml PUBLIC "-//Tellme Networks//Voice Markup Language 1.0//EN"
"http://resources.tellme.com/toolbox/vxml-tellme.dtd">

<vxml application="http://resources.tellme.com/lib/universals.vxml">

<form><block>
  <goto next="$url"/>
</block></form>

</vxml>
};
    exit;
}


sub DoProxyStuff ( $$ ) {
    my ($port, $args) = @_;
    my $url = "http://localhost:$port/?$args";
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new('GET', $url);
    my $buffer = "";
    my $response = $ua->request($request, sub {$buffer .= shift});
    print "Cache-Control: no-cache\n";
    print "Content-type: text/vxml\n\n";
    if ($response->is_error) {
        my $str = $response->message();
        print "<vxml><form><block><audio>$str</audio></block></form></vxml>\n";
    } else {
        print $buffer;
    }
    exit;
}

    
sub _waitForConnection {
    my $self = shift;
    delete $self->{'connection'};
    alarm(60);
    while (!$self->{'connection'}) {
        $self->{'connection'} = $self->{'daemon'}->accept();
    }
    alarm(0);
}

sub _MakeAbsoluteURL {
    my $self = shift;
    my ($url) = @_;
    
    $url =~ s/^['"](.*)["']$/$1/; # Strip surrounding quotes.

    if ($url =~ /^https?:/i) {
        # It's already an absolute URL; return it.
        return $url;
    }
    
    my $result = $self->{'origurl'};
    if ($url =~ m@^/@) {
        # URL starts with a slash, so it is relative to the root of our
        # original url.
        $result =~ s@(^https?://[^/]*)/.*$@$1@;
    } else {
        $result =~ s@/[^/]*$@/@;        # Trim everything after the last slash.
    }
    $result .= $url;
    return $result;
}
    


sub escapeHTML {
    my($self,$toencode) = @_;
    $toencode = $self unless ref($self);
    return undef unless defined($toencode);

    $toencode=~s/&/&amp;/g;
    $toencode=~s/\"/&quot;/g;
    $toencode=~s/>/&gt;/g;
    $toencode=~s/</&lt;/g;
    return $toencode;
}

=item $server->Audio([wav => 'file.wav'], [tts =>'text here']);

The C<Audio> method takes up to two named parameters, C<wav> and
C<tts>.  At least one of these must be provided.

=over 4

=item wav

C<wav> specifies a .wav audio file.  This file will be played.

=item tts

C<tts> specifies plain text.  (tts stands for Text To Speech.)  This
will be read in a computerized voice over the phone if a .WAV file
isn't specified or isn't found.

=back

You can also call C<Audio> with one or two non-named parameters.  If
you pass it only one parameter, it is assumed to be a C<tts> value.
If you pass it two parameters, the first one is treated as a C<wav>
value, and the second as a C<tts> value.

=cut

sub Audio
{
    my $self = shift;
    if (1 == @_) {
        @_ = ('tts' => $_[0]);
    } elsif (2 == @_ && $_[0] =~ /\.wav$/) {
        @_ = ('wav' => $_[0],
              'tts' => $_[1]);
    }
    my %args = @_;
    CheckArgs(\%args, ('tts', 'wav', 'data'));
    my $wav = $args{'wav'};
    my $tts = $args{'tts'};
    my $data = $args{'data'};
    if (!$wav && !$tts && !$data) {
        die "Must specify at least one of 'wav' or 'tts' to Audio";
    }
    if ($wav && $data) {
        die "Can't specify both 'wav' and 'data'.";
    }
    if ($self->{'mode'} eq 'cmdline') {
        my $msg = $tts || $wav || $data;
        print "$msg\n";
        return;
    }
    $tts ||= "";
    my $str;
    if ($wav) {
        $wav = $self->_MakeAbsoluteURL($wav);
        $str = qq{<audio src="$wav">};
    } elsif ($data) {
        $str = qq{<audio data="$data">};
    } else {
        $str = qq{<audio>};
    }
    $str .= escapeHTML($tts) . "</audio>";
    push(@{$self->{'outstr'}}, $str);
    Log("Saying $str");
}


=item $server->Pause(milliseconds => $num)

The C<Pause> method introduces a pause of the given number of
milliseconds. Use it between pieces of audio so that the audio sounds
more natural.  It must be called using the named parameter syntax.

=cut

sub Pause
{
    my $self = shift;
    my %args = @_;
    CheckArgs(\%args, ("milliseconds"));
    my $milli = $args{'milliseconds'};
    if (!$milli) {
        die "Must specify 'milliseconds' to Pause";
    }
    if ($self->{'mode'} eq 'cmdline') {
        return;
    }

    push(@{$self->{'outstr'}}, "<pause>$milli</pause>");
    Log("Pausing for $milli milliseconds");
}


=item $server->Listen(grammar => $grammar, [nomatch => $nomatchstr], 
[noinput => $noinputstr], [timeout => $seconds]);

The C<Listen> method will wait for the user to say something, and
return that value.

=over 4

=item grammar => $grammar

C<grammar> specifies the set of valid expressions that a user can say
at this point.  To learn more about grammars, please see the Tellme
Studio documentation at http://studio.tellme.com/grammarref/.  You
must specify either grammar or grammarsrc.

=item grammarsrc => $grammarfile

C<grammarsrc> specifies a file containing a grammar.  The grammar file
will be downloaded in a separate server transaction, much as audio
files (or image files in the HTML world) get downloaded separately.
This is the right thing to do if your grammar is very big and does not
dynamically change.

=item nomatch => $nomatch

C<nomatch> specifies what value to return if the user says something
that could not be matched by the grammar.  If you do not give this
parameter, then the VoiceXML::Server library will automatically tell the
user it didn't understand and will reprompt them.  This behavior does
not always work out so well, though, and it is a good idea to provide
your own nomatch handling.

=item noinput => $noinput

C<noinput> specifies what value to return if the user does not say
anything.  If you do not give this parameter, then the VoiceXML::Server
library will automatically tell the user it didn't hear anything and
will reprompt them.  This behavior does not always work out so well,
though, and it is a good idea to provide your own noinput handling.

=item timeout => $seconds

C<timeout> specifies how many seconds to wait before generating a
noinput event.  If you do not specify one, a platform default value is
used.

=back

=cut




sub Listen
{
    my $self = shift;
    my %args = @_;

    CheckArgs(\%args, ('grammar', 'grammarsrc', 'noinput', 'nomatch',
                       'timeout'));

    my $grammar = $args{'grammar'};
    my $grammarsrc = $args{'grammarsrc'};

    if ((!$grammar && !$grammarsrc) || ($grammar && $grammarsrc)) {
        die "Must specify exactly one of 'grammar' and 'grammarsrc' to Listen()";
    }
   
    if ($self->{'mode'} eq 'cmdline') {
        my $result = <STDIN>;
        if (!defined $result) {
            exit();
        }
        chomp($result);
        return $result;
    }

    if ($grammarsrc) {
        $grammarsrc = $self->_MakeAbsoluteURL($grammarsrc);
        $grammar = qq{<grammar src="$grammarsrc"/>};
    } else {
        $grammar = qq{<grammar><![CDATA[$grammar]]></grammar>};
    }

    my $conn = $self->{'connection'};
    $conn->send_basic_header();
    print $conn "Cache-Control: no-cache";
    $conn->send_crlf();
    print $conn "Content-type: text/vxml";
    $conn->send_crlf();
    $conn->send_crlf();
    my $myurl = escapeHTML($self->{'myurl'});

    my $outtext = "";
    if (@{$self->{'outstr'}}) {
        $outtext = "<prompt>" . join("\n", @{$self->{'outstr'}}) . "</prompt>";
    }

    my $noinput = qq{
  <audio>Sorry, I did not hear anything.</audio>
  <reprompt/>
};
    if ($args{'noinput'}) {
        $noinput = qq{<goto next="${myurl}result=$args{'noinput'}"/>};
    };


    my $nomatch = qq{<audio>What was that again?</audio>
<reprompt/>
};
    if ($args{'nomatch'}) {
        $nomatch = qq{<goto next="${myurl}result=$args{'nomatch'}"/>};
    }

    my $timeoutpart = "";
    if ($args{'timeout'}) {
        $timeoutpart = qq{ timeout="$args{'timeout'}"};
    }


    print $conn qq{<?xml version="1.0"?>
<!DOCTYPE vxml PUBLIC "-//Tellme Networks//Voice Markup Language 1.0//EN"
"http://resources.tellme.com/toolbox/vxml-tellme.dtd">

<vxml application="http://resources.tellme.com/lib/universals.vxml">

<form id="top">
<field id="session.vxmllib.result"$timeoutpart>
$outtext
$grammar
<noinput>
$noinput
</noinput>
<default>
$nomatch
</default>
<filled>
  <goto next="${myurl}result={session.vxmllib.result}"/>
</filled>
</field>
</form>
</vxml>
};
    
    $self->{'outstr'} = [];
 Log("Closing connection");
    while (1) {
        $self->{'connection'}->close();
        delete $self->{'connection'};
        Log("Waiting for new connection");
        $self->_waitForConnection();
        Log("Getting string from new connection");

        $self->{'outstr'} = [];

        while (my $r = $self->{'connection'}->get_request()) {
            if ($r->method eq 'GET' and $r->url->query =~ /result=(.*)$/) {
                my $result = $1;
                chomp($result);
                Log("Got string $result");
                return $result;
            } else {
                Log("Invalid request <" . $r->url->query . ">" . $r->as_string());
                $self->{'connection'}->send_error(RC_FORBIDDEN);
                exit();
            }
        } 
        Log("Connection went away without getting anything from it.");
    }
}


=item $server->GoToURL(url)

C<GoToURL> is used to exit your application.  It specifies a URL of
another VoiceXML page that should be loaded.

=cut


sub GoToURL
{
    my $self = shift;
    my ($url) = @_;
    $url = escapeHTML($self->_MakeAbsoluteURL($url));

    if ($self->{'mode'} eq 'cmdline') {
        print "Going to $url\n";
        exit;
    }
    my $conn = $self->{'connection'};
    $conn->send_basic_header();
    print $conn "Content-type: text/vxml";
    $conn->send_crlf();
    $conn->send_crlf();


    my $outtext = join("\n", @{$self->{'outstr'}});
    print $conn qq{<?xml version="1.0" ?>
<vxml>
 <form>
  <block>
   $outtext
   <goto next="$url"/>
  </block>
 </form>
</vxml>
};
    $conn->close();
    exit;
}


sub Log
{
    if (!$theserver->{'debug'}) {
        return;
    }
    my ($str) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    if (open(LOGFID, ">>$theserver->{'debugfilenamebase'}.log.$$")) {
        my $stamp = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
        print LOGFID "$stamp $str\n";
        close(LOGFID);
    }
}

sub DieLog
{
    my ($str) = (@_);
    Log($str);
    die $str;
}

1;

=back

=head1 CHANGE LOG

 * $Log: Server.pm,v $
 * Revision 1.6  2000/10/03 22:07:08  weissman
 * Fixed minor typo.
 *
 * Revision 1.5  2000/10/03 19:17:25  weissman
 * Added "Cache-Control: no-cache" header.
 *
 * Revision 1.4  2000/09/29 22:35:54  weissman
 * Added 'grammarsrc' parameter to Listen(), so that you can now specify
 * a separate grammar file.
 *
 * Revision 1.3  2000/09/27 22:23:53  weissman
 * GoToURL() wasn't working if given a relative URL.
 *
 * Revision 1.2  2000/09/27 18:22:05  weissman
 * Allow specifying the range of ports to use.
 *
 * Revision 1.1  2000/09/26 23:26:53: weissman
 * Initial release of Server::VoiceXML module.


=head1 AUTHOR

Terry Weissman <weissman@tellme.com>

Web page: http://studio.tellme.com/downloads/VoiceXML-Server/
