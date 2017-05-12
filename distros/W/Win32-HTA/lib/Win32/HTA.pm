package Win32::HTA;

=head1 NAME

Win32::HTA - HTML Applications with Perl as local backend

=head1 SYNOPSIS

    use Win32::HTA;

    my $hta = Win32::HTA->new();

    # Simple MessageBox with return value
    my $chosen = $hta->show(
        TITLE => 'Important Information!',
        DLG_HTML => qq(
            <p id="msg_txt">Something happened!</p><br>
            <button id="bok"     type="button" onclick="ret_handler();">OK</button>
            <button id="bcancel" type="button" onclick="esc_handler();">CANCEL</button>
        ),
        CSS => q(
            p      { width: 250px; text-align: center; }
            button { width:  80px; margin-left: 30px;}
        ),
        ON_LOAD => q[
            bok.focus();
        ],
        RET_HANDLER => q(pipe_string('OK')),
        ESC_HANDLER => q(pipe_string('CANCEL')),
    );
    print $chosen, "\n";

    # Reset to default
    $hta->clear();


    # AJAX communication
    require JSON;
    $hta->show(
        AJAX => sub {
            my($request) = @_;
            print JSON::encode_json($request);
            my $ok = int(rand()+0.5);
            return {
                succeeded => $ok,
                data      => {
                    name => $request->{request},
                    text => $request->{data},
                },
                $ok ? () : ( errtxt => 'Something went wrong!'),
            };
        },
        IE_MODE => 11,
        BG_COLOR => '#888800',
        DLG_HTML => qq(
            <button id="but" type="button" onclick="bpress()">Talk to Perl</button><br>
        ),
        RET_HANDLER => q(but.click();),
        CSS => 'button {width: 150px;}',
        JS_HEAD => q(
            function bpress() {
                var reply = ajax_request({request : "test", data : 'testdata'});
                if ( reply['succeeded'] ) {
                    alert(reply['data']['text']);
                } else {
                    alert(reply['errtxt']);
                }
                close();
            }
        ),
    );


=head1 DESCRIPTION

HTML Applications are an easy way to build simple and not so simple
GUI applications using HTML with script languages supported by Internet
Explorer (Javascript, VBScript and even PerlScript if you are using
ActivePerl).

As I am using Strawberry Perl, I thought launching mshta.exe from inside perl
and then communicating via AJAX could be interesting.

=cut

use 5.010;

use strict;
use warnings;

our $VERSION = '1.02';

use Carp;
use File::Temp qw(tempfile);
use Storable qw(dclone);
use Win32;

my %default_args = (
    H_ADJUST => 44,
    IE_MODE  => 8,
    IP_PORT  => 0,
    W_ADJUST => 24,
    map { $_ => '' } qw/
        AJAX
        BG_COLOR
        CSS
        DEBUG
        DLG_HTML
        ESC_HANDLER
        HEAD
        JS_BODY
        JS_HEAD
        ON_LOAD
        POST_HANDLER
        PRE_HANDLER
        RET_HANDLER
        TITLE
    /,
);

my $template_data;
{
    local $/ = undef;
    $template_data = <DATA>;
}


=head1 CONSTRUCTOR

=head2 new(%args)

Creates a new Win32::HTA object with the options given. See L</OPTIONS>

=cut
sub new {
    my($class, %args) = @_;

    my $self = bless(dclone(\%default_args), $class);

    @$self{ keys %args } = values %args;

    for my $arg ( keys %default_args ) {
        my $method_name = lc($arg);
        no strict 'refs';
        *{$method_name} = sub {
            my($self, $value) = @_;
            $self->{$arg} = $value if defined $value;
            return $self->{$arg};
        };
    }

    return $self;
}


=head1 METHODS

=head2 clear(%args)

Resets the object to the default values and sets the given values afterwards.
For options see L</OPTIONS>

=cut
sub clear {
    my($self, %args) = @_;

    @$self{ keys %default_args } = values %default_args;
    @$self{ keys %args         } = values %args;
}


sub _make_html {
    my($self) = @_;

    my $html = $template_data;

    $html = $self->{PRE_HANDLER}->($html) if $self->{PRE_HANDLER};

    {
        no warnings qw/uninitialized/;
        $html =~ s/\[\%(\w+)\%\]/$self->{$1}/g;
    }

    $html = $self->{POST_HANDLER}->($html) if $self->{POST_HANDLER};

    return $html;
}


sub _find_mshta {
    my($self) = @_;

    my $found;
    for my $p ( '.', split(/\s*;\s*/, $ENV{PATH}) ) {
        next unless $p;
        my $name = "$p\\mshta.exe";
        if ( -f $name ) {
            $found = $name;
            last;
        }
    }

    return $found;
}


sub _listen {
    my($self) = @_;

    require IO::Socket::INET;
    require IO::Select;

    $self->{_socket} = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => 'localhost',
        LocalPort => $self->ip_port(),
        ReuseAddr => 1,
    ) or carp "Can't listen: $@\n";

    $self->ip_port($self->{_socket}->sockport());

    $self->{_select} = IO::Select->new();
    $self->{_select}->add($self->{_socket});

    warn "Listening on port=$self->{IP_PORT}\n"
        if $self->debug();
}


sub _loop {
    my($self) = @_;

    $self->{_pobj}->GetExitCode(my $exitcode);

    while ( $exitcode == Win32::Process::STILL_ACTIVE() ) {

        $self->_handle_sockets();

        $self->{_pobj}->GetExitCode($exitcode);
    }
}


sub _handle_sockets {
    my($self) = @_;

    my $ssock = $self->{_socket};
    my $sel   = $self->{_select};

    while( my @ready = $sel->can_read(0.1) ) {

        foreach my $sock ( @ready )  {
            if ( $sock == $ssock ) {
                my $new = $ssock->accept;
                $sel->add($new);
            } else {
                my $rq_raw;
                while ( defined(my $line = <$sock>) ) {
                    if ( $line =~ /^\{/ ) {
                        chomp($line);
                        $rq_raw = $line;
                        last;
                    }
                }

                my $reply_object = $self->ajax()->(JSON::decode_json($rq_raw));

                my $reply = "HTTP/1.1 200 OK\n";
                $reply   .= "Content-Type: text/html; charset=utf-8\n\n";
                $reply   .= JSON::encode_json($reply_object || {});
                print $sock $reply;
                $sel->remove($sock);
                $sock->close;
            }
        }
    }
}

=head2 show(%args)

Displays the Application window with mshta.exe. Waits for the application
to close. Will return the string written by pipe_string() from the
javascript side of the HTA unless the 'AJAX' option is used.

For options see L</OPTIONS>.

=cut
sub show {
    my($self, %args) = @_;

    @$self{ keys %args } = values %args;

    $self->_listen() if $self->ajax();

    my $html = $self->_make_html();

    warn $html, "\n" if $self->debug();

    my($fh, $hta_fn) = tempfile(UNLINK => 1);
    print $fh $html;
    close($fh);

    my $mshta = $self->_find_mshta()
        or carp "mshta.exe not found in PATH";

    if ( $self->ajax() ) {
        eval { require Win32::Process }
            or die "Win32::Process is needed for ajax fuctionality\n";
        eval { require JSON }
            or die "JSON is needed for ajax fuctionality\n";

        Win32::Process::Create(
            my $pobj,
            $mshta,
            qq(mshta "$hta_fn"),
            0,
            Win32::Process::NORMAL_PRIORITY_CLASS(),
            "."
        ) || carp Win32::FormatMessage( Win32::GetLastError() );

        $self->{_pobj} = $pobj;

        $self->_loop();

        return 1;

    } else {
        my $ret = qx("$mshta" \"$hta_fn\");
        croak "running mshta command failed" unless defined $ret;
        chomp($ret);
        return $ret;
    }
}

=head2 Accessor methods

There are lower case accessor methods for all options. So instead of
passing options to new() clear() and show() you can do e.g.:

  $hta->title("Titletext");

  $hta->show();

=head1 OPTIONS

=head2 AJAX

Reference to a subroutine that acts as a request handler. It will get
passed a reference to whatever you request from the javascript side
of your HTA. It will be already parsed by JSON::decode_json, so you can
access the contents directly.

If you want to return something it has to be a reference to an array or
hash. It will be run through JSON::encode_json() and parsed by JSON.parse
on the javascript side automatically.

You can use the javascript function 'ajax_request(<obj>)' from inside your
javascript blocks given in the options JS_HEAD or JS_BODY. The synopsis has
a working example.

=head2 BG_COLOR

Shortcut for setting the background color for the HTML <body> tag.

=head2 CSS

Verbatim style sheet block. It will be set inside the <head> tag.

=head2 DEBUG

If set to a true value will output the generated HTML to stderr.

=head2 DLG_HTML

The HTML text for the interface. It will be placed inside a div with
id '__DIV__' that is a direct child of <body>

=head2 ESC_HANDLER

Javascript code that gets called when <Escape> is pressed. The event is
bound to the HTML <body>. There is a corresponding javascript funtion called
'esc_handler(obj)' that will be called

=head2 H_ADJUST

Number of pixels to adjust the height of the main window to account for
window decorations. Defaults to 44.

=head2 HEAD

additional tags place at the beginning of the header (before JS_HEAD)

=head2 IE_MODE

Internet Explorer version that will be emulated by mshta.exe. Defaults to 8.
This could be important especially for javascript capabilities.

=head2 IP_PORT

The tcp/ip port that will be used for listening to ajax requests. The
default is 0, which will let the OS chose the port. This is the safe
option. Use at your own risk.

=head2 JS_BODY

Javascript code that gets inserted after the main <div> tag.

=head2 JS_HEAD

Javascript code that gets inserted inside the <head> tag.

=head2 ON_LOAD

Javascript code that gets inserted inside a window.onload handler.

=head2 POST_HANDLER

Reference to a subroutine that will be called with expanded HTML text
as only parameter after variable expansion. Has to return the HTML text.
Use at your own risk.

=head2 PRE_HANDLER

Reference to a subroutine that will be called with the HTML template text
as only parameter before variable expansion. Has to return the new
template text. Use at your own risk.

=head2 RET_HANDLER

Javascript code that gets called when <Return> is pressed. The event is
bound to the HTML <body>.

=head2 TITLE

Text for the <title> tag.

=head2 W_ADJUST

Number of pixels to adjust the width of the main window to account for
window decorations. Defaults to 24.

=cut

=head1 JAVASCRIPT FUNCTIONS

There are some predefined utility functions you can use in your
javascript code:

=head2 dump_obj(obj)

Use this for dumping object information if your choosen IE Version does
not contain the better JSON.stringify(obj).

=head2 add_event(obj, type, function)

Wrapper for obj.addEventListener() or obj.attachEvent() that should do
the right thing for the different IE versions.

=head2 pipe_string(str)

Writes the string to stdout and closes the HTA. Will only work when you
don't use AJAX for communication.

=head2 ajax_request(obj)

Sends the stringified object data as AJAX request to the perl scripts
callback that has been specified with the AJAX option.

=cut

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Thomas Kratz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=[%IE_MODE%]" />
    <title>[%TITLE%]</title>
    <HTA:APPLICATION
        ID="oHTA"
        version="1.1"
        BORDER="thin"
        BORDERSTYLE="raised"
        CAPTION="Yes"
        CONTEXTMENU="no"
        INNERBORDER="no"
        MAXIMIZEBUTTON="no"
        MINIMIZEBUTTON="no"
        NAVIGATABLE="no"
        SCROLL="no"
        SCROLLFLAT="no"
        SELECTION="no"
        SHOWINTASKBAR="yes"
        SINGLEINSTANCE="yes"
        SYSMENU="yes"
        WINDOWSTATE="normal"
    >
    <meta charset="utf-8">
    [%HEAD%]
    <script language='javascript'>

        function dump_obj(obj) {
            var output = '';
            for (var property in obj) {
                output += property + ': ' + obj[property] + '; ';
            }
            return(output);
        }

        function add_event(obj, type, fn) {
            if ( obj.attachEvent ) {
                obj.attachEvent('on' + type, fn);
            } else if ( obj.addEventListener ) {
                obj.addEventListener(type, fn);
            }
        }

        function pipe_string(str) {
            var fso = new ActiveXObject('Scripting.FileSystemObject')
            var stdout = fso.GetStandardStream(1);
            close(stdout.Write(str));
        }

        function ajax_request(obj) {
            var rq = new ActiveXObject('winhttp.winhttprequest.5.1');
            rq.Open("POST", "http://localhost:[%IP_PORT%]", false);
            rq.Send(JSON.stringify(obj) + "\n");
            var reply = JSON.parse(rq.ResponseText);
            return(reply);
        }


        function resize_window(x,y) {
            window.resizeTo(x, y);
            var screenWidth  = document.parentWindow.screen.availWidth;
            var screenHeight = document.parentWindow.screen.availHeight;
            var posLeft      = (screenWidth  - x) / 2;
            var posTop       = (screenHeight - y) / 2;
            window.moveTo(posLeft, posTop);
        }

        function ret_handler(obj) {
            [%RET_HANDLER%]
        };

        function esc_handler(obj) {
            [%ESC_HANDLER%]
        };

        resize_window(0, 0);

        add_event(window, 'load', function() {
            var body = document.getElementById("__body__");
            var div  = document.getElementById("__div__");

            add_event(body, 'keydown', function(e) {
                if ( e.keyCode == 13 ) {
                    ret_handler(e.currentTarget);
                } else if ( e.keyCode == 27 ) {
                    close();
                    esc_handler(e.currentTarget);
                }
            });

            resize_window(div.offsetWidth + [%W_ADJUST%], div.offsetHeight + [%H_ADJUST%]);

            [%ON_LOAD%]
        });

        [%JS_HEAD%]

    </script>
    <style>
        body {
            background:[%BG_COLOR%];
            padding: 0px;
        }

        #__div__ {
            display: inline-block;
            padding: 0px;
            margin:  0px;
        }

        [%CSS%]

    </style>

</head>
<body id="__body__">
    <div id="__div__">
        [%DLG_HTML%]
    </div>
    <script language='javascript'>
        [%JS_BODY%]
    <script>
</body>