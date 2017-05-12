package LWP::AuthenAgent;

#==============================================================================
#
# Start of POD
#
#==============================================================================

=head1 NAME

LWP::AuthenAgent - a simple subclass of LWP::UserAgent to allow the user to
type in username / password information if required for autentication.

=head1 SYNOPSIS

    use LWP::AuthenAgent;

    my $ua = new LWP::AuthenAgent;
    my $response = $ua->request( new HTTP::Request 'GET' => $url );

=head1 DESCRIPTION

LWP::AuthenAgent simple overloads the get_basic_credentials method of
LWP::UserAgent. It prompts the user for username / passsword for a given realm,
supressing tty echoing of the password. Authentication details are stored
in the object for each realm, so that they can be re-used in subsequest
requests for the same realm, if necessary.

=head1 METHODS

LWP::AuthenAgent inherits all the methods available in LWP::UserAgent.

=head1 SEE ALSO

    LWP::UserAgent
    Term::ReadKey

=head1 AUTHOR

Ave Wrigley E<lt>Ave.Wrigley@itn.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe (CRE). All rights reserved.
This script and any associated documentation or files cannot be distributed
outside of CRE without express prior permission from CRE.

=cut

#==============================================================================
#
# End of POD
#
#==============================================================================

use Term::ReadKey;
use LWP::UserAgent;
use vars qw( $VERSION @ISA );

$VERSION = '0.001';
@ISA = qw( LWP::UserAgent );

#------------------------------------------------------------------------------
#
# overload get_basic_credentials method
#
#------------------------------------------------------------------------------

sub get_basic_credentials
{
    my $self    = shift;
    my $realm   = shift;
    my $uri     = shift;

    local( $| ) = 1;

    unless ( 
        $self->{ 'username' }{ $realm } and 
        $self->{ 'password' }{ $realm }
    )
    {
        print "\n\nAuthenticating URI $uri in realm $realm\n\n";
        do {
            print "Enter username : ";
            $self->{ 'username' }{ $realm } = <STDIN>;
            chomp( $self->{ 'username' }{ $realm } );
        }
        until ( length $self->{ 'username' }{ $realm } );
        do {
            print "Enter password : ";
            ReadMode 'noecho';
            $self->{ 'password' }{ $realm } = <STDIN>;
            ReadMode 'normal';
            print "\n";  # because we disabled echo
            chomp( $self->{ 'password' }{ $realm } );
        }
        until ( length $self->{ 'password' }{ $realm } );
    }
    return ( $self->{ 'username' }{ $realm }, $self->{ 'password' }{ $realm } );
}

#==============================================================================
#
# Return TRUE
#
#==============================================================================

1;
