package WWW::Mechanize::Sleepy;

our $VERSION = 0.7;

use strict;
use warnings;
use Carp qw( croak );
use base qw( WWW::Mechanize );

=head1 NAME 

WWW::Mechanize::Sleepy - A Sleepy Mechanize Agent

=head1 SYNOPSIS

    use WWW::Mechanize::Sleepy;
   
    # sleep 5 seconds between requests
    my $a = WWW::Mechanize::Sleepy->new( sleep => 5 );
    $a->get( 'http://www.cpan.org' );

    # sleep between 5 and 20 seconds between requests
    my $a = WWW::Mechanize::Sleepy->new( sleep => '5..20' );
    $a->get( 'http://www.cpan.org' );

    # don't sleep at all
    my $a = WWW::Mechanize::Sleepy->new();
    $a->get( 'http://www.cpan.org' );

=head1 DESCRIPTION

Sometimes when testing the behavior of a webserver it is important to be able
to space out your requests in order to simulate a person reading, thinking (or 
sleeping) at the keyboard.

WWW::Mechanize::Sleepy subclasses WWW::Mechanize to provide pauses between your server requests. Use it just like you would use WWW::Mechanize.

=head1 METHODS

All the methods are the same as WWW::Mechanize, except for the constructor
which accepts an additional parameter.

=head2 new()

The constructor which acts just like the WWW::Mechanize constructor except
you can pass it an extra parameter. 

=over 4

=item * sleep 

An amount of time in seconds to sleep.

    my $a = WWW::Mechanize::Sleepy->new( sleep => 5 );

Or a range of time to sleep within. Your robot will sleep a random
amount of time within that range.

    my $a = WWW::Mechanize::Sleepy->new( sleep => '5..20' );

If you would like to have a non sleeping WWW::Mechanize object, you can 
simply not pass in the sleep paramter.

    my $a = WWW::Mechanize::Sleepy->new();

=back

Note: since WWW::Mechanize::Sleepy subclasses WWW::Mechanize, which subclasses
LWP::UserAgent, you can pass in LWP::UserAgent::new() options to
WWW::Mechanize::Sleepy::new().

    my $a = WWW::Mechanize::Sleepy->new( 
	agent	    => 'foobar agent',
	timeout	    => 100
    );

=cut

sub new {
    my $class = shift;
    my %parms = @_;
    my $sleep = 0;
    if ( exists( $parms{ sleep } ) ) { 
	$sleep = $parms{ sleep };
	_sleepCheck( $sleep );
	delete( $parms{ sleep } );
    }
    my $self = $class->SUPER::new( %parms );
    $self->{ Sleepy_Time } = $sleep;
    return( $self );
}

=head2 sleep()

If you want to get or set your object's sleep value on the fly use sleep().

   my $a = WWW::Mechanize::Sleepy->new( sleep => '1..3' );
   ...
   print "currently sleeping ", $a->sleep(), " seconds\n";
   $a->sleep( '4..6' );

If you want to make your WWW::Mechanize::Sleepy object no longer sleepy just
set to 0.

    $a->sleep( 0 );

=cut

sub sleep {
    my ( $self, $arg ) = @_;
    if ( defined( $arg ) ) { 
	_sleepCheck( $arg );
	$self->{ Sleepy_Time } = $arg;
    }
    return( $self->{ Sleepy_Time } );
}

sub back {
    my $self = shift;
    $self->_sleep();
    $self->SUPER::back( @_ );
}

sub request {
    my $self = shift;
    $self->_sleep();
    $self->SUPER::request( @_ );
}

sub reload {
    my $self = shift;
    $self->_sleep();
    $self->SUPER::reload( @_ );
}

sub _sleep {
    my $self = shift;
    return( 1 ) if $self->{ Sleepy_Time } eq '0';
    my $sleep;
    if ( $self->{ Sleepy_Time } =~ /^(\d+)\.\.(\d+)$/ ) { 
	$sleep = int( rand( $2 - $1 ) ) + $1;
    } else { 
	$sleep = $self->{ Sleepy_Time };
    }
    CORE::sleep( $sleep );
    return( 1 );
}

sub _sleepCheck {
    my $sleep = shift;
    croak( "sleep parameter must be an integer or a range i1..i2" )
	if ( $sleep !~ /^(\d+)|(\d+\.\.\d+)$/ );
    if ( $sleep =~ /(\d+)\.\.(\d+)/ and $1 >= $2 ) { 
	croak( "sleep range (i1..i2) must have i1 < i2" );
    }
    return( 1 );
}


=head1 AUTHOR/MAINTAINER

WWW::Mechanize::Sleepy was originally written in 2003 by Ed Summers (ehs@pobox.com).
Since version 0.7 (September 2010) it has been maintained by Kostas Ntonas (kntonas@gmail.com).

=head1 SEE ALSO

=over 4

=item * L<WWW::Mechanize>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

1;
