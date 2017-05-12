package Tivoli::AccessManager::Admin::User;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Tivoli::AccessManager::Admin::Response;
use Tivoli::AccessManager::Admin::Group;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: User.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::User::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::User',
	  );

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

sub _miltomin {
    my $miltime = shift;
    return ( $miltime - $miltime % 100 ) * .6 + $miltime % 100;
}

sub _mintomil {
    my $mins = shift;

    return sprintf("%04d", ($mins - $mins % 60)/.6 + $mins % 60);
}

sub new {
    my $class = shift;
    my $cont = shift;
    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if ( @_ % 2 ) {
	warn "Incorrect syntax -- new() requires a hash\n";
	return undef;
    }

    my %opts = @_;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $self = bless {}, $class;

    $self->{name}  = $opts{name} || '';
    $self->{dn}    = $opts{dn}   || '';
    $self->{cn}    = $opts{cn}   || '';
    $self->{sn}    = $opts{sn}   || '';
    $self->{exist} = 0;
    $self->_userstore();
    $self->{context} = $cont;

    unless ( $self->{cn} ) {
	$self->{cn} = $1 if $self->{dn} =~ /^cn=(.+?),/;
    }

    # If the name was provided, call getuser to see if the user exists.
    if ( $self->{name} ) {
	my $rc = $self->user_get( $resp );
	
	if ( $rc ) {
	    $self->{dn} = $self->user_getdn();
	    $self->{cn} = $self->user_getcn();
	    $self->{sn} = $self->user_getsn();
	    $self->{exist} = 1;
	}
    }
    elsif ( $self->{dn} ) {
	my $rc = $self->user_getbydn( $resp );
	if ( $rc ) {
	    $self->{name} = $self->user_getid();
	    $self->{cn} = $self->user_getcn();
	    $self->{sn} = $self->user_getsn();
	    # It is possible for getbydn to return a user in the LDAP who is
	    # not TAMified.  This makes sure the discovered user is TAMified
	    $self->{exist} = $self->user_get($resp);
	}
    }

    return $self;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $gref = [];

    unless ( ref $self ) {
	my $pd = shift;
	unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = new( $self, $pd, @_ );
    }

    if ( @_ % 2 ) {
	$resp->set_message("Incorrect syntax -- create() requires a hash");
	$resp->set_isok(0);
	return $resp;
    }

    my %opts = @_;

    if ( $self->{exist} ) {
	$resp->set_message( $self->{name} . " already exists" );
	$resp->set_iswarning(1);
	$resp->set_value( $self );

	return $resp;
    }

    unless ( $self->{name} ) {
	$self->{name} = $opts{name} || '';
    }

    unless ( $self->{dn} ) {
	$self->{dn} = $opts{dn}   || '';
    }

    unless ( $self->{cn} ) {
	$self->{cn} = $opts{cn}   || '';
    }

    unless ( $self->{sn} ) {
	$self->{sn} = $opts{sn}   || '';
    }


    $opts{password}      ||= '';
    $opts{sso}           = defined( $opts{sso} ) ? $opts{sso} : 0;
    $opts{nopwdpolicy}   = defined( $opts{nopwdpolicy} ) ? $opts{nopwdpolicy} : 0;
    if ( defined( $opts{groups} ) ) {
	if (ref($opts{groups}) eq 'ARRAY') {
	    $gref  = $opts{groups};
	}
	elsif ( ref($opts{groups}) ) {
	    $resp->set_message("Invalid group syntax -- it must be a string or an array ref");
	    $resp->set_isok(0);
	    return $resp;
	}
	else {
	    push @$gref, $opts{groups};
	}
    }
    $opts{groups}        = [] unless defined( $opts{groups} );

    if ( $self->{name} and $self->{dn} and $self->{sn} and $self->{cn} ) {
	my $rc = $self->user_create( $resp, $opts{password}, $gref,
				    $opts{sso}, $opts{nopwdpolicy});
	if ( $resp->isok ) {
	    $self->{exist} = 1;
	    $resp->set_value($self);
	}
    }
    else {
	$resp->set_message("create: you must defined the userid, the DN, the CN and the SN");
	$resp->set_isok(0);
    }

    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $registry = 0;


    if ( @_ == 1 ) {
	$registry = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Incorrect syntax -- delete needs a hash or just one parameter");
	$resp->set_isok(0);
	return $resp;
    }
    else {
	my %opts = @_;
	$registry = $opts{registry} || 0;
    }

    unless ( $self->{exist} ) {
	$resp->set_message( "delete: " . $self->{name} . " doesn't exist" );
	$resp->set_isok(0);

	return $resp;
    }

    my $rc = $self->user_delete($resp,$registry);
    if ( $resp->isok ) {
	$resp->set_value( $rc );
	$self->{exist} = 0;
    }

    return $resp;
}

sub description {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
   
    if ( $self->{exist} ) {
	my $desc;

	if ( @_ == 1 ) {
	    $desc = shift;
	}
	elsif ( @_ % 2 ) {
	    $resp->set_message("Invalid syntax");
	    $resp->set_isok(0);
	    return $resp;
	}
	elsif (@_) {
	    my %opts = @_;
	    $desc = $opts{description} || '';
	}

	if ( defined $desc ) {
	    my $rc = $self->user_setdescription($resp, $desc);
	    $resp->isok && $self->user_get($resp);
	}
	if ( $resp->isok ) {
	    my $rc = $self->user_getdescription;
	    if ( defined $rc ) {
		$resp->set_value($rc);
	    }
	    else {
		$resp->set_message("Could not retrieve user's description");
		$resp->set_isok(0);
	    }
	}
    }
    else {
	$resp->set_message( "The user does not yet exist" );
	$resp->set_isok(0);
    }

    return $resp;
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
	$lifetime = $opts{lifetime} || 0;
    }
    else {
	$lifetime = 0;
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
	$rc = $self->user_setaccexpdate( $resp,
					 $lifetime,
					 $unlimited,
					 $unset );
	$resp->isok && $self->user_get($resp);
    } 
    if ( $resp->isok ) {
	($seconds,$unlimited,$unset) = $self->user_getaccexpdate($resp);
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

	$rc = $self->user_setdisabletimeint( $resp,
					     $seconds,
					     $disable,
					     $unset);
	$resp->isok && $self->user_get($resp);
    } 
    if ( $resp->isok ) {
	($seconds,$disable,$unset) = $self->user_getdisabletimeint( $resp );
	$resp->set_value( $disable ? "disable" : $unset ? "unset" : $seconds );
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

	$rc = $self->user_setmaxlgnfails( $resp,
					  $failures, 
					  $unset);
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {
	($failures,$unset) = $self->user_getmaxlgnfails( $resp );
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
	
	$rc = $self->user_setmaxpwdage( $resp,
					$seconds,
					$unset );
	$resp->isok && $self->user_get($resp);
    } 
    if ( $resp->isok ) {	
	($seconds,$unset) = $self->user_getmaxpwdage( $resp );
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
	$rc = $self->user_setmaxpwdrepchars( $resp,
						$chars,
						$unset );
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {	
	($chars,$unset) = $self->user_getmaxpwdrepchars( $resp );
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
	    $chars   = 0;
	    $unset   = 1;
	}
	else {
	    $resp->set_message("The parameter must either be an integer or 'unset'");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->user_setminpwdalphas( $resp,
					   $chars,
					   $unset );
	$resp->isok && $self->user_get($resp);
    } 
    if ( $resp->isok ) {	
	($chars,$unset) = $self->user_getminpwdalphas( $resp );
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
	$rc = $self->user_setminpwdnonalphas( $resp,
					      $chars,
					      $unset );
	$resp->isok && $self->user_get($resp);
	
    }
    if ( $resp->isok ) {
	($chars,$unset) = $self->user_getminpwdnonalphas( $resp );
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
	$rc = $self->user_setminpwdlen( $resp,
					$chars,
					$unset );
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {
	($chars,$unset) = $self->user_getminpwdlen( $resp );
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

	$rc = $self->user_setmaxconcurwebsess( $resp,
						  $session,
						  $displace,
						  $unlimited,
						  $unset,
						 );
	$resp->set_value($rc);
	
    }
    if ( $resp->isok ) {
	my $retval;
	($session,$displace,$unlimited,$unset) = $self->user_getmaxconcurwebsess( $resp );

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
	if ($allowed =~ /^\d+$/) {
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
	$rc = $self->user_setpwdspaces( $resp,
					$allowed,
			      	        $unset );
	$resp->isok && $self->user_get($resp);
    } 
    if ( $resp->isok ) {
	($allowed,$unset) = $self->user_getpwdspaces( $resp );
	$resp->set_value($unset ? "unset" : $allowed );
    }

    return $resp;
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
		    $resp->set_message( "days bitmask  > 127");
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

	$self->user_settodaccess( $resp,
				  $days,
				  $start,
				  $end,
				  $reference,
				  $unset );
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {
	@list = $self->user_gettodaccess( $resp );
	if ( $list[-1] ) {
	    $rc{days}  = 0;
	    $rc{start} = 0;
	    $rc{end}   = 0;
	    $rc{reference} = 'local';
	    $rc{unset} = 1;
	}
	else {
	    $rc{days}      = [ _todtolist($list[0]) ];
	    $rc{start}     = _mintomil( $list[1]);
	    $rc{end}       = _mintomil( $list[2]);
	    $rc{reference} = $list[3] ? 'UTC' : 'local';
	}

	$resp->set_value( \%rc );
    }
    return $resp;
}

sub list {
    my $class = shift;
    my $pd;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    # I want this to be called as either Tivoli::AccessManager::Admin::User->list or
    # $self->list
    if ( ref($class) ) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
	unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    $opts{maxreturn} = 0   unless defined( $opts{maxreturn} );
    $opts{pattern}   = '*' unless defined( $opts{pattern} );
    $opts{bydn}      = 0   unless defined( $opts{bydn} );


    my @rc = sort $opts{bydn} ? user_listbydn( $pd, $resp, 
					  $opts{pattern},
				 	  $opts{maxreturn} ) :
			   user_list( $pd, $resp, 
				      $opts{pattern},
				      $opts{maxreturn} );
    $resp->isok() && $resp->set_value( \@rc );
    return $resp;
}

sub groups {
    my $self  = shift;
    my (@groups, $group);
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my @dne = ();

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    if ( defined( $opts{remove} ) ) {
	for my $grp ( @{$opts{remove}} ) {
	    if ( ref $grp ) {
		$group = $grp;
	    }
	    else {
		$group = Tivoli::AccessManager::Admin::Group->new( $self->{context}, name => $grp );
	    }
	    my $gname = $group->name;

	    if ( $group->exist ) {
		$resp = $group->members( remove => [ $self->{name} ] );
		return $resp unless $resp->isok; 
	    }
	    else {
		push @dne, $gname;
	    }
	}
    }

    if ( defined( $opts{add} ) ) {
	for my $grp ( @{$opts{add}} ) {
	    if ( ref $grp ) {
		$group = $grp;
	    }
	    else {
		$group = Tivoli::AccessManager::Admin::Group->new( $self->{context}, name => $grp );
	    }
	    my $gname = $group->name;

	    if ( $group->exist ) {
		$resp = $group->members( add => [ $self->{name} ] );
		return $resp unless $resp->isok; 
	    }
	    else {
		push @dne, $gname;
	    }
	}
    }

    @groups = $self->user_getmemberships( $resp );
    $resp->isok and $resp->set_value(\@groups);
    if ( @dne ) {
	$resp->set_message("The following groups did not exist: " .  join(",",@dne));
	$resp->set_iswarning(1);
    }

    return $resp;
}

sub userimport {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( ref $self ) {
	my $pd = shift;
	unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}

	if ( @_ % 2 ) {
	    $resp->set_message("Invalid syntax");
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = new( $self, $pd, @_ );
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ( $self->{exist} ) {
	$resp->set_message("Cannot create a user that already exists");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->{name} ) {
	$self->{name} = $opts{name} || "";
    }

    unless ( $self->{dn} ) {
	$self->{dn} = $opts{dn} || "";
    }

    $opts{sso} = 0 unless defined($opts{sso});

    if ( $self->{name} and $self->{dn} ) {
	my $rc = $self->user_import( $resp, "", $opts{sso} );
	if ( $resp->isok() ) {
	    my $user = $self->user_get( $resp );
	    $self->{dn}   = $self->user_getdn();
	    $self->{name} = $self->user_getid();
	    $self->{cn}   = $self->user_getcn();
	    $self->{sn}   = $self->user_getsn();

	    $self->{exist} = 1;
	    if ( defined($opts{groups}) ) {
		$resp = $self->groups( add => $opts{groups} );
		return $resp unless $resp->isok;
	    }
	    $resp->isok and $resp->set_value( $self );
	}
    }
    elsif ( $self->{dn} ) {
	$resp->set_message("You must specify the user's name");
	$resp->set_isok(0);
    }
    else {
	$resp->set_message("You must specify the user's dn");
	$resp->set_isok(0);
    }

    return $resp;
}

sub accountvalid {
    my $self  = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($rc,$valid);

    if ( @_ == 1 ) {
	$valid = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$valid = $opts{valid};
    }

    # Set
    if ( defined($valid) ) {
	$rc = $self->user_setaccountvalid( $resp, $valid );
	$resp->isok && $self->user_get($resp);
    }

    if ( $resp->isok ) {
	$rc = $self->user_getaccountvalid();
	$resp->set_value( $rc );
    }

    return $resp;
}

sub passwordvalid {
    my $self  = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($rc,$valid);

    if ( @_ == 1 ) {
	$valid = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$valid = $opts{valid};
    }


    # 0 is a valid input value.  I need to test for definedness
    if ( defined($valid) ) {
	$rc = $self->user_setpasswordvalid( $resp, $valid );
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {
	$rc = $self->user_getpasswordvalid();
	$resp->set_value( $rc );
    }

    return $resp;
}

sub ssouser {
    my $self  = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($rc,$sso);

    if ( @_ == 1 ) {
	$sso = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid ssouser syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$sso = $opts{sso} || 0;
    }

    # Set
    if ( defined($sso) ) {
	$rc = $self->user_setssouser( $resp, $sso );
	$resp->isok && $self->user_get($resp);
    }
    if ( $resp->isok ) {
	$rc = $self->user_getssouser();
	$resp->set_value( $rc );
    }

    return $resp;
}

sub password {
    my $self     = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my ($password,$rc);

    if ( @_ == 1 ) {
	$password = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid password syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$password = $opts{password};
    }

    # Set
    if ( defined($password)) {
	$rc = $self->user_setpassword( $resp, $password );
	$resp->set_value( $rc );
    }
    else {
	$resp->set_message("There is no passwordget!");
	$resp->set_isok(0);
    }

    return $resp;
}

sub DESTROY {
    my $self = shift;

    $self->_userfree;
}

sub exist { $_[0]->{exist} }
sub name { $_[0]->{name} }
sub cn { $_[0]->{cn} }
sub dn { $_[0]->{dn} }
1;

=head1 NAME

Tivoli::AccessManager::Admin::User

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin

  my $pd = Tivoli::AccessManager::Admin->new( password => 'N3ew0nk' );
  my (@users,$resp);

  # Lets see who is there
  $resp = Tivoli::AccessManager::Admin::User->list( $pd, pattern => "luser*", maxreturn => 0 );
  print join("\n", $resp->value);

  # Lets search by DN instead
  $resp = Tivoli::AccessManager::Admin::User->list( $pd, pattern => "luser*", maxreturn => 0, bydn => 1 );
  print join("\n", $resp->value);

  # Lets create three new users, the easy way
  for my $i ( 0 .. 2 ) {
      my $name = sprintf "luser%02d", $i;
      $resp = Tivoli::AccessManager::Admin::User->create( $pd, name => $name,
	  			 dn => "cn=$name,ou=people,o=rox,c=us",
      				 sn => "Luser",
				 cn => "$name",
			         password => 'neeWonk');
      $users[$i] = $resp->value if $resp->isok;

      # Mark the account valid
      $resp = $users[$i]->accountvalid(1);
      # But force them to change the password on login
      $resp = $users[$i]->passwordvalid(0);
  }
  # A slightly different way to create a user
  push @users, Tivoli::AccessManager::Admin::User->new( $pd, name => 'luser03',
  				    dn => 'cn=luser03,ou=people,o=rox,c=us',
				    sn => 'Luser',
				    cn => 'luser03' );
  $resp = $users[-1]->create( password => 'Wonknee' );

  # Oops.  That last one was a mistake
  $resp = $users[-1]->delete;

  # Oops.  Deleting luser03 was a mistake.  Good thing we didn't remove her
  # from the registry
  $resp = $users[-1]->userimport;
  $resp = $users[-1]->password("Fjord!");

  # Nah.  Delete luser03 completely.
  $resp = $users[-1]->delete(1);

  # Hmm, lets put luser00 in a few groups
  $resp = $users[0]->groups( groups => [qw/sheep coworker/] );

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::User> implements the User portion of the TAM API.  There is a fair
amount of overlap between L<Tivoli::AccessManager::Admin::User> and
L<Tivoli::AccessManager::Admin::Context>.  Since I am a lazy POD writer, I
will refer you to that FM when appropriate.

=head1 CONSTRUCTOR

=head2 new( PDADMIN[, name =E<gt> NAME, dn =E<gt> DN, cn =E<gt> CN, sn =E<gt> SN] )

Creates a blessed L<Tivoli::AccessManager::Admin::User> object.  As with everything else, you will need
to destroy the object if you want to change the context.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
parameter.

=item name =E<gt> NAME

The user's name, aka, the userid.  If this parameter is provided, L</"new"> will
try to determine if the user is already known to TAM.  If the user is,
all the fields ( cn, sn and dn ) will be retrieved from TAM.

=item dn =E<gt> DN

The user's DN.  If this value is provided (but L</"name"> is not), L</"new">
will look to see if the user is already defined.  If the user is, the other
fields (name, cn and sn) will be retrieved from TAM.

=item cn =E<gt> CN

The user's common name.  Nothing special happens if you provide the cn.

=item sn =E<gt> SN

The user's surname.  There is nothing special about this parameter either.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::User> object, with an embedded context.

=head1 CLASS METHODS

Class methods behave like instance methods -- they return
L<Tivoli::AccessManager::Admin::Response> objects.

=head2 list(PDADMIN [,maxreturn =E<gt> N, pattern =E<gt> STRING, bydn => 1])

Lists some subset of the TAM users.  There is no export available -- it would
quickly become gruesome with all the other module's lists.

=head3 Parameters

=over 4

=item PDADMIN

A fully blessed L<Tivoli::AccessManager::Admin::Context> object.  Since this is a class method,
and L<Tivoli::AccessManager::Admin::Context> objects are stored in the instances, you must
provide it.

=item maxreturn =E<gt> N

The number of users to return from the query.  This will default to 0, which
means all users matching the pattern.  Depending on how your LDAP is
configured, this may cause issues.

=item pattern =E<gt> STRING

The pattern to search on.  The standard rules for TAM searches apply -- * and
? are legal wild cards.  If not specified, it will default to *, which may
cause issues with your LDAP.  

=item bydn => 1

Changes the search from UID to DN.  Do be aware that this will return all the
inetOrgPerson objects in the LDAP, not just the TAMified users.

=back

=head3 Returns

The resulting list of users.

=head1 METHODS

All of the methods return a L<Tivoli::AccessManager::Admin::Response> object.  See the
documentation for that module on how to coax the values out.

The methods, for the most part, follow the same pattern.  If the optional
parameters are sent, it has the effect of setting the attributes.  All
methods calls will embed the results of a 'get' in the
L<Tivoli::AccessManager::Admin::Response> object.

=head2 create( password =E<gt> 'password'[, sso =E<gt> 0|1, nopwdpolicy =E<gt> 0|1, groups =E<gt> [qw/list of groups/][, name =E<gt> NAME, dn =E<gt> DN, cn =E<gt> CN, sn =E<gt> SN] )

Crikey.  That's an awful number of options, isn't it?  L</"create">, as you
might suspect, creates a user in TAM.  You can call L</"create"> instead of
L</"new"> and retrieve the L<Tivoli::AccessManager::Admin::User> object out of the Response object.

=head3 Parameters

=over 4

=item password =E<gt> 'password'

The new user's password.  This is the only required parameter.

=item sso =E<gt> 0|1

Controls if the user is created as a GSO user.  It defaults to false.

=item nopwdpolicy =E<gt> 0|1

Determines if the password policy is ignored when the user is created.
Defaults to false -- which is to say the default password policy will be
enforced.

=item groups =E<gt> [qw/list of a groups/]

A reference to an array containing the list of groups to which the user will
be added upon creation.  Defaults to the empty list.

=item name =E<gt> NAME

=item dn   =E<gt> DN

=item cn   =E<gt> CN

=item sn   =E<gt> SN

These are the same as defined in L</"new"> and each one is required only if
you did not provide it to L</"new"> or if you are calling L</"create"> instead of
L</"new">.

=back

=head3 Returns

The success or failure of the operation if L</"new"> was used, the new
L<Tivoli::AccessManager::Admin::User> object if not.  If the name, the DN, the CN and the SN are not
present, you will get an error message.

=head2 userimport([name =E<gt> NAME, dn =E<gt> DN, groups =E<gt> [qw/list of groups], sso =E<gt> 0|1)

"TAMifies" an existing user in the LDAP.  I would have loved to simply name
this import, but that had some very unfortunate side affects.  As with
L</"create">, you can call this method to initialize the L<Tivoli::AccessManager::Admin::User> object.

=head3 Parameters

=over 4

=item name =E<gt> NAME

The user's ID.  This is optional if you provided it to L</"new">.

=item dn =E<gt> DN

The user's DN.  This too is optional if you provided it to L</"new">.

=item groups =E<gt> [ qw/ list of groups/ ]

The groups the imported user is to be granted membership.  

=item sso =E<gt> 0 | 1

Import the user as a GSO user or not.  Defaults to "not".

=back

=head3 Returns

The success of the operation.  If you called L</"userimport"> instead of
L</"new">, you will get the L<Tivoli::AccessManager::Admin::User> object.

=head2 delete(0|1)

Deletes the user from TAM.

=head3 Parameters

=over 4

=item 0 | 1

Controls deleting the user from the registry.  This is an optional parameter
and will default to 0.

=back

=head3 Returns

The result of the operation

=head2 groups([ remove =E<gt> [qw/list of groups/], add =E<gt> [qw/list of groups/] ] )

Adds the user to the listed groups, removes them from another list or simply
returns the user's groups.

=head3 Parameters

=over 4

=item add =E<gt> [ qw/ list of groups/ ]

The list of groups to which the user will be added.

=item remove =E<gt> [ qw/ list of groups/ ]

The list of groups from which the user will be removed.  If both the add and
the remove tag are provided, the removes are processed first.

=back

=head3 Returns

The user's group memberships after the removes and adds are processed.  If
some of the specified groups do not exist, they will be listed in the error
message from the L<Tivoli::AccessManager::Admin::Response> object and the iswarning flag will be
set.  I wish I had a better way of returning interesting error info.

=head2 accountvalid( 0|1 )

Marks the user's account valid or not

=head3 Parameters

=over 4

=item 0|1

0 sets the account invalid, 1 sets it valid.

=back

=head3 Returns

1 if the account is valid, 0 if not.

=head2 password( STR )

Changes the user's password to the specified value

=head3 Parameters

=over 4

=item STR

The new password

=back

=head3 Returns

The success of the operation.  Kindly note that there is no get password
function

=head2 description( STR )

Changes the user's description to the specified value

=head3 Parameters

=over 4

=item STR

The new description

=back

=head3 Returns

The user's description.

=head2 passwordvalid( 0|1 )

Marks the user's password valid or not

=head3 Parameters

=over 4

=item 0|1

0 sets the password invalid, 1 sets it valid.

=back

=head3 Returns

1 if the password is valid, 0 if not.

=head2 ssouser( 0|1 )

Marks the user as a GSO enabled user.

=head3 Parameters

=over 4

=item 0|1

Disable or enable GSO for the user, respectively.

=back

=head3 Returns

1 if the user is GSO enabled, 0 otherwise.

=head2 exist

Returns true if the user is known to TAM.

=head2 name

Returns the user's ID, if known.

=head2 accexpdate

=head2 disabletimeint

=head2 maxlgnfails

=head2 tod

=head2 maxpwdage

=head2 maxpwdrepchars

=head2 minpwdalphas

=head2 minpwdnonalphas

=head2 minpwdlen

=head2 pwdspaces

=head2 max_concur_session

These are identical to the same named functions in L<Tivoli::AccessManager::Admin::Context>.
See that very fine manual for documentation.  I will repeat one caveat here.
If you perform a get on a non-existent user, the functions will not return an
error.  No idea why not.

=head1 TODO

The interface to accexpdate blows chunketh.  It needs to become significantly
smarter -- I want it to be able to accept:
   10 days from now ( which would be 11/27/2004 as of this note )
   11/27/2004-12:00:00
   86400 * 10
   1101588906
and each one of those should do the same thing.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than I.

=head1 BUGS

Should L</"list"> return a list of names, or a list of L<Tivoli::AccessManager::Admin::User>
objects? 

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

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
    return rsp;
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return (ivadmin_context*)SvIV(SvRV(*fetched));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

void _userstore( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "tam_user",8,1);
    ivadmin_ldapuser* user;

    Newz( 5, user, 1, ivadmin_ldapuser );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _user slot");
    }

    sv_setiv(*fetched, (IV) user );
    SvREADONLY_on(*fetched);
}

ivadmin_ldapuser* _userget( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "tam_user", 8, 0 );

    if ( fetched ) {
	return (ivadmin_ldapuser*) SvIV(*fetched);
    }
    else {
	return NULL;
    }
}

char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched  = hv_fetch( self_hash, key, strlen(key), 0 );

    return( fetched ? SvPV_nolen( *fetched ) : NULL );
}

int user_create( SV* self, SV* resp, const char* pwd, AV* groups, int sso, int nopwdpolicy ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long rc;
    const char* name = _getname(self);
    char* dn = _fetch(self,"dn");
    char* cn = _fetch(self,"cn");
    char* sn = _fetch(self,"sn");

    const char** grp;
    int count,i;
    SV** fetched;

    count = av_len(groups) + 1;
    if ( count ) {
	Newz( 5, grp, count, const char* );
	for (i=0;i < count;i++ ) {
	    fetched = av_fetch(groups,i,0);
	    grp[i] = fetched ? (const char*)SvPV_nolen( *fetched ) : NULL;
	}
    }
    else {
	grp = NULL;
    }

    if ( name == NULL )
	croak("user_create: could not retrieve user name");

    if ( dn == NULL )
	croak("user_create: could not retrieve dn");

    if ( cn == NULL )
	croak("user_create: could not retrieve cn");

    if ( sn == NULL )
	croak("user_create: could not retrieve sn");

    rc = ivadmin_user_create3( *ctx, 
			       name, 
			       dn,
			       cn,
			       sn,
			       pwd,
    			       count,
			       grp,
			       sso,
			       nopwdpolicy,
			       rsp );
    return(rc == IVADMIN_TRUE);
}

int user_delete( SV* self, SV* resp, int registry ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    ivadmin_ldapuser* user = _userget(self);

    unsigned long rc;
    char *name = _getname(self);
   
    if( name == NULL )
	croak("user_delete: could not get user name");

    if ( user == NULL )
	croak("user_delete: could not get user object");

    rc = ivadmin_user_delete2( *ctx, 
			        name, 
				registry, 
				rsp );

    return(rc == IVADMIN_TRUE);
}

int user_get( SV* self, SV* resp ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    ivadmin_ldapuser* user = _userget(self);

    unsigned long rc;
    char *name = _getname(self);
   
    if ( name == NULL )
	croak("user_get: could not retrieve use name");

    if ( user == NULL )
	croak("user_get: could not get user object");

    rc = ivadmin_user_get( *ctx, 
			   name, 
			   user, 
			   rsp );
    return(rc == IVADMIN_TRUE);
}

int user_getbydn( SV* self, SV* resp ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    ivadmin_ldapuser* user = _userget(self);

    unsigned long rc;
    char *dn = _fetch(self,"dn");
   
    if (dn == NULL)
	croak("user_delete: could not get dn");

    if ( user == NULL )
	croak("user_delete: could not get user object");

    rc = ivadmin_user_getbydn(*ctx, 
			      dn,
			      user,
			      rsp );
    return(rc == IVADMIN_TRUE);
}

SV* user_getcn( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);
    char *cn;

    if ( user == NULL ) 
	croak("user_getcn: could not retrieve ivadmin_ldapuser object");
  
    cn = (char*)ivadmin_user_getcn(*user);
    return(cn ? newSVpv(cn,0):NULL);
}

SV* user_getdescription( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);
    char *desc;
    SV* bob;

    if ( user == NULL ) 
	croak("user_getdescription: could not retrieve ivadmin_ldapuser object");
 
    desc = (char*)ivadmin_user_getdescription(*user);
    bob = desc ? newSVpv(desc,0) : NULL;
    return(bob);
}

int user_setdescription(SV* self, SV* resp, const char* desc) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    unsigned long rc;

    char *name = _getname(self);
    
    if ( name == NULL )
	croak("user_setdescription: could not retrieve user name");
   
    rc = ivadmin_user_setdescription(*ctx,
				     name, 
				     desc,
				     rsp);
    return(IVADMIN_TRUE == rc);
}

SV* user_getdn( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);
    char *dn;

    if ( user == NULL ) 
	croak("user_getdn: could not retrieve ivadmin_ldapuser object");

    dn = (char*)ivadmin_user_getdn( *user);
    return(dn ? newSVpv(dn,0) : NULL);
}

SV* user_getid( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);
    char *id;

    if ( user == NULL ) 
	croak("user_getid: could not retrieve ivadmin_ldapuser object");
 
    id = (char*)ivadmin_user_getid( *user);
    return(id ? newSVpv(id,0) : NULL);
}

SV* user_getsn( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);
    const char *sn;

    if ( user == NULL ) 
	croak("user_getsn: could not retrieve ivadmin_ldapuser object");
 
    sn = ivadmin_user_getsn(*user);
    return(sn ? newSVpv(sn,0) : NULL);
}

int user_getaccountvalid( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);

    if ( user == NULL ) 
	croak("user_getaccountvalid: could not retrieve ivadmin_ldapuser object");

    return(IVADMIN_TRUE == ivadmin_user_getaccountvalid( *user));
}

int user_setaccountvalid( SV* self, SV* resp, int valid ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);

    char *name = _getname(self);
    
    if ( name == NULL )
	croak("user_setaccountvalid: could not retrieve user name");
    
    return(IVADMIN_TRUE == ivadmin_user_setaccountvalid( *ctx, name, valid, rsp ));
}

int user_getpasswordvalid( SV* self ) {
    ivadmin_ldapuser* user = _userget(self);

    if ( user == NULL ) 
	croak("user_getaccountvalid: could not retrieve ivadmin_ldapuser object");

    return(IVADMIN_TRUE == ivadmin_user_getpasswordvalid(*user));
}

int user_setpasswordvalid( SV* self, SV* resp, int valid ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);

    unsigned long rc;
    char *name = _getname(self);
    
    if ( name == NULL )
	croak("user_setpasswordvalid: could not retrieve user name");

    rc = ivadmin_user_setpasswordvalid( *ctx,
    					name,
					valid,
					rsp );
    return(rc == IVADMIN_TRUE);
}

int user_getssouser(SV* self) {
    ivadmin_ldapuser* user = _userget(self);

    if ( user == NULL ) 
	croak("user_getaccountvalid: could not retrieve ivadmin_ldapuser object");

    return(IVADMIN_TRUE == ivadmin_user_getssouser(*user));
}

int user_setssouser(SV* self, SV* resp, int sso) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);

    unsigned long rc;
    char *name = _getname(self);
    
    if ( name == NULL )
	croak("user_setssouser: could not get user name");

    rc = ivadmin_user_setssouser( *ctx,
    				  name,
				  sso,
				  rsp );
    return(rc == IVADMIN_TRUE);
}

int user_setpassword( SV* self, SV* resp, char* passwd ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);

    unsigned long rc;
    char *name = _getname(self);
    
    if ( name == NULL )
	croak("user_setpassword: could not retrieve user name");

    rc = ivadmin_user_setpassword( *ctx,
    				   name,
				   passwd,
				   rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getaccexpdate( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long seconds;
    unsigned long unlimited;
    unsigned long unset;
    
    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( name == NULL )
	croak("user_getaccexpdate: could not retrieve user name");

    rc = ivadmin_user_getaccexpdate( *ctx,
    				     name,
				     &seconds,
				     &unlimited,
				     &unset,
				     rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( seconds )));
	Inline_Stack_Push( sv_2mortal( newSViv( unlimited )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

void user_getmaxconcurwebsess(SV *self, SV* resp) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char *name = _getname(self);

    unsigned long session   = 0;
    unsigned long displace  = 0;
    unsigned long unlimited = 0;
    unsigned long unset     = 0;

    unsigned long rc = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getmaxconcurwebsess( *ctx,
				      name,
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

int user_setaccexpdate( SV* self, SV* resp, unsigned long seconds, unsigned long unlimited, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char *name = _getname(self);

    unsigned long rc = 0;

    if( name == NULL )
	croak("user_setaccexpdate: could not retrieve user name");

    rc = ivadmin_user_setaccexpdate( *ctx,
    				     name,
    				     seconds,
				     unlimited,
				     unset,
				     rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getdisabletimeint( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long seconds;
    unsigned long disable;
    unsigned long unset;
    
    if( name == NULL )
	croak("user_getdisabletimeint: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getdisabletimeint( *ctx,
    				     name,
				     &seconds,
				     &disable,
				     &unset,
				     rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( seconds )));
	Inline_Stack_Push( sv_2mortal( newSViv( disable )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setdisabletimeint( SV* self, SV* resp, unsigned long seconds, unsigned long unlimited, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    if( name == NULL )
	croak("user_setdisabletimeint: could not retrieve user name");

    return ivadmin_user_setdisabletimeint( *ctx,
    					name,
    					seconds,
					unlimited,
					unset,
					rsp );
}

void user_getmaxlgnfails( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname( self );

    unsigned long rc;
    unsigned long failures;
    unsigned long unset;

    if( name == NULL )
	croak("user_getmaxlgnfails: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getmaxlgnfails( *ctx,
    				     name,
				     &failures,
				     &unset,
				     rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( failures )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setmaxlgnfails( SV* self, SV* resp, unsigned long failures, unsigned long unset) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc = 0;

    if( name == NULL )
	croak("user_setmaxlgnfails: could not retrieve user name");

    rc = ivadmin_user_setmaxlgnfails( *ctx,
    				      name,
    				      failures,
				      unset,
				      rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getmaxpwdage( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long seconds;
    unsigned long unset;
    
    if( name == NULL )
	croak("user_getmaxpwdage: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getmaxpwdage( *ctx,
				 name,
				 &seconds,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( seconds )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }

    Inline_Stack_Done;
}

int user_setmaxpwdage( SV* self, SV* resp, unsigned long seconds, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setmaxpwdage: could not retrieve user name");

    rc =  ivadmin_user_setmaxpwdage( *ctx,
				    name,
				    seconds,
				    unset,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getmaxpwdrepchars( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long chars;
    unsigned long unset;

    if( name == NULL )
	croak("user_getmaxpwdrepchars: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getmaxpwdrepchars( *ctx,
				 name,
				 &chars,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( chars )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }

    Inline_Stack_Done;
}

int user_setmaxpwdrepchars( SV* self, SV* resp, unsigned long chars, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setmaxpwdrepchars: could not retrieve user name");

    rc =  ivadmin_user_setmaxpwdrepchars( *ctx,
    					name,
    					chars,
					unset,
					rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getmemberships( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long count;
    unsigned long i;
    char **groups;
    
    if( name == NULL )
	croak("user_getmemberships: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getmemberships( *ctx,
    				      name,
				      &count,
				      &groups,
				      rsp );
    if ( rc == IVADMIN_TRUE ) {
	for( i=0; i < count; i++ ) {
	    Inline_Stack_Push( sv_2mortal( newSVpv( groups[i],0 )));
	    ivadmin_free( groups[i] );
	}
    }
    Inline_Stack_Done;
}

void user_getminpwdalphas( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long chars;
    unsigned long unset;
    
    if( name == NULL )
	croak("user_getminpwdalphas: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getminpwdalphas( *ctx,
				 name,
				 &chars,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( chars )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setminpwdalphas( SV* self, SV* resp, unsigned long chars, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setminpwdalphas: could not retrieve user name");

    rc =  ivadmin_user_setminpwdalphas( *ctx,
    					name,
    					chars,
					unset,
					rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getminpwdlen( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long length;
    unsigned long unset;
    
    if( name == NULL )
	croak("user_getminpwdlen: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getminpwdlen( *ctx,
				 name,
				 &length,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( length )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setminpwdlen( SV* self, SV* resp, unsigned long length, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setminpwdlen: could not retrieve user name");

    rc =  ivadmin_user_setminpwdlen( *ctx,
    				     name,
    				     length,
				     unset ? IVADMIN_TRUE : IVADMIN_FALSE,
				     rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getminpwdnonalphas( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long chars;
    unsigned long unset;

    if( name == NULL )
	croak("user_getminpwdnonalphas: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getminpwdnonalphas( *ctx,
				 name,
				 &chars,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( chars )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setminpwdnonalphas( SV* self, SV* resp, unsigned long chars, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setminpwdnonalphas: could not retrieve user name");

    rc = ivadmin_user_setminpwdnonalphas( *ctx,
    					name,
    					chars,
					unset,
					rsp );
    return(rc == IVADMIN_TRUE);
}

void user_getpwdspaces( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc;
    unsigned long allowed;
    unsigned long unset;

    if( name == NULL )
	croak("user_getpwdspaces: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_getpwdspaces( *ctx,
				 name,
				 &allowed,
				 &unset,
				 rsp );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push( sv_2mortal( newSViv( allowed )));
	Inline_Stack_Push( sv_2mortal( newSViv( unset )));
    }
    Inline_Stack_Done;
}

int user_setpwdspaces( SV* self, SV* resp, unsigned long allowed, unsigned long unset) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    const char* name = _getname(self);

    unsigned long rc;

    if( name == NULL )
	croak("user_setpwdspaces: could not retrieve user name");

    rc =  ivadmin_user_setpwdspaces( *ctx,
    				      name,
    				      allowed,
				      unset,
				      rsp );
    return(rc == IVADMIN_TRUE);
}

void user_gettodaccess( SV* self, SV* resp ) {
    ivadmin_context* ctx   = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char *name = _getname(self);

    unsigned long days      = 0;
    unsigned long start     = 0;
    unsigned long end       = 0;
    unsigned long reference = 0;
    unsigned long unset     = 0;
    unsigned long rc        = 0;

    if( name == NULL )
	croak("user_gettodaccess: could not retrieve user name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_user_gettodaccess( *ctx,
    				    name,
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

int user_settodaccess( SV* self, SV* resp, unsigned long days, unsigned long start, unsigned long end, unsigned long reference, unsigned long unset ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *name = _getname(self);

    unsigned long rc = 0;
    
    if( name == NULL )
	croak("user_gettodaccess: could not retrieve user name");

    rc =  ivadmin_user_settodaccess(*ctx,
    				     name,
    				     days,
    				     start,
    				     end,
    				     reference,
				     unset,
				     rsp );
    return(rc == IVADMIN_TRUE);
}

int user_setmaxconcurwebsess(SV* self, SV* resp, unsigned long sessions,
				unsigned long displace, unsigned long
				unlimited, unsigned long unset) {

    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );

    char *name = _getname(self);
    return( ivadmin_user_setmaxconcurwebsess(*ctx,
				        name,
    					sessions,
    					displace,
    					unlimited,
    					unset,
					rsp ) );
}

int user_import( SV* self, SV* resp, char *groupname, int sso ) {
    ivadmin_context* ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
   
    unsigned long rc;

    char *name = _getname(self);
    char *dn = _fetch(self,"dn");
    char *group; 

    if( name == NULL )
	croak("user_import: could not retrieve user name");

    if( dn == NULL )
	croak("user_import: could not retrieve user dn");

    group = strlen(groupname) ? groupname : NULL;

    rc = ivadmin_user_import2( *ctx,
    			       name,
			       dn,
			       group,
			       sso,
			       rsp );
    return(rc == IVADMIN_TRUE);
}

void user_list( SV* pd, SV* resp, char* pattern, unsigned long maxret ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **users;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( ! strlen( pattern ) ) 
	pattern = IVADMIN_ALLPATTERN;

    if ( maxret == 0 ) 
        maxret = IVADMIN_MAXRETURN;

    rc = ivadmin_user_list( *ctx,
    			     pattern,
			     maxret,
			     &count,
			     &users,
			     rsp 
			    );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(users[i],0)));
	    ivadmin_free( users[i] );
	}
    }
    Inline_Stack_Done;
}

void user_listbydn( SV* pd, SV* resp, char* pattern, unsigned long maxret ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **users;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( ! strlen( pattern ) ) 
	pattern = IVADMIN_ALLPATTERN;

    if ( maxret == 0 ) 
        maxret = IVADMIN_MAXRETURN;

    rc = ivadmin_user_listbydn( *ctx,
    				 pattern,
				 maxret,
				 &count,
				 &users,
				 rsp 
			       );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(users[i],0)));
	    ivadmin_free( users[i] );
	}
    }
    Inline_Stack_Done;
}

void _userfree( SV* self ) {
    ivadmin_ldapuser* user = _userget( self );

    if ( user != NULL ) 
	Safefree( user );
    hv_delete( (HV*)SvRV(self), "tam_user", 8, 0 );
}
