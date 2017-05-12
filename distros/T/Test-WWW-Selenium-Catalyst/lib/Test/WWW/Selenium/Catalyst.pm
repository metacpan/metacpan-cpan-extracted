package Test::WWW::Selenium::Catalyst;

use warnings;
use strict;
use Carp;
use Alien::SeleniumRC;
use Test::WWW::Selenium;
use Test::More;
use Catalyst::Utils;
use Catalyst::EngineLoader;

BEGIN { $ENV{CATALYST_ENGINE} ||= 'HTTP'; }

local $SIG{CHLD} = 'IGNORE';

our $DEBUG = $ENV{CATALYST_DEBUG};
our $app; # app name (MyApp)
our $sel_pid; # pid of selenium server
our $app_pid; # pid of myapp server
our $www_selenium;

=head1 NAME

Test::WWW::Selenium::Catalyst - Test your Catalyst application with Selenium

=cut

our $VERSION = '0.07';

=head1 DEVELOPERISH RELEASE

This is still a test release.  It's working for me in production, but
it depends on a Java application (SeleniumRC), which can be
unreliable.  On my Debian system, I had to put C<firefox-bin> in my
path, and add C</usr/lib/firefox> to C<LD_LIBRARY_PATH>.  Every distro
and OS is different, so I'd like some feedback on how this works on
your system.  I would like to find a clean solution that lets this
module "Just Work" for everyone, but I have a feeling that it's going
to look more like C<if(gentoo){ ... } elsif (debian) { ... }> and so
on.  I can live with that, but I need your help to get to that stage!

Please report any problems to RT, the Catalyst mailing list, or the
#catalyst IRC channel on L<irc.perl.org>.  Thanks!

=head1 SYNOPSIS

    use Test::WWW::Selenium::Catalyst 'MyApp', 'command line to selenium';
    use Test::More tests => 2;

    my $sel = Test::WWW::Selenium::Catalyst->start; 
    $sel->open_ok('/');
    $sel->is_text_present_ok('Welcome to MyApp');

This module starts the SeleniumRC server and your Catalyst app so that
you can test it with SeleniumRC.  Once you've called
C<< Test::WWW::Selenium::Catalyst->start >>, everything is just like
L<Test::WWW::Selenium|Test::WWW:Selenium>.

=head1 METHODS

=head2 start(\%args)

Starts the Selenium and Catalyst servers, and returns a pre-initialized,
ready-to-use Test::WWW::Selenium object.

Arguments:

=over

=item app_uri

URI at which the application can be reached. If this is specified then no
application server will be started.

=item port

B<Default>: 3000

Port on which to run the catalyst application server. The C<MYAPP_PORT>
environment variable is also respected.


=item selenium_class

B<Default>: Test::WWW::Selenium

Classname of Selenium object to create. Use this if you want to subclass
selenium to add custom logic.

=item selenium_host

=item selenium_port

Location of externally running selenium server if you do not wish this module
to control one. See also for details.

=back

All other options passed verbatim to the selenium constructor.

B<NOTE>: By default a selenium server is started when you C<use> this module,
and it's killed when your test exits. If wish to manage a selenium server
yourself, (for instance you wish to start up a server once and run a number of
tests against it) pass C<-no_selenium_server> to import:

 use Test::WWW::Selenium::Catalyst 'MyApp',
   -no_selenium_server => 1

Along a similar vein you can also pass command line arguments to the selenium
server via C<-selenium_args>:

 use Test::WWW::Selenium::Catalyst 'MyApp',
   -selenium_args => "-singleWindow -port 4445"

=head2 sel_pid

Returns the process ID of the Selenium Server.

=head2 app_pid

Returns the process ID of the Catalyst server.

=cut


sub _start_server {
    my ($class, $args) = @_;
    # fork off a selenium server
    my $pid;
    if(0 == ($pid = fork())){
        local $SIG{TERM} = sub {
            diag("Selenium server $$ going down (TERM)") if $DEBUG;
            exit 0;
        };
        
        chdir '/';
        
        if(!$DEBUG){
            close *STDERR;
            close *STDOUT;
            #close *STDIN;
        }
        
        diag("Selenium running in $$") if $DEBUG;
        $class->_start_selenium($args);
        diag("Selenium server $$ going down") if $DEBUG;
        exit 1;
    }
    $sel_pid = $pid;
}

# Moved out to be subclassable seperately to the fork logic
sub _start_selenium {
    my ($class, $arg) = @_;
    $arg = '' unless defined $arg;
    Alien::SeleniumRC::start($arg)
      or croak "Can't start Selenium server";
}

sub sel_pid {
    return $sel_pid;
}

sub app_pid {
    return $app_pid;
}

sub import {
    my ($class, $appname, %args) = @_;

    croak q{Specify your app's name} if !$appname;
    $app = $appname;
    
    my $d = $ENV{Catalyst::Utils::class2env($appname). "_DEBUG"}; # MYAPP_DEBUG 
    if(defined $d){
        $DEBUG = $d;
    }

    $args{-selenium_args} ||= '-singleWindow';

    if ($ENV{SELENIUM_SERVER}) {
        $args{-no_selenium_server} = 1;
    }
    elsif ($ENV{SELENIUM_PORT}) {
        $args{-selenium_args} .= " -port " . $ENV{SELENIUM_PORT};
    }
   
    unless ($args{-no_selenium_server}) {
      $class->_start_server($args{-selenium_args}) or croak "Couldn't start selenium server";
    }
    return 1;
}

sub start {
    my $class = shift;
    my $args  = shift || {};

    my $port = delete $args->{port};
    $port ||= $ENV{Catalyst::Utils::class2env($app). "_PORT"} # MYAPP_PORT
          ||  3000;
 
    my $uri;

    # Check for CATALYST_SERVER env var like TWMC does.
    if ( $ENV{CATALYST_SERVER} ) {
      $uri = $ENV{CATALYST_SERVER};
    } elsif ( $args->{app_uri} ) {
      $uri = delete $args->{app_uri}
    } else {
      # start a Catalyst MyApp server
      eval("use $app");
      croak "Couldn't load $app: $@" if $@;
      
      my $pid;
      if(0 == ($pid = fork())){
          local $SIG{TERM} = sub {
              diag("Catalyst server $$ going down (TERM)") if $DEBUG;
              exit 0;
          };
          diag("Catalyst server running in pid $$ with port $port") if $DEBUG;
          my $loader = Catalyst::EngineLoader->new(application_name => $app);
          my $server = $loader->auto(port => $port, host => 'localhost',
              server_ready => sub {
                  diag("Server started on port $port") if $DEBUG;
              },
          );
          $app->run($port, 'localhost', $server);

          diag("Process $$ (catalyst server) exiting.") if $DEBUG;
          exit 1;
      }
      $uri = 'http://localhost:' . $port;
      $app_pid = $pid;
    }
    
    my $tries = 5;
    my $error;
    my $sel_class = delete $args->{selenium_class} || 'Test::WWW::Selenium';
    my $sel;

    if ($ENV{SELENIUM_SERVER}) {
        my $uri = $ENV{SELENIUM_SERVER};
        $uri =~ s!^(?:http://)?!http://!;
        $uri = new URI($uri);
        $args->{selenium_host} = $uri->host;
        $args->{selenium_port} = $uri->port;
    }
    elsif ($ENV{SELENIUM_PORT}) {
        $args->{selenium_port} = $ENV{SELENIUM_PORT};
    }

    my $sel_host = delete $args->{selenium_host} || 'localhost';
    my $sel_port = delete $args->{selenium_port} || 4444;
    while(!$sel && $tries--){ 
        sleep 1;
        diag("Waiting for selenium server to start")
          if $DEBUG;
        
        eval {
            $sel = $sel_class->new(
                host => $sel_host,
                port => $sel_port,
                browser => '*firefox',
                browser_url => $uri,
                auto_stop => 0,
                %$args
            );
        };
        $error = $@;
    }
    croak "Can't start selenium: $error" if $error;
    
    return $www_selenium = $sel;
}

END {
    if($sel_pid){
        if($www_selenium){
            diag("Shutting down Selenium Server $sel_pid") if $DEBUG;
            $www_selenium->stop();
            # This can fail if a page hasn't been requested yet.
            eval { $www_selenium->do_command('shutDownSeleniumServer') };
            undef $www_selenium;
        }
        diag("Killing Selenium Server $sel_pid") if $DEBUG;
        kill 15, $sel_pid or diag "Killing Selenium: $!";
        undef $sel_pid;

    } elsif ($www_selenium) {
        diag("Using external Selenium server. Don't shut it down.") if $DEBUG;
        undef $www_selenium;
    }

    if($app_pid){
        diag("Killing catalyst server $app_pid") if $DEBUG;
        kill 15, $app_pid or diag "Killing MyApp: $!";
        undef $app_pid;
    }
    diag("Waiting for children to die") if $DEBUG;
    waitpid $sel_pid, 0 if $sel_pid;
    waitpid $app_pid, 0 if $app_pid;
}


=head1 ENVIRONMENT

Debugging messages are shown if C<CATALYST_DEBUG> or C<MYAPP_DEBUG>
are set.  C<MYAPP> is the name of your application, uppercased.  (This
is the same syntax as Catalyst itself.)

C<CATALYST_SERVER> can be set to test against an externally running server,
in a similar manner to how L<Test::WWW::Mechanize::Catalyst> behaves.

The port that the application sever runs on can be affected by C<MYAPP_PORT>
in addition to being specifiable in the arguments passed to start.

=head1 DIAGNOSTICS

=head2 Specify your app's name

You need to pass your Catalyst app's name as the argument to the use
statement:

    use Test::WWW::Selenium::Catalyst 'MyApp'

C<MyApp> is the name of your Catalyst app.

=head1 SEE ALSO

=over 4 

=item * 

Selenium website: L<http://seleniumhq.org/>

=item * 

Description of what you can do with the C<$sel> object: L<Test::WWW::Selenium>
and L<WWW::Selenium>

=item * 

If you don't need a real web browser: L<Test::WWW::Mechanize::Catalyst>

=back

=head1 AUTHOR

Ash Berlin C<< <ash@cpan.org> >>

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-www-selenium-catalyst at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Selenium-Catalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 PATCHES

Send me unified diffs against the git HEAD at:

    git://github.com/jrockway/test-www-selenium-catalyst.git

You can view the repository online at 

    http://github.com/jrockway/test-www-selenium-catalyst/tree/master

Thanks in advance for your contributions!

=head1 ACKNOWLEDGEMENTS

Thanks for mst for getting on my (jrockway's) case to actually write this thing
:)

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ash Berlin, all rights reserved.

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::WWW::Selenium::Catalyst
