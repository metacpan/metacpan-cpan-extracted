package Tivoli::AccessManager::Admin::Context;
use strict;
use warnings;
use Carp;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Context.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::Context::VERSION = '1.11';
use Inline( C => 'DATA',
                INC  => '-I/opt/PolicyDirector/include',
		LIBS => '-lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME   => 'Tivoli::AccessManager::Admin::Context');
use Tivoli::AccessManager::Admin::Response;

my %tod = ( 1 => 'sun',
	    2 => 'mon',
	    4 => 'tue',
	    8 => 'wed',
	   16 => 'thu',
	   32 => 'fri',
	   64 => 'sat',
     );

my %revtod = map { $tod{$_} => $_ } keys %tod;

sub _todtolist {
    my $vector = shift;
    my @list;

    return qw/any/ unless $vector;

    for my $mask ( sort { $a <=> $b } keys %tod ) {
	push @list, $tod{$mask} if ( ($vector & $mask) == $mask );
    }
    return @list;
}

sub _listtotod {
    my $list = shift;
    my $vector = 0;

    for my $day ( @{$list} ) {
	$day = lc($day);
	if ( $day eq 'any' ) {
	    $vector = 0;
	    last;
	}
	$vector += $revtod{$day};
    }
    return $vector;
}

sub new {
    my $class = shift;
    my $self = {};
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( @_ % 2 ) {
	warn "Invalid syntax -- you did not send a hash\n";
	return undef;
    }
    my %opts = @_;
    my @options = qw/codeset server port keyringfile keystashfile configfile/;
    my $hardway = 0;

    $opts{userid} = $opts{userid} || "sec_master";
    $opts{domain} = $opts{domain} || "";

    unless ( defined($opts{local}) ) {
	unless ( defined($opts{password}) and $opts{password} ) {
	    warn "You must include the password\n";
	    return undef;
	}
    }

    for ( @options ) {
	$hardway++  if defined $opts{$_};
    }

    if ( defined($opts{local}) ) {
	$self = context_createlocal($class, $opts{codeset} || '', $resp);
    }
    elsif ( $hardway ) {
	unless ( $hardway == @options ) {
	    warn "If any one of " . join(", ", @options ) . " is defined, they must all be defined\n";
	    return undef;
	}
	$self = context_create3( $class,
				 @opts{qw/userid password domain/}, 
				 @opts{@options}, 
				 $resp 
			       );
					    
    }
    else {
	$self = context_createdefault2( $class,
				        $opts{userid}, 
					$opts{password}, 
					$opts{domain}, $resp );
    }

    unless ( $resp->isok ) {
	warn $resp->messages(), "\n";
	return undef;
    }

    return $self;

}

sub accexpdate {
    my $self = shift;
    my $lifetime = 0;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my ($seconds,$unlimited,$unset,$rc);
    if ( @_ == 1 ) {
	$lifetime = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$lifetime = $opts{lifetime} || '';
    }
    else {
	$lifetime = '';
    }


    if ( $lifetime ) {
	if ( $lifetime =~ /^\d+$/ ) {
	    $unlimited = 0;
	    $unset   = 0;
	}
	elsif ( $lifetime eq 'unlimited' ) {
	    ($unlimited,$unset,$lifetime) = (1,0,0);
	}
	elsif ( $lifetime eq 'unset' ) {
	    ($unlimited,$unset,$lifetime) = (0,1,0);
	}
	else {
	    $resp->set_message("The parameter must either be an integer, 'unset' or 'unlimited'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->context_setaccexpdate( $resp,
					    $lifetime,
					    $unlimited,
					    $unset );
    } 
    if ( $resp->isok ) {
	($seconds,$unlimited,$unset) = $self->context_getaccexpdate( $resp );
	$resp->set_value( $unlimited ? "unlimited" : $unset ? "unset" : $seconds);
    }

    return $resp; 
}

sub disabletimeint {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($seconds,$disable,$unset,$rc);

    if ( @_ == 1 ) {
	$seconds = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$seconds = $opts{seconds} || '';
    }
    else {
	$seconds = '';
    }

    if ( $seconds ) {
	if ( $seconds =~ /^\d+$/ ) {
	    $disable = 0;
	    $unset   = 0;
	}
	elsif ($seconds eq 'disable') {
	    ($disable,$unset,$seconds) = (1,0,0);
	}
	elsif ($seconds eq 'unset') {
	    ($disable,$unset,$seconds) = (0,1,0);
	}
	else {
	    $resp->set_message("The parameter must either be an integer, 'disable' or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}

	$rc = $self->context_setdisabletimeint( $resp,
					        $seconds,
					        $disable,
					        $unset);
    } 
    if ( $resp->isok ) {
	($seconds,$disable,$unset) = $self->context_getdisabletimeint( $resp );
	$resp->set_value( $disable ? "disabled" : $unset ? "unset" : $seconds );
    }

    return $resp; 
}

sub maxlgnfails {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($failures,$unset,$rc);


    if ( @_ == 1 ) {
	$failures = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$failures = $opts{failures} || '';
    }
    else {
	$failures = '';
    }

    if ( $failures ) {
	if ( $failures =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($failures eq 'unset') {
	    $failures = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}

	$rc = $self->context_setmaxlgnfails( $resp,
					     $failures, 
					     $unset
					   );
    }
    if ( $resp->isok ) {
	($failures,$unset) = $self->context_getmaxlgnfails( $resp );
	$resp->set_value($unset ? "unset" : $failures);
    }

    return $resp;
}

sub maxpwdage {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($seconds,$unset,$rc);

    if ( @_ == 1 ) {
	$seconds = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$seconds = $opts{seconds} || '';
    }
    else {
	$seconds = '';
    }

    if ( $seconds ) {
	if ( $seconds =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($seconds eq 'unset') {
	    $seconds = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	
	$rc = $self->context_setmaxpwdage( $resp,
					 $seconds,
					 $unset );
	$resp->set_value( $rc );
    } 
    if ( $resp->isok ) {	
	($seconds,$unset) = $self->context_getmaxpwdage( $resp );
	$resp->set_value($unset ? "unset" : $seconds);
    }

    return $resp;
}

sub maxpwdrepchars {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($chars,$unset,$rc);

    if ( @_ == 1 ) {
	$chars = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$chars = $opts{chars} || '';
    }
    else {
	$chars = '';
    }

    if ( $chars ) {
	if ( $chars =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($chars eq 'unset') {
	    $chars = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->context_setmaxpwdrepchars( $resp,
						$chars,
						$unset );
    }
    if ( $resp->isok ) {	
	($chars,$unset) = $self->context_getmaxpwdrepchars( $resp );
	$resp->set_value($unset ? "unset" : $chars);
    }

    return $resp;
}

sub minpwdalphas {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($chars,$unset,$rc);

    if ( @_ == 1 ) {
	$chars = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$chars = $opts{chars} || '';
    }
    else {
	$chars = '';
    }

    if ( $chars ) {
	if ( $chars =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($chars eq 'unset') {
	    $chars = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->context_setminpwdalphas( $resp,
					      $chars,
					      $unset );
	$resp->set_value($rc);
    } 
    if ( $resp->isok ) {	
	($chars,$unset) = $self->context_getminpwdalphas( $resp );
	$resp->set_value( $unset ? "unset" : $chars );
    }

    return $resp;
}

sub minpwdnonalphas {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($chars,$unset,$rc);

    if ( @_ == 1 ) {
	$chars = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$chars = $opts{chars} || '';
    }
    else {
	$chars = '';
    }

    if ( $chars ) {
	if ( $chars =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($chars eq 'unset') {
	    $chars = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->context_setminpwdnonalphas( $resp,
						 $chars,
						 $unset );
	$resp->set_value($rc);
	
    }
    if ( $resp->isok ) {
	($chars,$unset) = $self->context_getminpwdnonalphas( $resp );
	$resp->set_value($unset ? "unset" : $chars);
    }

    return $resp;
}

sub minpwdlen {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($chars,$unset,$rc);

    if ( @_ == 1 ) {
	$chars = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$chars = $opts{chars} || '';
    }
    else {
	$chars = '';
    }

    if ( $chars ) {
	if ( $chars =~ /^\d+$/ ) {
	    $unset   = 0;
	}
	elsif ($chars eq 'unset') {
	    $chars   = 8;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->context_setminpwdlen( $resp,
					   $chars,
					   $unset );
	$resp->set_value( $rc );
    }
    if ( $resp->isok ) {
	($chars,$unset) = $self->context_getminpwdlen( $resp );
	$resp->set_value($unset ? "unset" : $chars);
    }

    return $resp;
}

sub max_concur_session {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($session,$unset,$unlimited,$displace,$rc);

    if ( @_ == 1 ) {
	$session = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$session = $opts{session} || '';
    }
    else {
	$session = '';
    }

    if ( $session ) {
	if ( $session =~ /^\d+$/ ) {
	    ($unset,$unlimited,$displace) = (0,0,0);
	}
	elsif ($session eq 'displace') {
	    ($session,$unset,$unlimited,$displace) = (0,0,0,1);
	}
	elsif ($session eq 'unlimited') {
	    ($session,$unset,$unlimited,$displace) = (0,0,1,0);
	}
	elsif ($session eq 'unset') {
	    ($session,$unset,$unlimited,$displace) = (0,1,0,0);
	}
	else {
	    $resp->set_message("The parameter must be either an integers, 'displace', 'unlimited' or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}

	$rc = $self->context_setmaxconcurwebsess( $resp,
						  $session,
						  $displace,
						  $unlimited,
						  $unset,
						 );
	$resp->set_value($rc);
	
    }
    if ( $resp->isok ) {
	my $retval;
	($session,$displace,$unlimited,$unset) = $self->context_getmaxconcurwebsess( $resp );

	if ($unset) {
	    $retval = 'unset';
	}
	elsif ($displace) {
	    $retval = 'displace';
	}
	elsif ($unlimited) {
	    $retval = 'unlimited';
	}
	else {
	    $retval = $session;
	}
	$resp->set_value($retval);
    }

    return $resp;
}

sub pwdspaces {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($allowed,$unset,$rc);

    if ( @_ == 1 ) {
	$allowed = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$allowed = $opts{allowed} || '';
    }
    else {
	$allowed = '';
    }

    if ( $allowed ) {
	if ( $allowed =~ /^\d+$/ ) {
	    $unset = 0;
	}
	elsif ( $allowed eq 'unset' ) {
	    $allowed = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}

	$rc = $self->context_setpwdspaces( $resp,
					   $allowed,
			      	           $unset );
	$resp->set_value($rc);
    } 
    if ( $resp->isok ) {
	($allowed,$unset) = $self->context_getpwdspaces( $resp );
	$resp->set_value($unset ? "unset" : $allowed );
    }

    return $resp;
}

sub _miltomin {
    my $miltime = shift || 0;
    return ( $miltime - $miltime % 100 ) * .6 + $miltime % 100;
}

sub _mintomil {
    my $mins = shift;

    return ($mins - $mins % 60)/.6 + $mins % 60;
}

sub tod {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ( $days, $start, $end, $reference, $unset, $rc );
    my (@list, %rc );
  
    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    $reference = $opts{reference} || '';

    if ( $opts{days} ) {
	$reference = $reference eq 'UTC';

	if ( $opts{days} ne 'unset' ) {
	    if ( ref($opts{days})  ) {
		$days = _listtotod( $opts{days} )
	    }
	    else {
		if ( $opts{days} > 127 ) {
		    $resp->set_message( "error -- days bitmask  > 127");
		    $resp->set_isok(0);
		    return $resp;
		}
		$days = $opts{days};
	    }
	    $start = _miltomin( $opts{start} );
	    $end   = _miltomin( $opts{end} );
	    $unset = 0;
	}
	else {
	    $days = $start = $end  = 0;
	    $unset = 1;
	}

	$self->context_settodaccess( $resp,
				     $days,
				     $start,
				     $end,
				     $reference,
				     $unset );
    }
    if ( $resp->isok ) {
	@list = $self->context_gettodaccess( $resp );
	if ( $list[-1] ) {
	    $rc{days}  = 0;
	    $rc{start} = 0;
	    $rc{end}   = 0;
	    $rc{reference} = 'local';
	    $rc{unset} = 1;
	}
	else {
	    $rc{days}      = [ _todtolist( $list[0] ) ];
	    $rc{start}     = _mintomil( $list[1] );
	    $rc{end}       = _mintomil( $list[2] );
	    $rc{reference} = $list[3] ? 'UTC' : 'local';
	}

	$resp->set_value( \%rc );
    }

    return $resp;
}

sub userreg {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    $resp->set_value( $self->context_getuserreg( $resp ) ? "LDAP" : "DCE");

    return $resp;
}

sub codeset { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    $resp->set_value( $self->context_getcodeset() ? "LOCAL" : "UTF8" );

    return $resp;
}
    
1;

=head1 NAME

Tivoli::AccessManager::Admin::Context

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin::Context;

  $pdadmin = Tivoli::AccessManager::Admin::Context->new( password => 'foobar' );

  $resp->iserror() and die "Couldn't establish context\n";

=head1 Description

B<Tivoli::AccessManager::Admin::Context> handles the context related functions in the TAM API.
For the most part, it is used solely for establishing the context.  There are,
however, some global parameters that are set using this module.

As with all the other modules in this collection, you must have the
Authentication ADK installed to use this modules.

=head1 CONSTRUCTOR

=head2 new ( OPTIONS )

Logs into the policy server's domain,  In TAM speak, it creates a new context.
There are two different ways to call this function.  At the bare minimum, you
can simply provide a password.  This will then rely upon the configuration of
the PDRTE to figure out the rest of the information.  This is the same base
effect as saying "pdadmin -a sec_master -p <password>".  You can also specify
the userid and the domain with this method.

Alternately, you can specify all of the parameters below and log into any
domain with out changing the configuration of your RTE.  If anyone of the
parameters other than password, userid or domain are set, all must be set.

=head3 Parameters

=over 4

=item password =E<gt> PASSWORD

The password to be used when binding to the policy server.  This is the only
mandatory parameter.

=item userid =E<gt> USERID

The ID to use when binding to the policy server.
(Default:sec_master)

=item domain =E<gt> DOMAIN

The domain into which to bind.  
(Default: uhh.. Default )

=item codeset =E<gt> [UTF|LOCAL]

The codeset to be used to encode the character data.  It can be either UTF or
LOCAL.  

=item server =E<gt> SERVER

The name of the policy server.  This can be either a hostname or an IP
address.

=item port =E<gt> PORT

The port on which the policy server listens.

=item keyringfile =E<gt> PATH

The fully qualified path name ( FQPN ) to the keydatabase for the policy
domain.

=item keystashfile =E<gt> PATH

The FQPN to the stashed password for the keyring

=item configfile =E<gt> PATH

The FQPN to the pd.conf file

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::Context> object, or it will die on error.
If you cannot establish a context, nothing else will work.

=head1 METHODS

Most of the methods available on a B<Tivoli::AccessManager::Admin::Context> object follow the
same rules.  The L<Tivoli::AccessManager::Admin::Response> object will always contain the
results of a 'get'.  If any of the optional parameters are sent, a 'set' will
be performed.

=head2 accexpdate( SECONDS | 'unset' | 'unlimited' )

Returns the currently configured global account expiration date.

=head3 Parameters

=over 4

=item SECONDS | 'unset' | 'unlimited' 

The date when all passwords will expire.  The date is expressed as seconds
since the beginning of the Epoch.

=back

=head3 Returns

"unlimited", "unset" or the date in seconds since the Epoch when the passwords
will expire.

=head2 disabletimeint (SECONDS | 'disable' | 'unset' )

Returns the currently configured global account disable timeout.

=head3 Parameters

=over 4

=item SECONDS | 'disable' | 'unset'

The number of seconds an account will be disabled due to failed logins

=back

=head3 Returns

"disabled", "unset" or the time in seconds an account will be disabled

=head2 maxlgnfails ( N | 'unset' )

Returns the currently configured global maximum number of failed login
attempts.  

=head3 Parameters

=over 4

=item N | 'unset'

The number of failed login attempts before the account is disabled.

=back

=head3 Returns

"unset" or the number of allowed failed login attempts allowed.

=head2 maxpwdage ( SECONDS | 'unset')

Returns the currently configured global maximum password age.

=head3 Parameters

=over 4

=item SECONDS | 'unset'

The maximum age of a password expressed in seconds.

=back

=head3 Returns

"unset" or the maximum age of passwords in seconds.

=head2 maxpwdrepchars ( CHARS | 'unset' )

Returns the maximum repeated characters allowed in a password

=head3 Parameters

=over 4

=item CHARS | 'unset'

The maximum number of repeated characters in a password

=back

=head3 Returns

"unset" or the maximum repeated characters allowed in a password.

=head2 minpwdalphas ( CHARS | 'unset' )

Returns the minimum alphabetic characters in a password

=head3 Parameters

=over 4

=item CHARS | 'unset'

The minimum number of alphabetic characters in a password

=back

=head3 Returns

"unset" or the minimum alphabetic characters allowed in a password.

=head2 minpwdnonalphas ( CHARS | 'unset' )

Returns the minimum non-alphabetic characters in a password

=head3 Parameters

=over 4

=item CHARS | 'unset'

The minimum number of non-alphabetic characters in a password

=back

=head3 Returns

"unset" or the minimum non-alphabetic characters allowed in a password.

=head2 minpwdlen ( CHARS | 'unset' )

Returns the minimum password length

=head3 Parameters

=over 4

=item CHARS | 'unset'

The minimum number length of a password

=back

=head3 Returns

"unset" or the minimum length of a password.

=head2 pwdspaces ( 0 | 1 | 'unset' )

Returns the current policy on spaces in passwords

=head3 Parameters

=over 4

=item 0 | 1 | 'unset'

Whether or not to allows spaces in passwords.

=back

=head3 Returns

"unset" or 'allowed'.

=head2 max_concur_session(['displace'|'unlimited'|'unset'|NUM])

Returns or sets the current maximum concurrent web sessions allowed.

=head3 Parameters

=over 4

=item 'displace'|'unlimited'|'unset'|NUM

'unlimited' or 'unset' will disable the policy; NUM will set the maximum
allowed sessions; and 'displace' will cause the new session to replace the
old.

=back

=head3 Returns

The current setting.

=head2 tod( days =E<gt> 'unset' ) 

=head2 tod ( days =E<gt> [array], start =E<gt> N, end =E<gt> N, reference =E<gt> local | UTC )

Returns the current time of day access policy

=head3 Parameters

=over 4

=item days 

'unset' will cause the the time of day access policy to be unset.  Otherwise,
B<days> should be a reference to an array containing some combination of:
  mon, tue, wed, thu, fri, sat, sun or any.

If the word 'any' is found anywhere in the array, it will over ride all the
others.

=item start

The beginning of the allowed access time, expressed in 24-hour format.  Since
perl will try to interpret any number starting with a 0 as an octal number (
leading to annoying problems with 09xx ), you need to either drop the
preceding 0 ( eg, 900 ) or specify it as a string ( '0900' ).

=item end

The end of the allowed access time.  See the previous item for the caveats.

=item UTC|local

Under the covers, start and end are calculated as minutes past midnight.  TAM
needs to know if you are referencing midnight UTC or midnight local time.  The
default is 'local'.

=back

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object, the value of which is a hash with the
key/value pairs:

=over 4

=item days

An array reference to the days for which the policy is enforced.  If the TOD
policy is unset, this refers to an empty array.

=item start

The time of day when access is allowed, expressed in 24-hour format. If the TOD
policy is unset, this will be zero.


=item end

The time of day when access is denied, expressed in 24-hour format. If the TOD
policy is unset, this will be zero.

=item reference

UTC or local.  If the policy is unset, this will be local.

=back 



The following methods are all read-only.  I will not bother to say that again,
nor will you see any of the usual 'Parameter' or 'Returns' headings - the
description tells you the return value.

=head2 userreg

Returns the user registry that TAM is configured against.

=head2 isauthenticated

Returns true if the current context is authenticated

=head2 codeset

Returns the codeset currently associated with the context - "UTF8" or "LOCAL"

=head2 domainid

Returns the name of the domain associated with the context

=head2 mgmtdomain

Returns the management domain associated with the context.

=head2 mgmtsvrhost

Returns the hostname of the Policy Server 

=head2 mgmtsvrport

Returns the port of the Policy Server

=head2 userid

Returns the user id user to create the context.

=head1 SEE ALSO

L<Tivoli::AccessManager::Admin::Response>,

=head1 ACKNOWLEDGEMENTS

Please read L<Tivoli::AccessManager::Admin> for the full list of acks.  I stand upon the
shoulders of giants.

=head1 BUGS

None at the moment.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted by IBM.

=cut

__DATA__

__C__

#include "ivadminapi.h"

ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL ) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return( rsp );
}

SV* context_createdefault2( char* class, char* userid, char* password, 
		            char* domain, SV* resp) {
    ivadmin_context* ctx;
    ivadmin_response* rsp = _getresponse( resp );
    unsigned long status;
    
    New( 5, ctx, 1, ivadmin_context );

    SV*		obj_ref = newSViv((IV)&PL_sv_undef);
    SV*	        obj     = newSVrv( obj_ref, class );

    if ( strlen(domain) == 0 ) 
    	domain = NULL;

    status = ivadmin_context_createdefault2( userid, password, domain,
    				     ctx, rsp );

    if ( status == IVADMIN_TRUE ) { 
	sv_setiv(obj, (IV)ctx);
	SvREADONLY_on(obj);
    }
    return( obj_ref );
}

SV* context_create3( char *class, char* userid, char* pwd, char* domain,
		     char* codeset, char* server, unsigned long port,
		     const char* keyringfile, const char* keystashfile,
		     const char* configfile, SV* resp ) {
    unsigned long status = 0;
    ivadmin_context* ctx;

    New( 5, ctx, 1, ivadmin_context );
    ivadmin_response* rsp = _getresponse( resp );

    SV*		obj_ref = newSViv(0);
    SV*	        obj     = newSVrv( obj_ref, class );

    status = ivadmin_context_create3( userid, pwd, domain, codeset, server,
    				      port, keyringfile, keystashfile,
				      configfile, ctx, rsp );
    if ( status == IVADMIN_TRUE ) {
	sv_setiv(obj, (IV)ctx);
	SvREADONLY_on(obj);
    }
    return( obj_ref );
}

SV* context_createlocal( char* class,  char* codeset, SV* resp) {
    ivadmin_context* ctx;
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long status;
    
    New( 5, ctx, 1, ivadmin_context );

    SV*		obj_ref = newSViv((IV)&PL_sv_undef);
    SV*	        obj     = newSVrv( obj_ref, class );

    if ( codeset == NULL || strlen(codeset) == 0 ) 
    	codeset = IVADMIN_CODESET_LOCAL;

    status = ivadmin_context_createlocal( NULL, NULL, NULL, codeset, ctx, rsp );

    if ( status == IVADMIN_TRUE ) { 
	sv_setiv(obj, (IV)ctx);
	SvREADONLY_on(obj);
    }
    else {
	croak("No context\n");
    }
    return( obj_ref );
}

int isauthenticated( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));

    if ( ctx == NULL )
	croak("isauthenticated: could not retrieve context object");

    return( ivadmin_context_domainismanagement( *ctx ) );
}

int context_getcodeset( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));

    if ( ctx == NULL )
	croak("context_getcodeset: could not retrieve context object");

    return ( ivadmin_context_getcodeset( *ctx ) == IVADMIN_CODESET_UTF8 );
}

SV* domainid( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    char *id;

    if ( ctx == NULL )
	croak("domainid: could not retrieve context object");

    id = (char*)ivadmin_context_getdomainid(*ctx);
    return(id ? newSVpv(id,0) : NULL);
}

SV* mgmtdomainid( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    char *id;

    if ( ctx == NULL )
	croak("mgmtdomainid: could not retrieve context object");

    id = (char*)ivadmin_context_getmgmtdomainid( *ctx );
    return(id ? newSVpv(id,0) : NULL); 
}

SV* mgmtsvrhost( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    char *host;

    if ( ctx == NULL )
	croak("mgmtsvrhost: could not retrieve context object");

    host = (char*)ivadmin_context_getmgmtsvrhost( *ctx );
    return( host ? newSVpv(host,0) : NULL);
}

int mgmtsvrport( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));

    if ( ctx == NULL )
	croak("mgmtsvrport: could not retrieve context object");

    return(ivadmin_context_getmgmtsvrport( *ctx ));
}

SV* userid( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    char* user;

    if ( ctx == NULL )
	croak("userid: could not retrieve context object");

    user = (char*)ivadmin_context_getuserid(*ctx); 
    return( user ? newSVpv(user,0) : NULL);
}

void context_getaccexpdate( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long seconds   = 0;
    unsigned long unlimited = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getaccexpdate( *ctx,
    					&seconds,
					&unlimited,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(seconds)));
	Inline_Stack_Push(sv_2mortal(newSViv(unlimited == IVADMIN_TRUE)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getdisabletimeint( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long seconds   = 0;
    unsigned long unlimited = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getdisabletimeint( *ctx,
    					&seconds,
					&unlimited,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(seconds)));
	Inline_Stack_Push(sv_2mortal(newSViv(unlimited == IVADMIN_TRUE)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}


void context_getmaxlgnfails( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long failures  = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getmaxlgnfails( *ctx,
    					&failures,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(failures)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getmaxpwdage( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long seconds   = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getmaxpwdage( *ctx,
    					&seconds,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(seconds)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getmaxpwdrepchars( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long chars   = 0;
    unsigned long unset   = 0;
    unsigned long rc      = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getmaxpwdrepchars( *ctx,
    					&chars,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(chars)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getminpwdalphas( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long chars   = 0;
    unsigned long unset   = 0;
    unsigned long rc      = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getminpwdalphas( *ctx,
    					&chars,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(chars)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getminpwdnonalphas( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long chars   = 0;
    unsigned long unset   = 0;
    unsigned long rc      = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getminpwdnonalphas( *ctx,
    					&chars,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(chars)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getminpwdlen( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long length  = 0;
    unsigned long unset   = 0;
    unsigned long rc      = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getminpwdlen( *ctx,
    					&length,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(length)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_getpwdspaces( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long allowed = 0;
    unsigned long unset   = 0;
    unsigned long rc      = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getpwdspaces( *ctx,
    					&allowed,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(allowed == IVADMIN_TRUE)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

void context_gettodaccess( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long days      = 0;
    unsigned long start     = 0;
    unsigned long end       = 0;
    unsigned long reference = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_gettodaccess( *ctx,
    					&days,
					&start,
					&end,
					&reference,
					&unset,
					rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(days)));
	Inline_Stack_Push(sv_2mortal(newSViv(start)));
	Inline_Stack_Push(sv_2mortal(newSViv(end)));
	Inline_Stack_Push(sv_2mortal(newSViv(reference)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

int context_getuserreg( SV* cont, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long registry = 0;
    unsigned long rc      = 0;

    rc = ivadmin_context_getuserreg( *ctx,
    				     &registry,
				     rsp );
    return (( rc == IVADMIN_TRUE ) && 
    	    ( registry == IVADMIN_CONTEXT_LDAPUSERREG ));
} 

void context_getmaxconcurwebsess(SV *cont, SV* resp) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long session   = 0;
    unsigned long displace  = 0;
    unsigned long unlimited = 0;
    unsigned long unset     = 0;

    unsigned long rc = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_context_getmaxconcurwebsess( *ctx,
				      &session,
				      &displace,
				      &unlimited,
				      &unset,
				      rsp);
    
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(session)));
	Inline_Stack_Push(sv_2mortal(newSViv(displace == IVADMIN_TRUE)));
	Inline_Stack_Push(sv_2mortal(newSViv(unlimited == IVADMIN_TRUE)));
	Inline_Stack_Push(sv_2mortal(newSViv(unset == IVADMIN_TRUE)));
    }

    Inline_Stack_Done;
}

int context_setaccexpdate( SV* cont, SV* resp, unsigned long seconds, 
			   unsigned long unlimited, unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setaccexpdate( *ctx,
    					  seconds,
					  unlimited,
					  unset,
					  rsp ) );
}

int context_setdisabletimeint( SV* cont, SV* resp, unsigned long seconds,
			       unsigned long disable, unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setdisabletimeint( *ctx,
    					  seconds,
					  disable,
					  unset,
					  rsp ) );
}

int context_setmaxlgnfails( SV* cont, SV* resp, unsigned long failures,
			    unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setmaxlgnfails( *ctx,
    					  failures,
					  unset,
					  rsp ) );
}

int context_setmaxpwdage( SV* cont, SV* resp, unsigned long seconds, 
			  unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setmaxpwdage( *ctx,
    					 seconds,
					 unset,
					 rsp ) );
}

int context_setmaxpwdrepchars( SV* cont, SV* resp, unsigned long chars, unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setmaxpwdrepchars( *ctx,
    					      chars,
					      unset,
					      rsp ) );
}

int context_setminpwdalphas( SV* cont, SV* resp, unsigned long chars, 
			     unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setminpwdalphas(*ctx,
    					   chars,
					   unset,
					   rsp ) );
}

int context_setminpwdnonalphas( SV* cont, SV* resp, unsigned long chars,
				unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setminpwdnonalphas(*ctx,
    					   chars,
					   unset,
					   rsp ) );
}

int context_setminpwdlen( SV* cont, SV* resp, unsigned long length, 
			     unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setminpwdlen(*ctx,
    				        length,
					unset,
					rsp ) );
}

int context_setpwdspaces( SV* cont, SV* resp, unsigned long allowed, 
			  unsigned long unset) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setpwdspaces(*ctx,
    					allowed,
					unset,
					rsp ) );
}

int context_settodaccess( SV* cont, SV* resp, unsigned long days, 
			  unsigned long start, unsigned long end, 
			  unsigned long reference, unsigned long unset ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_settodaccess(*ctx,
    					days,
    					start,
    					end,
    					reference,
					unset,
					rsp ) );
}

int context_setmaxconcurwebsess(SV* cont, SV* resp, unsigned long sessions,
				unsigned long displace, unsigned long
				unlimited, unsigned long unset) {

    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response* rsp = _getresponse( resp );

    return( ivadmin_context_setmaxconcurwebsess(*ctx,
    					sessions,
    					displace,
    					unlimited,
    					unset,
					rsp ) );
}

void DESTROY( SV* cont ) {
    ivadmin_context* ctx = (ivadmin_context*)SvIV(SvRV(cont));
    ivadmin_response rsp;

    if ( ctx != NULL ) {
	ivadmin_context_delete( *ctx, &rsp );
	Safefree( ctx );
    }
}

