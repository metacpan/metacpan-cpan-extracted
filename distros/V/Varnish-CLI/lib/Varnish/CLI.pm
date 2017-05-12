package Varnish::CLI;
use Moose;
use Net::Telnet;
use Carp;
use Digest::SHA qw/sha256_hex/;

=head1 NAME

Varnish::CLI - An interface to the Varnish CLI

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Varnish CLI is a great administration tool, but a bit difficult to script for.
This module allows easy script interface to it.

    use Varnish::CLI;
    my $varnish = Varnish::CLI->new( host    => $host,
                                     port    => $port,
                                     timeout => $timeout,
                                     secret  => $secret,
                                );
    $varnish->send( 'url.purge .*' );

The Varnish::CLI can be initialised without any parameters, and will usually work for the default
Varnish settings:

    my $varnish = Varnish::CLI->new();

If you have started your Varnish CLI with a secret, you must will have to pass the contents
of your secret file, otherwise authentication will fail...  Makes sense!! :)
Remember - complete contents of the secret file (including a newline if it exists!)

    my $varnish = Varnish::CLI->new( secret => $secret );
    
=head1 PROPERTIES

    has host =>        ( is       => 'ro',
                         isa      => 'Str',
                         required => 1,
                         default  => 'localhost' );

    has port =>        ( is       => 'ro',
                         isa      => 'Int',
                         required => 1,
                         default  => 6082 );

    has timeout =>     ( is       => 'rw',
                         isa      => 'Int',
                         required => 1,
                         default  => 1 );

    has t =>           ( is       => 'rw',
                         isa      => 'Net::Telnet',
                         clearer  => 'clear_t' );
                
    has secret =>      ( is       => 'rw',
                         isa      => 'Str' );

    has connected =>   ( is       => 'rw',
                         isa      => 'Int',
                         default  => 0,
                         required => 1 );

    has last_lines =>  ( is       => 'rw',
                         isa      => 'ArrayRef',
                         default  => sub{ [] } );

    has last_status => ( is       => 'rw',
                         isa      => 'Int',
                        );

=cut
has host =>        ( is       => 'ro',
                     isa      => 'Str',
                     required => 1,
                     default  => 'localhost' );

has port =>        ( is       => 'ro',
                     isa      => 'Int',
                     required => 1,
                     default  => 6082 );

has timeout =>     ( is       => 'rw',
                     isa      => 'Int',
                     required => 1,
                     default  => 1 );

has secret =>      ( is       => 'rw',
                     isa      => 'Str' );

has t =>           ( is       => 'rw',
                     isa      => 'Net::Telnet',
                     clearer  => 'clear_t' );
                
has connected =>   ( is       => 'rw',
                     isa      => 'Int',
                     default  => 0,
                     required => 1 );

has last_lines =>  ( is       => 'rw',
                     isa      => 'ArrayRef',
                     default  => sub{ [] } );

has last_status => ( is       => 'rw',
                     isa      => 'Int',
                    );


=head1 SUBROUTINES/METHODS

=head2 connect

Connect to the Varnish CLI interface

=cut
sub connect{
    my( $self ) = shift;
    if( $self->t() and $self->connected() ){
        return 1;
    }
    my $t = Net::Telnet->new(
        Host                    => $self->host(),
        Port                    => $self->port(),
        Timeout                 => $self->timeout(),
        Output_record_separator => "\n",
        Input_record_separator  => "\n",
        );
    $self->t( $t );
    $t->open(); 
    $self->_parse_response();

    # A 107 response on connection means the Varnish CLI expects authentication
    if( $self->last_status() == 107 ){
        if( not $self->secret() ){
            croak( "Connection failed: authentication required, but no secret given\n" );
        }
        
        my $challenge = substr( $self->last_lines()->[0], 0, 32 );
        my $auth = sha256_hex( $challenge . "\n" . $self->secret() . $challenge . "\n" );
        $self->send( "auth $auth" );
        if( $self->last_status != 200 ){
            croak( "Authentication failed!\n" );
        }
    }
    
    if( $self->last_status() != 200 ){
        croak( "Connection failed\nStatus: " . $self->last_status() . "\n". 
               "Last lines: \n\t" . join( "\t", @{ $self->last_lines() } ) . "\n" );
    }
    return 1;
}

=head2 close

Close the connection to the Varnish CLI interface

=cut
sub close{
    my( $self ) = shift;
    if( not $self->t() or not $self->connected() ){
        carp( "Close called, but not connected" );
        return 1;
    }
    my $t = $self->t();
    $t->print( 'quit' );
    $t->close();
    $self->clear_t();
    $self->connected( 0 );
}

=head2 send

Send a command to the Varnish CLi

=cut
sub send{
    my( $self, $command ) = @_;
    if( ! $command ){
        croak( "Cannot call send without a command" );
    }
    # Make sure we're connected
    $self->connect();
    $self->t->print( $command  );
    $self->_parse_response();
    if( $self->last_status() != 200 ){
        croak( "Command failed: $command\nStatus: " . $self->last_status() . "\n". 
               "Last lines: \n\t" . join( "\t", @{ $self->last_lines() } ) . "\n" );
    }
}

# Private method to parse the response from the CLI
sub _parse_response{
    my $self = shift;
    my $t = $self->t();
    my $line = $t->getline();
    if( $line !~ m/^(\d+)\s*(\d+)\s*$/ ){
        $self->connected( 0 );
        print "Next line:\n";
        print $t->getline();
        croak( "Unexpected line:\n($line)" );

    }
    my $status = $1;
    my $chars = $2;
    my $got_chars = 0;
    $self->connected( 1 );
    my @lines;
    while( $got_chars < $chars ){
        push( @lines, $t->getline() );
        $got_chars += length( $lines[-1] );
    }
    # There's always one empty line after
    push( @lines, $t->getline() );
    $self->last_lines( \@lines );
    $self->last_status( $status );
}

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-varnish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Varnish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Varnish::CLI

You can also look for information at:

=over 4

=item * Repository on Github

L<https://github.com/robin13/Varnish-CLI>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Varnish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Varnish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Varnish>

=item * Search CPAN

L<http://search.cpan.org/dist/Varnish/>

=back


=head1 ACKNOWLEDGEMENTS

L<http://www.varnish-cache.org/>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Varnish
