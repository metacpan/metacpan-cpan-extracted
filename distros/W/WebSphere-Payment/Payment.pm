package WebSphere::Payment;

use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;
use strict;
use vars qw($VERSION $defaultpmurl $defaultcurrency $ua $h $defaultpmadmin $defaultgwhost
$defaultgwport $defaultsetprof $defaultsignbrand $defaultaccountnumber $defaultcassette 
$defaultmerole $defaultpmhost $defaultaccounttitle);
$VERSION = '1.21';


#Default Values
$defaultpmadmin  = 'YWRtaW46YWRtaW4=';  #('user:password' base64 encoded)
$defaultpmurl = 'http://localhost/webapp/PaymentManager/PaymentServlet';
$defaultpmhost = 'localhost';
$defaultmerole = 2; # Supervisor
$defaultgwhost = '200.3.3.142';
$defaultgwport = '10010'; 
$defaultsetprof = 8;
$defaultsignbrand = 'VISA';
$defaultaccountnumber = 1000;
$defaultcassette = 'SET';
$defaultcurrency = 862;
$defaultaccounttitle = 'Default Account';

#
# Public Methods
#
#-------------------------------------------------------
# Subroutine:  new
# Author: Luis Moreno
# Date: 20010612
# Modified: 
# Description:
#-------------------------------------------------------
sub new() {
    my ($type, $class, $timeout, $pmhost) = ();
    my $defaulttimeout = 120;
    my $self = {};
    ($ua, $h) = ();

    $type = shift;
    $class = ref($type) || $type;
    bless($self, $class);

    $self->{pmurl} = shift || $defaultpmurl;
    $self->{pmadmin} = shift || $defaultpmadmin;
    $self->{currency} = shift || $defaultcurrency;
    $self->{prirc} = -2;
    $self->{secrc} = -2;
    $timeout = shift || $defaulttimeout;
    $ua = LWP::UserAgent->new; 
    $ua->timeout($timeout);
    $h = new HTTP::Headers; 
    $h->header(Connection => 'Keep-Alive',
	       Accept => 'application/XML',
	       Accept_Language => 'en-US',
	       Authorization => 'Basic ' . $self->{pmadmin},
	       Content_Type => 'application/x-www-form-urlencoded',
	       Host => 'localhost',
	       User_Agent => 'Java PaymentServerClient',
	       Content_Encoding => '8859_1');
    return $self;
}




#-------------------------------------------------------
# Subroutine:  acceptPayment
# Author: Luis Moreno
# Date: 20010612
# Modified:
# Description: Send a transaction using the Payment Manager engine, with the data 
# specified in the hash referenced by paydataref
#-------------------------------------------------------
sub acceptPayment() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
		$paydataref->{operation} = 'ACCEPTPAYMENT';
		$paydataref->{paymenttype} = 'SET';
		$paydataref->{etapiversion} = 3;
		$paydataref->{currency} = $self->{currency} if (! $paydataref->{currency});
		$paydataref->{paymentamount} = $paydataref->{amount} if (! $paydataref->{paymentamount});
		$paydataref->{paymentnumber} = 1 if (! $paydataref->{paymentnumber});

		$postcontent = hash2content($paydataref);
		$h->content_length(length ($postcontent));
		$request = HTTP::Request->new(POST => $self->{pmurl},$h);
		$request->content($postcontent);
    
		$inittime = time;
		$response = $ua->request($request);
		$deltatime = time - $inittime;

		if ($response->is_success) {
		    $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
		    $self->{prirc} = $1;
		    $self->{secrc} = $2;
		    $self->{pmmessage} = $4;
		    $answer = 1;
		} else {
		    $self->{error}  = $response->message;
		}
		undef $request;
		undef $response;
    }   
    else {
	$self->{error} = "Invalid payment data reference"
    } 
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  batchClose
# Author: Luis Moreno
# Date: 20010926
# Modified:
# Description: Closes a batch given the merchantnumber within a hash reference and the 
# number of the batch to be closed 
#-------------------------------------------------------
sub batchClose() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;
    my $batchnumber = shift;

    if (ref($paydataref) eq "HASH" and ($batchnumber >= 1)) {
		$paydataref->{operation} = 'BatchClose';
		$paydataref->{force} = 1;
		$paydataref->{etapiversion} = 3;
		$paydataref->{batchnumber} = $batchnumber;

		$postcontent = hash2content($paydataref);
		$h->content_length(length ($postcontent));
		$request = HTTP::Request->new(POST => $self->{pmurl},$h);
		$request->content($postcontent);
    
		$inittime = time;
		$response = $ua->request($request);
		$deltatime = time - $inittime;

		if ($response->is_success) {
		    $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
		    $self->{prirc} = $1;
		    $self->{secrc} = $2;
		    $self->{pmmessage} = $4;
		    $answer = 1;
		} else {
		    $self->{error}  = $response->message;
		}
		undef $request;
		undef $response;
    }   
    else {
	$self->{error} = "Invalid payment data reference";
    } 
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  getOpenBatchNumber
# Author: Luis Moreno
# Date: 20010926
# Modified:
# Description: Given the merchantnumber within a hash reference returns the number of the 
# batch if exists 
#-------------------------------------------------------
sub getOpenBatchNumber() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
	$paydataref->{operation} = 'QueryBatches';
	$paydataref->{state} = 'batch_open';
	$paydataref->{accountnumber} = $defaultaccountnumber
	    if (! $paydataref->{accountnumber});
	$paydataref->{etapiversion} = 3;

	$postcontent = hash2content($paydataref);
	$h->content_length(length ($postcontent));
	$request = HTTP::Request->new(POST => $self->{pmurl},$h);
	$request->content($postcontent);

	$inittime = time;
	$response = $ua->request($request);
	$deltatime = time - $inittime;

	if ($response->is_success) {
	    $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="(\d*)"/;
	    $self->{prirc} = $1;
	    $self->{secrc} = $2;
	    if ($3 >= 1) {
		$answer = 1;
		$response->content =~ /batchNumber="(\d*)"/;
		$answer = $1;
	    }
	} else {
	    $self->{error}  = $response->message;
	}
	undef $request;
	undef $response;
    }
    else {
        $self->{error} = "Invalid payment data reference";
    }
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  createMerchant
# Author: Luis Moreno
# Date: 20010926
# Modified:
# Description: Create a new merchant in the payment manager system 
#-------------------------------------------------------
sub createMerchant() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
	$paydataref->{operation} = 'CreateMerchant';
	$paydataref->{etapiversion} = 3;
	$paydataref->{enabled} = 1;

	$postcontent = hash2content($paydataref);
	$h->content_length(length ($postcontent));
	$request = HTTP::Request->new(POST => $self->{pmurl},$h);
	$request->content($postcontent);
	$inittime = time;
	$response = $ua->request($request);
	$deltatime = time - $inittime;


	if ($response->is_success) {
	    $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
	    $self->{prirc} = $1;
	    $self->{secrc} = $2;
	    $self->{pmmessage} = $4;
	    $answer = 1;
	} else {
	    $self->{error}  = $response->message;
	}
	undef $request;
	undef $response;
    }   
    else {
	$self->{error} = "Invalid payment data reference";
    } 
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  createPaySystem
# Author: Luis Moreno
# Date: 20010926
# Modified:
# Description: Authorize a merchant to use a pay system (SET for example). 
#-------------------------------------------------------
sub createPaySystem() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
        $paydataref->{operation} = 'CreatePaySystem';
        $paydataref->{etapiversion} = 3;
        $paydataref->{enabled} = 1;

        $postcontent = hash2content($paydataref);
        $h->content_length(length ($postcontent));
        $request = HTTP::Request->new(POST => $self->{pmurl},$h);
        $request->content($postcontent);
        $inittime = time;
        $response = $ua->request($request);
        $deltatime = time - $inittime;


        if ($response->is_success) {
            $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
            $self->{prirc} = $1;
            $self->{secrc} = $2;
            $self->{pmmessage} = $4;
	    $answer = 1;
	}
	else {
	    $self->{error}  = $response->message;
	}
	undef $request;
	undef $response;
    }
    else {
	$self->{error} = "Invalid payment data reference";
    }
    return($answer);
}


#-------------------------------------------------------
# Subroutine:  createAccount
# Author: Luis Moreno
# Date: 20011001
# Modified:
# Description: Create a new Account for a merchant. An account represents the relationship 
# between a merchant and an acquirer
#-------------------------------------------------------
sub createAccount() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
	$paydataref->{operation} = 'CreateAccount';
	$paydataref->{accountnumber} = $defaultaccountnumber
	    if (! $paydataref->{accountnumber});
	$paydataref->{'%24acquirersetprofile'} = $defaultsetprof
	    if (! $paydataref->{'%24acquiresetprofile'});
	$paydataref->{'%24gatewayhostname'} = $defaultgwhost
	    if (! $paydataref->{'%24gatewayhostname'});
	$paydataref->{'%24gatewayport'} = $defaultgwport
	    if (! $paydataref->{'%24gatewayport'});
	$paydataref->{'%24signingbrandid'} = $defaultsignbrand
	    if (! $paydataref->{'%24signingbrandid'});
	$paydataref->{'accounttitle'} = $defaultaccounttitle
	    if (! $paydataref->{'accounttitle'});
	$paydataref->{'financialinstitution'} = $defaultaccounttitle
	    if (! $paydataref->{'financialinstitution'});
        $paydataref->{etapiversion} = 3;
        $paydataref->{enabled} = 1;

        $postcontent = hash2content($paydataref);
        $h->content_length(length ($postcontent));
        $request = HTTP::Request->new(POST => $self->{pmurl},$h);
        $request->content($postcontent);
        $inittime = time;
        $response = $ua->request($request);
        $deltatime = time - $inittime;


        if ($response->is_success) {
            $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
            $self->{prirc} = $1;
            $self->{secrc} = $2;
            $self->{pmmessage} = $4;
	    $answer = 1;
        }
        else {
            $self->{error}  = $response->message;
        }
        undef $request;
        undef $response;
    }
    else {
        $self->{error} = "Invalid payment data reference";
    }
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  SetUserAccessRights
# Author: Luis Moreno
# Date: 20011002
# Modified:
# Description: Set permissions to a user of the Realm. The user must have the same name 
# of the merchant 
#-------------------------------------------------------
sub setUserAccessRights() {
    my ($answer, $postcontent, $request, $inittime, $response, $deltatime) = ();
    my $self = shift;
    my $paydataref = shift;

    if (ref($paydataref) eq "HASH") {
        $paydataref->{operation} = 'SetUserAccessRights';
        $paydataref->{etapiversion} = 3;
        $paydataref->{user} = $paydataref->{merchanttitle};
	$paydataref->{role} = $defaultmerole
	    if (! $paydataref->{role});

        $postcontent = hash2content($paydataref);
        $h->content_length(length ($postcontent));
        $request = HTTP::Request->new(POST => $self->{pmurl},$h);
        $request->content($postcontent);
	$inittime = time;
	$response = $ua->request($request);
	$deltatime = time - $inittime;


	if ($response->is_success) {
            $response->content =~ /<PSApiResult\sprimaryRC="(\d*)"\ssecondaryRC="(\d*)"\sobjectCount="\d*"\s*(\w*Message="(.*)\.")??\/>$/;
            $self->{prirc} = $1;
            $self->{secrc} = $2;
            $self->{pmmessage} = $4;
            $answer = 1;

        }
	else {
	    $self->{error}  = $response->message;
	}
	undef $request;
	undef $response;
    }
    else {
	$self->{error} = "Invalid payment data reference";
    }
    return($answer);
}

#-------------------------------------------------------
# Subroutine:  close
# Author: Luis Moreno
# Date: 20010612
# Modified:
# Description:
#-------------------------------------------------------
sub close() {
    undef $ua;
    undef $h;
}

# Non public subs

#-------------------------------------------------------
# Subroutine:  hash2content
# Author: Luis Moreno
# Date: 20010612
# Modified:
# Description:
#-------------------------------------------------------
sub hash2content($hashref) {
    my ($hashref) = @_;
    my ($postcontent, $key) = ();

    foreach $key (keys %{$hashref}) {
	$postcontent .= uc($key) . '=' . $hashref->{$key} . '&';
    }
    chop($postcontent);
    return($postcontent);
}

1;

__END__

=head1 NAME

CashRegister - Simple Perl interface to IBM WebSphere
Payment Manager 2.2 API

=head1 SYNOPSIS

use WebSphere::Payment;
$cashregister = new WebSphere::Payment($pmurl,$currency,$admin, $timeout); 
# Creating a merchant
$paystubref = {merchantnumber => $merchantnumber,
               merchanttitle => $merchantname,
               cassettename => 'SET',
           };
my ($errortext) = ();

if ($cashregister->createMerchant($paystubref) and
    !($cashregister->{prirc} or $cashregister->{secrc})) {
    if ($cashregister->createPaySystem($paystubref) and
        !($cashregister->{prirc} or $cashregister->{secrc})) {
        if ($cashregister->createAccount($paystubref) and
            !($cashregister->{prirc} or $cashregister->{secrc})) {
            if (! $cashregister->setUserAccessRights($paystubref) or
                ($cashregister->{prirc} or $cashregister->{secrc})) {
                $errortext =  "SetUserAccessRights error";
            }
        }
        else {
            $errortext =  "Create Account error";
        }
    }
    else {
        $errortext = "Create PaySystem error";
    }
}
else {
    $errortext = "Create Merchant error";
}
if ($errortext) {
    print "Fail...$errortext\n";
}
else {
    print "Results...OK\n";
}
print "prirc: " . $cashregister->{prirc} .  "\n";
print "secrc: " . $cashregister->{secrc} . "\n";
print "pmmessage: " . $cashregister->{pmmessage} . "\n";

$paystubref = {merchantnumber => $merchantnumber, 
	       ordernumber => $ordernumber, 
	       approveflag => 0, 
	       depositflag => 0, 
	       amount => $amount, 
	       '%24expiry' => $yyyydd, 
	       '%24pan' => $cardnumber, 
	       '%24brand' => $cardtype, 
	       '%24orderdescription' => $description,
	       '%24cardverifycodes' => $cvv2};

# Sending a transaction
if ($cashregister->acceptPayment($paystubref)) { 
    print "Results\n"; 
    print "prirc: " . $cashregister->{prirc} . "\n";
    print "secrc: " . $cashregister->{secrc} . "\n";
}
print "pmmessage: " . $cashregister->{pmmessage} . "\n"; 
# Closing a Batch
if ($batch = $cashregister->getOpenBatchNumber($paystubref)) {
    print "\n\nClosing the Batch number: $batch\n";
    $cashregister->batchClose($paystubref, $batch);
    print "prirc: " . $cashregister->{prirc} .  "\n";
    print "secrc: " . $cashregister->{secrc} . "\n";
    print "pmmessage: " . $cashregister->{pmmessage} . "\n";
}
else {
    print "No batch opens. " . $cashregister->{error};
}
$cashregister->close();

=head1 REQUIRES

Perl5.005

=head1 EXPORTS
Nothing

=head1 DESCRIPTION

WebSphere::Payment provides a simple Interface to the
API of the payment engine IBM WebSphere Payment
Manager 2.2. It achieves this task, through commands
send via http POST method.

=head1 METHODS


=head2 Creation

=over 4

=item new WebSphere::Payment($pmurl,$admin,$currency,$timeout)

Create a new WebSphere::Payment object. If no parameters
are specified, the object will be initialized with
the default values. The pmurl is the url where the
Payment Manager servlet (PaymentServlet) is listening.
The currency parameter, represent the type of currency
the transactions will use. The admin parameter
consists of a userid and password string, separated
by a single colon (":") character, encoded with a
base64 encoding. This userid must have administrator
permissions on the Payment Manager.


=back

=head2 API Methods

=over 4

=item acceptPayment($paydataref)

Send a transaction using the Payment Manager engine,
with the data specified in the hash referenced by
paydataref.

=item batchClose($paydataref, batchnumber)

Closes a batch given the merchantnumber within a hash reference and
the number of the batch to be closed

=item getOpenBatchNumber($paydataref)

Given the merchantnumber within a hash reference returns the number of the batch if exists

=item createMerchant($paydataref)

Create a new merchant in the payment manager system

=item createPaySystem($paydataref)

Authorize a merchant to use a pay system (SET for example).

=item createAccount($paydataref)

Create a new Account for a merchant. An account represents the relationship between 
a merchant and an acquirer

=item SetUserAccessRights($paydataref)

Set permissions to a user of the Realm. The user must have the same name of the merchant 

=back

=head1 HISTORY

This module was originally created in Jun 2001 by Luis Moreno
1.20 Methods: batchClose, getOpenBatchNumber, createMerchant, createPaySystem, createAccount, setUserAccessRights (Oct 2001)
1.21 Minor documentation changes


=head1 AUTHOR

Luis Moreno, luis@cantv.net

=head1 COPYRIGHT

The IBM WebSphere Payment Manager is trademark of the
IBM Corporation in the United States or both.

    This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), IBM WebSphere Payment Manager Programmer's Guide and Reference

=cut


