package Wildling::Json;

use strict;
use warnings;

# Minimal JSON parser for wildling template files (core Perl only).

{
    package Wildling::Json::Bool;
    use overload
      'bool'   => sub { ${ $_[0] } },
      '""'     => sub { ${ $_[0] } ? 'true' : 'false' },
      fallback => 1;
}

our $TRUE  = bless \( my $true  = 1 ), 'Wildling::Json::Bool';
our $FALSE = bless \( my $false = 0 ), 'Wildling::Json::Bool';

sub is_true {
    my ($value) = @_;
    return defined($value) && ref($value) && $value->isa('Wildling::Json::Bool') && $$value;
}

sub parse {
    my ($text) = @_;
    my $parser = Wildling::Json::_Parser->new($text);
    my $value  = $parser->parse_value();
    $parser->skip_whitespace();
    if ( $parser->{pos} != length( $parser->{text} ) ) {
        die "Unexpected trailing JSON content\n";
    }
    return $value;
}

sub parse_object {
    my ($text) = @_;
    my $value = parse($text);
    if ( !( ref($value) eq 'HASH' ) ) {
        die "Template root must be a JSON object\n";
    }
    return $value;
}

package Wildling::Json::_Parser;

use strict;
use warnings;

sub new {
    my ( $class, $text ) = @_;
    return bless { text => $text, pos => 0 }, $class;
}

sub skip_whitespace {
    my ($self) = @_;
    while ( $self->{pos} < length( $self->{text} ) ) {
        my $c = substr( $self->{text}, $self->{pos}, 1 );
        if ( $c eq ' ' || $c eq "\n" || $c eq "\r" || $c eq "\t" ) {
            $self->{pos}++;
        }
        else {
            return;
        }
    }
}

sub peek {
    my ( $self, $expected ) = @_;
    return $self->{pos} < length( $self->{text} )
      && substr( $self->{text}, $self->{pos}, 1 ) eq $expected;
}

sub expect {
    my ( $self, $expected ) = @_;
    $self->skip_whitespace();
    if ( !$self->peek($expected) ) {
        die "Expected '$expected' at $self->{pos}\n";
    }
    $self->{pos}++;
}

sub parse_string {
    my ($self) = @_;
    $self->expect('"');
    my $out = '';
    while ( $self->{pos} < length( $self->{text} ) ) {
        my $c = substr( $self->{text}, $self->{pos}, 1 );
        $self->{pos}++;
        if ( $c eq '"' ) {
            return $out;
        }
        if ( $c eq '\\' ) {
            if ( $self->{pos} >= length( $self->{text} ) ) {
                die "Unterminated escape\n";
            }
            my $esc = substr( $self->{text}, $self->{pos}, 1 );
            $self->{pos}++;
            if ( $esc eq '"' || $esc eq '\\' || $esc eq '/' ) {
                $out .= $esc;
            }
            elsif ( $esc eq 'b' ) {
                $out .= "\b";
            }
            elsif ( $esc eq 'f' ) {
                $out .= "\f";
            }
            elsif ( $esc eq 'n' ) {
                $out .= "\n";
            }
            elsif ( $esc eq 'r' ) {
                $out .= "\r";
            }
            elsif ( $esc eq 't' ) {
                $out .= "\t";
            }
            elsif ( $esc eq 'u' ) {
                if ( $self->{pos} + 4 > length( $self->{text} ) ) {
                    die "Invalid unicode escape\n";
                }
                my $hex = substr( $self->{text}, $self->{pos}, 4 );
                die "Invalid unicode escape\n" unless $hex =~ /\A[0-9a-fA-F]{4}\z/;
                $out .= chr( hex($hex) );
                $self->{pos} += 4;
            }
            else {
                die "Invalid escape \\$esc\n";
            }
        }
        else {
            $out .= $c;
        }
    }
    die "Unterminated string\n";
}

sub parse_number {
    my ($self) = @_;
    my $start = $self->{pos};
    if ( $self->peek('-') ) {
        $self->{pos}++;
    }
    while ( $self->{pos} < length( $self->{text} )
        && substr( $self->{text}, $self->{pos}, 1 ) =~ /\d/ )
    {
        $self->{pos}++;
    }
    my $is_double = 0;
    if ( $self->peek('.') ) {
        $is_double = 1;
        $self->{pos}++;
        while ( $self->{pos} < length( $self->{text} )
            && substr( $self->{text}, $self->{pos}, 1 ) =~ /\d/ )
        {
            $self->{pos}++;
        }
    }
    if ( $self->{pos} < length( $self->{text} ) ) {
        my $c = substr( $self->{text}, $self->{pos}, 1 );
        if ( $c eq 'e' || $c eq 'E' ) {
            $is_double = 1;
            $self->{pos}++;
            if ( $self->peek('+') || $self->peek('-') ) {
                $self->{pos}++;
            }
            while ( $self->{pos} < length( $self->{text} )
                && substr( $self->{text}, $self->{pos}, 1 ) =~ /\d/ )
            {
                $self->{pos}++;
            }
        }
    }
    my $raw = substr( $self->{text}, $start, $self->{pos} - $start );
    return 0 + $raw;
}

sub parse_boolean {
    my ($self) = @_;
    if ( substr( $self->{text}, $self->{pos}, 4 ) eq 'true' ) {
        $self->{pos} += 4;
        return $Wildling::Json::TRUE;
    }
    if ( substr( $self->{text}, $self->{pos}, 5 ) eq 'false' ) {
        $self->{pos} += 5;
        return $Wildling::Json::FALSE;
    }
    die "Invalid boolean at $self->{pos}\n";
}

sub parse_null {
    my ($self) = @_;
    if ( substr( $self->{text}, $self->{pos}, 4 ) eq 'null' ) {
        $self->{pos} += 4;
        return undef;
    }
    die "Invalid null at $self->{pos}\n";
}

sub parse_array {
    my ($self) = @_;
    $self->expect('[');
    my @array;
    $self->skip_whitespace();
    if ( $self->peek(']') ) {
        $self->{pos}++;
        return \@array;
    }
    while (1) {
        push @array, $self->parse_value();
        $self->skip_whitespace();
        if ( $self->peek(']') ) {
            $self->{pos}++;
            return \@array;
        }
        $self->expect(',');
    }
}

sub parse_object {
    my ($self) = @_;
    $self->expect('{');
    my %obj;
    $self->skip_whitespace();
    if ( $self->peek('}') ) {
        $self->{pos}++;
        return \%obj;
    }
    while (1) {
        $self->skip_whitespace();
        my $key = $self->parse_string();
        $self->skip_whitespace();
        $self->expect(':');
        $obj{$key} = $self->parse_value();
        $self->skip_whitespace();
        if ( $self->peek('}') ) {
            $self->{pos}++;
            return \%obj;
        }
        $self->expect(',');
    }
}

sub parse_value {
    my ($self) = @_;
    $self->skip_whitespace();
    if ( $self->{pos} >= length( $self->{text} ) ) {
        die "Unexpected end of JSON\n";
    }
    my $c = substr( $self->{text}, $self->{pos}, 1 );
    if ( $c eq '{' ) {
        return $self->parse_object();
    }
    elsif ( $c eq '[' ) {
        return $self->parse_array();
    }
    elsif ( $c eq '"' ) {
        return $self->parse_string();
    }
    elsif ( $c eq 't' || $c eq 'f' ) {
        return $self->parse_boolean();
    }
    elsif ( $c eq 'n' ) {
        return $self->parse_null();
    }
    elsif ( $c eq '-' || $c =~ /\d/ ) {
        return $self->parse_number();
    }
    die "Unexpected character at $self->{pos}\n";
}

1;
