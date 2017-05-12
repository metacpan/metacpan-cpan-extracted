package HTML::HTPL::LDAP;

use Net::LDAP;
use HTML::HTPL::Lib;
use HTML::HTPL::Result;
use strict;

sub new {
    my ($class, $server, $port, $bind, $pass) = &trans(@_);

    my $self = {'server' => $server, 'port' => $port, 
                    'bind' => $bind, 'pass' => $pass};
    bless $self, $class;
}

sub bind {
    my $self = shift;

    my $server = $self->{'server'};
    my $port = $self->{'port'};
    my $bind = $self->{'bind'};
    my $pass = $self->{'pass'};

    my $dir = Net::LDAP->new($server, port => $port);
    my $result = $dir->bind($bind, password => $pass) if ($bind && $pass);
    $self->{'dir'} = $dir;
}

sub unbind {
    my $self = shift;
    my $dir = $self->{'dir'};

    $dir->unbind;

    $self->{'dir'} = undef;
}

sub search {
    my ($self, $filter, $start, $scope, $attributes, $sizelimit, $sortkey) = &trans(@_);

    $self->bind;

    my $dir = $self->{'dir'};

    my @attrs = split(/\s+/, $attributes);

    my @p = (@attrs && ('attrs' => \@attrs), $start && ('base' => $start));
    

    $sizelimit = undef unless ($sizelimit > 0);

    my $mesg = $dir->search(scope => $scope, 
    sizelimit => $sizelimit,
        filter => $filter, @p);

    my @entries = ($sortkey ? $mesg->sorted($sortkey) :  $mesg->entries);

    @attrs = unitecolumns(@entries) unless (@attrs);

    unless (join(" ", @attrs) =~ /<dn>/i) {
        unshift(@attrs, "dn") 
    }

    my $result = new HTML::HTPL::Result(undef, @attrs);

    my ($entry, $key, $val, @vals);

    foreach $entry (@entries) {
        my @values;
        foreach $key (@attrs) {
            if (lc($key) eq "dn") {
                $val = $entry->dn;
            } else {
                @vals = $entry->get($key);
                $val = "@vals";
            }
            push(@values, $val);
        }
        $result->addrow(@values);
    }
    $self->unbind;
    
    $result;
}


sub add {
    my ($self, $dn, $attributes) = &trans(@_);

    $self->bind;

    my @atts = &parseattr($attributes);

    my $dir = $self->{'dir'};

    my $result = $dir->add($dn, attributes => \@atts);

    $self->unbind;
}

sub modify {
    my ($self, $dn, $attributes) = &trans(@_);

    $self->bind;

    my @atts = &parseattr($attributes);

    my $dir = $self->{'dir'};

    $dir->modify($dn, attributes => \@atts);

    $self->unbind;
}

sub delete {
    my ($self, $dn) = @_;

    $self->bind;

    my $dir = $self->{'dir'};

    $dir->delete($dn);
    
    $self->unbind;
}

sub parseattr {
    my $attributes = shift;
    my $pair;
    my ($key, $val);
    my @atts;

    foreach $pair(split(/;\s*/, $attributes)) {
        ($key, $val) = ($pair =~ /^\s*(\S+)\s*:\s*(.*)\s*$/);
        push (@atts, $key, $val);
    }
    @atts;
}

sub unitecolumns {
    my @entries = @_;
    my %h = {};
    my ($entry, $attr);

    foreach $entry (@entries) {
        foreach $attr ($entry->attributes) {
            $h{$attr} = 1;
        }
    }

    return keys %h;
}

sub trans {
    my @p = @_;
    my @t;

    push(@t, shift @p);
    foreach (@p) {
        push(@t, &HTML::HTPL::Lib::trim($_));
    }

    return @t;
}

1;
