=head1 NAME

XAO::DO::Cache::Memory - memory storage back-end for XAO::Cache

=head1 SYNOPSIS

You should not use this object directly, it is a back-end for
XAO::Cache.

=head1 DESCRIPTION

Cache::Memory is the default implementation of XAO::Cache back-end. It
stores data in memory.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Cache::Memory;
use strict;
use XAO::Utils;
use XAO::Objects;
use Clone qw(clone);

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Memory.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item calculate_size ($)

Calculates size in bytes of the given reference.

=cut

sub calculate_size ($$) {
    my $self=shift;
    my $d=shift;
    my $r=ref($d);
    my $sz=0;
    while($r eq 'REF') {
        $d=$$d;
        $r=ref($d);
        $sz+=4;
    }
    if($r eq 'ARRAY') {
        foreach my $dd (@$d) {
            $sz+=$self->calculate_size($dd);
        }
    }
    elsif($r eq 'HASH') {
        foreach my $dk (keys %$d) {
            # very rough estimate
            $sz+=length($dk) + $self->calculate_size($d->{$dk});
        }
    }
    elsif($r eq 'SCALAR') {
        $sz=length($$d) + 4;
    }
    elsif($r eq '') {
        $sz=length($d) + 4;
    }
    else {
        $sz+=200;
    }
    return $sz;
}

###############################################################################

=item drop (@)

Drops an element from the cache.

=cut

sub drop ($@) {
    my $self=shift;

    my $key=$self->make_key($_[0]);
    my $data=$self->{data};
    my $ed=$data->{$key};

    return unless $ed;

    if($ed->{next}) {
        $data->{$ed->{next}}->{previous}=$ed->{previous};
    }
    else {
        $self->{least_recent}=$ed->{previous};
    }

    if($ed->{previous}) {
        $data->{$ed->{previous}}->{next}=$ed->{next};
    }
    else {
        $self->{most_recent}=$ed->{next};
    }

    delete $data->{$key};
}

###############################################################################

=item drop_all ($)

Drops all elements.

=cut

sub drop_all ($$$) {
    my ($self,$key,$ed)=@_;

    $self->{'data'}={ };
    $self->{'least_recent'}=$self->{'most_recent'}=undef;
    $self->{'current_size'}=0;
}

###############################################################################

=item get (\@)

Retrieves an element from the cache. Does not check if it is expired or
not, that is done in exists() method and does not update access time.

=cut

sub get ($$) {
    my $self=shift;

    my $key=$self->make_key($_[0]);

    ### dprint "MEMORY: get(",$key,")";

    my $ed=$self->{'data'}->{$key};

    my $expire=$self->{'expire'};

    my $exists=($ed && (!$expire || $ed->{'access_time'} + $expire > time));

    return $exists ? $ed->{'element'} : undef;
}

###############################################################################

=item make_key (\@)

Makes a key from the given list of coordinates.

=cut

sub make_key ($$) {
    my $self=shift;
    return join("\001",map { defined($_) ? $_ : '' } @{$_[0]});
}

###############################################################################

=item put (\@\$)

Add a new element to the cache; before adding it checks cache size and
throws out elements to make space for the new element. Order of removal
depends on when an element was accessed last.

=cut

sub put ($$$) {
    my $self=shift;

    my $key=$self->make_key(shift);

    # We store a deep copy, not an actual data piece. It must be OK to
    # modify the original data after it's cached.
    #
    my $element=clone(shift);

    my $data=$self->{data};
    my $size=$self->{size};
    my $nsz=$size ? $self->calculate_size($element) : 0;

    my $lr=$self->{least_recent};
    my $expire=$self->{'expire'};
    my $now=time;
    my $count=5;
    while(defined($lr)) {
        my $lred=$data->{$lr};
        last unless $count--;
        last unless ($size && $self->{current_size}+$nsz>$size) ||
                    ($expire && $lred->{access_time}+$expire < $now);
        $lr=$self->drop_oldest($lr,$lred);
    }

    $data->{$key}={
        size        => $nsz,
        element     => $element,
        access_time => time,
        previous    => undef,
        next        => $self->{most_recent},
    };

    ### dprint "MEMORY: put(",$key," => ",$element,") size=",$self->{'size'}," expire=",$self->{'expire'};

    $data->{$self->{most_recent}}->{previous}=$key
        if defined($self->{most_recent});

    $self->{most_recent}=$key;
    $self->{least_recent}=$key unless defined($self->{least_recent});
    $self->{current_size}+=$nsz;

    return undef;
}

###############################################################################

=item setup (%)

Sets expiration time and maximum cache size.

=cut

sub setup ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    $self->{'expire'}=$args->{'expire'} || 0;
    $self->{'size'}=($args->{'size'} || 0) * 1024;

    $self->drop_all();
}

###############################################################################

=back

=head1 PRIVATE METHODS

=over

###############################################################################

=item drop_oldest ($)

Drops oldest element from the cache using supplied key and element.

=cut

sub drop_oldest ($$$) {
    my ($self,$key,$ed)=@_;

    ### dprint "drop_oldest()";

    $self->{most_recent}=undef if defined($self->{most_recent}) &&
                                  $self->{most_recent} eq $key;

    my $previous=$ed->{previous};
    $self->{least_recent}=$previous;

    $self->{current_size}-=$ed->{size};

    my $data=$self->{data};

    $data->{$previous}->{next}=undef if defined($previous);

    delete $data->{$key};

    ### $self->print_chain();

    return $previous;
}

###############################################################################

=item print_chain ()

Prints cache as a chain from the most recent to the least recent. The
order is most_recent->next->...->next->least_recent.

=cut

sub print_chain ($) {
    my $self=shift;
    my $data=$self->{data};

    dprint "CHAIN: mr=",$self->{most_recent},
           " lr=",$self->{least_recent},
           " csz=",$self->{current_size},
           " size=",$self->{size},"\n";
    my $id=$self->{most_recent};
    my $c='';
    while(defined($id)) {
        my $ed=$data->{$id};
        $c.="->" if $id ne $self->{most_recent};
        $c.="[$id/$ed->{access_time}/".($ed->{previous}||'')."/".($ed->{next}||'')."]";
        $id=$ed->{next};
    }
    print STDERR "$c\n";
}

###############################################################################

=item touch ($)

Private method that updates access time and moves an element to the most
recent position.

=cut

sub touch ($$$) {
    my ($self,$key,$ed)=@_;

    $ed->{access_time}=time;

    my $previous=$ed->{previous};
    if(defined $previous) {
        my $next=$ed->{next};

        my $data=$self->{data};

        my $ped=$data->{$previous};
        $ped->{next}=$next;

        $self->{least_recent}=$previous if $self->{least_recent} eq $key;

        if(defined($next)) {
            my $ned=$data->{$next};
            $ned->{previous}=$previous;
        }

        $ed->{next}=$self->{most_recent};
        $ed->{previous}=undef;

        $self->{most_recent}=$data->{$ed->{next}}->{previous}=$key;
    }

    ### $self->print_chain;
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2002 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::DO::Cache::Memory>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
