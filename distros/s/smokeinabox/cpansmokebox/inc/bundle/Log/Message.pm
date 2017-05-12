package Log::Message;

use strict;

use Params::Check qw[check];
use Log::Message::Item;
use Log::Message::Config;
use Locale::Maketext::Simple Style => 'gettext';

local $Params::Check::VERBOSE = 1;

BEGIN {
    use vars        qw[$VERSION @ISA $STACK $CONFIG];

    $VERSION    =   0.02;

    $STACK      =   [];
}



### subs ###
sub import {
    my $pkg     = shift;
    my %hash    = @_;

    $CONFIG = new Log::Message::Config( %hash )
                or die loc(qq[Problem initialising %1], __PACKAGE__);

}

sub new {
    my $class   = shift;
    my %hash    = @_;

    my $conf = new Log::Message::Config( %hash, default => $CONFIG ) or return undef;

    if( $conf->private || $CONFIG->private ) {

        return _new_stack( $class, config => $conf );

    } else {
        my $obj = _new_stack( $class, config => $conf, stack => $STACK );

        ### if it was an empty stack, this was the first object
        ### in that case, set the global stack to match it for
        ### subsequent new, non-private objects
        $STACK = $obj->{STACK} unless scalar @$STACK;

        return $obj;
    }
}

sub _new_stack {
    my $class = shift;
    my %hash  = @_;

    my $tmpl = {
        stack   => { default        => [] },
        config  => { default        => bless( {}, 'Log::Message::Config'),
                     required       => 1,
                     strict_type    => 1
                },
    };

    my $args = check( $tmpl, \%hash, $CONFIG->verbose ) or (
        warn(loc(q[Could not create a new stack object: %1], 
                Params::Check->last_error)
        ),
        return
    );


    my %self = map { uc, $args->{$_} } keys %$args;

    return bless \%self, $class;
}

sub _get_conf {
    my $self = shift;
    my $what = shift;

    return defined $self->{CONFIG}->$what()
                ?  $self->{CONFIG}->$what()
                :  defined $CONFIG->$what()
                        ?  $CONFIG->$what()
                        :  undef;           # should never get here
}

### should extra be stored in the item object perhaps for later retrieval?
sub store {
    my $self = shift;
    my %hash = ();

    my $tmpl = {
        message => {
                default     => '',
                strict_type => 1,
                required    => 1,
            },
        tag     => { default => $self->_get_conf('tag')     },
        level   => { default => $self->_get_conf('level'),  },
        extra   => { default => [], strict_type => 1 },
    };

    ### single arg means just the message
    ### otherwise, they are named
    if( @_ == 1 ) {
        $hash{message} = shift;
    } else {
        %hash = @_;
    }

    my $args = check( $tmpl, \%hash ) or ( 
        warn( loc(q[Could not store error: %1], Params::Check->last_error) ), 
        return 
    );

    my $extra = delete $args->{extra};
    my $item = Log::Message::Item->new(   %$args,
                                        parent  => $self,
                                        id      => scalar @{$self->{STACK}}
                                    )
            or ( warn( loc(q[Could not create new log item!]) ), return undef );

    push @{$self->{STACK}}, $item;

    {   no strict 'refs';

        my $sub = $args->{level};

        $item->$sub( @$extra );
    }

    return 1;
}

sub retrieve {
    my $self = shift;
    my %hash = ();

    my $tmpl = {
        tag     => { default => qr/.*/ },
        level   => { default => qr/.*/ },
        message => { default => qr/.*/ },
        amount  => { default => '' },
        remove  => { default => $self->_get_conf('remove')  },
        chrono  => { default => $self->_get_conf('chrono')  },
    };

    ### single arg means just the amount
    ### otherwise, they are named
    if( @_ == 1 ) {
        $hash{amount} = shift;
    } else {
        %hash = @_;
    }

    my $args = check( $tmpl, \%hash ) or (
        warn( loc(q[Could not parse input: %1], Params::Check->last_error) ), 
        return 
    );
    
    my @list =
            grep { $_->tag      =~ /$args->{tag}/       ? 1 : 0 }
            grep { $_->level    =~ /$args->{level}/     ? 1 : 0 }
            grep { $_->message  =~ /$args->{message}/   ? 1 : 0 }
            grep { defined }
                $args->{chrono}
                    ? @{$self->{STACK}}
                    : reverse @{$self->{STACK}};

    my $amount = $args->{amount} || scalar @list;

    my @rv = map {
                $args->{remove} ? $_->remove : $_
           } scalar @list > $amount
                            ? splice(@list,0,$amount)
                            : @list;

    return wantarray ? @rv : $rv[0];
}

sub first {
    my $self = shift;

    my $amt = @_ == 1 ? shift : 1;
    return $self->retrieve( amount => $amt, @_, chrono => 1 );
}

sub final {
    my $self = shift;

    my $amt = @_ == 1 ? shift : 1;
    return $self->retrieve( amount => $amt, @_, chrono => 0 );
}

sub flush {
    my $self = shift;
    
    return splice @{$self->{STACK}};
}

1;

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
