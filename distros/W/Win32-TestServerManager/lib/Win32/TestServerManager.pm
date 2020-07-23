package Win32::TestServerManager;

use strict;
use warnings;
use Carp;
use Win32;
use Win32::Process;
use File::Spec;

our $VERSION = '0.06';

sub new {
  my $class = shift;

  bless {}, $class;
}

sub spawn {
  my ($self, $id, $args, $options) = @_;

  $self->kill($id) if $self->{$id};

  if ( !defined $args )         { $options = {}; $args = ''; }
  elsif ( ref $args eq 'HASH' ) { $options = $args; $args = ''; }

  if ( !defined $options )      { $options = {}; }
  elsif ( ref $options ne 'HASH' ) {
    croak "Usage: ->spawn( id, args, { options } )";
  }

  $args .= ' ' . $options->{args} if $options->{args};

  my $executable = $options->{executable} || $^X;

  my $flag = $options->{cflag} || NORMAL_PRIORITY_CLASS;
     $flag |= CREATE_NEW_CONSOLE if $options->{new_console};
     $flag |= CREATE_NO_WINDOW   if $options->{no_window};

  my $workdir = $options->{working_dir} || '.';

  if ( $options->{create_server_with} ) {
    my $code = $options->{create_server_with};
    if ( ref $code eq 'CODE' ) {
      require B::Deparse;
      my $deparser = B::Deparse->new;
      $code = $deparser->coderef2text( $code );
    }
    require File::Temp;
    my $tmpfile = File::Temp::tempnam( $workdir => '_tmp' );
    open my $fh, '>', $tmpfile or die $!;
    print $fh $code;
    close $fh;
    $args = "$args $tmpfile";
    $self->{$id}->{tmpfile} = $tmpfile;
  }

  $self->{$id}->{dont_kill} = $options->{dont_kill};

  Win32::Process::Create(my $process,
    $executable,
    "$executable $args",
    0,
    $flag,
    File::Spec->rel2abs($workdir),
  ) or croak Win32::FormatMessage( Win32::GetLastError() );

  $self->{$id}->{process} = $process;
}

sub instance {
  my ($self, $id) = @_;
  return exists $self->{$id} ? $self->{$id} : undef;
}

sub process  {
  my ($self, $id) = @_;
  if ( my $instance = $self->instance($id) ) {
    return exists $instance->{process} ? $instance->{process} : undef;
  }
  return;
}

sub instances {
  my $self = shift;
  keys %{ $self };
}

sub pid {
  my ($self, $id) = @_;

  if ( my $instance = $self->{$id} ) {
    return $instance->{process}->GetProcessID;
  }
  return;
}

sub kill {
  my ($self, $id, $exitcode) = @_;

  $exitcode = 0 unless defined $exitcode;

  if ( my $instance = delete $self->{$id} ) {
    if ( $instance->{tmpfile} ) {
      my $counter = 0;
      while ( $counter++ < 3 ) {
        unlink $instance->{tmpfile};
        last unless -f $instance->{tmpfile};
        sleep 1;
        $counter++;
      }
    }
    return if $instance->{dont_kill};

    $instance->{process}->Kill($exitcode);
  }
}

sub DESTROY {
  my $self = shift;

  foreach my $id ( keys %{ $self } ) {
    $self->kill($id);
  }
}

1;

__END__

=head1 NAME

Win32::TestServerManager - manage simple test servers on Win32

=head1 SYNOPSIS

    use Test::More 'no_plan';
    use Test::WWW::Mechanize;
    use Win32::TestServerManager;

    my $manager = Win32::TestServerManager->new;

    # you can run a ready-made perl server
    $manager->spawn(
        testserver => 'script/test_server.pl',
        { new_console => 1 }
    );

    # or other executables
    $manager->spawn(
        lighty => '-D -f lighty.conf',
        { executable => 'c:\lighttpd\bin\lighttpd.exe' }
    );

    # you can provide a source code of a temporary server script
    $manager->spawn(
        onthefly => '',
        { create_server_with => server_script_source() }
    );

    # you can omit blank command line args
    $manager->spawn(
        onthefly => { create_server_with => server_script_source() }
    );

    # coderef would be deparsed into a source code, and then turned into a script
    $manager->spawn(
        onthefly => { create_server_with => \&server_func }
    );

    # do some Mech stuff
    my $mech = Test::WWW::Mechanize->new;
    $mech->get_ok('http://localhost:8888/');

    # you can kill servers explicitly
    $manager->kill('testserver');

    # other servers will be killed at DESTROY time

    sub server_script_source { return <<'EndofScript';
    #!c:\perl\bin\perl.exe

    my $server = TestServer->new(8080);
    $server->run;

    package TestServer;
    use base 'HTTP::Server::Simple::CGI';

    EndofScript
    }

    sub server_func {
        my $server = TestServer->new(8080);
        $server->run;

        package TestServer;
        use base 'HTTP::Server::Simple::CGI';
    }

=head1 DESCRIPTION

It's a bit harder to test web applications on Win32, due to the limitations of fork and signals. You can use LWP/Mech stuff, and you can run servers written in Perl, but you usually need something to run both servers and test scripts at the same time, and cleanly kill them later.

This module helps you to create new processes to run external servers (which may be, or may not be, written in Perl), and helps you to kill them. Actually you can use this for other purposes, but if you want to launch rather complicated applications, or if you want finer control, you may want to use L<Win32::Job>.

OK. I admit. I wrote this just because I was tired of launching fastcgi server script and lighty proxy from one console at the same time again and again.

=head1 METHODS

=head2 new

creates an object.

=head2 spawn

creates a new process and spawns a (server) application. This usually takes two or three arguments:

=over 4

=item id

a scalar name of the process you want to create.

=item args

an optional string which represents command line arguments for the executable (default: perl) to run.

=item options

an optional hashref. Acceptable keys are:

=over 4

=item executable

If you want to launch other executable than perl (apache, lighttpd, etc), provide an absolute path to the executable.

=item args

a string which represents command line arguments for the executable to run. If you also set "args" outside the hashref (see above), this optional "args" would be appended.

=item working_dir

is where temporary file would be created (current directory by default).

=item new_console

If this is set to true, new process would be created with new console. If your server spits lots of debugging message, this may help.

=item no_window

If this is set to true, new process would be created without a window. This may be convenient sometimes but usually you don't want to set this, as you'll need task manager to kill the process by yourself.

=item cflag

If you want to specify more complicated cflag (see L<Win32::Process> for details), use this.

=item create_server_with

A temporary file would be created to be a final argument to the executable. Despite of the name, you can pass the contents as a config file like:

    $manager->spawn(
        lighty => '-D -f ',
        {
          executable => 'c:\lighttpd\bin\lighttpd.exe',
          create_server_with => <<'EndofConf',
    server.port = 8090
    server.document-root = ".\root"
    EndofConf
        }
    );

In this case, the final command line argument passed to Win32::Process::Create would be "c:\lighttpd\bin\lighttpd.exe -D -f <temporary file>".

As of 0.03, you can provide a code reference, which would be deparsed and then turned into a server script.

=item dont_kill

by default, the processes created by this module would be killed at DESTROY time, but if this is set to true, the process wouldn't be killed. This may be handy if you just want to launch servers. Of course such servers should be killed by yourself.

=back

=back

=head2 kill

kills the process: takes the id you've specified at spawn time.

=head2 pid

shows the pid of the process: takes the id you've specified at spawn time.

=head2 process

returns the Win32::Process object you created: takes the id you've specified at spawn time.

=head2 instance

returns an internal hashref which holds the process object, a temporary filename you may have created, and 'dont_kill' flag: takes the id you've specified at spawn time.

=head2 instances

returns an array of instance ids you've specified and created.

=head1 SEE ALSO

L<Win32::Job>, L<Win32::Process>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
