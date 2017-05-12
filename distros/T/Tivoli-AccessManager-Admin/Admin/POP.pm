package Tivoli::AccessManager::Admin::POP;
use strict;
use warnings;
use Carp;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: POP.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::POP::VERSION = '1.11';
use Inline( C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
	        NAME => 'Tivoli::AccessManager::Admin::POP',
	    );

use Tivoli::AccessManager::Admin::Response;

my %audit = ( 
	    1 => 'permit',
	    2 => 'deny',
	    4 => 'error',
	    8 => 'admin',
	   15 => 'all' );

my %revaudit = map { $audit{$_} => $_ } keys %audit;

my %tod = ( 
	    1 => 'sun',
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
	next unless $mask;
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

sub _audtolist {
    my $vector = shift;
    my @list;

    return qw/none/ unless $vector;

    return qw/all/ if $vector == 15;

    for my $mask ( keys %audit ) {
	push @list, $audit{$mask} if ($vector & $mask) == $mask;
    }
    return @list;
}

sub _listtoaud {
    my $list = shift;
    my $vector = 0;

    for my $level ( @{$list} ) {
	$level = lc $level;
	if ( $level eq 'all' ) {
	    $vector = 15;
	    last;
	}
	elsif ( $level eq 'none' ) {
	    $vector = 0;
	    last;
	}

	unless ( defined $revaudit{$level} ) {
	    return -1;
	}
	$vector += $revaudit{$level};
    }
    return $vector;
}

sub new {
    my $class = shift;
    my $cont  = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }
    if ( @_ % 2 ) {
	warn "new() invalid syntax -- you did not send a hash\n";
	return undef;
    }
    my %opts  = @_;

    my $self = bless {}, $class;

    $self->{context} = $cont;
    $self->{name}    = $opts{name} || "";
    $self->_popstore();
    $self->{exist} = 0;

    if ( $self->{name} ) {
	$self->{exist} = $self->pop_get($resp);
    }

    return $self
}

sub create {
    my $class = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$self,$name);

    if ( ref $class ) {
	$self = $class;
    }
    else {
	my $pd = shift;
	unless (defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context')){
	    $resp->set_message("Invalid Tivoli::AccessManager::Admin::Context object");
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = $class->new($pd, @_);
	unless ( defined $self ) {
	    $resp->set_isok(0);
	    $resp->set_message('Error creating object');
	    return $resp;
	}
    }

    if ( @_ == 1 ) {
	$name = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$name = $opts{name} || '';
    }
    else {
	$name = '';
    }

    unless ( $self->{name} ) {
	$self->{name} = $name;
    }

    unless ( $self->{name} ) {
	$resp->set_message("create: syntax error -- cannot create nameless POP");
	$resp->set_isok(0);
	return $resp;
    }

    $rc = $self->pop_create($resp);
    if ( $resp->isok ) {
	$resp->set_value($self);
	$self->{exist} = 1;
    }
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rc;

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot delete a POP that doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    $rc = $self->pop_delete($resp);
    if ( $resp->isok ) {
	$resp->set_value($rc);
	$self->{exist} = 0;
    }
    return $resp;
}

sub attach {
    my $self = shift;
    my $resp;

    if ( @_ ) {
	$resp = $self->objects(attach => ref $_[0] ? $_[0] : [@_]);
    }
    else {
	$resp = Tivoli::AccessManager::Admin::Response->new;
	$resp->set_message("Where am I attaching the pop?");
	$resp->set_isok(0);
    }
    return $resp;
}

sub detach {
    my $self = shift;
    my ($resp,$list);

    if ( @_ ) {
	$list = ref $_[0] ? $_[0] : [@_];
    }
    else {
	$resp = $self->find;
	return $resp unless $resp->isok;
	$list = [$resp->value];
    }

    $resp = $self->objects(detach => $list);
    return $resp;
}

sub find {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    my @rc = $self->pop_find( $resp );
    $resp->isok and $resp->set_value(\@rc);

    return $resp;
}

sub objects {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rc;
    my %dispatch = ( detach => \&pop_detach,
		     attach => \&pop_attach );

    if ( @_ % 2 ) {
	$resp->set_message("objects() invalid syntax -- you did not send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    unless ( $self->{exist} ) {
	$resp->set_message("$self->{name} doesn't exist yet");
	$resp->set_isok(0);
	return $resp;
    }

    for my $key ( qw/detach attach/ ) {

	if ( defined( $opts{$key} ) ) {
	    my $objs = $opts{$key};
	    if ( ref($objs) eq 'ARRAY' ) {
		for my $obj ( @{$objs} ) {
		    $rc = $dispatch{$key}->( $self,$resp, ref $obj ? $obj->name : $obj );
		    return $resp unless $resp->isok;
		}
	    }
	    else {
		$rc = $dispatch{$key}->( $self, $resp, ref $objs ? $objs->name : $objs );
		return $resp unless $resp->isok;
	    }
	}
    }

    my @rc = $self->pop_find( $resp );
    $resp->isok and $resp->set_value(\@rc);

    return $resp;
}

sub list {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my (@rc,$pd);

    if ( ref $self ) {
	$pd = $self->{context};
    }
    else {
	$pd = shift;
    }

    @rc = pop_list( $pd, $resp );
    # ARGH!  I cannot figure out how to test this last freakin branch.
    $resp->isok and $resp->set_value( \@rc );
    return $resp;
}

sub anyothernw {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($level,$rc);

    if ( @_ == 1 ) {
	$level = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$level = $opts{level} || '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    # Since 0 is a valid value for level, I need to use the definedness
    if ( defined($level) ) {
	if ( $level eq 'forbidden' ) {
	    $rc = $self->pop_setanyothernw_forbidden2( $resp );
	}
	else {
	    $level = 0 if $level eq 'unset';
	    $rc = $self->pop_setanyothernw2($resp, $level || 0 );
	}
	$resp->isok and $self->pop_get($resp);
    }

    $rc = $self->pop_getanyothernw2($resp);
    if ( $rc > 100000000 or $rc == 0 ) {
	$rc = 'unset';
    }
    elsif ( $rc == 1000 ) {
	$rc = 'forbidden';
    }

    $resp->isok and $resp->set_value($rc);
    return $resp;
}

sub description {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$desc);

    if ( @_ == 1 ) {
	$desc = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$desc = $opts{description} || '';
    }
    else {
	$desc = '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    if ($desc) {
	$rc = $self->pop_setdescription( $resp, $desc);
	if ( $resp->isok ) {
	    $rc = $self->pop_get($resp);
	}
	return $resp unless $resp->isok;
    }
    $resp->set_value($self->pop_getdescription());
    return $resp;
}

sub audit {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$level);

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    if ( @_ == 1 ) {
	$level = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$level = $opts{level} || '';
    }
    else {
	$level = '';
    }
    # If we are setting the audit level and an array has been sent, we need to
    # translate that into a bitmask.
    if ($level) {
	my $vec;
	# If we have been sent an array, translate that into a bitmask
	if ( ref( $level ) ) {
	    $vec = _listtoaud($level);
	    if ( $vec == -1 ) {
		$resp->set_message("Invalid audit level(s): " . join(", ",@{$level}));
		$resp->set_isok(0);
		return $resp;
	    }
	}
	elsif ( $level =~ /^-?\d+$/ ) {
	    # Make sure the provided bitmask makes sense
	    if ( $level > 15 or $level < 0 ) {
		$resp->set_message("Invalid audit level: $level");
		$resp->set_isok(0);
		return $resp;
	    }
	    $vec = $level;
	}
	else {
	    $vec = _listtoaud([$level]);
	    if ( $vec == -1 ) {
		$resp->set_message("Invalid audit level: $level");
		$resp->set_isok(0);
		return $resp;
	    }
	}

	$rc = $self->pop_setauditlevel( $resp, $vec);
	$resp->isok and $self->pop_get($resp);
    }

    if ( $resp->isok ) {
	$level = $self->pop_getauditlevel;

	$resp->set_value($level,[_audtolist($level)]);
    }
    return $resp;
}

sub ipauth {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $done = 0;
    my $rc;
    my %dispatch = ( add => \&pop_setipauth2,
		     remove => \&pop_removeipauth2,
		     forbidden => \&pop_setipauth_forbidden2
		 );

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    if ( @_ % 2 ) {
	$resp->set_message("ipauth invalid syntax -- you did not send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    for my $op ( qw/add remove forbidden/ ) {
	next unless defined $opts{$op};
	for my $ip ( keys %{$opts{$op}} ) {
	    unless (defined($opts{$op}{$ip}{NETMASK}) ) {
		$resp->set_message("No netmask provided for $ip -- SKIPPING");
		$resp->set_iswarning(1);
		delete $opts{$op}{$ip};
		next;
	    }
	    my @call = ($self, $resp, $ip, $opts{$op}{$ip}{NETMASK});
	    if ( $op eq 'add' ) {
		unless (defined($opts{$op}{$ip}{AUTHLEVEL}) ) {
		    $resp->set_message("No auth level provided for $ip -- SKIPPING");
		    $resp->set_iswarning(1);
		    delete $opts{$op}{$ip};
		    next;
		}
		push @call,$opts{$op}{$ip}{AUTHLEVEL};
	    }

	    $rc = $dispatch{$op}->(@call);
	    return $resp unless $resp->isok;
	}
    }

    # After all that, get the new ipauths and embed them 
    $rc = $self->pop_getipauth2($resp);
    $resp->set_value( $rc );

    return $resp;
}

sub qop {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($rc,$qop);

    if ( @_ == 1 ) {
	$qop = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$qop = $opts{qop} || '';
    }
    else {
	$qop = '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    if ( $qop ) { 
	unless ( $qop eq 'none' or
		 $qop eq 'integrity' or
		 $qop eq 'privacy' ) {
	    $resp->set_message("qop must be one of: none, integrity or privacy");
	    $resp->set_isok(0);
	    return $resp;
	}
	$rc = $self->pop_setqop($resp, $qop);
	$resp->isok and $self->pop_get($resp);
    }
    $resp->isok and $resp->set_value($self->pop_getqop());
    return $resp;
}

sub _miltomin {
    my $miltime = shift;
    return ( $miltime - $miltime % 100 ) * .6 + $miltime % 100;
}

sub _mintomil {
    my $mins = shift;

    return sprintf( "%04d", ($mins - $mins % 60)/.6 + $mins % 60 );
}

sub tod {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my ($start,$end,$days, $reference, %rc, @list);

    if ( @_ % 2 ) {
	$resp->set_message("tod invalid syntax -- you did not send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    $reference   = $opts{reference} || '';

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    if ( defined( $opts{days} ) ) {
	$reference = $reference eq 'UTC';

	if ( ref($opts{days})  ) {
	    for my $tday ( @{$opts{days}} ) {
		unless ( defined($revtod{$tday}) or $tday eq 'any' ) {
		    $resp->set_message( "Invalid day: $tday.  Valid days are " . join(", ", keys %revtod ) );
		    $resp->set_isok(0);
		    return $resp;
		}
	    }
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

	$start = defined($opts{start}) ? $opts{start} : 0;
	$end   = defined($opts{end})   ? $opts{end}   : 2359;

	$self->pop_settod( $resp, 
			   $days, 
			   _miltomin($start), 
			   _miltomin($end), 
			   $reference );
	$resp->isok and $self->pop_get($resp);
    }

    if ( $resp->isok ) {
	@list          = $self->pop_gettod;
	$rc{days}      = [ _todtolist( $list[0] || 0 ) ];
	$rc{start}     = _mintomil( $list[1]  || 0);
	$rc{end}       = _mintomil( $list[2]  || 0);
	$rc{reference} = $list[3] ? 'UTC' : 'local';

	$resp->set_value( \%rc );
    }
    return $resp;
}

sub warnmode {
    my $self = shift;
    my $mode;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    if ( @_ == 1 ) {
	$mode = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$mode = $opts{mode};
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot set warnmode on a non-existent POP");
	$resp->set_isok(0);
	return $resp;
    }

    if ( defined($mode) ) {
	$self->pop_setwarnmode( $resp, $mode ? 1 : 0 );
	$resp->isok and $self->pop_get($resp);
    }

    $resp->isok and $resp->set_value( $self->pop_getwarnmode );
    return $resp;
}

sub name {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ( $self->{exist} ) {
	$resp->set_message("The POP doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }
    $resp->set_value( $self->pop_getid() );
    return $resp;
}

sub _addval {
    my $self = shift;
    my $opts = shift;
    my @attrs;

    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $rc;

    for my $key ( keys %$opts ) {
	# Loop if given an array.  Don't otherwise.
	if ( ref($opts->{$key} ) ) {
	    for my $val ( @{$opts->{$key}} ) {
		$rc = $self->pop_attrput( $resp, $key, $val );
		return $resp unless $resp->isok;
	    }
	}
	else {
	    $rc = $self->pop_attrput( $resp, $key, $opts->{$key} );
	}
	return $resp unless $resp->isok;
    }
    return $resp;
}

sub _remvalue {
    my $self = shift;
    my $opts = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $rc;
    
    for my $key ( keys %$opts ) {
	# Loop if given an array.  Don't otherwise.
	if ( ref($opts->{$key}) ) {
	    for my $val ( @{$opts->{$key}} ) {
		$rc = $self->pop_attrdelval( $resp, $key, $val );
		return $resp unless $resp->isok;
	    }
	}
	else {
	    $rc = $self->pop_attrdelval( $resp, $key, $opts->{$key} );
	}
	return $resp unless $resp->isok;
    }
    return $resp;
}

sub _remkey {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $key  = shift;

    my (@keys,$rc);


    if ( ref($key) eq 'ARRAY' ) {
	push @keys, @$key;
    }
    elsif ( ref($key) ) {
	$resp->set_message("remkey invalid syntax -- you must provide an array refs or scalars");
	$resp->set_isok(0);
	return $resp;
    }
    else {
	push @keys, $key;
    }

    for ( @keys ) {
	$rc = $self->pop_attrdelkey( $resp, $_ );
	last unless $resp->isok;
    }
    return $resp;
}

sub attributes {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rhash = {};

    if ( @_ % 2 ) {
	$resp->set_message("attributes invalid syntax -- you did not send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot modify attributes on a non-existent POP");
	$resp->set_isok(0);
	return $resp;
    }

    if ( defined $opts{remove} ) {
	$resp = $self->_remvalue( $opts{remove} ); 
	return $resp unless $resp->isok; 
    }

    if ( defined $opts{removekey} ) {
	$resp = $self->_remkey( $opts{removekey} ); 
	return $resp unless $resp->isok; 
    }

    if ( defined $opts{add} ) {
	$resp = $self->_addval( $opts{add} );
	return $resp unless $resp->isok; 
    }

    # just in case one of the above branches was actually taken, refresh the
    # cached object
    $self->pop_get($resp);
    if ( $resp->isok ) {
	for my $key ( $self->pop_attrlist ) {
	    $rhash->{$key} = [ $self->pop_attrget($key) ];
	}
	$resp->set_value( $rhash );
    }
    return $resp;
}

sub DESTROY {
    $_[0]->_popfree;
}

sub exist { $_[0]->{exist} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::POP

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;
    my ($pop,$resp,$obj);
    my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);

    # Instantiate a new pop
    $pop = Tivoli::AccessManager::Admin::POP->new($pd, name => 'test');

    # Actually create the POP in the policy db
    $resp = $pop->create();

    # Set its description
    $resp = $pop->description( "POP goes the monkey" );

    # Attach it
    $resp = $pop->attach('/test/monkey');

    # See where it is now attached
    $resp = $pop->find;

    # Detach it now
    $resp = $pop->detach('/test/monkey');

    # Get a full list of POPs
    $resp = Tivoli::AccessManager::Admin::POP->list($pd);

    # Set the level for any other network
    $resp = $pop->anyothernw( 2 );
    # Forbid access from any other network
    $resp = $pop->anyothernw( 'forbidden' );

    # Set an IP auth level for a few networks
    $resp = $pop->ipauth(add => {'192.168.8.0' => {NETMASK => '255.255.255.0',
						   AUTHLEVEL => 1 }.
				 '192.168.9.0' => {NETMASK => '255.255.255.0',
						   AUTHLEVEL => 2}
				}
			);

    # Forbid the entire 10.x.x.x network
    $resp = $pop->ipauth(forbidden => {'10.0.0.0' => {NETMASK=>'255.0.0.0'}});

    # Set the audit level
    $resp = $pop->audit( [qw/all/] );

    # Set the QoP level
    $resp = $pop->qop('privacy');

    # Set Time of Day access
    $resp = $pop->tod( days => [qw/monday tuesday wednesday/],
		       start => '0800',
		       end   => '1800',
		     );

    # Set the warn mode
    $resp = $pop->warnmode(1);

    # Set an extended attribute or two
    $resp = $pop->attributes( add => { foobar => 'baz',
				       silly  => [qw/one two three/] }
			    );
    # Clean up after myself
    $pop->delete;

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::POP> allows manipulation of POPs via perl.

=head1 CONSTRUCTORS

=head2 new( PDADMIN[, name =E<gt> NAME] )

Creates a blessed L<Tivoli::AccessManager::Admin::POP> object.  It should be noted that creating
the object in perl is not the same thing as creating it in TAM's policy
database.  See L</"create"> to do that.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This parameter is, as usual, required.

=item name =E<gt> NAME

The POP's name.  This is technically speaking optional, but it may have some
unintentional side effects if not provided.  Namely, the object will assume it
doesn't exist, which will cause problems when trying to do anything to it.

In short, if you intend on calling L</"create"> you can forget this parameter.
Otherwise, include it.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::POP> object.  If there is an error, you will get
undef.

=head2 create(PDADMIN, name =E<gt> NAME)

Creates the object in TAM's policy database and returns the blessed reference.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This parameter is required.

=item name =E<gt> NAME

The POP's name.  When using L</"create"> as a constructor, this parameter is
required.

=back

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object containing the newly created object.  I refer
you to that module's documentation for digging the value out.

=head1 CLASS METHODS

Class methods behave like instance methods in that they all return a
L<Tivoli::AccessManager::Admin::Response> object.

=head2 list(PDADMIN)

List all of the POPs defined in TAM.

=head3 Parameters

=over 4

=item PDADMIN

The standard, initialized L<Tivoli::AccessManager::Admin::Context> object.

=back

=head3 Returns

The list of all defined POPs.

=head1 METHODS

All of the methods return a L<Tivoli::AccessManager::Admin::Response> object unless otherwise
explicitly stated.  See the documentation for that module on how to coax the
values out.

The methods, for the most part, follow the same pattern.  If the optional
parameters are sent, it has the effect of setting the attributes.  All
methods calls will embed the results of a 'get' in the
L<Tivoli::AccessManager::Admin::Response> object.

=head2 create([name =E<gt> NAME])

Creates a new POP in TAM's policy db.  This method can be used as both class
and instance method.

=head3 Parameters

=over 4

=item name =E<gt> NAME

The name of the new POP.  This parameter is only required when you did not use
it in the L</"new"> call.

=back

=head3 Returns

The success or failure of the create operation.

=head2 delete

Deletes the object.

=head3 Parameters

None

=head3 Returns

The success or failure of the operation.  Please note that you really should
detach a POP before trying to delete it.

=head2 objects( [detach =E<gt> OBJECTS[, [attach =E<gt> OBJECTS]] )

Attaches or detaches a POP.  Weird little fact.  The C API for ACLs does not
contain an attach or detach method -- you have to use the methods for the
protected objects.  POPs have their own attach and detach calls.

If both parameters are used, all of the detaches will be done before
attaching.

=head3 Parameters

=over 4

=item detach =E<gt> OBJECTS

Detach the POP from the listed objects.  OBJECTS can be a list or a single
value.  It can be either a string (e.g., '/test/monkey') or a
L<Tivoli::AccessManager::Admin::ProtObject> object or a mix of them.

=item attach =E<gt> OBJECTS

Attach the POP to the listed objects.  The same combination of values can be
used as listed above.

=back

=head3 Returns

The success or failure of the operation.  You will also get a list of the
current places the POP is attached.

=head2 attach OBJECTS[,...]

A convenience method that wraps L</"objects"> with an attach message.  See
L</"objects"> for a full description of the parameters and returns.

=head2 detach OBJECTS[,...]

A convenience method that wraps L</"objects"> with a detach message.  See
L</"objects"> for a full description of the parameters and returns.

=head2 find

Finds and lists everyplace the POP is attached.

=head3 Parameters

None

=head3 Returns

A possibly empty list of everyplace the POP is attached,

=head2 list

L</"list"> can also be used as an instance method, although I personally do
not think it makes much sense.

=head3 Parameters

None, when used as an instance method.

=head3 Returns

A list of all defined POPs.

=head2 anyothernw([<NUMBER>|unset|forbidden])

Set the authentication level for any other network.

=head3 Parameters

=over 4

=item <NUMBER>|unset|forbidden

Sets the authentication level to the provided number, unset or forbidden.

=back

=head3 Returns

The success or failure of the operation, along with the current (possibly new)
level.

=head2 description([STRING])

Sets or gets the POP's description.

=head3 Parameters

=over 4

=item STRING

The new description.  This parameter is optional.

=back

=head3 Returns

The POP's description if set, an empty string otherwise.

=head2 audit( [BITMASK|[STRING[,STRING...]]] )

Sets the audit level on the POP.

=head3 Parameters

=over 4

=item BITMASK|STRING|ARRAYREF

The underlying C library uses a bit mask to set the audit level.  You can
either send this bitmask, a single word that will be translated into a bitmask
or a list of words that will be translated into a bit mask.

If the words "all" or "none" appear anywhere in the list, the bitmask will be
set as indicated below.

The name to bitmask mapping looks like this:

=over 4

=item * 
none   =E<gt> 0

=item * 
permit =E<gt> 1

=item * 
deny   =E<gt> 2

=item *
error  =E<gt> 4

=item *
admin  =E<gt> 8

=item *
all    =E<gt> 15

=back

=back

=head3 Returns

The numeric bitmask if evaluated in scalar context; the wordier list if used
in list context.

=head2 ipauth( [add =E<gt> HASHREF, remove =E<gt> HASHREF, forbidden =E<gt> HASHREF] )

Sets the IP based authentication restrictions.

=head3 Parameters

=over 4

=item add =E<gt> HASHREF

Sets the required authentication level for an IP address and/or
network.  The referant of the hash ref is a hash of hashes, keyed off the IP
address.  The contents of the subhashes look like:

=over 4

=item NETMASK =E<gt> <NETMASK>

The netmask for the ip address.  It should be requested in the quad-dot format
(e.g., 255.255.255.0).  I should likely be smart enough to handle CIDR
notation and what ever IPV6 uses, but I am not.

=item AUTHLEVEL =E<gt> <NUMBER>

Required only when adding, this specifies the authentication level for the
IP/netmask.  There is no default -- I didn't think it safe to guess.

=back

=item remove =E<gt> HASHREF

Removes the IP auth restriction from the POP.  The referant of the hash ref
should look just like it does for adding.

=item forbidden =E<gt> HASHREF

Forbids access from some subnet. The referant of the hash ref
should look just like it does for adding.

=back

=head3 Returns

An array of hashes that look mostly like the parameter hashes.  For the
record, I dislike this function.

=head2 qop( [level] )

Sets the "quality of protection" on the POP.

=head3 Parameters

=over 4

=item level

The level of protection, it must be one of these three options: none,
integrity or privacy.  You will need to refer to the WebSEAL Administration
Guide for the meaning of those three values.

=back

=head3 Returns

The current level of protection.

=head2 tod ( days =E<gt> [array], start =E<gt> N, end =E<gt> N, reference =E<gt> local | UTC )

Returns the current time of day access policy on the POP.

=head3 Parameters

=over 4

=item days 

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

=head2 warnmode([0|1])

Sets the warnmode on the POP.

=head3 Parameters

=over 4

=item O | 1

Disble or enable the warn mode.

=back

=head3 Returns

The current value

=head2 attributes([add => { attribute => value },][remove => { attribute => value },][removekey => attribute])

Adds keys and attributes to the POP, removes values from an attribute and
removes a key.

=head3 Parameters

=over 4

=item add => { attribute => value[,...] }

An anonymous hash pointing to the attributes and the value(s) for that
attribute.  If you want to set more than one value on the attribute, it must
be sent as an anonymous array.

If the attribute does not already exist, it will be created.

=item remove => { attribute => value[,...] }

Removes the value(s) from the named attribute(s).  If you are removing
multiple values from an attribute, you must use an anonymous array.  Note,
this will not remove the attribute, only values from the attribute.

=item removekey => value[,...]

Removes attributes from the POP.  As always, if you want to remove multiple
attributes, you need to use an anonymous array.

=back

=head3 Returns

A hash containing the defined attributes as the keys and the values.  All of
the values are returned as anonymous arrays.

=head2 exist

Returns true if the POP exists, false otherwise.

=back 

=cut

__DATA__
__C__

#include "ivadminapi.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

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

void _popstore( SV* self ) {
    SV** fetched = hv_fetch((HV*)SvRV(self),"_pop", 4, 1 );
    ivadmin_pop* pop;

    Newz( 5, pop, 1, ivadmin_pop );
    if ( fetched ) {
	sv_setiv(*fetched,(IV)pop);
	SvREADONLY_on(*fetched);
    }
    else {
	croak("Couldn't create _pop stash");
    }
}

static ivadmin_pop* _getpop(SV* self) {
    SV** fetched = hv_fetch((HV*)SvRV(self),"_pop", 4, 0 );

    return fetched ? (ivadmin_pop*)SvIV(*fetched) : NULL;
}

int pop_attach( SV* self, SV* resp, char* objname ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*            popid = _getname(self);

    unsigned long rc;

    if( popid == NULL )
	croak("pop_attach: could not retrieve popid");

    rc = ivadmin_pop_attach( *ctx,
    			     popid,
			     objname,
			     rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_attrdelkey( SV* self, SV* resp,  char* attr_key ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char* 	      popid = _getname(self);
    unsigned long rc = 0;

    if ( popid == NULL )
	croak("pop_attrdelkey: could not retrieve name");
    
    rc = ivadmin_pop_attrdelkey( *ctx, 
				 popid,
				 attr_key,
				 rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_attrdelval( SV* self, SV* resp, char* attr_key, char* attr_val ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char*             popid = _getname(self);
    unsigned long rc = 0;

    if ( popid == NULL )
	croak("pop_attrdelval: could not retrieve name");

    rc = ivadmin_pop_attrdelval( *ctx, popid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

void pop_attrget( SV* self, char* attr_key ) {
    ivadmin_pop* pop = _getpop(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **attrval;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( pop == NULL )
	croak("pop_attrget: Couldn't retrieve the ivadmin_pop object");

    rc = ivadmin_pop_attrget( *pop,
    			       attr_key,
    			       &count,
			       &attrval );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(attrval[i],0)));
	    ivadmin_free( attrval[i] );
	}
    }
    Inline_Stack_Done;
}

void pop_attrlist( SV* self ) {
    ivadmin_pop* pop = _getpop(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **attrlist;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( pop == NULL )
	croak("pop_attrlist: Couldn't retrieve the ivadmin_pop object");

    rc = ivadmin_pop_attrlist( *pop,
    			       &count,
			       &attrlist
			     );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(attrlist[i],0)));
	    ivadmin_free( attrlist[i] );
	}
    }
    Inline_Stack_Done;
}

int pop_attrput( SV* self, SV* resp,  char* attr_key, char *attr_val ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char*             popid = _getname(self);
    unsigned long rc = 0;

    if ( popid == NULL )
	croak("pop_attrput: could not retrieve name");
    
    rc = ivadmin_pop_attrput( *ctx, popid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_create( SV* self, SV* resp ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char*	      popid = _getname(self);
    unsigned long rc = 0;

    if ( popid == NULL )
	croak("pop_create: could not retrieve name");
    
    rc = ivadmin_pop_create( *ctx, popid, rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_delete( SV* self, SV* resp ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char*	      popid = _getname(self);
    unsigned long rc = 0;

    if ( popid == NULL )
	croak("pop_delete: could not retrieve name");
 
    rc = ivadmin_pop_delete( *ctx, popid, rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_detach( SV* self, SV* resp, char* objid ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    unsigned long rc = 0;

    rc = ivadmin_pop_detach( *ctx, objid, rsp );
    return(rc == IVADMIN_TRUE);
}

void pop_find( SV* self, SV* resp ) {
    ivadmin_context*  ctx   = _getcontext(self);
    ivadmin_response* rsp   = _getresponse( resp );
    char*	      popid = _getname(self);
    
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **objlist;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( popid == NULL )
	croak("pop_find: could not retrieve name");

    rc = ivadmin_pop_find( *ctx,
    			   popid,
    			   &count,
			   &objlist,
			   rsp
			 );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(objlist[i],0)));
	    ivadmin_free( objlist[i] );
	}
    }
    Inline_Stack_Done;
}

int pop_get( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    ivadmin_pop *pop      = _getpop(self);
    char *popid           = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_get: could not retrieve name");

    if ( pop == NULL )
	croak("pop_get: Couldn't retrieve the ivadmin_pop object");

    rc = ivadmin_pop_get( *ctx,
    			  popid,
			  pop,
			  rsp );

    return(rc == IVADMIN_TRUE);
}

unsigned long pop_getanyothernw2( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* popid           = _getname(self);
    unsigned long level;
    unsigned long rc;

    if ( popid == NULL )
	croak("pop_get: could not retrieve name");

    rc = ivadmin_pop_getanyothernw2( *ctx, 
				     popid, 
				     &level, 
				     rsp );

    return(level);
}

unsigned long pop_getauditlevel( SV* self ) {
    ivadmin_pop *pop      = _getpop(self);

    if ( pop == NULL )
	croak("pop_get: Couldn't retrieve the ivadmin_pop object");

    return(ivadmin_pop_getauditlevel(*pop));
}

SV* pop_getdescription( SV* self ) {
    ivadmin_pop* pop = _getpop(self);
    const char *desc;

    if ( pop == NULL )
	croak("pop_getdescription: Couldn't retrieve the ivadmin_pop object");

    desc = ivadmin_pop_getdescription(*pop);
    return(desc ? newSVpv(desc,0) : NULL);
}

SV* pop_getid( SV* self ) {
    ivadmin_pop* pop = _getpop(self);
    const char *popid;

    if ( pop == NULL )
	croak("pop_getid: Couldn't retrieve the ivadmin_pop object");

    popid = ivadmin_pop_getid(*pop);
    return(popid ? newSVpv(popid,0) : NULL);
}

HV* pop_getipauth2( SV* self, SV* resp ) {
    ivadmin_context*  ctx = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* name            = _getname(self);

    HV* tophash = newHV();          
    HV* subhash;                   
    SV** entry;

    unsigned long count; 
    unsigned long rc; 
    unsigned long i;
    unsigned char** network; 
    unsigned char** netmask;
    unsigned long* authMethod;

    count = 0;

    Newz(5, network, 256, char*);
    Newz(5, netmask, 256, char*);
    Newz(5, authMethod, 256, long);

    rc = ivadmin_pop_getipauth2(*ctx,
			        name,
    				&count,
				network,
				netmask,
				authMethod,
				rsp
			      );

    if ( rc == IVADMIN_TRUE ) {

	if ( count > 256 ) {
	    Newz(5, network, count, char*);
	    Newz(5, netmask, count, char*);
	    Newz(5, authMethod, count, long);

	    rc = ivadmin_pop_getipauth2(*ctx,
					name,
					&count,
					network,
					netmask,
					authMethod,
					rsp
				      );
	}
	else if ( count < 256 ) {
	    Renew(network,count,char*);
	    Renew(netmask,count,char*);
	    Renew(authMethod,count,long);
	}


	for( i = 0; i < count; i++ ) {
	    subhash = newHV();
	    hv_store(tophash, network[i], strlen(network[i]), newRV_noinc((SV*)subhash),0);

	    hv_store(subhash, "NETMASK", 7, newSVpv(netmask[i], strlen(netmask[i])), 0);
	    if ( authMethod[i] == IVADMIN_IPAUTH_FORBIDDEN ) {
		hv_store(subhash, "AUTHLEVEL", 9, newSVpv("forbidden", 9),0);
	    } 
	    else {
		hv_store(subhash, "AUTHLEVEL", 9, newSViv((IV)authMethod[i]),0);
	    }
	}
    }

    Safefree(network);
    Safefree(netmask);
    Safefree(authMethod);

    return(tophash);
}

SV* pop_getqop( SV* self ) {
    ivadmin_pop* pop = _getpop(self);
    const char *qop;

    if ( pop == NULL )
	croak("pop_getqpop: Couldn't retrieve the ivadmin_pop object");

    qop = ivadmin_pop_getqop(*pop);
    return(qop ? newSVpv(qop,0) : NULL);
}

void pop_gettod( SV* self ) {
    ivadmin_pop* pop = _getpop(self);

    unsigned long days      = 0;
    unsigned long start     = 0;
    unsigned long end       = 0;
    unsigned long reference = 0;
    unsigned long rc        = 0;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( pop == NULL )
	croak("pop_gettod: Couldn't retrieve the ivadmin_pop object");

    rc = ivadmin_pop_gettod( *pop,
    			    &days,
			    &start,
			    &end,
			    &reference
			  );
    if ( rc == IVADMIN_TRUE ) {
	Inline_Stack_Push(sv_2mortal(newSViv(days)));
	Inline_Stack_Push(sv_2mortal(newSViv(start)));
	Inline_Stack_Push(sv_2mortal(newSViv(end)));
	Inline_Stack_Push(sv_2mortal(newSViv(reference)));
    }

    Inline_Stack_Done;
}

int pop_getwarnmode( SV* self ) {
    ivadmin_pop* pop = _getpop(self);

    if ( pop == NULL )
	croak("pop_getwarnmode: Couldn't retrieve the ivadmin_pop object");

    return ivadmin_pop_getwarnmode( *pop );
}

void pop_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **pops;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_pop_list( *ctx,
			   &count,
			   &pops,
			   rsp 
			 );

    if ( rc == IVADMIN_TRUE ) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(pops[i],0)));
	    ivadmin_free( pops[i] );
	}
    }
    Inline_Stack_Done;
}

int pop_removeipauth2( SV* self, SV* resp, char* network, char* netmask ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_removeipauth2: Couldn't retrieve the pop id");

    rc = ivadmin_pop_removeipauth2( *ctx,
    				   popid,
				   network,
				   netmask,
				   rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setanyothernw2( SV* self, SV* resp, unsigned long level ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	     popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setanyothernw2: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setanyothernw2( *ctx,
    				    popid,
				    level,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setanyothernw_forbidden2( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	     popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setanyothernw_forbidden2: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setanyothernw_forbidden2(*ctx,
					      popid,
					      rsp);
    return(rc == IVADMIN_TRUE);
}

int pop_setauditlevel( SV* self, SV* resp, unsigned long level ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	     popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setauditlevel: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setauditlevel( *ctx,
    				    popid,
				    level,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setdescription( SV* self, SV* resp, char* desc ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	     popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setdescription: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setdescription( *ctx,
    				    popid,
				    desc,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setipauth2( SV* self, SV* resp, const char* network, const char* netmask, long authMethod ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc; 

    if ( popid == NULL )
	croak("pop_setipauth2: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setipauth2( *ctx,
    				popid,
				network,
				netmask,
				authMethod,
				rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setipauth_forbidden2(SV* self,SV* resp, const char* network,const char* netmask) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setipauth_forbidden2: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setipauth_forbidden2( *ctx,
    				popid,
				network,
				netmask,
				rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setqop( SV* self, SV* resp, char* qop ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setqop: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setqop( *ctx,
    			     popid,
			     qop,
			     rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_settod( SV* self, SV* resp, long days, long start, long end, long reference ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_settod: Couldn't retrieve the pop id");

    rc = ivadmin_pop_settod( *ctx,
    			     popid,
			     days,
			     start,
			     end,
			     reference,
			     rsp );
    return(rc == IVADMIN_TRUE);
}

int pop_setwarnmode( SV* self, SV* resp, long warnmode ) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*	      popid = _getname(self);

    unsigned long rc;

    if ( popid == NULL )
	croak("pop_setwarnmode: Couldn't retrieve the pop id");

    rc = ivadmin_pop_setwarnmode( *ctx,
				  popid,
				  warnmode,
				  rsp );
    return(rc == IVADMIN_TRUE);
}

void _popfree(SV* self) {
    ivadmin_pop* pop = _getpop( self );

    if ( pop != NULL ) 
	Safefree( pop );

    hv_delete((HV*)SvRV(self),"_pop", 4, 0 );
}
