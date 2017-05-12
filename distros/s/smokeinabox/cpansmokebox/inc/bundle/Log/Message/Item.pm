package Log::Message::Item;

use strict;
use Params::Check qw[check];
use Log::Message::Handlers;

### for the messages to store ###
use Carp ();

BEGIN {
    use vars qw[$AUTOLOAD $VERSION];

    $VERSION    =   $Log::Message::VERSION;
}

### create a new item.
### note that only an id (position on the stack), message and a reference
### to its parent are required. all the other things it can fill in itself
sub new {
    my $class   = shift;
    my %hash    = @_;

    my $tmpl = {
        when        => { no_override    => 1,   default    => scalar localtime },
        id          => { required       => 1    },
        message     => { required       => 1    },
        parent      => { required        => 1    },
        level       => { default        => ''   },      # default may be conf dependant
        tag         => { default        => ''   },      # default may be conf dependant
        longmess    => { default        => _clean(Carp::longmess()) },
        shortmess   => { default        => _clean(Carp::shortmess())},
    };

    my $args = check($tmpl, \%hash) or return undef;

    return bless $args, $class;
}

sub _clean { map { s/\s*//; chomp; $_ } shift; }

sub remove {
    my $item = shift;
    my $self = $item->parent;

    return splice( @{$self->{STACK}}, $item->id, 1, undef );
}

sub AUTOLOAD {
    my $self = $_[0];

    $AUTOLOAD =~ s/.+:://;

    return $self->{$AUTOLOAD} if exists $self->{$AUTOLOAD};

    local $Carp::CarpLevel = $Carp::CarpLevel + 3;

    {   no strict 'refs';
        return *{"Log::Message::Handlers::${AUTOLOAD}"}->(@_);
    }
}

sub DESTROY { 1 }

1;

__END__

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
