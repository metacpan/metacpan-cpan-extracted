package Valence;

use common::sense;

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;
use Callback::Frame;
use JSON::XS;
use File::Spec;
use File::ShareDir;

use Alien::Electron;
use Valence::Object;


our $VERSION = '0.201';


sub new {
  my ($class, %args) = @_;

  my $electron_binary = $args{electron_binary} ||
                        $ENV{ELECTRON_BINARY} ||
                        $Alien::Electron::electron_binary;
  debug(1, sub { "Electron binary location: $electron_binary" });

  my $valence_dir = $args{valence_dir} ||
                    $ENV{VALENCE_DIR} ||
                    File::ShareDir::dist_dir('Valence');
  debug(1, sub { "Valence JS directory: $valence_dir" });

  my $self = {
    next_object_id => 1,
    object_map => {},

    next_callback_id => 1,
    callback_map => {},
  };

  bless $self, $class;

  my ($fh1, $fh2) = portable_socketpair();

  $self->{cv} = run_cmd [ $electron_binary, $valence_dir ],
                        close_all => 1,
                        '>' => $fh2,
                        '<' => $fh2,
                        '2>' => $ENV{VALENCE_DEBUG} >= 2 ? \*STDERR : File::Spec->devnull(),
                        '$$' => \$self->{pid};

  close $fh2;

  $self->{fh} = $fh1;

  $self->{hdl} = AnyEvent::Handle->new(fh => $self->{fh});

  my $line_handler; $line_handler = sub {
    my ($hdl, $line) = @_;

    my $msg = eval { decode_json($line) };

    if ($@) {
      warn "error decoding JSON from electron: $@: $line";
    } else {
      debug(1, sub { "<<<<<<<<<<<<<<<<< Message from electron" }, $msg, 1);

      $self->_handle_msg($msg);
    }

    $self->{hdl}->push_read(line => $line_handler);
  };

  $self->{hdl}->push_read(line => $line_handler);

  return $self;
}



sub _handle_msg {
  my ($self, $msg) = @_;

  if ($msg->{cmd} eq 'cb') {
    $self->{callback_map}->{$msg->{cb}}->(@{ $msg->{args} });
  } else {
    warn "unknown cmd: '$msg->{cmd}'";
  }
}


sub run {
  my ($self) = @_;

  $self->{cv} = AE::cv;

  $self->{cv}->recv;
}




sub _send {
  my ($self, $msg) = @_;

  debug(1, sub { "Sending to electron >>>>>>>>>>>>>>>>>" }, $msg);

  $self->{hdl}->push_write(json => $msg);

  $self->{hdl}->push_write("\n");
}


sub _call_method {
  my ($self, $msg) = @_;

  ## Manipulate arguments

  for (my $i=0; $i < @{ $msg->{args} }; $i++) {
    if (ref $msg->{args}->[$i] eq 'CODE') {
      my $callback_id = $self->{next_callback_id}++;

      push @{ $msg->{args_cb} }, [$i, $callback_id];

      $self->{callback_map}->{$callback_id} = $msg->{args}->[$i];

      $msg->{args}->[$i] = undef;
    }
  }

  ## Send msg

  $msg->{cmd} = 'call';

  my $obj = Valence::Object->_valence_new(valence => $self);

  $msg->{save} = $obj->{id};

  $self->_send($msg);

  return $obj;
}


sub _get_attr {
  my ($self, $msg) = @_;

  ## Send msg

  $msg->{cmd} = 'attr';

  my $obj = Valence::Object->_valence_new(valence => $self);

  $msg->{save} = $obj->{id};

  $self->_send($msg);

  return $obj;
}


sub require {
  my ($self) = shift;

  return $self->_call_method({ method => 'require', args => \@_, });
}




my $pretty_js_ctx;

sub debug {
  my ($level, $msg_cb, $to_dump, $indent) = @_;

  return if $level > $ENV{VALENCE_DEBUG};

  $pretty_js_ctx ||=  JSON::XS->new->pretty->canonical;

  my $out = "\n" . $msg_cb->() . "\n";

  $out .= $pretty_js_ctx->encode($to_dump) . "\n" if $to_dump;

  $out =~ s/\n/\n                /g if $indent;

  print STDERR $out;
}



sub DESTROY {
  my ($self) = @_;

  kill 'KILL', $self->{pid};
}


1;



__END__

=encoding utf-8

=head1 NAME

Valence - Perl interface to electron GUI tool-kit

=head1 SYNOPSIS

    use Valence;

    my $valence = Valence->new;

    my $electron = $valence->require('electron');

    $electron->attr('app')->on(ready => sub {
      my $main_window = $electron->attr('BrowserWindow')->new({
                           width => 1000,
                           height => 600,
                           title => 'My App',
                        });

      $main_window->loadURL('data:text/html,Hello World!'); ## or file://, https://, etc
    });

    $valence->run; ## enter event loop

=head1 DESCRIPTION

L<Electron|https://github.com/atom/electron> is chromium-based GUI application framework. It allows you to create "native" applications in HTML, CSS, and javascript. The L<Valence> perl module is an RPC binding that lets you use perl instead of javascript for the electron "main" process. It bundles a javascript module L<valence.js|https://github.com/hoytech/valence> which is responsible for proxying messages between the browser render process(es) and your perl controller process.

Since valence is a generic RPC framework, none of the electron methods are hard-coded in the perl or javascript bridges. This means that all of the L<electron docs|https://github.com/atom/electron/tree/master/docs> are applicable and should be used as reference when developing with this module.

B<NOTE>: This module depends on L<Alien::Electron> which will download and install the electron distribution appropriate for your operating system. On linux this depends on having the C<X11> environment variable set. See the L<Alien::Electron> documention for more details.

=head1 DESIGN

=head2 ASYNC PROGRAMMING

Like browser programming itself, programming the perl side of a Valence application is done asynchronously. The L<Valence> package depends on L<AnyEvent> for this purpose so you can use whichever event loop you prefer. See the L<AnyEvent> documentation for details on asynchronous programming.

The C<run> method of the Valence context object simply waits on a condition variable that will never be signalled (well you can signal it if you want to, it's in C<< $valence->{cv} >>) in order to enter the event loop and "sleep forever". C<run> is mostly there so you don't need to type C<< use AnyEvent; AE::cv->recv >> in simple scripts/examples.

=head2 METHODS

The C<require> method initiates a C<require> call in the electron main process and immediately returns a C<Valence::Object>. Any methods that are called on this object will initiate the corresponding method calls in the electron main process and will also themselves return C<Valence::Object>s. The C<new> method is slightly special in that it will use the javascript C<new> function, but it too returns C<Valence::Object>s corresponding to the newly constructed javascript objects:

    my $main_window = $electron->attr('BrowserWindow')->new({ title => "My Title" });

C<Valence::Object>s are essentially perl-side references to values inside the electron main javascript process. If you destroy the last reference to one of these objects, their corresponding values will be deleted in the javascript process and eventually garbage collected.

As well as calling methods on C<Valence::Object>s, you may also treat them as C<sub>s and pass in callbacks that receive the referenced values. This is how you can access javascript values from the perl process. For example:

    $main_window->getPosition->(sub {
      my $pos = shift;
      print "POSITION: x = $pos->[0], y => $pos->[1]\n";
    });

=head2 ATTRIBUTES

C<Valence::Object> has a special C<attr> method which looks up an object attribute and returns a C<Valence::Object> referring to the attribute value. For example:

    my $web_contents = $main_window->attr('webContents');
    ## similar to this JS: var web_contents = main_window.webContents;

Eventually I may make attributes accessible via a hash reference overload which would be a slightly nicer syntax.

=head2 CALLBACKS

Because interacting with an electron process via valence is done asynchronously, callbacks are used nearly everywhere.

When a perl C<sub> is found in the arguments passed to a method, it is replaced with a stub that will be replaced with a javascript function inside the electron main process. When this javascript function is invoked, an asynchronous message will be sent to the perl process which will trigger the execution of your original C<sub>.

For example, here is how to install a sub that will be executed whenever the main window comes into focus:

    $main_window->on('focus', sub { say "FOCUSED" });

Note: Due to a current limitation, C<sub>s nested inside hashes or arrays will not get stubbed out correctly.

If you are seeing this error when closing the browser window:

    EV: error in callback (ignoring): AnyEvent::Handle uncaught error: Broken pipe at...

then it means that the C<electron> process has exited but you haven't handled the C<close> event. In this case, typically you just want to exit the perl process also:

    $main_window->on(close => sub { exit });


=head1 DEBUGGING

If you set the C<VALENCE_DEBUG> value to C<1> or higher, you will see a prettified dump of the JSON protocol between the perl and electron process

    Sending to electron >>>>>>>>>>>>>>>>>
    {
       "args" : [
          "app"
       ],
       "cmd" : "call",
       "method" : "require",
       "save" : "1"
    }


    Sending to electron >>>>>>>>>>>>>>>>>
    {
       "args" : [
          "ready",
          null
       ],
       "args_cb" : [
          [
             1,
             1
          ]
       ],
       "cmd" : "call",
       "method" : "on",
       "obj" : "1",
       "save" : "3"
    }


    ...

                    <<<<<<<<<<<<<<<<< Message from electron
                    {
                       "args" : [
                          {}
                       ],
                       "cb" : 1,
                       "cmd" : "cb"
                    }

If you set C<VALENCE_DEBUG> to C<2> or higher, you will also see the standard error output from the electron process, which includes C<console.error()> output.


=head1 IPC

An essential feature of valence is providing bi-directional, asynchronous messaging between your application and the browser render process. It does this over the standard input/standard output interface provided by C<valence.js>. Without this support we would need to allocate some kind of network port or unix socket and start something like an AJAX or websocket server.

=head2 BROWSER TO PERL

In order for the browser to send a message to your perl code, it should execute something like the following javascript code:

    var ipcRenderer = require('electron').ipcRenderer;
    ipcRenderer.send('my-event', 'my message');

On the perl side, you receive these messages like so:

    my $ipcMain = $electron->attr('ipcMain');
    $ipcMain->on('my-event' => sub {
        my ($event, $message) = @_;

        print $message; ## prints 'my message'
    });

=head2 PERL TO BROWSER

Sending messages from perl to the browser should use code like this:

    my $web_contents = $main_window->attr('webContents');
    $web_contents->send('my-event' => 'my message');

And the javascript side can receive these messages like so:

    var ipcRenderer = require('electron').ipcRenderer;
    ipcRenderer.on('my-event', function(event, message) {
        console.log(message); // prints 'my message'
    });

=head2 IPC READY EVENTS

Before applications can send messages from perl to javascript, the C<ipcRenderer.on()> function must have been called to handle these messages. If you try to send a message before this, it is likely that the message will be delivered to the browser before the handler has been installed so your message will be lost. Applications should have javascript send a message indicating that the communication channel is ready, after which the perl component can begin sending messages to the browser.

For an example of how this is done, see the C<t/ipc.t> test and how the perl side subscribes to a C<ready> IPC message before attempting to send its C<ping> message, and how the C<t/static/remote.html> arranges for javascript to send the C<ready> message after it has installed its C<ping> handler.

=head1 TESTS

Currently this software has two tests, C<load.t> which verifies L<Valence> is installed and C<ipc.t> which starts electron and then proceeds to confirm bi-directional transfer of messages between javascript and perl.

=head1 BACKWARDS COMPATIBILITY

The extent to which this module is backwards-compatible depends on the underlying C<electron> project. The API was changed drastically between electron C<0.25.1> and C<1.0.1> (corresponding to L<Valence> releases C<0.100> and C<0.200>) so you will have to port your apps over. Sorry about that. The changes are described in more detail in L<this electron blog post|http://electron.atom.io/blog/2015/11/17/electron-api-changes>.

Presumably now that C<electron> has reached version C<1.0.0> it should now be more stable.

=head1 BUGS

A fairly large limitation with the proxying approach is that event handlers cannot prevent the default event from firing (ie with C<event.preventDefault()>). This is because the stub event handler in javascript simply forwards the event trigger and its arguments to the perl process and returns.

As mentioned above, C<sub>s nested inside hashes or arrays will currently not properly get stubbed out (but this can be fixed if needed).

Attributes should ideally be accessed via a hash reference overload instead of the C<attr> special method.

C<new> methods cannot yet accept more than one parameter (due to a limitation in C<valence.js> -- how do you do this in JS?).

When a callback function is deleted on the javascript side, the perl-side doesn't know about this so its corresponding callback will remain forever. Is there a way to detect this in JS?

It currently always sends a C<save> (immediately followed by a C<destroy>) even when it doesn't need the value. This is inefficient and should be fixed using C<wantarray>.

Exceptions thrown in the JS side should be handled better (using L<Callback::Frame>).

=head1 SEE ALSO

L<The Valence perl module github repo|https://github.com/hoytech/Valence-p5>

L<Alien::Electron>

L<The electron project|https://github.com/atom/electron> - Official website

Valence was heavily inspired by the L<thrust|https://github.com/breach/thrust> project and some parts were ported over from my L<Thrust> module.

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015-2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.

The bundled C<valence/valence.js> library is Copyright (c) 2015-2016 Doug Hoye and is licensed under the 2-clause BSD license.

Electron itself is Copyright (c) 2014-2016 GitHub Inc. and is licensed under the MIT license.

=cut
