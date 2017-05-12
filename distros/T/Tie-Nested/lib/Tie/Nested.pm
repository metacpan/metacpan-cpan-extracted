# Copyrights 2010 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.06.
use warnings;
use strict;

package Tie::Nested;
use vars '$VERSION';
$VERSION = '0.10';


use Log::Report 'tie-nested', syntax => 'SHORT';
use Data::Dumper;


sub TIEHASH(@)
{   my $class = shift;
    my $add   = @_ % 2 ? shift : {};
    my $self  = (bless {}, $class)->init({@_} );
    my @a     = %$add;
    tie %$add, $self->{mine};
    $self->{data} = $add;
    $self->STORE(shift @a, shift @a) while @a;
    $self;
}


sub TIEARRAY(@)
{   my $class = shift;
    my $add   = @_ % 2 ? shift : [];
    $add = [$add] if ref $add ne 'ARRAY';
    my $self  = (bless {}, $class)->init( {@_} );
    tie @$add, $self->{mine};
    $self->{data} = $add;
    $self;
}

sub init($)
{   my ($self, $args) = @_;

    my ($mine, @nest_opts);
    if(my $r = $args->{recurse})
    {   $r = [ $r ] if ref $r ne 'ARRAY';
        $mine = $r->[0];
        @nest_opts  = (recurse => $r);
    }
    elsif(my $n = $args->{nestings})
    {   ($mine, my @nest) = ref $n eq 'ARRAY' ? @$n : $n;
        @nest_opts  = (nestings => \@nest) if @nest;
    }
    else
    {   error __x"tie needs either 'recurse' or 'nestings' parameter";
    }

    defined $mine
	or error __x"requires a package name for the tie on the data";

    $self->{mine} = $mine;
    $self->{nest} = \@nest_opts if @nest_opts;
    $self;
}

sub STORE($$$)
{   my ($self, $k, $v) = @_;
    my $t = $self->{mine};
    my $d = $self->{data} ||= $t->($k, $v);

    if(my $nest = $self->{nest})
    {
	if(ref $v eq 'HASH' && $nest->[1][0]->can('TIEHASH'))
	{   tie %$v, ref $self, {%$v}, @$nest;
            return $d->{$k} = $v;
        }
        elsif(ref $v eq 'ARRAY' && $nest->[1][0]->can('TIEARRAY'))
        {   tie @$v, ref $self, [@$v], @$nest;
            return $d->{$k} = $v;
	}
    }

    (tied %$d)->STORE($k, $v);
}

my $end;
END { $end++ }

our $AUTOLOAD;
sub AUTOLOAD(@)
{   return if $end;
    $AUTOLOAD =~ s/.*\:\://;
    my $d     = shift->{data};
    my $obj   = tied %$d;
    return if $AUTOLOAD eq 'DESTROY' && ! $obj->can('DESTROY');
    $obj->$AUTOLOAD(@_);
}

1;
