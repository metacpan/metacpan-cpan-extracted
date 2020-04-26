package Util::Medley::Cache;
$Util::Medley::Cache::VERSION = '0.030';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Carp;
use CHI;
use File::Path 'remove_tree';
use Data::Printer alias => 'pdump';
use Kavorka qw(-all);

########################################################

=head1 NAME

Util::Medley::Cache - Simple caching mechanism.

=head1 VERSION

version 0.030

=cut

########################################################

=head1 SYNOPSIS

  #
  # positional
  #
  $self->set('unittest', 'test1', {foo => bar});
  
  my $data = $self->get('unitest', 'test1');
 
  my @keys = $self->getKeys('unittest');

  $self->delete('unittest', 'test1');
                
  # 
  # named pair 
  #
  $self->set(ns   => 'unittest', 
             key  => 'test1', 
             data => { foo => 'bar' });

  my $data = $self->get(ns  => 'unittest', 
                        key => 'test1');

  my @keys = $self->getKeys(ns => 'unittest');

  $self->delete(ns  => 'unittest', 
                key => 'test1');

=cut

########################################################

=head1 DESCRIPTION

This class provides a thin wrapper around CHI.  The caching has 2 levels:
 
=over

=item * level 1 (memory)

=item * level 2 (disk)

=back

When fetching from the cache, level 1 (L1) is always checked first.  If the
requested object is not found, it searches the level 2 (L2) cache.

The cached data can be an object, reference, or string.

All methods confess on error.

=cut

########################################################

=head1 ATTRIBUTES

=head2 rootDir (optional)

Location of the L2 file cache.  

=over

=item default

$HOME/.util-medley/cache

=back

=cut

has rootDir => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildRootDir'
);

=head2 enabled (optional)

Toggles caching on or off.

=over

=item default

1

=back

=cut

has enabled => (
	is      => 'rw',
	isa     => 'Bool',
	lazy    => 1,
	builder => '_buildEnabled',
);

=head2 expireSecs (optional)

Sets the cache expiration.  

=over

=item default

0 (never)

=back

=cut

has expireSecs => (

	# zero = never
	is      => 'rw',
	isa     => 'Int',
	default => 0,
);

=head2 ns (optional)

Sets the cache namespace.  

=cut

has ns => (
	is  => 'rw',
	isa => 'Str',
);

=head2 l1Enabled (optional)

Toggles the L1 cache on or off.

=over

=item default

1

=item env var

To disable L1 cache, set MEDLEY_CACHE_L1_DISABLED=1.

=back

=cut

has l1Enabled => (
	is      => 'rw',
	isa     => 'Bool',
	lazy    => 1,
	builder => '_buildL1Enabled',
);

=head2 l2Enabled (optional) 

Toggles the L2 cache on or off.

=over

=item default

1

=item env var

To disable L2 cache, set MEDLEY_CACHE_L2_DISABLED=1.

=back

=cut

has l2Enabled => (
	is      => 'rw',
	isa     => 'Bool',
	lazy    => 1,
	builder => '_buildL2Enabled',
);

##########################################################

has _chiObjects => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} }
);

has _l1Cache => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} }
);

##########################################################

=head1 METHODS

=head2 clear 

Clears all cache for a given namespace.

=over

=item usage:

 clear([$ns])
 
 clear([ns => $ns])

=item args:

=over

=item ns [Str]

The cache namespace.

=back

=back

=cut

multi method clear (Str :$ns) {

	$self->_l1Clear(@_) if $self->l1Enabled;
	$self->_l2Clear(@_) if $self->l2Enabled;

	return 1;
}

multi method clear (Str $ns?) {

	my %a;
	$a{ns} = $ns if $ns;
	
	return $self->clear(%a);
}

=head2 delete 

Deletes a cache object.

=over

=item usage:

 delete($key, [$ns])
 
 delete(key => $key, [ns => $ns])

=item args:

=over

=item key [Str]

Unique identifier of the cache object.

=item ns [Str] 

The cache namespace. 

=back

=back

=cut

multi method delete (Str :$key!,
               		 Str :$ns) {

	$self->_l1Delete(@_) if $self->l1Enabled;
	$self->_l2Delete(@_) if $self->l1Enabled;

	return 1;
}

multi method delete (Str $key, 
					 Str $ns?) { 

	my %a;
	$a{key} = $key;
	$a{ns} = $ns if $ns;

	return $self->delete(%a);		
}

=head2 destroy

Deletes L1 cache and removes L2 from disk completely.

=over

=item usage:

 destroy([$ns])
  
 destroy([ns => $ns])
  
=item args:

=over

=item ns [Str]

The cache namespace.  

=back

=back

=cut

multi method destroy (Str :$ns) {
	
	$self->_l1Destroy(@_) if $self->l1Enabled;
	$self->_l2Destroy(@_) if $self->l1Enabled;

	return 1;
}

multi method destroy (Str $ns?) {

	my %a;
	$a{ns} = $ns if $ns;
	
	return $self->destroy(%a);
}

=head2 get

Gets a unique cache object.  Returns undef if not found.

=over

=item usage:

 get($key, [$ns])
 
 get(key => $key, [ns => $ns])
 
=item args:

=over

=item key [Str]

Unique identifier of the cache object.

=item ns [Str]

The cache namespace.  

=back

=back

=cut

multi method get (Str :$key!,
				  Str :$ns) {

	if ( $self->l1Enabled ) {
		my $data = $self->_l1Get(@_);
		if ($data) {
			return $data;
		}
	}

	if ( $self->l2Enabled ) {
		my $data = $self->_l2Get(@_);
		if ($data) {
			$self->_l1Set(@_, data => $data);
			return $data;
		}
	}
}

multi method get (Str $key, Str $ns?) {

	my %a;
	$a{key} = $key;
	$a{ns} = $ns if $ns;
	
	return $self->get(%a);	
}

=head2 getKeys

Returns a list of cache keys.

=over

=item usage:

 getKeys([$ns])
 
 getKeys([ns => $ns])
 
=item args:

=over

=item ns [Str]

The cache namespace.  

=back

=back

=cut

multi method getKeys (Str :$ns) {

	if ( $self->l2Enabled ) {
		return $self->_l2GetKeys(@_);
	}

	if ( $self->l1Enabled ) {
		return $self->_l1GetKeys(@_);
	}
}

multi method getKeys (Str $ns?) {

	my %a;
	$a{ns} = $ns if $ns;
	
	return $self->getKeys(ns => $ns);	
}

=head2 getNamespaceDir

Gets the L2 cache dir.

=over

=item usage:

 getNamespaceDir([$ns])
 
 getNamespaceDir([ns => $ns])
 
=item args:

=over

=item ns [Str]

The cache namespace.  

=back

=back

=cut

multi method getNamespaceDir (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	return sprintf "%s/%s", $self->rootDir, $ns;
}

multi method getNamespaceDir (Str $ns?) {

	my %a;
	$a{ns} = $ns if $ns;
	
	return $self->getNamespaceDir(%a);
}

=head2 set

Commits the data object to the cache.

=over

=item usage:

 set($key, $data, [$ns])
 
 set(key => $key, data => $data, [ns => $ns])
   
=item args:

=over

=item key [Str]

Unique identifier of the cache object.

=item data [Object|Ref|Str]

An object, reference, or string.

=item ns [Str]

The cache namespace.  

=back

=back

=cut

multi method set (Str :$key!,
            	  Any :$data!,
            	  Str :$ns) {

	$self->_l1Set(@_) if $self->l1Enabled;
	$self->_l2Set(@_) if $self->l2Enabled;

	return 1;
}

multi method set (Str $key,
            	  Any $data,
            	  Str $ns?) {
            	
	my %a;
	$a{key} = $key;
	$a{data} = $data;
	$a{ns} = $ns if $ns;
	
	return $self->set(%a);            	
}
            	
############################################################

method _getChiObject (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my $href = $self->_chiObjects;

	if ( exists $href->{$ns} ) {
		return $href->{$ns};
	}

	my %params = (
		driver    => 'File',
		root_dir  => $self->rootDir,
		namespace => $ns,
	);

	my $chi = CHI->new(%params);
	$href->{$ns} = $chi;
	$self->_chiObjects($href);

	return $chi;
}

method _buildL1Enabled {

	if ( $self->enabled ) {
		if ( !$ENV{MEDLEY_CACHE_L1_DISABLED} ) {
			return 1;
		}
	}

	return 0;
}

method _buildL2Enabled {

	if ( $self->enabled ) {
		if ( !$ENV{MEDLEY_CACHE_L2_DISABLED} ) {
			return 1;
		}
	}

	return 0;
}

method _buildRootDir {

	if ( defined $ENV{HOME} ) {
		return "$ENV{HOME}/.chi";
	}

	confess "unable to determine HOME env var";
}

method _buildEnabled {

	if ( $ENV{MEDLEY_CACHE_DISABLED} ) {
		return 0;
	}

	return 1;
}

method _l1Get (Str :$ns,
               Str :$key!) {

	$ns = $self->_getNamespace($ns);

	$self->_l1Expire(@_);

	my $l1 = $self->_l1Cache;
	if ( $l1->{$ns}->{$key}->{data} ) {
		return $l1->{$ns}->{$key}->{data};
	}

	return;
}

method _l1Expire (Str :$ns,
                  Str :$key!) {

	$ns = $self->_getNamespace($ns);

	my $l1 = $self->_l1Cache;

	if ( $l1->{$ns}->{$key} ) {
		my $href = $l1->{$ns}->{$key};

		if ( $href->{expire_epoch} ) {    # zero or undef = never

			if ( time() > $href->{expire_epoch} ) {
				$self->_l1Delete(@_);
			}
		}
		else {
			# zero or undef = never
		}
	}

	return;
}

method _l1Delete (Str :$ns,
                  Str :$key!) {

	$ns = $self->_getNamespace($ns);

	my $l1 = $self->_l1Cache;
	if ( $l1->{$ns}->{$key} ) {
		delete $l1->{$ns}->{$key};
	}

	return;
}

method _l1Destroy (Str :$ns) {

	$self->_l1Clear(@_);
}

method _l2Destroy (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my $href = $self->_chiObjects;
	if ($href->{$ns}) {
		delete $href->{$ns};
	}

	remove_tree($self->getNamespaceDir(ns => $ns));	
}

method _l1Clear (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my $l1 = $self->_l1Cache;
	$l1->{$ns} = {};
}

method _l2Clear (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my $chi = $self->_getChiObject( ns => $ns );
	$chi->clear;
}

method _l1Set (Str :$ns,
               Str :$key!,
               Any :$data!) {
	
	$ns = $self->_getNamespace($ns);

	my $node = {
		data         => $data,
		expire_epoch => 0,
	};

	if ( $self->expireSecs ) {    # defined and greater than zero
		$node->{expire_epoch} = time + int( $self->expireSecs );
	}

	my $l1 = $self->_l1Cache;
	$l1->{$ns}->{$key} = $node;

	return;
}

method _l1GetKeys (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my $l1 = $self->_l1Cache;
	if ( $l1 and $l1->{$ns} ) {
		return keys %{ $l1->{$ns} };
	}
}

method _getExpireSecsForChi {

	if ( $self->expireSecs ) {    # defined and > 0
		return $self->expireSecs;
	}

	return 'never';
}

method _l2Set (Str :$ns,
               Str :$key!,
               Any :$data!) {

	$ns = $self->_getNamespace($ns);

	my $chi = $self->_getChiObject( ns => $ns );

	return $chi->set( $key, $data, $self->_getExpireSecsForChi );
}

method _l2Delete (Str :$ns,
                  Str :$key) {

	$ns = $self->_getNamespace($ns);

	my $chi = $self->_getChiObject( ns => $ns );
	$chi->expire($key);

	return;
}

method _l2Get (Str :$ns,
               Str :$key) {

	$ns = $self->_getNamespace($ns);

	my $chi = $self->_getChiObject( ns => $ns );
	return $chi->get($key);
}

method _l2GetKeys (Str :$ns) {

	$ns = $self->_getNamespace($ns);

	my @keys;

	my $chi = $self->_getChiObject( ns => $ns );
	if ($chi) {
		@keys = $chi->get_keys;
	}

	return @keys;
}

method _getNamespace (Str|Undef $ns) {

	if ( !$ns ) {
		if ( !$self->ns ) {
			confess "must provide namespace";
		}

		return $self->ns;
	}

	return $ns;
}

1;
