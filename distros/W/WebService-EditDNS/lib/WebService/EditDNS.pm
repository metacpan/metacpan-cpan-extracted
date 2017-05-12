package WebService::EditDNS;

use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use URI::Escape;

=head1 NAME

WebService::EditDNS - Perl interface to EditDNS API

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

WebService::EditDNS provides an interface to EditDNS API, allowing for control
of domains and records hosted at EditDNS.

    use WebService::EditDNS;

    # Create a new instance of WebService::EditDNS
    my $editdns = WebService::EditDNS->new(email => 'your@email.address',
                                           apihash => 'your_API_hash');

    # Add a new domain
    $editdns->add_domain(domain => 'example.com');

    # Add a type A record
    $editdns->add_record(domain => 'example.com',
                         record => 'www.example.com',
                         type => 'A',
                         data => '12.34.56.78');

    # Delete a record
    $editdns->delete_record(domain => 'example.com',
                            record => 'www.example.com',
                            type => 'A');

    # Delete a domain
    $editdns->delete_domain(domain => 'example.com');
         
    ...

=head1 METHODS

=head2 new

Creates a new instance of WebService::EditDNS.

    my $editdns = WebService::EditDNS->new(email => 'your@email.address',
                                           apihash => 'your_API_hash');

Parameters:

=over 4

=item * email

B<(Required)> E-mail address registered at EditDNS.net.

=item * apihash

B<(Required)> API hash generated for the EditDNS account.

=item * domain

I<(Optional)> Domain name. If specified in the constructor call, it can be
ommitted in further calls to L<"add_record"> and L<"delete_record">. 

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless($self, $class);
    
    if (!defined $args{'email'}) {
        carp "Required parameter 'email' is not defined";
    }
    
    if (!defined $args{'apihash'}) {
        carp "Required parameter 'apihash' is not defined";
    }
    
    $self->{'email'} = $args{'email'};
    $self->{'apihash'} = $args{'apihash'};
    $self->{'domain'} = $args{'domain'};
    
    $self->{'ua'} = LWP::UserAgent->new;
    $self->{'ua'}->agent("WebService::EditDNS/$VERSION (Perl)");
    
    return $self; 
}

# Send a EditDNS API request

sub _api_request {
    my $self = shift;
    my %args = (
        'email'     => $self->{'email'},
        'apihash'   => $self->{'apihash'},
        'domain'    => $self->{'domain'},
        @_
    );
    
    if (!defined $args{'email'}) {
        carp "Required parameter 'email' is not defined";
    }
    
    if (!defined $args{'apihash'}) {
        carp "Required parameter 'apihash' is not defined";
    }
    
    if (!defined $args{'domain'}) {
        carp "Required parameter 'domain' is not defined";
    }
    
    my $url = 'https://www.editdns.net/api/api.php';
    my $prefix = '?';
       
    for my $arg (keys %args) {
        $url .= $prefix . $arg . '=' . uri_escape($args{$arg});
        $prefix = '&';
    }
    
    my $request = HTTP::Request->new(GET => $url);
    
    # Send the request and get the response
    my $response = $self->{'ua'}->request($request);
    
    # Received a HTTP error code
    if (!$response->is_success) {
        carp "Request failed (Server response: \"" .
            $response->status_line . "\")";
        return undef;
    }
    
    # Successful EditDNS API responses start with "200:", if it's missing then
    # we have an error
    if ($response->content !~ /^200:/) {
        (my $error = $response->content) =~ s/\n$//;
        carp "Operation failed (API error message: \"" .
            $error . "\")";
        return undef;
    }
}

=head2 add_domain

Adds a new domain.

    $editdns->add_domain(domain => 'example.com');

Parameters:

=over 4

=item * domain

B<(Required)> Domain name.

=item * default_ip

I<(Optional)> Default IP address that the domain's root and www records will
point to.

=item * master_ns

I<(Optional)> The IP address or hostname of a master nameserver (for
backup/slave domains).

=back

=cut

sub add_domain {
    my $self = shift;
    my %args = @_;
    
    # Translate parameter names (EditDNS uses camelCase) 
    $args{'defaultIP'} = $args{'default_ip'} if defined $args{'default_ip'};
    $args{'masterNS'} = $args{'master_ns'} if defined $args{'master_ns'};
    
    # Make original parameters undefined
    $args{'default_ip'} = undef;
    $args{'master_ns'} = undef;
    
    $args{'addDomain'} = '1';
    
    return $self->_api_request(%args);
}

=head2 delete_domain

Deletes a domain.

    $editdns->delete_domain(domain => 'example.com');

Parameters:

=over 4

=item * domain

B<(Required)> Domain name.

=back

=cut

sub delete_domain {
    my $self = shift;
    my %args = @_;
    
    $args{'deleteDomain'} = '1';
    
    return $self->_api_request(%args);
}

=head2 add_record

Adds a new record.

    $editdns->add_record(domain => 'example.com',
                         record => 'www.example.com',
                         type => 'A',
                         data => '12.34.56.78')

Parameters:

=over 4

=item * domain

B<(Required)> Domain name. Can be ommitted if set with L<"new">.

=item * record

B<(Required)> Record name.

=item * type

B<(Required)> Record type (e.g., "A", "MX", "CNAME", etc.).

=item * data

B<(Required)> Record data (e.g., IP address for a type A record).

=item * ttl

I<(Optional)> TTL (time to live) value for the record. 

=item * aux

I<(Optional)> AUX value for the record (mostly used with MX records).

=back

=cut

sub add_record {
    my $self = shift;
    my %args = @_;
    
    if (!defined $args{'record'}) {
        carp "Required parameter 'record' is not defined";
    }
    
    if (!defined $args{'type'}) {
        carp "Required parameter 'type' is not defined";
    }
    
    if (!defined $args{'data'}) {
        carp "Required parameter 'data' is not defined";
    }
    
    $args{'addRecord'} = '1';
    
    return $self->_api_request(%args);
}

=head2 delete_record

Deletes a record.

    $editdns->delete_record(domain => 'example.com',
                            record => 'mail.example.com',
                            type => 'MX');

Parameters:

=over 4

=item * domain

B<(Required)> Domain name. Can be ommitted if set with L<"new">.

=item * record

B<(Required)> Record name.

=item * type

B<(Required)> Record type.

=back

=cut

sub delete_record {
    my $self = shift;
    my %args = @_;
    
    if (!defined $args{'record'}) {
        carp "Required parameter 'record' is not defined";
    }
    
    if (!defined $args{'type'}) {
        carp "Required parameter 'type' is not defined";
    }
    
    $args{'deleteRecord'} = '1';
    
    return $self->_api_request(%args);
}

=head1 AUTHOR

Michal Wojciechowski, C<< <odyniec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-editdns at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-EditDNS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::EditDNS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-EditDNS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-EditDNS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-EditDNS>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-EditDNS>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michal Wojciechowski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WebService::EditDNS
