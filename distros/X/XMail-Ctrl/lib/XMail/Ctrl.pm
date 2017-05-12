package XMail::Ctrl;

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
use Digest::MD5();
use IO::Socket;



# ABSTRACT: Crtl access to XMail server

$VERSION = 2.4;


# Perl interface to crtl for XMail
# Written by Aaron Johnson solution@gina.net

# Once you create a new xmail connection don't
# let it sit around too long or it will time out!

sub new {

    my ( $class, %args ) = @_;

    my $self = bless {
        _helo         => {},
        _last_error   => {},
        _last_success => {},
        _command_ok   => 0,
        _io           => undef,
        _ctrlid       => $args{ctrlid} || "",
        _ctrlpass     => $args{ctrlpass} || "",
        _host         => $args{host} || "127.0.0.1",
        _port         => $args{port} || 6017,
        debug         => $args{debug} || 0,
    }, $class;

    # no point of connecting unless we got a password
    return $self unless $args{ctrlpass};

    # Skip connection with argument no_connect
    $self->connect unless $args{no_connect};
    return $self;
}

# connect
#    returns a 0/1 value indicating the result
#    errors are retrieved by last_error as such.
#
#      print $ctrl->last_error->{description}
#         unless $ctrl->connect;
#
#    errors could be one of:
#     * Failed connecting to server ([socket_info])
#     * Authentication failed

sub connect {
    my $self = shift;

    # return ok if a connection is already present
    $self->connected and return 1;

    my ( $host, $port ) = ( $self->{_host}, $self->{_port} );

    $self->{_io} =
      IO::Socket::INET->new( PeerAddr => $host, PeerPort => $port );

    $self->last_error("Connection failed [$host:$port] ($@)")
      and return 0
      unless defined $self->{_io};

    print STDOUT "\n" if $self->debug > 1;

    # get the helo string or return failure
    defined( my $buf = $self->_recv ) or return 0;

    # gather some useful stuff from the helo string
    
    # version 1.19 and above no longer return OS removed 
    $buf =~ /^\+\d+ (<[\d\.@]+>)\D+([\d\.]+)/; # \(([^\)]+)\).+/;
    $self->{_helo} = { timestamp => $1, 
                       version => $2, 
		       # os => $3 
		      };

    # create and send MD5 auth string
    $self->_send(
        $self->{_ctrlid} . "\t#"
          . Digest::MD5::md5_hex(
            $self->{_helo}{timestamp} . $self->{_ctrlpass}
          )
      )
      or return 0;    # shouldn't happen.

    # receive auth results
    $buf = $self->_recv;

    # auth not accepted ?
    unless ( defined $buf && $buf =~ /^\+/ ) {

        #  upon a xmail MD5 auth failure, xmail returns a
        # "-00171 Resource lock entry not found". don't think this status
        # fits very well and there actually is a ERR_MD5_AUTH_FAILED (-152)
        # defined in the xmail errorcode table. Reporting that instead
        # since that more accurately describes what just happened.

        $self->last_error( "00152",
            "MD5 authentication failed [$self->{_ctrlid}\@$host:$port]" );

        # the server will cut the connection here, so we'd better get rid of
        # the socket object accordingly
        undef $self->{_io};
        return 0;
    }

    $buf =~ /^.(\d+)\s?(.*)/ and $self->last_success( $1, $2 );
    return 1;
}

# helo,
# returns a 3-key hash (timestamp,version,os)
# Calling this method before a connection is made
# obviously will return an empty hash. Helo information
# will be unset when a call to quit is made.
sub helo {
    return (shift)->{_helo};
}

# connected,
# returns the connection state.
sub connected {
    my $self = shift;
    return ( defined $self->{_io} && $self->{_io}->connected ) ? 1 : 0;
}

# last_error,
# returns a two-key hash (code/description) exposing the last
# error encountered. method quit will undefine. on no errors
# an emtpy hash is returned. If running in debug mode, errors
# are additionally printed out to the console as they appear.
sub last_error {
    my ( $self, $code, $desc ) = @_;
    if ($code) {

        # if there the code is not a xmail code and
        # the desc has no value then we shift
        # the description to be the code and
        # assign our custom error code (-99999)
        if ( $code !~ /^\d+/ || !$desc ) {
            $desc = $code;
            $code = "99999";
        }
        $desc =~ s/\r?\n$//;
        print STDOUT "error:   code:$code  description:$desc\n"
          if $self->{debug};
        $self->{_last_error} = { code => $code, description => $desc };
    }
    return $self->{_last_error};
    
}

# last_success,
# returns a two-key hash (code/description) exposing the last
# successfull xcommand. method quit will undefine.
sub last_success {
    my ( $self, $code, $desc ) = @_;
    if ( defined($code) ) {
        return $self->{_last_success} = {} if $code eq '0';    #reset
        $desc =~ s/\r?\n$// if $desc;
        print STDOUT "ok   :   code:$code  description:$desc\n"
          if $self->{debug} > 2;
        $self->{_last_success} = { code => $code, description => $desc };
    }
    return $self->{_last_success};
}

# debug,
# sets debug mode (0-2)
sub debug {
    my ( $self, $set ) = @_;
    $self->{debug} = $set if defined $set;
    return $self->{debug};
}

# _send, wraps socket recv + does dbg output. returns 0 or 1
sub _send {
    my ( $self, $data ) = @_;
    $data .= "\r\n" unless $data =~ /\r?\n$/;

    # if the socket has been shutdown by the server, send returns
    # a defined value,(perlfunc says otherwise) but it will atleast
    # reset the connected state to false, so by additionally check
    # connection state after send, we can detect a dead peer and
    # perform a transparent reconnect and retransmit of the last command...
    unless(defined $self->{_io}->send($data) && $self->connected){

       # socket is down, reconnect and retransmit
       print STDOUT "info :   reconnecting [$self->{_host}:$self->{_port}]\n"
	   if $self->debug > 2;
	 # still failing ? then report a permanent error...
       $self->last_error("socket::send failed, no connection")
         && return 0
         unless $self->connect && defined $self->{_io}->send($data);
	}

    print STDOUT "debug:<< $data" if $self->debug > 1;
    return 1;
}

# _recv, wraps socket recv + does dbg output. returns indata or undef
sub _recv {
    my ( $self, $bufsz ) = @_;
    my $buf;
    return unless $self->connected;

    $self->last_error("socket::recv failed, no connection")
      && return
      unless $self->connected && defined $self->{_io}->recv( $buf, $bufsz || 128 );
      
    print STDOUT "debug:>> $buf" if $self->debug > 1;
    return $buf;
}

# xcommand, invoked by the autoloaded method
#
# *    on a getter command, x data is returned if the command
#     was successful. otherwise undef is returned.
#      my $data = $ctrl->userlist(...);
#      print $ctrl->last_error->{code} unless defined $data;
#
# *    on a setter command, undef/1 is returned indicating the result
#      print $ctrl->last_error->{description}
#        unless $ctrl->useradd(...) [ ==1 ]
#
#  An eventual error occuring during the transaction is
#  retrieved by the last_error method
#
sub xcommand {
    my ( $self, $args ) = @_;
    $self->command_ok(0);

    # $self->last_success(0);

    my @build_command = qw(
      domain
      alias
      account
      mlusername
      username
      password
      mailaddress
      perms
      usertype
      loc-domain
      loc-username
      extrn-domain
      extrn-username
      extrn-password
      authtype
      relative-file-path
      vars
      lev0
      lev1
      msgfile
    );
    
    my $command = delete $args->{command};
    foreach my $step (@build_command) {
        if ( ref $args->{$step} ne "HASH" ) {
            $command .= "\t$args->{$step}" if $args->{$step};
        }
        else {
            foreach my $varname ( keys %{ $args->{$step} } ) {
                $command .= "\t$varname\t$args->{$step}{$varname}";
            }
        }
        delete $args->{$step};
    }

    # no connection, try bring one up, return on failure
    $self->connect or return;

    # make debug output reader friendly
    print STDOUT "\n" if $self->debug > 1;

    # issue the command, return if send failure
    $self->_send($command) or return;

    local ($_);
    my $sck = $self->{_io};
    my ( $charge, $mode, $desc, $line, @data );
    while ( defined( $line = <$sck> ) ) {
        print STDOUT "debug:>> $line" if $self->debug > 1;
        if ( defined $mode ) {

            # weed out newlines
            $line =~ s/\r?\n$//;

            # end of input, break outta here
            last if $line =~ /^\.$/;

            # pile up input
            push ( @data, $line );
        }
        else {
            if ( $line =~ /^(.)(\d+)\s?(.*)/ ) {
                ( $charge, $mode, $desc ) = ( $1, $2, $3 );
            }

            # report '-' unless regexp matched
            $self->command_ok( $charge || '-' );

            if ( $charge eq '+' ) {
                $self->last_success( $mode, $desc );
                return 1 if $mode eq '00000';
                last if $mode ne '00100';

            }
            else {
                $self->last_error( $mode, $desc );
                return;
            }
        }
    }

    $self->last_error("Unknown recv error")
      and return
      if not defined $mode;    # cannot happen ?! :~/

    # got a +00101 code, xmail expects a list
    if ( $mode eq '00101' ) {
        @data =
          ( ref( $args->{output_to_file} ) eq 'ARRAY' )
          ? @{ $args->{output_to_file} }
          : split ( /\r?\n/, $args->{output_to_file} );

        for (@data) {

            # From Xmail docs section "Setting mailproc.tab file":
            # if line begins with a period... take care of that.
            $_ = ".$_" if /^\./;
            $self->_send($_) or last;    # end if error
        }
        $self->_send(".");
        $line = $self->_recv;

        # determine whether the list was accepted..
        $line =~ /^(.)(\d+)\s?(.*)/
          or $self->last_error( $line || "Unknown recv error" )
          and return;

        ( $charge, $mode, $desc ) = ( $1, $2, $3 );

        # set error and return unless good return status
        $self->last_error( $mode, $desc )
          and return
          unless $charge eq '+';

        # command_ok should be updated here aswell
        $self->command_ok($charge);

        # update last_success
        $self->last_success( $mode, $desc );
        return 1;
    }

    # got a +00100, a list as indata
    # return as-is unless told otherwise, the rare case I'd presume
    return ( join ( "\r\n", @data ) . "\r\n" ) if $self->raw_list;

    # ...otherwise, build up an array ref
    my $array_ref;
    my $count = 0;

    # attempting to save some memory on large lists
    while ( defined( $_ = shift @data ) ) {
        tr/"//d;
        $array_ref->[ $count++ ] = [ split /\t/ ];
    }
    return $array_ref;
}

sub error {
    my ($self) = @_;
    return $self->last_error->{code};
}

sub mode {
    my ($self) = @_;
    return $self->last_success->{code};
}

sub command_ok {
    my ( $self, $value ) = @_;
    return $self->{_command_ok} if ( !defined($value) );
    $self->{_command_ok} = ( $value eq '+' ) ? 1 : 0;
    return $self->{_command_ok};
}

sub raw_list {
    my ( $self, $value ) = @_;
    if ($value) {
        $self->{raw_list} = $value;
        return;
    }
    else {
        return $self->{raw_list};
    }
     
}

sub quit {
    my $self = shift;
    $self->{_helo}         = {};
    $self->{_last_error}   = {};
    $self->{_last_success} = {};
    if ( $self->connected ) {
        $self->_send("quit");
        $self->{_io}->close;
        undef $self->{_io};
    }
    return;
}

sub AUTOLOAD {
    my ( $self, $args ) = @_;

    $AUTOLOAD =~ /.*::(\w+)/;
    my $command = $1;
    if ( $command =~ /[A-Z]/ ) { exit }
    $args->{command} = $command;
    return $self->xcommand($args);
    
}

1;

__END__

=pod

=head1 NAME

XMail::Ctrl - Crtl access to XMail server

=head1 VERSION

version 2.4

=head1 SYNOPSIS

    use XMail::Ctrl;
    my $XMail_admin      = "aaron.johnson";
    my $XMail_pass       = "mypass";
    my $XMail_port       = "6017";
    my $XMail_host       = "example.com";
    my $test_domain      = "example.com";
    my $test_user        = "rick";

    my $xmail = XMail::Ctrl->new(
                ctrlid   => "$XMail_admin",
                ctrlpass => "$XMail_pass",
                port     => "$XMail_port",
                host     => "$XMail_host"
            ) or die $!;

    my $command_ok = $xmail->useradd(
            {
                username => "$test_user",
                password => 'test',
                domain   => "$test_domain",
                usertype => 'U'
            }
            );

    printf("Failed to add user <%s@%s>\n", $test_user, $test_domain)
       unless $cmd_ok;

    # setting the mailproc.tab

    my $proc = $xmail->usersetmproc(
            {
                username       => "$test_user",
                domain         => "$test_domain",
                output_to_file => "command for mailproc.tab",

            }
             );

    $xmail->quit;

=head1 DESCRIPTION

This module allows for access to the Crtl functions for XMail.
It operates over TCP/IP. It can be used to communicate with either
Windows or Linux based XMail based servers.

The code was written on a Win32 machine and has been tested on
Mandrake and Red Hat Linux as well with Perl version 5.6 and 5.8

As of version 2.0 all code is written on under a Linux platform
using Perl 5.8.  It has been tested on:
- Mandrake 9.0 with Perl 5.8 by Aaron Johnson
- Mandrake 8.2 with Perl 5.6.1 by Aaron Johnson
- ActiveState Perl (5.8) on Windows by Thomas Loo

Version 2.0 and higher require Digest::MD5, all passwords are
now sent as an MD5 value.

=head2 Overview

All commands take the same arguments as outlined in the XMail
(http://www.xmailserver.com) documentation.  All commands are
processed by name and arguments can be sent in the any order.

Example command from manual (is one line):
"useradd"[TAB]"domain"[TAB]"username"[TAB]"password"[TAB]"usertype"<CR><LF>

This turns into:

    $xmail->useradd( {
        domain => "domain.com",
        username => "username",
        password => "password",
        usertype => "U"
        }
        );

You can put the four parts in any order, they are put in the
correct order by the modules internals.

The command structure for XMail allows a fairly easy interface
to the command set.  This module has NO hardcoded xmail methods.
As long as the current ordering of commands is followed in the
XMail core the module should work to any new commands unchanged.

Any command that accepts vars can be used
by doing the following:

To send uservarsset (user.tab) add a vars anonymous hash,
such as:

    $xmail->uservarsset( {
    domain   => 'aopen.hank.net',
    username => 'rick',
    vars     => {
        RealName      => 'Willey FooFoo',
        RemoteAddress => '300.000.000.3',
        VillageGrid   => '45678934'
        }
    } );

The ".|rm" command can used as described in the XMail docs.

If you are having problems you might want to turn on debugging
(new in 1.5)

    $xmail->debug(1);

to help you track down the cause.

Setting the debug level to 4 will provide a very complete
output of the communication between the server and your
program. A line starting with >> (incoming) indicates what the Ctrl
service sent back and << (outgoing) indicates what the XMail::Ctrl
sent to the server.

All commands return a 1 if successful and undef on failure.

=head2 Lists

Lists are now (as of 1.3) returned as an array reference unless
you set the raw_list method to true.

    $xmail->raw_list(1);

To print the lists you can use a loop like this:

    my $list = $xmail->userlist( { domain => 'yourdomin.net' } );
    foreach my $row (@{$list}) {
    print join("\t",@{$row}) . "\n";
    }

Refer to the XMail documentation for each command for information
on which columns will be returned for a particular command.

You can send a noop (keeps the connection alive) with:

    $xmail->noop();

As of version 1.5 you can perform any froz command:

    $froz = $xmail->frozlist();

    foreach my $frozinfo (@{$froz}) {
        s/\"//g foreach @{$frozinfo};
        $res = $xmail->frozdel( {
                        lev0 => "$frozinfo->[1]",
                        lev1 => "$frozinfo->[2]" || '0',
                        msgfile => "$frozinfo->[0]",
                        });
        print $res , "\n";
    }

=head1 NAME

XMail::Ctrl - Crtl access to XMail server

=head1 VERISON

version 2.3 of XMail::Ctrl

released 07/10/2004

=head1 BUGS

Possible problems dealing with wild card requests.  I have
not tested this fully.  Please send information on what you
are attempting if you feel the module is not providing the
correct function.

=head1 THANKS

Thanks to Davide Libenzi for a sane mail server with
an incredibly consistent interface for external control.

Thanks to Mark-Jason Dominus for his wonderful classes at
the 2000 Perl University in Atlanta, GA where the power of
AUTOLOAD was revealed to me.

Thanks to my Dad for buying that TRS-80 in 1981 and getting
me addicted to computers.

Thanks to my wife for leaving me alone while I write my code
:^)

Thanks to Oscar Sosa for spotting the lack of support for
editing the 'tab' files

Thanks to Thomas Loo for making many major refactoring
contributions for version 2.0 as well as providing better
debugging output.

=head1 CHANGES

Changes file included in distro

=head1 AUTHOR

Aaron Johnson <aaronjjohnson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Aaron Johnson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
