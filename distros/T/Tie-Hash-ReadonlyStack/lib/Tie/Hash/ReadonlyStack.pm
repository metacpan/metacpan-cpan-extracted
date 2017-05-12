package Tie::Hash::ReadonlyStack;

# use warnings;
use strict;

$Tie::Hash::ReadonlyStack::VERSION = '0.2';

sub clear_compiled_cache {
    my ( $self, @keys ) = @_;
    
    if (@keys) {
        my $count = 0;
        for my $k (@keys) {
            if (exists $self->{'compiled'}{$k}) {
                delete $self->{'compiled'}{$k} if exists $self->{'compiled'}{$k};
                $count++;
            }
        }
        return $count if $count;
        return;
    }
    else {
        %{ $self->{'compiled'} } = (); 
        return 1;
    }
}

sub add_lookup_override_hash_without_clearing_cache {
    my ( $self, $name, $hr ) = @_;
    
    return if $name eq 'readonly_hash';
    return if exists $self->{'hashes'}{$name};

    unshift @{ $self->{'order'} }, $name;
    $self->{'hashes'}{$name} = $hr;
}

sub add_lookup_override_hash {
    my ( $self, $name, $hr ) = @_;
    
    if ( !tied(%{$hr}) ) { 
        $self->clear_compiled_cache(keys %{$hr});
    }
    else {
        for my $key ( keys %{ $self->{'compiled'} } ) {
            if ( exists $self->{'compiled'}{$key} ) {
                delete $self->{'compiled'}{$key};
            }
        }
    }
    
    return $self->add_lookup_override_hash_without_clearing_cache($name, $hr);
}

sub add_lookup_fallback_hash {
    my ( $self, $name, $hr ) = @_;
    return if $name eq 'readonly_hash';
    return if exists $self->{'hashes'}{$name};

    push @{ $self->{'order'} }, $name;
    $self->{'hashes'}{$name} = $hr;
}

sub del_lookup_hash {
    my ( $self, $name, $only_if_exists ) = @_;
    return if $name eq 'readonly_hash';
    return if $only_if_exists && !exists $self->{'hashes'}{$name};

    delete $self->{'hashes'}{$name};
    @{ $self->{'order'} } = grep { $_ ne $name } @{ $self->{'order'} };
    for my $key ( keys %{ $self->{'compiled'} } ) {
        if ( exists $self->{'compiled'}{$key}{'found_in'} && $self->{'compiled'}{$key}{'found_in'} eq $name ) {
            delete $self->{'compiled'}{$key};
        }
    }
    return 1;
}

sub get_keys_not_in_stack {
    my ($self) = @_;

    return map { !exists $self->{'compiled'}{$_}{'found_in'} ? $_ : () } keys %{ $self->{'compiled'} };
}

sub TIEHASH {
    my ( $class, $mainhash ) = @_;
    return bless {
        'compiled' => {},
        'hashes'   => { 'readonly_hash' => $mainhash },
        'order'    => ['readonly_hash']
    }, $class;
}

# tied to a read only handle (gdbm) or one you do not want updated (DBI) ?
sub STORE {
    my ( $self, $key, $val ) = @_;
    $self->{'compiled'}{$key}{'value'} = $val;
}

sub DELETE {
    my ( $self, $key ) = @_;
    return if !exists $self->{'compiled'}{$key};

    my $val = $self->{'compiled'}{$key}{'value'};

    delete $self->{'compiled'}{$key};
    return $val;
}

sub CLEAR {
    my ($self) = @_;
    delete $self->{'compiled'};

    for my $hash_name ( @{ $self->{'order'} } ) {
        next if $hash_name eq 'readonly_hash';
        untie $self->{'hashes'}{$hash_name} if tied( $self->{'hashes'}{$hash_name} );
        delete $self->{'hashes'}{$hash_name};
    }
}

sub EXISTS {
    my ( $self, $key ) = @_;

    return 1 if exists $self->{'compiled'}{$key} && exists $self->{'compiled'}{$key}{'value'};

    for my $hash_name ( @{ $self->{'order'} } ) {
        return 1 if exists $self->{'hashes'}{$hash_name}{$key};
    }

    return;
}

sub FETCH {
    my ( $self, $key ) = @_;

    return $self->{'compiled'}{$key}{'value'} if exists $self->{'compiled'}{$key} && exists $self->{'compiled'}{$key}{'value'};

    for my $hash_name ( @{ $self->{'order'} } ) {
        if ( exists $self->{'hashes'}{$hash_name}{$key} ) {
            $self->{'compiled'}{$key}{'found_in'} = $hash_name;
            $self->{'compiled'}{$key}{'value'}    = $self->{'hashes'}{$hash_name}{$key};
            return $self->{'compiled'}{$key}{'value'};
        }
    }

    return;
}

sub SCALAR {
    return scalar %{ shift->{'compiled'} };
}

sub FIRSTKEY {
    my $self = shift;
    my $c    = keys %{ $self->{'compiled'} };    # reset each() iterator
    each %{ $self->{'compiled'} };
}

sub NEXTKEY {
    return each %{ shift->{'compiled'} };
}

sub UNTIE {
    my $self = shift;
    delete $self->{'compiled'};
    for my $hash_name ( @{ $self->{'order'} } ) {
        untie $self->{'hashes'}{$hash_name} if tied( $self->{'hashes'}{$hash_name} );
        delete $self->{'hashes'}{$hash_name};
    }
    delete $self->{'order'};
    delete $self->{'hashes'};
}

# sub DESTROY {
#     my $self = shift;
# }

1;
