package Thrust;

use common::sense;

our $VERSION = '0.200';

use AnyEvent;
use AnyEvent::Util;
use AnyEvent::Handle;
use JSON::XS;
use File::ShareDir;
use Scalar::Util;
use Alien::Thrust;

use Thrust::Window;



our $THRUST_BOUNDARY = "\n--(Foo)++__THRUST_SHELL_BOUNDARY__++(Bar)--\n";




my $js;

sub debug {
  my ($level, $msg_cb, $to_dump, $indent) = @_;

  return if $level > $ENV{THRUST_DEBUG};

  $js ||=  JSON::XS->new->pretty->canonical;

  my $out = "\n" . $msg_cb->() . "\n";

  $out .= $js->encode($to_dump) . "\n" if $to_dump;

  $out =~ s/\n/\n                /g if $indent;

  print STDERR $out;
}



sub new {
  my ($class, %args) = @_;

  my $self = {
    action_id => 10, # start at 10 to make groking protocol a bit easier from debug dumps
  };

  bless $self, $class;

  my ($fh1, $fh2) = portable_socketpair();

  $self->{cv} = run_cmd [ $Alien::Thrust::thrust_shell_binary ],
                        close_all => 1,
                        '>' => $fh2,
                        '<' => $fh2,
                        '2>' => $ENV{THRUST_DEBUG} >= 2 ? \*STDERR : '/dev/null', ## FIXME: /dev/null not portable
                        '$$' => \$self->{pid};

  close $fh2;

  $self->{fh} = $fh1;

  $self->{hdl} = AnyEvent::Handle->new(fh => $self->{fh});

  my $line_handler; $line_handler = sub {
    my ($hdl, $line) = @_;

    my $msg = eval { decode_json($line) };

    if (defined $msg) {

      debug(1, sub { "<<<<<<<<<<<<<<<<< Message from thrust shell" }, $msg, 1);

      if ($msg->{_action} eq 'reply') {
        my $action_cb = $self->{actions}->{$msg->{_id}};
        if ($action_cb) {
          $action_cb->($msg);
        } else {
          warn "reply to unknown request";
        }
      } elsif ($msg->{_action} eq 'event') {
        my $window = $self->{windows}->{$msg->{_target}};

        if ($window) {
          $window->_trigger($msg->{_type}, $msg->{_event});
        }
      }
    }

    $self->{hdl}->push_read(line => $line_handler);
  };

  $self->{hdl}->push_read(line => $line_handler);

  return $self;
}

sub run {
  my ($self) = @_;

  $self->{cv} = AE::cv;

  $self->{cv}->recv;
}

sub do_action {
  my ($self, $params, $cb) = @_;

  my $action_id = $self->{action_id}++;

  $params->{_id} = $action_id;

  debug(1, sub { "Sending to thrust shell >>>>>>>>>>>>>>>>>" }, $params);

  $self->{hdl}->push_write(json => $params);

  $self->{hdl}->push_write($THRUST_BOUNDARY);

  $self->{actions}->{$action_id} = sub {
    delete $self->{actions}->{$action_id};
    $cb->($_[0]->{_result});
  };
}

sub window {
  my ($self, %args) = @_;

  $self = Thrust->new if !ref $self; ## in case you forget the ->new in one-liners

  my $window = { thrust => $self, };
  bless $window, 'Thrust::Window';

  $self->do_action({ '_action' => 'create', '_type' => 'window', '_args' => \%args, }, sub {
    my $id = $_[0]->{_target};
    $window->{target} = $id;
    $self->{windows}->{$id} = $window;
    Scalar::Util::weaken $self->{windows}->{$id};
    $window->_trigger_event('ready');
  });

  return $window;
}



sub DESTROY {
  my ($self) = @_;

  kill 'KILL', $self->{pid};
}


1;


__END__

=encoding utf-8

=head1 NAME

Thrust - Perl bindings to the Thrust cross-platform application framework

=head1 SYNOPSIS

    use Thrust;

    my $t = Thrust->new;

    my $w = $t->window(
              root_url => 'data:text/html,Hello World!', ## or file://, https://, etc
              title => 'My App',
              size => { width => 800, height => 600 },
            )->show;

    $t->run; ## enter event loop

=head1 DESCRIPTION

Thrust is a chromium-based cross-platform and cross-language application framework. It allows you to create "native"-like applications using HTML/CSS for the interface and (of course) perl for the glue code to filesystems, DBs, networking, libraries, and everything else perl is great at.

This is the easiest way to install perl-thrust:

    curl -sL https://raw.github.com/miyagawa/cpanminus/master/cpanm | sudo perl - Thrust

Read more about Thrust at its L<official website|https://github.com/breach/thrust>. There are bindings for many other languages such as node.js, go, and python.

Like the bindings for other languages, installing the perl module will download a zip file from github which contains the C<thrust_shell> binary. It will extract this into the perl distribution's private share directory.

Unlike the bindings for other languages, in the perl ones there are no definitions for individual thrust methods. Instead, an AUTOLOAD is used to automatically "forward" all perl method calls (and their JSON encoded arguments) to the thrust shell. This has the advantage that there is generally no need to do anything to the perl bindings when new methods/parameters are added to the thrust shell. However, it has the disadvantage that sometimes the API is less convenient. For instance, instead of positional arguments in (for example) the C<move> method, you must use the named C<x> and C<y> parameters.

Like the bindings in other languages, methods can be invoked on a window object even before the window is created. The methods will be queued up and invoked in order once the window is ready. After that point, all messages are delivered to the window asynchronously. For example, here is a one-liner command to open a maximized window with the dev tools console expanded:

    $ perl -MThrust -e 'Thrust->window->show->maximize->open_devtools->run'

To understand how the above works, consider that the perl bindings also support some one-liner shortcuts such as method chaining, an implicit C<Thrust> context created by C<window>, and a C<run> method on the window.

=head1 ASYNC PROGRAMMING

Like browser programming itself, programming the perl side of a Thrust application is done asynchronously. The Thrust package depends on L<AnyEvent> for this purpose so you can use whichever event loop you prefer. See the L<AnyEvent> documentation for details on asynchronous programming.

The C<run> methods of the Thrust context/window objects simply wait on a condition variable that will never be signalled (well you can if you want to, it's in C<< $t->{cv} >>) in order to enter the event loop and "sleep forever". C<run> is mostly there so you don't need to type C<< use AnyEvent; AE::cv->recv >> in simple scripts/examples.

Almost all methods on the window object can optionally take a callback argument that will be called once the operation has been completed. For example:

    $w->maximize(sub { say "window has been maximized" });

If present, the callback must be the final argument. For methods that require parameters, the parameters must be in a hash-ref preceeding the (optional) callback:

    $w->resize({ width => 100, height => 100 },
               sub { say "window has been resized" });

=head1 EVENT HANDLERS

Window objects have an C<on> method which allows you to append a callback to be invoked when a particular event is triggered.

For example, normally closing a window will not cause the termination of your perl program. Instead, the C<closed> event will be triggered. By default nothing is listening for this event so it is discarded. If you want you can make the closing of one or more windows terminate your perl program as well (which in turn kills all the other windows this process has started):

    $window->on(closed => sub { exit });

If you ever wish to remove handlers for an event, window objects also have a C<clear> method:

    $window->clear('closed');

See the thrust API docs for information on the potential events and actions. To snoop on the event traffic to and from the thrust shell, set the environment variable C<THRUST_DEBUG> to C<1> or higher. Set it to C<2> or higher to also see the standard error debugging output from the C<thrust_shell> process. Here is a simple example of the traffic when you create and show a window:

    $ THRUST_DEBUG=1 perl -MThrust -e 'Thrust->new->window->show->run'

    Sending to thrust shell >>>>>>>>>>>>>>>>>
    {
       "_action" : "create",
       "_args" : {},
       "_id" : 10,
       "_type" : "window"
    }


                <<<<<<<<<<<<<<<<< Message from thrust shell
                {
                   "_action" : "reply",
                   "_error" : "",
                   "_id" : 10,
                   "_result" : {
                      "_target" : 1
                   }
                }
                
                
    Sending to thrust shell >>>>>>>>>>>>>>>>>
    {
       "_action" : "call",
       "_args" : null,
       "_id" : 11,
       "_method" : "show",
       "_target" : 1
    }


                <<<<<<<<<<<<<<<<< Message from thrust shell
                {
                   "_action" : "reply",
                   "_error" : "",
                   "_id" : 11,
                   "_result" : {}
                }
                
                
                <<<<<<<<<<<<<<<<< Message from thrust shell
                {
                   "_action" : "event",
                   "_event" : {},
                   "_id" : 1,
                   "_target" : 1,
                   "_type" : "focus"
                }


=head1 REMOTE EVENTS

One of the most useful features of thrust is its support for bi-directional messaging between your application and the browser over pipes connecting to the thrust shell's stdin/stdout. Without this support we would need to allocate some kind of network port or unix socket file and start something like an AJAX or websocket server.

In order for the browser to send a message to your perl code, it should execute something like the following javascript code:

    THRUST.remote.send({ foo: 'bar' }); // send message to perl

On the perl side, you will need to install an event handler for the C<remote> event by calling the C<on> method of a window object:

    $w->on('remote', sub {
        my $msg = $_[0]->{message};

        print $msg->{foo}; # prints bar
    });

In order to send a message from perl to the browser, call the C<remote> method on a window object:

    $w->remote({ message => { foo => 'bar' } });

On the javascript side, you will need to install a handler like so:

    THRUST.remote.listen(function(msg) {
        console.log(msg['foo']); // prints bar
    });

B<IMPORTANT NOTE>: Before applications can send messages from perl to javascript, the C<THRUST.remote.listen> function must have been called. If you try to send a message before this, it is likely that the message will be delivered to the browser before the handler has been installed so your message will be lost. Applications should make javascript send a message indicating that the communication channel is ready to indicate to the perl component that it can begin sending messages to the browser.

=head1 TESTS

Currently this software has two tests, C<load.t> that verifies L<Thrust> is installed and C<remote.t> which starts and shows the thrust shell, then proceeds to confirm bi-directional transfer of messages between javascript and perl. Maybe the test-suite shouldn't show a window by default?

=head1 BUGS

Haha this software is so beta. I've only tested this so far on 64-bit linux so the cross-platform claim is theoretical.

Only the window object is currently exposed. Eventually the window code should be refactored into a base class so that session and menu can be implemented as well (as done in the node.js bindings).

Add a test that verifies C<thrust_shell> is killed when your program exits or is killed.

The perl bindings don't report errors from the thrust shell properly to your code yet. Eventually I think they should use L<Callback::Frame>.
 
Actually C<thrust_shell> doesn't have great error checking itself. Any error messages like the following probably indicate that you passed in some malformed argument and terminated the thrust_shell abnormally:

    AnyEvent::Handle uncaught error: Broken pipe at /usr/local/lib/perl/5.18.2/AnyEvent/Loop.pm line 248.

The fact that C<thrust_shell> binaries are duplicated for every language binding is good and bad: depending on how backwards compatible everything is, duplication may be necessary because of protocol changes. It's bad in that you can't immediately apply bug-fixes to all copies of C<thrust_shell> on your system.

=head1 SEE ALSO

L<The Thrust perl module github repo|https://github.com/hoytech/Thrust>

L<Alien::Thrust>

L<The Thrust project|https://github.com/breach/thrust> - Official website

L<The node.js Thrust bindings|https://github.com/breach/node-thrust/> - These are the most complete bindings

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

Thrust itself is Copyright (c) 2014 Stanislas Polu and is licensed under the MIT license.

=cut



{"_id":1,"_action":"create","_type":"window","_args":{"root_url":"http://google.com"}}
--(Foo)++__THRUST_SHELL_BOUNDARY__++(Bar)--

{"_action":"reply","_error":"","_id":1,"_result":{"_target":1}}
--(Foo)++__THRUST_SHELL_BOUNDARY__++(Bar)--

{"_id":2,"_action":"call","_target":1,"_method":"show","_args":{}}
--(Foo)++__THRUST_SHELL_BOUNDARY__++(Bar)--
