package VM::CloudAtCost;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use JSON;
use Data::Clean::FromJSON;

use Exporter qw(import);

our $VERSION = "0.1";  

sub new {
    my ($class, %params) = @_;

    my $url = $params{url};
    
    my $agent = LWP::UserAgent->new();

    $agent->timeout($params{timeout})
    if $params{timeout};
    
    $agent->ssl_opts(%{$params{ssl_opts}})
    if $params{ssl_opts} && ref $params{ssl_opts} eq 'HASH';

    my $self = {
        url   => $url,
        agent => $agent
    };
    bless $self, $class;

    return $self;
}

# syntax: $cloud->listServers(login => $UserID, key => $APIkey ); 
sub listServers { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};

    my $result = $self->_get("/api/v1/listservers.php", %params);
    return $result->{data};	
#    return $result->{data} ? @{$result->{data}} : ();
}

# syntax: $cloud->listTemplates(login => $UserID, key => $APIkey ); 
sub listTemplates { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};

    my $result = $self->_get("/api/v1/listtemplates.php", %params);
    return $result->{data} ? @{$result->{data}} : ();
}

# syntax: $cloud->listTasks(login => $UserID, key => $APIkey );
sub listTasks { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    
    my $result = $self->_get("/api/v1/listtasks.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
}

# syntax: $cloud->powerOperation(login => $UserID, key => $APIkey, sid => $ServerID, action => '[poweron, poweroff, reset]')
sub powerOperation { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    die "missing sid parameter" unless $params{sid};
    die "missing action parameter" unless $params{action};
    die "invalid action parameter" unless $params{action} eq 'poweron' or
                                          $params{action} eq 'poweroff'   or
                                          $params{action} eq 'reset';
    
    my $result = $self->_post("/api/v1/powerop.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
}

# syntax: $cloud->renameServer(login => $UserID, key => $APIkey, sid => $ServerID, name => $NewServerName )
sub renameServer { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    die "missing name parameter" unless $params{name};
    die "missing sid parameter" unless $params{sid};
    
    my $result = $self->_post("/api/v1/renameserver.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
}

# 
# syntax: $cloud->rDNS(login => $UserID, key => $APIkey, sid => $ServerID, hostname => $HostName )
sub rDNS { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    die "missing hostname parameter" unless $params{hostname};
    die "missing sid parameter" unless $params{sid};
    
    my $result = $self->_post("/api/v1/rdns.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
}

# syntax: $cloud->console(login => $UserID, key => $APIkey, sid => $ServerID)
sub console { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    die "missing sid parameter" unless $params{sid};
    
    my $result = $self->_post("/api/v1/console.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
}

# syntax: $cloud->runMode(login => $UserID, key => $APIkey, sid => $ServerID, mode => '[normal | safe]'  )
sub runMode { 
    my ($self,%params) = @_;
    die "missing login parameter" unless $params{login};
    die "missing key parameter" unless $params{key};
    die "missing name parameter" unless $params{name};
    die "missing sid parameter" unless $params{sid};
    die "missing mode parameter" unless $params{mode};
    die "invalid mode parameter" unless $params{mode} eq 'normal' or
                                          $params{mode} eq 'safe';
    
    my $result = $self->_post("/api/v1/runmode.php", %params);
    return $result->{data} ? @{$result->{data}} : ();	
} 

sub _get {
    my ($self, $path, %params) = @_;

    my $url = URI->new($self->{url} . $path);
    $url->query_form(%params);

    my $response = $self->{agent}->get($url);

    my $result = eval { from_json($response->content()) };

    if ($response->is_success()) {
        my $JSONcleaner=Data::Clean::FromJSON->new();
        my $cleanJSON = $JSONcleaner->clean_in_place($result);     	
        return $result;
    } else {
    	if (($response->code eq "400") || 
	    	($response->code eq "403") ||
	    	($response->code eq "412") ||
	    	($response->code eq "500") ||
	    	($response->code eq "503") ) {
    		# certain status codes means certain things.......
    		return $response->code;
    	} elsif ($result) { die  "server error: " . $result->{error};
        } else { die  "communication error: " . $response->message()
        }
    }
}

sub _post {
    my ($self, $path, %params) = @_;
    
    my $url = URI->new($self->{url} . $path);
    
    # this is a hack
    my @array; 
    for my $key ( keys %params) {  push(@array,"$key=$params{$key}"); }; 
    my $content = join('&',@array);  
 	
    my $response = $self->{agent}->post(
        $self->{url} . $path,
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Content'      => $content
    );
    
    my $result = eval { from_json($response->content()) };

    if ($response->is_success()) {
        my $JSONcleaner=Data::Clean::FromJSON->new();
        my $cleanJSON = $JSONcleaner->clean_in_place($result);    	
        return $result;
    } else {
    	if (($response->code eq "400") || 
	    	($response->code eq "403") ||
	    	($response->code eq "412") ||
	    	($response->code eq "500") ||
	    	($response->code eq "503") ) {
    		# certain status codes means certain things.......
    		return $response->code;
    	} elsif ($result) {
            croak "server error: " . $result->{error};
        } else {
            croak "communication error: " . $response->message()
        }
    }

}
1;
__END__

=head1 NAME

VM::CloudAtCost - Perl implimentation of API interface to CloudAtCost 

=head1 DESCRIPTION

This module provides a Perl interface to access CloudAtCosts API and manage 
basic functions available through it. 


=head1 SYNOPSIS


my $cloud = VM::CloudAtCost->new( url => 'https://panel.cloudatcost.com' ); 

my $SERVERS = $cloud->listServers(login => $userid, login => $userid);


=head1 CLASS METHODS

=head2 VM::CloudAtCost->new( url => 'https://panel.cloudatcost.com' );

Creates a new L<::CloudAtCost> instance.

=head1 INSTANCE METHODS

=head2 $cloud->listServers(login => $userid, login => $userid);

Returns an ARRAY of servers associated with the account. 

=head2 $cloud->listTemplates( login => $userid, key => $APIkey );

List all templates available

=head2 $cloud->listTasks( login => $userid, key => $APIkey );

List all tasks in operation

=head2 $cloud->renameServer(  login => $userid, key => $APIkey , sid => $server->{sid}, name => $NewName )

Rename the server label

=head2 $cloud->rDNS( login => $userid, key => $APIkey , sid => $server->{sid}, hostname => 'cloud.bosconet.org');

Modify the reverse DNS & hostname of the VPS

=head2 $cloud->powerOperation( login => $userid, key => $APIkey , sid => $server->{sid}, action => '[poweroff|poweron|reset]');

Performs specified power actions (on, off, reset) for the given server 

=head2 $cloud->console(login => $UserID, key => $APIkey, sid => $ServerID)

Request URL for console access

=head2 $cloud->runMode(login => $UserID, key => $APIkey, sid => $ServerID, mode => '[normal | safe]'  )

Set the run mode of the server to either 'normal' or 'safe'. Safe automatically turns off the server after 7 days of idle usage. Normal keeps it on indefinitely.


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 P Johnson [littleurl]

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
