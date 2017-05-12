package XML::Validator::Schema::SimpleType;
use strict;
use warnings;


=item NAME

XML::Validator::Schema::SimpleType

=head1 DESCRIPTION

XML Schema simple type system.  This module provides objects and class
methods to support simple types.  For complex types see the ModelNode
class.

=head1 USAGE

  # create a new anonymous type based on an existing type
  my $type = $string->derive();

  # create a new named type based on an existing type
  my $type = $string->derive(name => 'myString');

  # add a restriction
  $type->restrict(enumeration => "10");

  # check a value against a type
  ($ok, $msg) = $type->check($value);

=cut

use Carp qw(croak);
use XML::Validator::Schema::Util qw(XSD _err);

# facet support bit-patterns
use constant LENGTH         => 0b0000000000000001;
use constant MINLENGTH      => 0b0000000000000010;
use constant MAXLENGTH      => 0b0000000000000100;
use constant PATTERN        => 0b0000000000001000;
use constant ENUMERATION    => 0b0000000000010000;
use constant WHITESPACE     => 0b0000000000100000;
use constant MAXINCLUSIVE   => 0b0000000001000000;
use constant MAXEXCLUSIVE   => 0b0000000010000000;
use constant MININCLUSIVE   => 0b0000000100000000;
use constant MINEXCLUSIVE   => 0b0000001000000000;
use constant TOTALDIGITS    => 0b0000010000000000;
use constant FRACTIONDIGITS => 0b0000100000000000;

# hash mapping names to values
our %FACET = (length         => LENGTH,
              minLength      => MINLENGTH,
              maxLength      => MAXLENGTH,    
              pattern        => PATTERN,    
              enumeration    => ENUMERATION,
              whiteSpace     => WHITESPACE,  
              maxInclusive   => MAXINCLUSIVE,  
              maxExclusive   => MAXEXCLUSIVE, 
              minInclusive   => MININCLUSIVE, 
              minExclusive   => MINEXCLUSIVE, 
              totalDigits    => TOTALDIGITS, 
              fractionDigits => FRACTIONDIGITS);

# initialize builtin types
our %BUILTIN;

# create the primitive types
$BUILTIN{string} = __PACKAGE__->new(name   => 'string',
                                    facets => LENGTH|MINLENGTH|MAXLENGTH|
                                              PATTERN|ENUMERATION|WHITESPACE,
                                   );

$BUILTIN{boolean} = __PACKAGE__->new(name   => 'boolean',
                                     facets => PATTERN|WHITESPACE,
                                    );
$BUILTIN{boolean}->restrict(enumeration => "1",
                            enumeration => "0",
                            enumeration => "true",
                            enumeration => "false");

$BUILTIN{decimal} = __PACKAGE__->new(name   => 'decimal',
                                     facets => TOTALDIGITS|FRACTIONDIGITS|
                                               PATTERN|WHITESPACE|
                                               #ENUMERATION|
                                               MAXINCLUSIVE|MAXEXCLUSIVE|
                                               MININCLUSIVE|MINEXCLUSIVE,
                                    );
$BUILTIN{decimal}->restrict(pattern => qr/^[+-]?(?:(?:\d+(?:\.\d+)?)|(?:\.\d+))$/);

$BUILTIN{dateTime} = __PACKAGE__->new(name   => 'dateTime', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{dateTime}->restrict(pattern => qr/^[-+]?(\d{4,})-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:(?:Z)|(?:[-+]\d{2}:\d{2}))?$/);

$BUILTIN{float} = __PACKAGE__->new(name => 'float',
                                    facets => PATTERN|WHITESPACE,
                                              #|ENUMERATION|
                                              #MAXINCLUSIVE|MAXEXCLUSIVE|
                                              #MININCLUSIVE|MINEXCLUSIVE);
                                   );

$BUILTIN{float}->restrict(pattern => 
     qr/^[+-]?(?:(?:INF)|(?:NaN)|(?:\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?)$/);

$BUILTIN{double} = __PACKAGE__->new(name => 'double',
                                    facets => PATTERN|WHITESPACE,
                                              #|ENUMERATION|
                                              #MAXINCLUSIVE|MAXEXCLUSIVE|
                                              #MININCLUSIVE|MINEXCLUSIVE);
                                   );

$BUILTIN{double}->restrict(pattern => 
     qr/^[+-]?(?:(?:INF)|(?:NaN)|(?:\d+(?:\.\d+)?)(?:[eE][+-]?\d+)?)$/);

$BUILTIN{duration} = __PACKAGE__->new(name => 'duration',
                                    facets => PATTERN|WHITESPACE,);
#facets => PATTERN|WHITESPACE|ENUMERATION|MAXINCLUSIVE|MAXEXCLUSIVE|MININCLUSIVE|MINEXCLUSIVE);
                                   
# thanks to perlmonk Abigail-II
$BUILTIN{duration}->restrict(pattern => qr /^-? # Optional leading minus.
              P                            # Required.
              (?=[T\d])                    # Duration cannot be empty.
           (?:(?!-) \d+ Y)?      # Non-negative integer, Y (optional)
           (?:(?!-) \d+ M)?      # Non-negative integer, M (optional)
           (?:(?!-) \d+ D)?      # Non-negative integer, D (optional)
	(
           (?:T (?=\d)           # T, must be followed by a digit.
           (?:(?!-) \d+ H)?      # Non-negative integer, H (optional)
           (?:(?!-) \d+ M)?      # Non-negative integer, M (optional)
           (?:(?!-) \d+\.\d+ S)?  # Non-negative decimal, S (optional)
           )?                              # Entire T part is optional
	)$/x);

$BUILTIN{time} = __PACKAGE__->new(name   => 'time', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{time}->restrict(pattern => 
	qr /^[0-2]\d:[0-5]\d:[0-5]\d(\.\d+)?(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/);

$BUILTIN{date} = __PACKAGE__->new(name   => 'date', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{date}->restrict(pattern => 
	qr /^[-]?(\d{4,})-(\d\d)-(\d\d)(??{ _validate_date($1,$2,$3) })(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/);
		

$BUILTIN{gYearMonth} = __PACKAGE__->new(name   => 'gYearMonth', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{gYearMonth}->restrict(pattern => 
	qr /^[-]?(\d{4,})-(1[0-2]{1}|0\d{1})(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/);

$BUILTIN{gYear} = __PACKAGE__->new(name   => 'gYear', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{gYear}->restrict(pattern => 
	qr /^[-]?(\d{4,})(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/);

$BUILTIN{gMonthDay} = __PACKAGE__->new(name   => 'gMonthDay', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{gMonthDay}->restrict(pattern => 
	qr /^--(\d{2,})-(\d\d)(??{_validate_date(1999,$1,$2)})(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/ );

$BUILTIN{gDay} = __PACKAGE__->new(name   => 'gDay', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{gDay}->restrict(pattern => 
	qr /^---([0-2]\d{1}|3[0|1])(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/ );

$BUILTIN{gMonth} = __PACKAGE__->new(name   => 'gMonth', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{gMonth}->restrict(pattern => 
	qr /^--(0\d|1[0-2])(Z?|([+|-]([0-1]\d|2[0-4])\:([0-5]\d))?)$/ );

$BUILTIN{hexBinary} = __PACKAGE__->new(name   => 'hexBinary', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{hexBinary}->restrict(pattern => 
	qr /^([0-9a-fA-F][0-9a-fA-F])+$/);


$BUILTIN{base64Binary} = __PACKAGE__->new(name   => 'base64Binary', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{base64Binary}->restrict(pattern => 
	qr /^([0-9a-zA-Z\+\\\=][0-9a-zA-Z\+\\\=])+$/);

$BUILTIN{anyURI} = __PACKAGE__->new(name   => 'anyURI',
                                    facets => LENGTH|MINLENGTH|MAXLENGTH|
                                              PATTERN|ENUMERATION|WHITESPACE,
                                   );

$BUILTIN{QName} = __PACKAGE__->new(name   => 'QName', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{QName}->restrict(pattern => 
	qr /^([A-z][A-z0-9]+:)?([A-z][A-z0-9]+)$/);

$BUILTIN{NOTATION} = __PACKAGE__->new(name   => 'NOTATION', 
                                      facets => PATTERN|WHITESPACE
                                                #|ENUMERATION|
                                                #MAXINCLUSIVE|MAXEXCLUSIVE|
                                                #MININCLUSIVE|MINEXCLUSIVE,
                                     );
$BUILTIN{NOTATION}->restrict(pattern => 
	qr /^([A-z][A-z0-9]+:)?([A-z][A-z0-9]+)$/);

# create derived types
$BUILTIN{integer} = $BUILTIN{decimal}->derive(name => 'integer');
$BUILTIN{integer}->restrict(pattern => qr/^[+-]?\d+$/);

# http://www.w3.org/TR/2000/CR-xmlschema-2-20001024/#nonPositiveInteger
$BUILTIN{nonPositiveInteger} = $BUILTIN{integer}->derive(name => 'nonPositiveInteger');
$BUILTIN{nonPositiveInteger}->restrict( maxInclusive => 0 );

# http://www.w3.org/TR/2000/CR-xmlschema-2-20001024/#nonNegativeInteger
$BUILTIN{nonNegativeInteger} = $BUILTIN{integer}->derive(name => 'nonNegativeInteger');
$BUILTIN{nonNegativeInteger}->restrict( minInclusive => 0 );

# http://www.w3.org/TR/2000/CR-xmlschema-2-20001024/#positiveInteger
$BUILTIN{positiveInteger} = $BUILTIN{nonNegativeInteger}->derive(name => 'positiveInteger');
$BUILTIN{positiveInteger}->restrict( minInclusive => 1 );

# http://www.w3.org/TR/2000/CR-xmlschema-2-20001024/#negativeInteger
$BUILTIN{negativeInteger} = $BUILTIN{nonPositiveInteger}->derive(name => 'negativeInteger');
$BUILTIN{negativeInteger}->restrict( maxInclusive => -1 );

$BUILTIN{int} = $BUILTIN{integer}->derive(name => 'int');
$BUILTIN{int}->restrict(minInclusive => -2147483648, 
                        maxInclusive => 2147483647);

$BUILTIN{unsignedInt} = $BUILTIN{integer}->derive(name => 'unsignedInt');
$BUILTIN{unsignedInt}->restrict(minInclusive => 0,
                                maxInclusive => 4294967295);

$BUILTIN{short} = $BUILTIN{int}->derive(name => 'short');
$BUILTIN{short}->restrict(minInclusive => -32768,
                        maxInclusive => 32767);

$BUILTIN{unsignedShort} = $BUILTIN{unsignedInt}->derive(name => 
                                                        'unsignedShort');
$BUILTIN{unsignedShort}->restrict(maxInclusive => 65535);

$BUILTIN{byte} = $BUILTIN{short}->derive(name => 'byte');
$BUILTIN{byte}->restrict(minInclusive => -128,
                         maxInclusive => 127);

$BUILTIN{unsignedByte} = $BUILTIN{unsignedShort}->derive(name => 
                                                         'unsignedByte');
$BUILTIN{unsignedByte}->restrict(maxInclusive => 255);

$BUILTIN{normalizedString} = $BUILTIN{string}->derive(name => 
                                                      'normalizedString');
$BUILTIN{normalizedString}->restrict(whiteSpace => 'replace');

$BUILTIN{token} = $BUILTIN{normalizedString}->derive(name => 'token');
$BUILTIN{token}->restrict(whiteSpace => 'collapse');

$BUILTIN{NMTOKEN} = $BUILTIN{token}->derive(name => 'NMTOKEN');
$BUILTIN{NMTOKEN}->restrict(pattern => qr/^[-.:\w\d]*$/);

######################
# SimpleType methods #
######################

# create a new type, filing in the library if named
sub new {
    my ($pkg, %arg) = @_;
    my $self = bless(\%arg, $pkg);

    return $self;
}

# create a type derived from this type
sub derive {
    my ($self, @opt) = @_;

    my $sub = ref($self)->new(@opt);
    $sub->{base} = $self;

    return $sub;
}

sub restrict {
    my $self = shift;
    my $root = $self->root;

    while (@_) {
        my ($key, $value) = (shift, shift);
        
        
        # is this a legal restriction? (base types can do whatever they want
        _err("Found illegal restriction '$key' on type derived from '$root->{name}'.")
          unless ($self == $root) or 
                 ($FACET{$key} & $root->{facets});

        push @{$self->{restrict}{$key} ||= []}, $value;
    }
}

# returns the ultimate base type for this type
sub root {
    my $self = shift;
    my $p = $self;
    while ($p->{base}) {
        $p = $p->{base};
    }
    return $p;
}

sub normalize_ws {
    my ($self, $value) = @_;
    
    if ($self->{restrict}{whiteSpace}) {
        my $ws = $self->{restrict}{whiteSpace}[0];
        if ($ws eq 'replace') {
            $value =~ s![\t\n\r]! !g;            
        } elsif ($ws eq 'collapse') {
            $value =~ s!\s+! !g;
            $value =~ s!^\s!!g;
            $value =~ s!\s$!!g;
        }
        return $value;
    }
    return $self->{base}->normalize_ws($value) if $self->{base};
    return $value;
}

sub check {
    my ($self, $value) = @_;
    my $root = $self->root;
    my ($ok, $msg);

    # first deal with whitespace, necessary before applying facets
    $value = $self->normalize_ws($value);

    # first check base restrictions
    if ($self->{base}) {
        ($ok, $msg) = $self->{base}->check($value);
        return ($ok, $msg) unless $ok;
    }

    # check various constraints
    my $r = $self->{restrict};

    if ($r->{length}) {
        foreach my $len (@{$r->{length}}) {         
            return (0, "is not exactly $len characters.")
              unless length($value) eq $len;
        }
    }

    if ($r->{maxLength}) {
        foreach my $len (@{$r->{maxLength}}) {         
            return (0, "is longer than maximum $len characters.")
              if length($value) > $len;
        }
    }

    if ($r->{minLength}) {
        foreach my $len (@{$r->{minLength}}) {         
            return (0, "is shorter than minimum $len characters.")
              if length($value) < $len;
        }
    }

    if ($r->{enumeration}) {
        return (0, 'not in allowed list (' . 
                   join(', ', @{$r->{enumeration}}) . ')')
          unless grep { $_ eq $value } (@{$r->{enumeration}});
    }

    if ($r->{pattern}) {
        my $pass = 0;
        foreach my $pattern (@{$r->{pattern}}) {
            if ($value =~ /$pattern/) {
                $pass = 1;
                last;
            }
        }
        return (0, "does not match required pattern.")
          unless $pass;
    }

    if ($r->{minInclusive}) {
        foreach my $min (@{$r->{minInclusive}}) {
            return (0, "is below minimum (inclusive) allowed, $min")
              if $value < $min;
        }
    }

    if ($r->{minExclusive}) {
        foreach my $min (@{$r->{minExclusive}}) {
            return (0, "is below minimum allowed, $min")
              if $value <= $min;
        }
    }

    if ($r->{maxInclusive}) {
        foreach my $max (@{$r->{maxInclusive}}) {
            return (0, "is above maximum (inclusive) allowed, $max")
              if $value > $max;
        }
    }

    if ($r->{maxExclusive}) {
        foreach my $max (@{$r->{maxExclusive}}) {
            return (0, "is above maximum allowed, $max")
              if $value >= $max;
        }
    }

    if ($r->{totalDigits} or $r->{fractionDigits}) {
        # strip leading and trailing zeros for numeric constraints
        (my $digits = $value) =~ s/^([+-]?)0*(\d*\.?\d*?)0*$/$1$2/g;

        if ($r->{totalDigits}) {
            foreach my $tdigits (@{$r->{totalDigits}}) {
                return (0, "has more total digits than allowed, $tdigits")
                  if $digits =~ tr!0-9!! > $tdigits;
            }
        }

        if ($r->{fractionDigits}) {
            foreach my $fdigits (@{$r->{fractionDigits}}) {
                return (0, "has more fraction digits than allowed, $fdigits")
                  if $digits =~ /\.\d{$fdigits}\d/;
            }
        }
    }

    return (1);
}

#
# begin code taken from Date::Simple
#

my @days_in_month = ([0,31,28,31,30,31,30,31,31,30,31,30,31],
                     [0,31,29,31,30,31,30,31,31,30,31,30,31]);

sub _validate_date {
    my ($y, $m, $d)= @_;

    # any +ve integral year is valid
    return q{(?!)} if $y != abs int $y;
    return q{(?!)} unless 1 <= $m and $m <= 12;
    return q{(?!)} unless 1 <= $d and $d <=$days_in_month[_leap_year($y)][$m];

    # perl 5.10.0 choked on (?=) here, switching to just returning
    # nothing, which should also always match.
    return '';
}

sub _leap_year {
    my $y = shift;
    return (($y%4==0) and ($y%400==0 or $y%100!=0)) || 0;
}

#
# end code taken from Date::Simple
#

1;
