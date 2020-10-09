package Tie::ListKeyedHash;

use strict;
use warnings;

BEGIN {
    $Tie::ListKeyedHash::VERSION = "1.03";
}

my $func_table = {}; # storage for the anon CODE refs used for hash lookups

####

sub new {
    my $proto   = shift;
    my $package = __PACKAGE__;
    my $class;
    if (ref($proto)) {
        $class = ref($proto);
    } elsif ($proto) {
        $class = $proto;
    } else {
        $class = $package;
    }
    my $self;
    if (1 == @_) {
        $self = shift;

    } else {
        $self = {};
    }
    bless $self,$class;

    if (0 < @_) {
        require Carp;
        Carp::confess($package . '::new() - Unexpected parameters passed');
    }

    return $self;
}

####

sub TIEHASH {
    return new(@_);
}

####

sub STORE {
    my $self = shift;

    my ($key,$value) = @_;
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    return $self->put($key,$value);
}

####

sub FETCH {
    my $self = shift;

    my ($key) = @_;
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    return $self->get($key);
}

####

sub DELETE {
    my $self = shift;
    
    my ($key) = @_;
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }
    return $self->delete($key);
}

####

sub CLEAR {
    my $self = shift;

    return $self->clear;
}

####

sub EXISTS {
    my $self = shift;

    my ($key) = @_;
    if (not ref $key) {
        $key = [split(/$;/,$key)];
    }

    return $self->exists($key);
}

####

sub FIRSTKEY {
    my $self = shift;
    
    my $a = keys %{$self}; # Resets the 'each' to the start
    my $key = scalar each %{$self};
    return if (not defined $key);
    return [$key];
}

####

sub NEXTKEY {
    my $self = shift;

    my ($last_key) = @_;
    my $key = scalar each %{$self};
    return if (not defined $key);
    return [$key];
}

####

sub clear {
    my ($self) = shift;

    %$self = ();
}

####

sub exists {
    my ($self) = shift;

    my ($data_ref) = @_;

    my @data = eval { @$data_ref; };
    if ($@) {
        require Carp;
        Carp::confess("bad key passed to exists");
    }

    # Its _OK_ if the hash element doesn't exist
    no warnings;

    if ($#data == 0) {
        return CORE::exists $$self{$data[0]};
    } elsif ($#data == 1) {
        return CORE::exists $$self{$data[0]}{$data[1]};
    } elsif ($#data > 12) {
        my $anon_sub = $func_table->{-func_index}->{-exists}->[$#data];
        unless (defined $anon_sub) {
            my $lookup = '$$self';
            my $count;
            for ($count=0;$count<=$#data;$count++) {
                $lookup .= '{$$dataref[' . $count . ']}';
            }
            $lookup =<<"EOF";
sub {
my (\$self,\$dataref) = \@_;
return CORE::exists ($lookup);
};
EOF
            $anon_sub = eval ($lookup);
            $func_table->{-func_index}->{-exists}->[$#data] = $anon_sub;
        }
        return $self->$anon_sub(\@data);
    } elsif ($#data == 2) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]};
    } elsif ($#data == 3) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]};
    } elsif ($#data == 4) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]};
    } elsif ($#data == 5) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]};
    } elsif ($#data == 6) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]};
    } elsif ($#data == 7) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]};
    } elsif ($#data == 8) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]};
    } elsif ($#data == 9) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]};
    } elsif ($#data == 10) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]};
    } elsif ($#data == 11) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]};
    } else { # if ($#data == 12) {
        return CORE::exists $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]}{$data[12]};
    }
}

####

sub get {
    my $self = shift;

    my ($data_ref) = @_;

    my @data = @$data_ref;

    # Its _OK_ if the hash element doesn't exist
    no warnings;

    if ($#data == 0) {
        return $$self{$data[0]};
    } elsif ($#data == 1) {
        return $$self{$data[0]}{$data[1]};
    } elsif ($#data > 12) {
        my $anon_sub = $func_table->{-func_index}->{-get}->[$#data];
        unless (defined $anon_sub) {
            my $lookup = '$$self';
            my $count;
            for ($count=0;$count<=$#data;$count++) {
                $lookup .= '{$$dataref[' . $count . ']}';
            }
            $lookup =<<"EOF";
sub {
my (\$self,\$dataref) = \@_;
return $lookup;
};
EOF
            $anon_sub = eval ($lookup);
            $func_table->{-func_index}->{-get}->[$#data] = $anon_sub;
        }
        return $self->$anon_sub(\@data);
    } elsif ($#data == 2) {
        return $$self{$data[0]}{$data[1]}{$data[2]};
    } elsif ($#data == 3) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]};
    } elsif ($#data == 4) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]};
    } elsif ($#data == 5) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]};
    } elsif ($#data == 6) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]};
    } elsif ($#data == 7) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]};
    } elsif ($#data == 8) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]};
    } elsif ($#data == 9) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]};
    } elsif ($#data == 10) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]};
    } elsif ($#data == 11) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]};
    } elsif ($#data == 12) {
        return $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]}{$data[12]};
    } else { # if ($#data == -1) 
        return $self;
    }
}

####

sub put {
    my $self = shift;

    my ($data_ref,$value) = @_;

    my @data = @$data_ref;

    unless (2 == @_) {
        require Carp;
        Carp::confess ("Tie::ListKeyedHash::put called without a value to set.\n");

    } elsif ($#data == 0) {
        $$self{$data[0]} = $value;

    } elsif ($#data == 1) {
        $$self{$data[0]}{$data[1]} = $value;

    } elsif ($#data > 12) {
        my $anon_sub =  $func_table->{-func_index}->{-put}->[$#data];
        unless (defined $anon_sub) {
            my $lookup = '$$self';
            my $count;
            for ($count=0;$count<=$#data;$count++) {
                $lookup .= '{$$dataref[' . $count . ']}';
            }
        $lookup =<<"EOF";
sub {
    my (\$self,\$dataref,\$valueref) = \@_;
    $lookup = \$valueref;
};
EOF
            $anon_sub = eval ($lookup);
            $func_table->{-func_index}->{-put}->[$#data] = $anon_sub;
        }
        $self->$anon_sub(\@data,$value);
    } elsif ($#data == 2) {
        $$self{$data[0]}{$data[1]}{$data[2]} = $value;
    } elsif ($#data == 3) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]} = $value;
    } elsif ($#data == 4) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]} = $value;
    } elsif ($#data == 5) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]} = $value;
    } elsif ($#data == 6) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]} = $value;
    } elsif ($#data == 7) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]} = $value;
    } elsif ($#data == 8) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]} = $value;
    } elsif ($#data == 9) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]} = $value;
    } elsif ($#data == 10) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]} = $value;
    } elsif ($#data == 11) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]} = $value;
    } elsif ($#data == 12) {
        $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]}{$data[12]} = $value;
    } else { # if ($#data == -1) 
        require Carp;
        Carp::confess ("Tie::ListKeyedHash::put called without a valid key.\n");
    }
}

####

sub delete {
    my ($self) = shift;

    my ($data_ref) = @_;

    my @data = @$data_ref;

    if ($#data == 0) {
        delete $$self{$data[0]};
    } elsif ($#data == 1) {
        delete $$self{$data[0]}{$data[1]};
    } elsif ($#data > 12) {
        my $anon_sub = $func_table->{-func_index}->{-clear}->[$#data];
        unless (defined $anon_sub) {
            my $lookup = '$$self';
            my $count;
            for ($count=0;$count<=$#data;$count++) {
                $lookup .= '{$$dataref[' . $count . ']}';
            }
            $lookup =<<"EOF";
sub {
    my (\$self,\$dataref) = \@_;
    delete $lookup;
};
EOF
            $anon_sub = eval ($lookup);
            $func_table->{-func_index}->{-clear}->[$#data] = $anon_sub;
        }
        $self->$anon_sub(\@data);
    } elsif ($#data == 2) {
        delete $$self{$data[0]}{$data[1]}{$data[2]};
    } elsif ($#data == 3) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]};
    } elsif ($#data == 4) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]};
    } elsif ($#data == 5) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]};
    } elsif ($#data == 6) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]};
    } elsif ($#data == 7) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]};
    } elsif ($#data == 8) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]};
    } elsif ($#data == 9) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]};
    } elsif ($#data == 10) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]};
    } elsif ($#data == 11) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]};
    } elsif ($#data == 12) {
        delete $$self{$data[0]}{$data[1]}{$data[2]}{$data[3]}{$data[4]}{$data[5]}{$data[6]}{$data[7]}{$data[8]}{$data[9]}{$data[10]}{$data[11]}{$data[12]};
    } else { # if ($#data < 0) That is what 'clear' is for ;)
        require Carp;
        Carp::confess ("Tie::ListKeyedHash::_delete object field called with no fields specified.\n");
    }
}

####

sub DESTROY {}

####

1;
