package WebService::Hexonet::Connector::Logger;

use 5.030;
use strict;
use warnings;
use Data::Dumper;

use version 0.9917; our $VERSION = version->declare('v2.10.2');


sub new {
    my ($class) = @_;
    return bless {}, $class;
}


sub log {
    my ( $self, $post, $r, $error ) = @_;
    if ( defined $error ) {
        print {*STDERR} Dumper($post);
        print {*STDERR} 'HTTP communication failed: ' . $error;
        print {*STDERR} Dumper( $r->getCommandPlain() );
        print {*STDERR} Dumper( $r->getPlain() );
    } else {
        print {*STDOUT} Dumper($post);
        print {*STDOUT} Dumper( $r->getCommandPlain() );
        print {*STDOUT} Dumper( $r->getPlain() );
    }
    return $self->{data};
}

1;

__END__

=pod

=head1 NAME

WebService::Hexonet::Connector::Logger - Library to cover API request and response data output / logging.

=head1 SYNOPSIS

This module is internally used by the L<WebService::Hexonet::Connector::APIClient|WebService::Hexonet::Connector::APIClient> module.
To be used in the way:

    # create a new instance by
    $logger = WebService::Hexonet::Connector::Logger->new();

    # Log API Request / Response Data
    # * specify request data in $data in string format
    # * specify an instance of WebService::Hexonet::Connector::Response in $r.    
    # * specify an error message as string in $error (optional parameter)
    $logger->log( $data, $r, $error );
    #  vs.
    $logger->log( $data, $r );    

=head1 DESCRIPTION

HEXONET Backend API communication will be printed to STDOUT/STDERR by default.
This mechanism can be overwritten by a CustomLogger implementation.
Use method setCustomLogger of WebService::Hexonet::Connector::APIClient for this.
Important is that a custom implementation provides method `log` and supports all the arguments explained.

=head2 Methods

=over

=item C<new>

Returns a new L<WebService::Hexonet::Connector::Logger|WebService::Hexonet::Connector::Logger> object.

=item C<log($post, $r, $error)>

Log API Request / Response Data
Specify request data in $data in string format
Specify an instance of WebService::Hexonet::Connector::Response in $r.
Specify an error message as string in $error. Optional. Thought for forwarding HTTP errors.

=back

=head1 LICENSE AND COPYRIGHT

This program is licensed under the L<MIT License|https://raw.githubusercontent.com/hexonet/perl-sdk/master/LICENSE>.

=head1 AUTHOR

L<HEXONET GmbH|https://www.hexonet.net>

=cut
