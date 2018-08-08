package UR::Value::Text;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Value::Text',
    is => ['UR::Value'],
);

use overload (
    '.' => \&concat,
    '""' => \&stringify,
    fallback => 1,
);

sub swap {
    my ($a, $b) = @_;
    return ($b, $a);
}

sub concat {
    my ($self, $other, $swap) = @_;
    my $class = ref $self;
    $self = $self->id;
    ($self, $other) = swap($self, $other) if $swap;
    return $class->get($self . $other);
}

sub stringify {
    my $self = shift;
    return $self->id;
}

sub capitalize {
    my $self = shift;
    my $seps = join('', ' ', @_); # allow other separators
    my $regexp = qr/[$seps]+/;
    my $capitalized_string = join(' ', map { ucfirst } split($regexp, $self->id));
    return $self->class->get($capitalized_string);
}

sub to_camel {
    my $self = shift;
    my $seps = join('', ( @_ ? @_ : ( ' ', '_' )));
    my $regexp = qr/[$seps]+/;
    my $camel_case = join('', map { ucfirst } split($regexp, $self->id));
    return $self->class->get($camel_case);
}

sub to_lemac { # camel backwards = undo camel case. This was nutters idea. Ignore 'git blame'
    my $self = shift;
    # Split on the first capital or the start of a number
    my @words = split( /(?=(?<![A-Z])[A-Z])|(?=(?<!\d)\d)/, $self->id);
    # Default join is a space
    my $join = ( defined $_[0] ) ? $_[0] : ' '; 
    return $self->class->get( join($join, map { lc } @words) );
}

sub to_hash {
    my ($self, $split) = @_; # split splits to value of a key into many values

    my $text = $self->id;
    if ( $text !~ m#^-# ) {
        $self->warning_message('Can not convert text object with id "' . $self->id . '" to hash. Text must start with a dash (-)');
        return;
    }

    my %hash;
    my @values = split(/\s?(\-{1,2}\D[\w\d\-]*)\s?/, $text);
    shift @values;
    for ( my $i = 0; $i < @values; $i += 2 ) {
        my $key = $values[$i];
        $key =~ s/^\-{1,2}//;
        if ( $key eq '' ) {
            $self->warning_message("Can not convert text ($text) to hash. Found empty dash (-).");
            return;
        }
        my $value = $values[$i + 1];
        if ( defined $value ){
            $value =~ s/\s*$//;
        }
        else {
            $value = '';
        }
        # FIXME What if the key exists? 
        if ( defined $split ) { 
            $hash{$key} = [ split($split, $value) ];
        }
        else {
            $hash{$key} = $value;
        }
    }

    #print Data::Dumper::Dumper(\@values, \%hash);
    return UR::Value::HASH->get(\%hash);
}

1;

