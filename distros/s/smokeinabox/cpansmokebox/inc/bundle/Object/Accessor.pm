package Object::Accessor;

use strict;
use Carp            qw[carp croak];
use vars            qw[$FATAL $DEBUG $AUTOLOAD $VERSION];
use Params::Check   qw[allow];
use Data::Dumper;

### some objects might have overload enabled, we'll need to
### disable string overloading for callbacks
require overload;

$VERSION    = '0.36';
$FATAL      = 0;
$DEBUG      = 0;

use constant VALUE => 0;    # array index in the hash value
use constant ALLOW => 1;    # array index in the hash value
use constant ALIAS => 2;    # array index in the hash value

sub new {
    my $class   = shift;
    my $obj     = bless {}, $class;
    
    $obj->mk_accessors( @_ ) if @_;
    
    return $obj;
}

sub mk_accessors {
    my $self    = $_[0];
    my $is_hash = UNIVERSAL::isa( $_[1], 'HASH' );
    
    ### first argument is a hashref, which means key/val pairs
    ### as keys + allow handlers
    for my $acc ( $is_hash ? keys %{$_[1]} : @_[1..$#_] ) {
    
        ### already created apparently
        if( exists $self->{$acc} ) {
            __PACKAGE__->___debug( "Accessor '$acc' already exists");
            next;
        }

        __PACKAGE__->___debug( "Creating accessor '$acc'");

        ### explicitly vivify it, so that exists works in ls_accessors()
        $self->{$acc}->[VALUE] = undef;
        
        ### set the allow handler only if one was specified
        $self->{$acc}->[ALLOW] = $_[1]->{$acc} if $is_hash;
    }

    return 1;
}

sub ls_accessors {
    ### metainformation is stored in the stringified 
    ### key of the object, so skip that when listing accessors
    return sort grep { $_ ne "$_[0]" } keys %{$_[0]};
}

sub ls_allow {
    my $self = shift;
    my $key  = shift or return;
    return exists $self->{$key}->[ALLOW]
                ? $self->{$key}->[ALLOW] 
                : sub { 1 };
}

sub mk_aliases {
    my $self    = shift;
    my %aliases = @_;
    
    while( my($alias, $method) = each %aliases ) {

        ### already created apparently
        if( exists $self->{$alias} ) {
            __PACKAGE__->___debug( "Accessor '$alias' already exists");
            next;
        }

        $self->___alias( $alias => $method );
    }

    return 1;
}

### XXX this creates an object WITH allow handlers at all times.
### even if the original didnt
sub mk_clone {
    my $self    = $_[0];
    my $class   = ref $self;

    my $clone   = $class->new;
    
    ### split out accessors with and without allow handlers, so we
    ### don't install dummy allow handers (which makes O::A::lvalue
    ### warn for example)
    my %hash; my @list;
    for my $acc ( $self->ls_accessors ) {
        my $allow = $self->{$acc}->[ALLOW];
        $allow ? $hash{$acc} = $allow : push @list, $acc;

        ### is this an alias?
        if( my $org = $self->{ $acc }->[ ALIAS ] ) {
            $clone->___alias( $acc => $org );
        }
    }

    ### copy the accessors from $self to $clone
    $clone->mk_accessors( \%hash ) if %hash;
    $clone->mk_accessors( @list  ) if @list;

    ### copy callbacks
    #$clone->{"$clone"} = $self->{"$self"} if $self->{"$self"};
    $clone->___callback( $self->___callback );

    return $clone;
}

sub mk_flush {
    my $self = $_[0];

    # set each accessor's data to undef
    $self->{$_}->[VALUE] = undef for $self->ls_accessors;

    return 1;
}

sub mk_verify {
    my $self = $_[0];
    
    my $fail;
    for my $name ( $self->ls_accessors ) {
        unless( allow( $self->$name, $self->ls_allow( $name ) ) ) {
            my $val = defined $self->$name ? $self->$name : '<undef>';

            __PACKAGE__->___error("'$name' ($val) is invalid");
            $fail++;
        }
    }

    return if $fail;
    return 1;
}   

sub register_callback {
    my $self    = shift;
    my $sub     = shift or return;
    
    ### use the memory address as key, it's not used EVER as an
    ### accessor --kane
    $self->___callback( $sub );

    return 1;
}


### custom 'can' as UNIVERSAL::can ignores autoload
sub can {
    my($self, $method) = @_;

    ### it's one of our regular methods
    if( $self->UNIVERSAL::can($method) ) {
        __PACKAGE__->___debug( "Can '$method' -- provided by package" );
        return $self->UNIVERSAL::can($method);
    }

    ### it's an accessor we provide;
    if( UNIVERSAL::isa( $self, 'HASH' ) and exists $self->{$method} ) {
        __PACKAGE__->___debug( "Can '$method' -- provided by object" );
        return sub { $self->$method(@_); }
    }

    ### we don't support it
    __PACKAGE__->___debug( "Cannot '$method'" );
    return;
}

### don't autoload this
sub DESTROY { 1 };

### use autoload so we can have per-object accessors,
### not per class, as that is incorrect
sub AUTOLOAD {
    my $self    = shift;
    my($method) = ($AUTOLOAD =~ /([^:']+$)/);

    my $val = $self->___autoload( $method, @_ ) or return;

    return $val->[0];
}

sub ___autoload {
    my $self    = shift;
    my $method  = shift;
    my $assign  = scalar @_;    # is this an assignment?

    ### a method on our object
    if( UNIVERSAL::isa( $self, 'HASH' ) ) {
        if ( not exists $self->{$method} ) {
            __PACKAGE__->___error("No such accessor '$method'", 1);
            return;
        } 
   
    ### a method on something else, die with a descriptive error;
    } else {     
        local $FATAL = 1;
        __PACKAGE__->___error( 
                "You called '$AUTOLOAD' on '$self' which was interpreted by ".
                __PACKAGE__ . " as an object call. Did you mean to include ".
                "'$method' from somewhere else?", 1 );
    }        

    ### is this is an alias, redispatch to the original method
    if( my $original = $self->{ $method }->[ALIAS] ) {
        return $self->___autoload( $original, @_ );
    }        

    ### assign?
    my $val = $assign ? shift(@_) : $self->___get( $method );

    if( $assign ) {

        ### any binding?
        if( $_[0] ) {
            if( ref $_[0] and UNIVERSAL::isa( $_[0], 'SCALAR' ) ) {
            
                ### tie the reference, so we get an object and
                ### we can use it's going out of scope to restore
                ### the old value
                my $cur = $self->{$method}->[VALUE];
                
                tie ${$_[0]}, __PACKAGE__ . '::TIE', 
                        sub { $self->$method( $cur ) };
    
                ${$_[0]} = $val;
            
            } else {
                __PACKAGE__->___error( 
                    "Can not bind '$method' to anything but a SCALAR", 1 
                );
            }
        }
        
        ### need to check the value?
        if( exists $self->{$method}->[ALLOW] ) {

            ### double assignment due to 'used only once' warnings
            local $Params::Check::VERBOSE = 0;
            local $Params::Check::VERBOSE = 0;
            
            allow( $val, $self->{$method}->[ALLOW] ) or (
                __PACKAGE__->___error( 
                    "'$val' is an invalid value for '$method'", 1), 
                return 
            ); 
        }
    }
    
    ### callbacks?
    if( my $sub = $self->___callback ) {
        $val = eval { $sub->( $self, $method, ($assign ? [$val] : []) ) };
        
        ### register the error
        $self->___error( $@, 1 ), return if $@;
    }

    ### now we can actually assign it
    if( $assign ) {
        $self->___set( $method, $val ) or return;
    }
    
    return [$val];
}

### XXX O::A::lvalue is mirroring this behaviour! if this
### changes, lvalue's autoload must be changed as well
sub ___get {
    my $self    = shift;
    my $method  = shift or return;
    return $self->{$method}->[VALUE];
}

sub ___set {
    my $self    = shift;
    my $method  = shift or return;
   
    ### you didn't give us a value to set!
    exists $_[0] or return;
    my $val     = shift;
 
    ### if there's more arguments than $self, then
    ### replace the method called by the accessor.
    ### XXX implement rw vs ro accessors!
    $self->{$method}->[VALUE] = $val;

    return 1;
}

sub ___alias {
    my $self    = shift;
    my $alias   = shift or return;
    my $method  = shift or return;
    
    $self->{ $alias }->[ALIAS] = $method;
    
    return 1;
}

sub ___debug {
    return unless $DEBUG;

    my $self = shift;
    my $msg  = shift;
    my $lvl  = shift || 0;

    local $Carp::CarpLevel += 1;
    
    carp($msg);
}

sub ___error {
    my $self = shift;
    my $msg  = shift;
    my $lvl  = shift || 0;
    local $Carp::CarpLevel += ($lvl + 1);
    $FATAL ? croak($msg) : carp($msg);
}

### objects might be overloaded.. if so, we can't trust what "$self"
### will return, which might get *really* painful.. so check for that
### and get their unoverloaded stringval if needed.
sub ___callback {
    my $self = shift;
    my $sub  = shift;
    
    my $mem  = overload::Overloaded( $self )
                ? overload::StrVal( $self )
                : "$self";

    $self->{$mem} = $sub if $sub;
    
    return $self->{$mem};
}

{   package Object::Accessor::Lvalue;
    use base 'Object::Accessor';
    use strict;
    use vars qw[$AUTOLOAD];

    ### constants needed to access values from the objects
    *VALUE = *Object::Accessor::VALUE;
    *ALLOW = *Object::Accessor::ALLOW;

    ### largely copied from O::A::Autoload 
    sub AUTOLOAD : lvalue {
        my $self    = shift;
        my($method) = ($AUTOLOAD =~ /([^:']+$)/);

        $self->___autoload( $method, @_ ) or return;

        ### *dont* add return to it, or it won't be stored
        ### see perldoc perlsub on lvalue subs
        ### XXX can't use $self->___get( ... ), as we MUST have
        ### the container that's used for the lvalue assign as
        ### the last statement... :(
        $self->{$method}->[ VALUE() ];
    }

    sub mk_accessors {
        my $self    = shift;
        my $is_hash = UNIVERSAL::isa( $_[0], 'HASH' );
        
        $self->___error(
            "Allow handlers are not supported for '". __PACKAGE__ ."' objects"
        ) if $is_hash;
        
        return $self->SUPER::mk_accessors( @_ );
    }                    
    
    sub register_callback {
        my $self = shift;
        $self->___error(
            "Callbacks are not supported for '". __PACKAGE__ ."' objects"
        );
        return;
    }        
}    


### standard tie class for bound attributes
{   package Object::Accessor::TIE;
    use Tie::Scalar;
    use Data::Dumper;
    use base 'Tie::StdScalar';

    my %local = ();

    sub TIESCALAR {
        my $class   = shift;
        my $sub     = shift;
        my $ref     = undef;
        my $obj     =  bless \$ref, $class;

        ### store the restore sub 
        $local{ $obj } = $sub;
        return $obj;
    }
    
    sub DESTROY {
        my $tied    = shift;
        my $sub     = delete $local{ $tied };

        ### run the restore sub to set the old value back
        return $sub->();        
    }              
}

1;
