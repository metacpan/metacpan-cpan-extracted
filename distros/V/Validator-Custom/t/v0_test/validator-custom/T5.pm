package T5;
use base 'Validator::Custom';

sub new {
  my $self = shift;
  
  $self->register_constraint(
    C1 => sub {
        my ($value, $args) = @_;
        
        return [1, [$value, $args]];
    },
    
    C2 => sub {
        my ($value, $args) = @_;
        
        return [0, [$value, $args]];
    },
    
    TRIM_LEAD => sub {
        my $value = shift;
        
        $value =~ s/^ +//;
        
        return [1, $value];
    },
    
    TRIM_TRAIL => sub {
        my $value = shift;
        
        $value =~ s/ +$//;
        
        return [1, $value];
    },
    
    NO_ERROR => sub {
        return [0, 'a'];
    },
    
    C3 => sub {
        my ($values, $args) = @_;
        if ($values->[0] == $values->[1] && $values->[0] == $args->[0]) {
            return 1;
        }
        else {
            return 0;
        }
    },
    C4 => sub {
        my ($value, $arg) = @_;
        return defined $arg ? 1 : 0;
    },
    C5 => sub {
        my ($value, $arg) = @_;
        return [1, $arg];
    },
    C6 => sub {
        my $self = $_[2];
        return [1, $self];
    }
  );
  
  return $self;
}

1;
