package VUser::SOAP::Dispatcher;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: Dispatcher.pm,v 1.9 2007/07/03 21:10:57 perlstalker Exp $

use Data::Dumper;

use SOAP::Lite;
use VUser::SOAP;
use VUser::ExtLib qw(:config);
use VUser::Log qw(:levels);

our @ISA = qw(Exporter SOAP::Server::Parameters);

my $c_sec = 'vsoapd';

sub login {
    my $self = shift;
    my $user = shift;
    my $password = shift;
    my $envelope = shift; # SOAP::SOM object
    
    VUser::SOAP::Log(LOG_DEBUG, "In login");
    
    # Is there a way to get the IP from a SOAP::SOM object?
    my $ip = '127.0.0.1';
    
    # Check auth
    my $authinfo = VUser::SOAP::login($user, $password, $ip);
    
    VUser::SOAP::Log(LOG_DEBUG, "Mid login");
    
    if (not defined $authinfo) {
        # auth failed FAULT
        VUser::SOAP::Log(LOG_INFO, "Login failed for $user\@$ip");
        die $self->SOAP::Fault->faultcode('Server.Custom')->faultstring("Failed login");
    } else {
        VUser::SOAP::Log(LOG_INFO, "Login successful for $user\@$ip");
        my $soap_info = SOAP::Data->name('authinfo' => $authinfo);
        return $soap_info;
    }
}

sub get_keywords {
    my $self = shift;
    my $envelope = pop; # SOAP::SOM object
    my $authinfo = $envelope->valueof ("//authinfo");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    #return VUser::SOAP::get_keywords($authinfo);
    my @keywords = VUser::SOAP::get_keywords($authinfo);
    return SOAP::Data->name('keywords' => @keywords);
}

sub get_actions {
    my $self = shift;
    my $env = pop; # SOAP::SOM object
    my $authinfo = $env->valueof ("//authinfo");
    
    VUser::SOAP::Log(LOG_DEBUG, "get_actions()");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    my $keyword = $env->valueof('//keyword');
    
    my @actions = VUser::SOAP::get_actions ($authinfo, $keyword);
    #use Data::Dumper; print Dumper \@actions;
    VUser::SOAP::Log(LOG_DEBUG, 'Actions: '.Dumper(\@actions));
    return SOAP::Data->name('actions' => @actions);
}

sub get_options {
    my $self = shift;
    my $envelop = pop; # SOAP::SOM object
    my $authinfo = $envelop->valueof ("//authinfo");
    
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
       if (not VUser::SOAP::check_ticket($authinfo)) {
           # error: invalid or expired ticket: FAULT
           die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Authentication failed');
        }
    }
    
    #print STDERR "get_options() Passed options: ";
    #use Data::Dumper; print Dumper [@_];
    
    my $keyword = $envelop->valueof('//keyword');
    my $action = $envelop->valueof('//action');
    
    VUser::SOAP::Log (LOG_DEBUG, "Dispatch: get options for %s | %s", $keyword, $action);
    
    if (not defined $keyword or not defined $action) {
        die SOAP::Fault->faultcode('Server.Custom')->faultstring("Missing keyword or action");
    }
    
    my @options = VUser::SOAP::get_options ($authinfo, $keyword, $action);
    return SOAP::Data->name('options' => @options);
}

# SOAP Param order: keyword, action, @params

# This might be hairy from a WSDL perspective since the options change
# based on the keyword/action pair that's used. It might be better if, instead,
# a hash is used (as per the original vsoapd) in this case. Or it might be 
# be better if it's not here at all.
# For now, I'll leave it here as an undocumented feature.
sub run_tasks {
    my $self = shift;
    
    my $env = $_[-1]; # SOAP::SOM object

    my $keyword = shift;
    my $action = shift;
    my @params = @_;
    
    my $authinfo = $env->valueof ("//authinfo");
        
    # authenticate here
    if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
        if (not VUser::SOAP::check_ticket($authinfo)) {
            # error: invalid or expired ticket: FAULT
            die SOAP::Fault
             ->faultcode('Server.Custom')
             ->faultstring('Authentication failed');
        }
    }
       
    # We've successfully gotten passed the authentication.
    # Let's do some work.
    #print "Authinfo: "; use Data::Dumper; print Dumper $authinfo;
    VUser::SOAP::Log (LOG_DEBUG, "Authinfo $authinfo");
	return VUser::SOAP::rs2soap(VUser::SOAP::run_tasks($authinfo,
	                                                   $keyword->value,
	                                                   $action->value,
	                                                   @params));
}

#sub handle {
#    my $self = shift;
#    print STDERR "Getting a handle\n";
#    $self->SUPER::handle(@_);
#}

sub AUTOLOAD {
    use vars '$AUTOLOAD';
    my $self = shift;
    
    my $envelope = $_[-1]; # SOAP::SOM object
    
    my @params = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    #print "name: $name\n";
    if ($name =~ /^([^_]+)_([^_]+)$/) {
	   my $keyword = $1;
	   my $action = $2;
	   
	   my $authinfo = $envelope->valueof ("//authinfo");
    
       # authenticate here
       if (check_bool(VUser::SOAP::conf($c_sec, 'require authentication'))) {
           if (not VUser::SOAP::check_ticket($authinfo)) {
               # error: invalid or expired ticket: FAULT
               die SOAP::Fault
                ->faultcode('Server.Custom')
                ->faultstring('Authentication failed');
           }
       }
       
       # We've successfully gotten passed the authentication.
       # Let's do some work.
       my $results = VUser::SOAP::rs2soap(VUser::SOAP::run_tasks($authinfo,
	                                                      $keyword, $action, @params));
	   #print "results: "; use Data::Dumper; print Dumper $results;
	   return $results;
    } else {
        VUser::SOAP::Log(LOG_INFO, "Unknown method called: $name");
	   die SOAP::Fault->faultcode("Server.Custom")
	       ->faultstring("Unknown method");
    }
}

1;

__END__

=head1 NAME

VUser::SOAP::Dispatcher - Dispatch SOAP functions

=head1 DESCRIPTION

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
