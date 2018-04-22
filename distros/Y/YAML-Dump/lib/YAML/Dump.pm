package YAML::Dump; # adapted from YAML::Tiny 1.73
use 5.010; # this is where I want to start from
use strict;
# use warnings; # disabled in modules
{ our $VERSION = '1.84'; }

use B;
use Scalar::Util qw< blessed refaddr >;
use Exporter qw< import >;

our @EXPORT_OK = qw{ Dump INDENT };

use constant INDENT => '  ';

sub Dump { return YAML::Dump->new(@_)->_dump_string; }

sub new { my $class = shift; bless [ @_ ], $class; }

sub dumper_for_objects {  # support for dumping booleans
   my $self = shift;

   # try to look for booleans
   if (my $line = $self->_tentative_dumper_for_boolean(@_)) {
      return $line;
   }

   # check derived class or monkey patching
   if ($self->can('dumper_for_unknown')) {
      my @retval = $self->dumper_for_unknown(@_);
      return @retval unless (@retval == 1) && ref($retval[0]);
      my (undef, $line, $indent, $seen) = @_;
      my $type = ref $retval[0];
      my @lines =
           ($type eq 'ARRAY') ? $self->_dump_array($retval[0], $indent, $seen)
         : ($type eq 'HASH') ?  $self->_dump_hash($retval[0], $indent, $seen)
         : die \"YAML::Dump does not support $type references";
      if ($line =~ m{-\s*$}mxs) {
         substr $lines[0], 0, length($line), $line;
         return @lines;
      }
      else {
         return $line, @lines;
      }
   }

   # last resort... complain loudly
   my $type = ref $_[0];
   die \"YAML::Dump does not support $type references";
}

sub _tentative_dumper_for_boolean {
   my ($self, $element, $line, $indent, $seen) = @_;

   if (blessed $element) {
      state $boolean_candidates = [
         'JSON::PP::Boolean',
         'boolean',
         'JSON::XS::Boolean',
         'Types::Serialiser::Boolean',  # should not be needed
         'Mojo::JSON::_Bool',           # only up to Mojolicious 6.21
      ];
      for my $boolean (@$boolean_candidates) {
         next unless $element->isa($boolean);
         return $line . ($element ? ' true' : ' false');
      }
   }
   elsif ((ref($element) eq 'SCALAR') && defined($$element)
          && (ref(my $bo = B::svref_2object($element)) eq 'B::IV'))
   {
      my $value = $bo->int_value;
      return $line . ' false' if $value == 0;
      return $line . ' true'  if $value == 1;
   }

   return;
}

#####################################################################
# Constants

# Printed form of the unprintable characters in the lowest range
# of ASCII characters, listed by ASCII ordinal position.
my @UNPRINTABLE = qw(
    0    x01  x02  x03  x04  x05  x06  a
    b    t    n    v    f    r    x0E  x0F
    x10  x11  x12  x13  x14  x15  x16  x17
    x18  x19  x1A  e    x1C  x1D  x1E  x1F
);

# Printable characters for escapes
my %UNESCAPES = (
    0 => "\x00", z => "\x00", N    => "\x85",
    a => "\x07", b => "\x08", t    => "\x09",
    n => "\x0a", v => "\x0b", f    => "\x0c",
    r => "\x0d", e => "\x1b", '\\' => '\\',
);

# These 3 values have special meaning when unquoted and using the
# default YAML schema. They need quotes if they are strings.
my %QUOTE = map { $_ => 1 } qw{ null true false };


#####################################################################
# YAML::Tiny Implementation.
#
# These are the private methods that do all the work. They may change
# at any time, most probably as a result of changes in YAML::Tiny

# Save an object to a string
sub _dump_string {
    my $self = shift;
    return '' unless ref $self && @$self;

    # Iterate over the documents
    my $indent = 0;
    my @lines  = ();

    eval {
        foreach my $cursor ( @$self ) {
            push @lines, '---';

            # An empty document
            if ( ! defined $cursor ) {
                # Do nothing

            # A scalar document
            } elsif ( ! ref $cursor ) {
                $lines[-1] .= ' ' . $self->_dump_scalar( $cursor );

            # A list at the root
            } elsif ( ref $cursor eq 'ARRAY' ) {
                unless ( @$cursor ) {
                    $lines[-1] .= ' []';
                    next;
                }
                push @lines, $self->_dump_array( $cursor, $indent, {} );

            # A hash at the root
            } elsif ( ref $cursor eq 'HASH' ) {
                unless ( %$cursor ) {
                    $lines[-1] .= ' {}';
                    next;
                }
                push @lines, $self->_dump_hash( $cursor, $indent, {} );

            } else {
                my @objs = $self->dumper_for_objects( $cursor, '', $indent, {} );
                if (@objs == 1) {
                  $lines[-1] .= $objs[0];
                }
                else {
                  push @lines, @objs;
                }
            }
        }
    };
    if ( ref $@ eq 'SCALAR' ) {
        $self->_error(${$@});
    } elsif ( $@ ) {
        $self->_error($@);
    }

    join '', map { "$_\n" } @lines;
}

sub _has_internal_string_value {
    my $value = shift;
    my $b_obj = B::svref_2object(\$value);  # for round trip problem
    return $b_obj->FLAGS & B::SVf_POK();
}

sub _dump_scalar {
    my $string = $_[1];
    my $is_key = $_[2];
    # Check this before checking length or it winds up looking like a string!
    my $has_string_flag = _has_internal_string_value($string);
    return '~'  unless defined $string;
    return "''" unless length  $string;
    if (Scalar::Util::looks_like_number($string)) {
        # keys and values that have been used as strings get quoted
        if ( $is_key || $has_string_flag ) {
            return qq['$string'];
        }
        else {
            return $string;
        }
    }
    if ( $string =~ /[\x00-\x09\x0b-\x0d\x0e-\x1f\x7f-\x9f\'\n]/ ) {
        $string =~ s/\\/\\\\/g;
        $string =~ s/"/\\"/g;
        $string =~ s/\n/\\n/g;
        $string =~ s/[\x85]/\\N/g;
        $string =~ s/([\x00-\x1f])/\\$UNPRINTABLE[ord($1)]/g;
        $string =~ s/([\x7f-\x9f])/'\x' . sprintf("%X",ord($1))/ge;
        return qq|"$string"|;
    }
    if ( $string =~ /(?:^[~!@#%&*|>?:,'"`{}\[\]]|^-+$|\s|:\z)/ or
        $QUOTE{$string}
    ) {
        return "'$string'";
    }
    return $string;
}

sub _dump_array {
    my ($self, $array, $indent, $seen) = @_;
    if ( $seen->{refaddr($array)}++ ) {
        die \"YAML::Dump does not support circular references";
    }
    my @lines  = ();
    foreach my $el ( @$array ) {
        my $line = (INDENT x $indent) . '-';
        my $type = ref $el;
        if ( ! $type ) {
            $line .= ' ' . $self->_dump_scalar( $el );
            push @lines, $line;

        } elsif ( $type eq 'ARRAY' ) {
            if ( @$el ) {
                push @lines, $line;
                push @lines, $self->_dump_array( $el, $indent + 1, $seen );
            } else {
                $line .= ' []';
                push @lines, $line;
            }

        } elsif ( $type eq 'HASH' ) {
            if ( keys %$el ) {
                my $first = @lines;
                push @lines, $self->_dump_hash( $el, $indent + 1, $seen );
                substr $lines[$first], 0, length($line), $line;
            } else {
                $line .= ' {}';
                push @lines, $line;
            }

        } else {
            push @lines, $self->dumper_for_objects($el, $line, $indent + 1, $seen);
        }
    }
    $seen->{refaddr($array)}--;

    @lines;
}

sub _dump_hash {
    my ($self, $hash, $indent, $seen) = @_;
    if ( $seen->{refaddr($hash)}++ ) {
        die \"YAML::Dump does not support circular references";
    }
    my @lines  = ();
    foreach my $name ( sort keys %$hash ) {
        my $el   = $hash->{$name};
        my $line = (INDENT x $indent) . $self->_dump_scalar($name, 1) . ":";
        my $type = ref $el;
        if ( ! $type ) {
            $line .= ' ' . $self->_dump_scalar( $el );
            push @lines, $line;

        } elsif ( $type eq 'ARRAY' ) {
            if ( @$el ) {
                push @lines, $line;
                push @lines, $self->_dump_array( $el, $indent + 1, $seen );
            } else {
                $line .= ' []';
                push @lines, $line;
            }

        } elsif ( $type eq 'HASH' ) {
            if ( keys %$el ) {
                push @lines, $line;
                push @lines, $self->_dump_hash( $el, $indent + 1, $seen );
            } else {
                $line .= ' {}';
                push @lines, $line;
            }

        } else {
            push @lines, $self->dumper_for_objects($el, $line, $indent + 1, $seen);
        }
    }
    $seen->{refaddr($hash)}--;

    @lines;
}

sub _error {
    my $errstr = $_[1];
    $errstr =~ s/ at \S+ line \d+.*//;
    require Carp;
    Carp::croak( $errstr );
}

1;
