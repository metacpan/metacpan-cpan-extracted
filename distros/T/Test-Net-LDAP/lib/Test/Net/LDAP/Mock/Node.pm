use 5.006;
use strict;
use warnings;

package Test::Net::LDAP::Mock::Node;

use Net::LDAP::Util qw(canonical_dn ldap_explode_dn);
use Scalar::Util qw(blessed);

sub new {
    my ($class) = @_;
    
    return bless {
        entry    => undef,
        submap   => {},
        password => undef,
    }, $class;
}

sub entry {
    my $self = shift;
    
    if (@_) {
        my $old = $self->{entry};
        $self->{entry} = shift;
        return $old;
    } else {
        return $self->{entry};
    }
}

sub make_node {
    my ($self, $spec) = @_;
    
    return $self->_descend_path($spec, sub {
        my ($node, $rdn) = @_;
        return $node->_make_subnode($rdn);
    });
}

sub get_node {
    my ($self, $spec) = @_;
    
    return $self->_descend_path($spec, sub {
        my ($node, $rdn) = @_;
        return $node->_get_subnode($rdn);
    });
}

sub traverse {
    my ($self, $callback, $scope) = @_;
    $scope ||= 0; # 0: base, 1: one, 2: sub
    
    my $visit;
    $visit = sub {
        my ($node, $deep) = @_;
        $callback->($node);
        
        # $deep == 0 or 1
        if ($scope > $deep) {
            $node->_each_subnode(sub {
                my ($subnode) = @_;
                $visit->($subnode, 1);
            });
        }
    };
    
    $visit->($self, 0);
}

sub password {
    my $self = shift;
    my $password = $self->{password};
    $self->{password} = shift if @_;
    return $password;
}

sub _descend_path {
    my ($self, $spec, $callback) = @_;
    
    if (ref $spec eq 'HASH') {
        my $node = $callback->($self, $spec);
        return $node;
    } else {
        my $dn_list;
        
        if (ref $spec eq 'ARRAY') {
            $dn_list = $spec;
        } else {
            my $dn = blessed($spec) ? $spec->dn : $spec;
            $dn_list = ldap_explode_dn($dn, casefold => 'lower');
        }
        
        my $node = $self;
        my $parent;
        
        for my $rdn (reverse @$dn_list) {
            $parent = $node;
            $node = $callback->($node, $rdn) or last;
        }
        
        return $node;
    }
}

sub _make_subnode {
    my ($self, $rdn) = @_;
    # E.g. $rdn == {ou => 'Sales'}
    my $canonical = lc canonical_dn([$rdn], casefold => 'none');
    return $self->{submap}{$canonical} ||= ref($self)->new;
}

sub _get_subnode {
    my ($self, $rdn) = @_;
    # E.g. $rdn == {ou => 'Sales'}
    my $canonical = lc canonical_dn([$rdn], casefold => 'none');
    return $self->{submap}{$canonical};
}

sub _each_subnode {
    my ($self, $callback) = @_;
    my $submap = $self->{submap};
    
    for my $canonical (keys %$submap) {
        $callback->($submap->{$canonical});
    }
}

1;
