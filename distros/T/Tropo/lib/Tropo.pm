package Tropo;

# ABSTRACT: Use the TropoAPI via Perl

use strict;
use warnings;

use Moo;
use Types::Standard qw(ArrayRef);
use Path::Tiny;
use JSON;

use overload '""' => \&json;

our $VERSION = 0.16;

has objects => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

for my $subname ( qw(call say ask on wait) ) {
    my $name     = ucfirst $subname;
    my @parts    = qw/Tropo WebAPI/;
    
    my $filename = path( @parts, $name . '.pm' );
    require $filename;
    
    my $module = join '::', @parts, $name;
    
    no strict 'refs';
    
    *{"Tropo::$subname"} = sub {
        my ($tropo,@params) = @_;
        
        my $obj = $module->new( @params );
        $tropo->add_object( { $subname => $obj } );

        return $tropo;
    };
}

sub perl {
    my ($self) = @_;
    
    my @objects;
    my $last_type = '';
    
    for my $index ( 0 .. $#{ $self->objects } ) {
        my $object      = $self->objects->[$index];
        my $next_object = $self->objects->[$index+1];

        my ($type,$obj) = %{ $object };
        my ($next_type) = %{ $next_object || { '' => ''} };

        if ( $type ne $last_type && $type eq $next_type && $type ne 'on' ) {
            push @objects, { $type => [ $obj->to_hash ] };
        }
        elsif ( $type ne $last_type && $type ne $next_type || $type eq 'on' ) {
            push @objects, { $type => $obj->to_hash };
        }
        else {
            push @{ $objects[-1]->{$type} }, $obj->to_hash;
        }

        $last_type = $type;
    }
    
    my $data = {
        tropo => \@objects,
    };
    
    return $data;
}

sub json {
    my ($self) = @_;
    
    my $data   = $self->perl;
    my $string = JSON->new->encode( $data );
    
    return $string;
}

sub add_object {
    my ($self, $object) = @_;
    
    return if !$object;
    
    push @{ $self->{objects} }, $object;
}

1;

__END__

=pod

=head1 NAME

Tropo - Use the TropoAPI via Perl

=head1 VERSION

version 0.16

=head1 SYNOPSIS

Ask the 

  my $tropo = Tropo->new;
  $tropo->call(
    to => $clients_phone_number,
  );
  $tropo->say( 'hello ' . $client_name );
  $tropo->json;

Creates this JSON output:

  {
      "tropo":[
          {
              "call": {
                      "to":"+14155550100"
              }
          },
          {
              "say": [
                  {
                      "value":"Tag, you're it!"
                  }
              ]
          }
      ]
  }

You can also chain the method calls:

  my $tropo = Tropo->new;
  print $tropo->call( to => $phone )->say ( 'hello' )->json;

=head1 DESCRIPTION

=head1 HOW THE TROPO API WORKS

The Tropo server I<talks> with your web application via json sent with HTTP POST requests.

When you'd like to initiate a call/text message, you have to start a session.

        my $session = Tropo::RestAPI::Session->new(
            url => 'https://tropo.developergarden.com/api/', # use developergarden.com api
        );

        my $data = $session->create(
            token        => $token,
            call_session => $id,
        ) or print $session->err;

When you create a session you can pass any parameter you want. The only mandatory parameter
is I<token>. You'll find that token in your developergarden account in the application management.

The Tropo server then requests the URI that you added in the application management. It is an
HTTP POST request that contains session data (the parameters that you passed, too). An example of
the dumped request data can be found below.

Your application has to send JSON data back to the Tropo server. In that JSON data you can define
(see command I<on>) which URLs the Tropo server requests on specific events. 

=head1 COMMANDS

This list show the commands currently implemented. This library is under heavy development,
so that more commands will follow in the near future:

=head2 ask

=head2 call

=head2 on

=head2 say

=head2 wait

A detailed description of all commands and their attributes can be found at
L<http://www.developergarden.com/fileadmin/microsites/ApiProject/Dokumente/Dokumentation/Api_Doc_5_0/telekom-tropo-2.1/html/method_summary.html|DeveloperGarden>.

Only C<on> can't be found there.

=head1 EXAMPLES

All examples can be found in the I<examples> directory of this distribution. Those examples
might have extra dependencies that you might have to install when you want to run the code.

You also need an account e.g. for developergarden.com or tropo.com.

=head2 Two factor authentication

I<call_customer.psgi>

You can find a small C<Mojolicious::Lite> application that calls a customer to tell him a
code... On the start page a small form is shown where the customer sends his phone number.
Then a new call is initiated and the Tropo provider calls the customer and tells him the
secret.

=head2 Handle incoming calls

I<televote.psgi>

You can publish a phonenumber that is connected to your application (e.g. in developergardens
application management). The people call that number and are asked to "vote"...

=head1 MORE INFO

Here you can find some detailed info that might help to debug your code.

=head2 Session data sent from Tropo to your app

    $VAR1 = {
          'session' => {
                       'userType' => 'NONE',
                       'parameters' => {
                                       'token' => 'your_api_token',
                                       'action' => 'create',
                                       'call_session' => 'zRlbp7UET5ecDcneDCnoB4'
                                     },
                       'callId' => undef,
                       'initialText' => undef,
                       'timestamp' => '2013-09-06T18:53:20.168Z',
                       'accountId' => '9183',
                       'id' => '9884f64erb41e97948083c25980d63683'
                     }
        };

=head1 ACKNOWLEDGEMENT

I'd like to thank Richard from Telekoms Developergarden. He has done a lot of debugging during
the #startuphack (Hackathon at "Lange Nacht der Startups" 2013).

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
