package Trickster::Validator;

use strict;
use warnings;
use v5.14;

use Trickster::Exception;

sub new {
    my ($class, $rules) = @_;
    
    return bless {
        rules => $rules || {},
        errors => {},
    }, $class;
}

sub validate {
    my ($self, $data) = @_;
    
    $self->{errors} = {};
    
    for my $field (keys %{$self->{rules}}) {
        my $rules = $self->{rules}{$field};
        my $value = $data->{$field};
        
        for my $rule (@$rules) {
            my ($rule_name, @args) = ref($rule) eq 'ARRAY' ? @$rule : ($rule);
            
            my $method = "_validate_$rule_name";
            if ($self->can($method)) {
                my $error = $self->$method($field, $value, @args);
                if ($error) {
                    push @{$self->{errors}{$field}}, $error;
                }
            }
        }
    }
    
    return keys %{$self->{errors}} == 0;
}

sub errors {
    my ($self) = @_;
    return $self->{errors};
}

sub throw_if_invalid {
    my ($self) = @_;
    
    unless ($self->is_valid) {
        Trickster::Exception::BadRequest->throw(
            message => 'Validation failed',
            details => $self->errors,
        );
    }
}

sub is_valid {
    my ($self) = @_;
    return keys %{$self->{errors}} == 0;
}

# Validation rules

sub _validate_required {
    my ($self, $field, $value) = @_;
    
    return "$field is required" unless defined $value && $value ne '';
    return undef;
}

sub _validate_min {
    my ($self, $field, $value, $min) = @_;
    
    return undef unless defined $value;
    
    if ($value =~ /^\d+$/) {
        return "$field must be at least $min" if $value < $min;
    } else {
        return "$field must be at least $min characters" if length($value) < $min;
    }
    
    return undef;
}

sub _validate_max {
    my ($self, $field, $value, $max) = @_;
    
    return undef unless defined $value;
    
    if ($value =~ /^\d+$/) {
        return "$field must be at most $max" if $value > $max;
    } else {
        return "$field must be at most $max characters" if length($value) > $max;
    }
    
    return undef;
}

sub _validate_email {
    my ($self, $field, $value) = @_;
    
    return undef unless defined $value;
    
    return "$field must be a valid email" unless $value =~ /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return undef;
}

sub _validate_regex {
    my ($self, $field, $value, $pattern) = @_;
    
    return undef unless defined $value;
    
    return "$field has invalid format" unless $value =~ $pattern;
    return undef;
}

sub _validate_in {
    my ($self, $field, $value, @allowed) = @_;
    
    return undef unless defined $value;
    
    return "$field must be one of: " . join(', ', @allowed) 
        unless grep { $_ eq $value } @allowed;
    
    return undef;
}

sub _validate_numeric {
    my ($self, $field, $value) = @_;
    
    return undef unless defined $value;
    
    return "$field must be numeric" unless $value =~ /^-?\d+\.?\d*$/;
    return undef;
}

sub _validate_integer {
    my ($self, $field, $value) = @_;
    
    return undef unless defined $value;
    
    return "$field must be an integer" unless $value =~ /^-?\d+$/;
    return undef;
}

sub _validate_url {
    my ($self, $field, $value) = @_;
    
    return undef unless defined $value;
    
    return "$field must be a valid URL" 
        unless $value =~ m{^https?://[^\s/$.?#].[^\s]*$}i;
    
    return undef;
}

sub _validate_custom {
    my ($self, $field, $value, $callback) = @_;
    
    return undef unless defined $value;
    
    my $result = $callback->($value);
    return $result if $result; # Return error message if validation fails
    return undef;
}

1;

__END__

=head1 NAME

Trickster::Validator - Data validation for Trickster

=head1 SYNOPSIS

    use Trickster::Validator;
    
    my $validator = Trickster::Validator->new({
        name => ['required', ['min', 3], ['max', 50]],
        email => ['required', 'email'],
        age => ['numeric', ['min', 18]],
        role => [['in', 'admin', 'user', 'guest']],
    });
    
    if ($validator->validate($data)) {
        # Data is valid
    } else {
        my $errors = $validator->errors;
    }

=head1 DESCRIPTION

Trickster::Validator provides robust data validation with common
validation rules and custom validators.

=head1 VALIDATION RULES

=over 4

=item * required - Field must be present and non-empty

=item * min - Minimum value or length

=item * max - Maximum value or length

=item * email - Valid email format

=item * regex - Match a regular expression

=item * in - Value must be in a list

=item * numeric - Must be a number

=item * integer - Must be an integer

=item * url - Valid URL format

=item * custom - Custom validation function

=back

=cut
