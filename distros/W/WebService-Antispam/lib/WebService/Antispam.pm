package WebService::Antispam;

use 5.006;
use strict;
use warnings FATAL => 'all';
use JSON::XS;
use LWP::UserAgent;

our $VERSION = '1.04'; 

# JSON object
my $json_xs = JSON::XS->new;
$json_xs->utf8(1);

my %connection_params = (
    'server_url' => 'http://moderate.cleantalk.ru',
    'server_url' => 'http://localhost',
    'api_url' => '/api2.0',
    'auth_key' => undef, 
    'connection_timeout' => 3, 
    'method_name' => 'check_message', 
    'agent' => 'perl-api-' . $VERSION, 
);

my %response = (
    'allow' => 0,
    'id' => undef,
    'comment' => '*** Connection error: %s Automoderator cleantalk.org ***',
    'stop_queue' => 0,
    'inactive' => 0,
);

sub new {
    my $class = shift;
    my $params = shift;
    my $self = bless {} , $class;
    
    foreach (keys %connection_params) {
        $connection_params{$_} = $$params{$_} if defined($$params{$_});
    }
     
    return $self;
}

sub request {
    my $class = shift;
    my $params = shift;
    
    $$params{'auth_key'} = $connection_params{'auth_key'};
    $$params{'method_name'} = $connection_params{'method_name'} if !defined($$params{'method_name'});
    $$params{'agent'} = $connection_params{'agent'} if !defined($$params{'agent'});

    my $ua = LWP::UserAgent->new;
    $ua->timeout($connection_params{'connection_timeout'});

    my $server_url = $connection_params{'server_url'} . $connection_params{'api_url'}; 
    
    my $request = HTTP::Request->new(POST => $server_url);
    $request->header('content-type' => 'application/json');
    $request->content($json_xs->encode($params));

    my $result = undef;
    my $response = $ua->request($request);
    if ($response->is_success) {
        eval{
            $result = $json_xs->decode($response->decoded_content);
        };
        if ($@ || ref($result) ne 'HASH') {
            $response{'comment'} = sprintf($response{'comment'}, $response->decoded_content);
            return \%response;
        } 
    } else {
        $response{'comment'} = sprintf($response{'comment'}, $response->message);
        return \%response;
    }

    return $result;
}

__END__

=head1 NAME

WebService::Antispam - test visitors accounts or posts for spam 

=head1 SYNOPSIS
    
    use strict;
    use WebService::Antispam;

    my $ct = WebService::Antispam->new({
                auth_key => '12345' # API key, please get on cleantalk.org
            });

    my $response = $ct->request({
        message => 'abc', # Comment visitor to the site 
        example => undef, # The text of the article to which visitor created a comment. 
        sender_ip => '196.19.250.114', # IP address of the visitor 
        sender_email => 'stop_email@example.com', # Email IP of the visitor
        sender_nickname => 'spam_bot', # Nickname of the visitor
        submit_time => 12, # The time taken to fill the comment form in seconds
        js_on => 1, # The presence of JavaScript for the site visitor, 0|1
    });

=head1 DESCRIPTION

This class filters spam registrations and spam comments at web-site. It's a client application for cloud anti-spam service cleantalk.org.

In normal use the application creates an WebService::Antispam, and configures it with values - API key, server URL, timeouts and etc. It then make a request call with values of site visitor - text comment, sender ip, sender email, form fill time and etc. This request then passed to one of cleantalk.org servers via HTTP + JSON. Server returns an answer encoded with JSON, this answer consist values indicates spam or not this comment/registration by site visitor.

=head1 CONSTRUCTOR METHODS

The following constructor methods are available:

=over 4

=item $ct = WebService::Antispam->new( %options )

This method constructs a new WebService::Antispam object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

    KEY                     DEFAULT
    -----------             --------------------
    server_url              http://moderate.cleantalk.ru 
    api_url                 /api2.0
    auth_key                undef
    connection_timeout      3 
    method_name             check_message
    agent                   perl-api- . $VERSION 

=item $ct->request( %options )

This method will dispatch call to servers. There will be reference to a hash with server's response:

    KEY                     VALUE 
    -----------             --------------------
    allow                   0|1 - spam or not comment/registration
    id                      MD5_HEX - unique request ID
    comment                 string - description about request from server
    stop_queue              0|1 - should comment move to site's moderation queue or not
    inactive                0|1 - should registration move to inactive state or not

=back

=head1 AUTHOR

CleanTalk, C<< <welcome at cleantalk.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-cleantalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-CleanTalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Antispam


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-CleanTalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-CleanTalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-CleanTalk>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-CleanTalk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 CleanTalk.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Antispam

