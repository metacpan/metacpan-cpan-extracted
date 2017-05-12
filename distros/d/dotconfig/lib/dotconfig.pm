package dotconfig;
use strict;
use warnings;
use Carp ();
use Encode ();
use Exporter 'import';
our $VERSION = '0.04';
our @EXPORT = qw( load_config decode_config );

sub load_config {
    my ($path, $option) = @_;
    open my $fh, "<", $path or Carp::croak $!;
    my $text = Encode::decode_utf8(do { local $/; <$fh> });
    decode_config($text, $option);
}

sub new {
    my ($class, %option) = @_;
    bless {
        option => { %option },
    }, $class;
}

sub decode {
    my ($self, $text) = @_;
    decode_config($text, $self->{option});
}

sub decode_config {
    my ($text, $option) = @_;
    my $decoder = dotconfig::Decoder->new($text, $option);
    if (my $config = $decoder->config) {
        return $$config;
    } else {
        die "No value found in the config";
    }
}

# sub encode {
#     my ($self, $value) = @_;
# }
# 
# sub encode_config {
# }

package
    dotconfig::Decoder;
use strict;
use warnings;
use Math::BigInt;
use Math::BigFloat;
use JSON ();
use constant {
    DC_SPACE           => ' ',
    DC_TAB             => "\t",
    DC_LF              => "\n",
    DC_CR              => "\r",
    DC_FALSE           => 'false',
    DC_TRUE            => 'true',
    DC_NULL            => 'null',
    DC_BEGIN_ARRAY     => '[',
    DC_END_ARRAY       => ']',
    DC_BEGIN_MAP       => '{',
    DC_END_MAP         => '}',
    DC_NAME_SEPARATOR  => ':',
    DC_VALUE_SEPARATOR => ',',
    DC_QUOTATION_MARK  => '"',
    DC_ESCAPE          => '\\',
    DC_SOLIDUS         => '/',
    DC_BACKSPACE       => "\b",
    DC_FORM_FEED       => "\f",
};

sub new {
    my ($class, $text, $option) = @_;
    bless {
        tape   => $text,
        index  => 0,
        option => {
            allow_bigint => 1,
            %{$option // {}},
        },
    }, $class;
}

sub _peek {
    my ($self, $next) = @_;
    my $eos_pos = $self->{index} + ($next // 0) + 1;
    if (length $self->{tape} >= $eos_pos) {
        return substr $self->{tape}, $self->{index} + $next // 0, 1;
    }
}

sub _match_str {
    my ($self, $str) = @_;
    my $next = substr $self->{tape}, $self->{index}, length $str;
    if (length $next == length $str and $str eq $next) {
        return 1;
    }
}

sub _consume {
    my ($self, $length) = @_;
    $self->{index} += $length // 1;
}

sub _consume_if {
    my ($self, $expected) = @_;
    if ($self->_match_str($expected)) {
        $self->{index} += length $expected;
        return 1;
    }
}

sub _consume_if_space {
    my ($self, $char) = @_;
    if ( $char eq DC_SPACE
      or $char eq DC_TAB
      or $char eq DC_LF
      or $char eq DC_CR
    ) {
        $self->{index} += 1;
        return 1;
    }
}

sub config {
    my ($self, $config) = @_;

    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            next if $self->_consume_if_space($char);
            if ($char eq DC_BEGIN_MAP) {
                return $self->config(\$self->map);
            }
            elsif ($char eq DC_BEGIN_ARRAY) {
                return $self->config(\$self->array);
            }
            elsif ($char eq DC_QUOTATION_MARK) {
                return $self->config(\$self->string);
            }
            elsif ($char eq "<" and $self->_match_str("<<")) {
                return $self->config(\$self->heredoc);
            }
            elsif ($char =~ /[0-9\-]/) {
                if ($self->_match_str("0x")) {
                    return $self->config(\$self->hex);
                }
                elsif ($self->_match_str("0b")) {
                    return $self->config(\$self->binary);
                }
                elsif ($self->_match_str("0o")) {
                    return $self->config(\$self->octal);
                }
                else {
                    return $self->config(\$self->number);
                }
            }
            elsif (my $false = $self->false) {
                return $self->config($false);
            }
            elsif (my $true = $self->true) {
                return $self->config($true);
            }
            elsif (my $null = $self->null) {
                return $self->config($null);
            }
            elsif ($char eq DC_SOLIDUS) {
                if ($self->_match_str("//") or $self->_match_str("/*")) {
                    $self->comment;
                    next;
                } else {
                    die "Unexpected charcter `/`";
                }
            }
            else {
                return $config;
            }
        } else {
            last; # EOF
        }
    }

    return $config;
}

sub false { shift->_consume_if(DC_FALSE) ? \JSON::false : undef }
sub true  { shift->_consume_if(DC_TRUE)  ? \JSON::true  : undef }
sub null  { shift->_consume_if(DC_NULL)  ? \JSON::null  : undef }

sub number {
    my $self   = shift;
    my $string = "";

    # minus
    if ($self->_consume_if("-")) {
        $string .= "-";
        if (defined(my $char = $self->_peek(0))) {
            unless ($char =~ /[0-9]/) {
                die "Unexpected number format (found `$char` after `-`)";
            }
        } else {
            die "Unexpected number format (no number after `-`)";
        }
    }

    # int
    if ($self->_consume_if("0")) {
        $string .= "0";
        if (defined(my $char = $self->_peek(0))) {
            if ($char =~ /[0-9]/) {
                die "Unexpected number format (found `$char` after `0`)";
            }
        } else {
            return $string + 0;
        }
    }

    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($char =~ /[0-9.]/) { # `.` for frac
                $string .= $char;
                $self->_consume;
                next;
            } else {
                last;
            }
        } else {
            last;
        }
    }

    # exp
    if ($self->_consume_if("e") or $self->_consume_if("E")) {
        $string .= "e";
        if ($self->_consume_if("+")) {
            $string .= "+";
        } elsif ($self->_consume_if("-")) {
            $string .= "-";
        }

        my $digit_after_exp;
        while (1) {
            if (defined(my $char = $self->_peek(0))) {
                if ($char =~ /[1-9]/) {
                    $string .= $char;
                    $self->_consume;
                    $digit_after_exp = 1;
                } else {
                    last;
                }
            } else {
                last;
            }
        }

        unless ($digit_after_exp) {
            die "Unexpected number format (no digit after exp)";
        }
    }

    if ($string =~ /[.eE]/) { # is float
        return $self->{option}{allow_bigint} ? Math::BigFloat->new($string) : $string;
    } else { # is integer
        if (($string + 0) =~ /[.eE]/) {
            return $self->{option}{allow_bigint} ? Math::BigInt->new($string) : $string;
        } else {
            return $string + 0;
        }
    }
}

sub hex {
    my $self = shift;
    my $prefix  = "0x";
    $self->_consume_if($prefix)
        or die "Expected `$prefix`";

    my $string = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($char =~ /[A-F0-9]/i) {
                $string .= $char;
                $self->_consume;
                next;
            } else {
                return oct "$prefix$string";
            }
        } else {
            return oct "$prefix$string";
        }
    }
}

sub binary {
    my $self = shift;
    my $prefix  = "0b";
    $self->_consume_if($prefix)
        or die "Expected `$prefix`";

    my $string = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($char =~ /[01]/i) {
                $string .= $char;
                $self->_consume;
                next;
            } else {
                return oct "$prefix$string";
            }
        } else {
            return oct "$prefix$string";
        }
    }
}

sub octal  {
    my $self = shift;
    my $prefix  = "0o";
    $self->_consume_if($prefix)
        or die "Expected `$prefix`";

    my $string = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($char =~ /[0-7]/i) {
                $string .= $char;
                $self->_consume;
                next;
            } else {
                return oct "0$string";
            }
        } else {
            return oct "0$string";
        }
    }
}

sub comment {
    my $self = shift;
    if ($self->_match_str("//")) {
        $self->inline_comment;
    }
    elsif ($self->_match_str("/*")) {
        $self->block_comment;
    }
    else {
        die "Unexpected charcter `/`";
    }
}

sub inline_comment {
    my $self = shift;
    $self->_consume_if(DC_SOLIDUS . DC_SOLIDUS)
        or die "Expected `" . DC_SOLIDUS . DC_SOLIDUS . "`";

    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            $self->_consume;
            if ($char eq DC_LF) {
                return;
            } else {
                next;
            }
        } else {
            $self->_consume;
            return;
        }
    }
}

sub block_comment {
    my $self = shift;
    $self->_consume_if("/*")
        or die "Expected `/*`";

    while (1) {
        if ($self->_match_str("//")) {
            $self->inline_comment;
        }
        elsif ($self->_match_str("/*")) {
            $self->block_comment;
        }
        elsif ($self->_match_str("*/")) {
            $self->_consume(2);
            return;
        }
        else {
            $self->_consume;
        }
    }

}

sub string {
    my $self = shift;
    $self->_consume_if(DC_QUOTATION_MARK)
        or die "Expected `" . DC_QUOTATION_MARK . "`";

    my $string = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($char eq DC_ESCAPE) {
                if (defined(my $next_char = $self->_peek(1))) {
                    my $escapes = {
                        DC_QUOTATION_MARK() => DC_QUOTATION_MARK,
                        DC_ESCAPE()         => DC_ESCAPE,
                        DC_SOLIDUS()        => DC_SOLIDUS,
                        "b" => DC_BACKSPACE,
                        "f" => DC_FORM_FEED,
                        "n" => DC_LF,
                        "r" => DC_CR,
                        "t" => DC_TAB,
                    };
                    if (my $ch = $escapes->{$next_char}) {
                        $string .= $ch;
                        $self->_consume(2);
                        next;
                    } elsif ($next_char eq 'u') { # TODO UTF-16 support?
                        my $utf = "";
                        for (1..4) {
                            my $char = $self->_peek(1 + $_);
                            if (defined $char && $char =~ /[A-F0-9]/i) {
                                $utf .= $char;
                            } else {
                                die "Unexpected end of escaped UTF string";
                            }
                        }
                        $self->_consume(6);

                        if ((my $hex = CORE::hex $utf) > 127) {
                            $string .= pack U => $hex;
                        } else {
                            $string .= chr $hex;
                        }
                    } else {
                        die "Unexpected escape sequence";
                    }
                } else {
                    die "Unexpected end of string literal";
                }

            } elsif ($char eq DC_QUOTATION_MARK) {
                if ($self->_peek(-1) eq DC_ESCAPE) {
                    $string .= $char;
                    $self->_consume;
                    next;
                } else {
                    $self->_consume;
                    return $string;
                }
            } else {
                $string .= $char;
                $self->_consume;
                next;
            }
        } else {
            die "Unterminated string";
        }
    }
}

sub heredoc {
    my $self = shift;

    $self->_consume_if("<<")
        or die "Expected `<<`";

    my $strip_space = $self->_consume_if("-") ? 1 : 0;

    my $delimiter = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            $self->_consume;
            if ($char eq DC_SPACE or $char eq DC_TAB) {
                next;
            } elsif ($char eq DC_LF) {
                last;
            } else {
                $delimiter .= $char;
            }
        } else {
            die "Unexpected end of heredoc";
        }
    }

    my $string = "";
    while (1) {
        last if $self->_consume_if($delimiter);
        if (defined(my $char = $self->_peek(0))) {
            $self->_consume;
            $string .= $char;
            next;
        } else {
            die "Unexpected end of heredoc";
        }
    }
    chomp $string;

    if ($strip_space) {
        my @lines = split /\n/, $string;
        my $last_line = pop @lines;
        my $indent = 0;
        for (split //, $last_line) {
            $indent++ if $_ eq DC_SPACE
        }

        $string = join DC_LF, map { substr $_, $indent } @lines;
    }

    return $string;
}

sub array  {
    my $self = shift;

    $self->_consume_if(DC_BEGIN_ARRAY)
        or die "Expected `" . DC_BEGIN_ARRAY . "`";

    my $array = [];
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($self->_consume_if(DC_END_ARRAY)) {
                return $array;
            }
            elsif ($self->_consume_if(DC_VALUE_SEPARATOR)) {
                next;
            }
            else {
                if (defined(my $value = $self->config)) {
                    push @$array, $$value;
                } else {
                    next; # trailing comma is valid
                }
            }
        } else {
            return $array;
        }
    }
}

sub map {
    my $self = shift;
    $self->_consume_if(DC_BEGIN_MAP)
        or die "Expected `" . DC_BEGIN_MAP . "`";

    my $map = [];

    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            next if $self->_consume_if_space($char);
            if ($self->_match_str("//") or $self->_match_str("/*")) {
                $self->comment;
                next;
            }
            elsif ($self->_consume_if(DC_END_MAP)) {
                last;
            }
            else {
                $self->map_members($map);
                last;
            }
        } else {
            last;
        }
    }

    return { @$map };
}

sub map_members {
    use constant { map { ($_ => $_) } qw/
        STATE_KEY
        STATE_KEY_SEPARATOR
        STATE_VALUE
        STATE_VALUE_SEPARATOR
    / };

    my $self    = shift;
    my $members = shift;
    my $state   = shift // STATE_KEY;

    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            next if $self->_consume_if_space($char);
            if ($self->_match_str("//") or $self->_match_str("/*")) {
                $self->comment;
                next;
            }
            elsif ($self->_consume_if(DC_END_MAP)) {
                return;
            }
            else {
                if ($state eq STATE_KEY) {
                    if (defined(my $key = $self->map_key)) {
                        push @$members, $key;
                        $self->map_members($members, STATE_KEY_SEPARATOR);
                        return;
                    } else {
                        die "Unexpected member key name in map";
                    }
                }
                elsif ($state eq STATE_KEY_SEPARATOR) {
                    if ($self->_consume_if(DC_NAME_SEPARATOR)) {
                        $self->map_members($members, STATE_VALUE);
                        return;
                    } else {
                        die "Expected `" . DC_NAME_SEPARATOR . "` but got unexpected char at " . $self->{index};
                    }
                }
                elsif ($state eq STATE_VALUE) {
                    if (defined(my $value = $self->config)) {
                        push @$members, $$value;
                        $self->map_members($members, STATE_VALUE_SEPARATOR);
                        return;
                    } else {
                        die "Invalid value";
                    }
                }
                elsif ($state eq STATE_VALUE_SEPARATOR) {
                    if ($self->_consume_if(DC_VALUE_SEPARATOR)) {
                        $self->map_members($members, STATE_KEY);
                        return;
                    } else {
                        die "Expected `" . DC_VALUE_SEPARATOR . "` but got `$char` at " . $self->{index};
                        return;
                    }
                }
                else {
                    die "Unexpected state: `$state`";
                }
            }
        } else {
            return;
        }
    }
}

sub map_key {
    my $self = shift;

    use constant { map { ($_ => $_) } qw/
        MODE_MAP_KEY_NAKED
        MODE_MAP_KEY_QUOTED
    / };

    my $mode = $self->_match_str(DC_QUOTATION_MARK)
        ? MODE_MAP_KEY_QUOTED
        : MODE_MAP_KEY_NAKED;

    my $string = "";
    while (1) {
        if (defined(my $char = $self->_peek(0))) {
            if ($mode eq MODE_MAP_KEY_QUOTED) {
                return $self->string;
            } else {
                if ($self->_consume_if_space($char)) {
                    next;
                }
                elsif ($self->_match_str("//") or $self->_match_str("/*")) {
                    $self->comment;
                    next;
                }
                elsif ($self->_match_str(DC_NAME_SEPARATOR)) {
                    return $string;
                }
                else {
                    $string .= $char;
                    $self->_consume;
                    next;
                }
            }
        } else {
            die "Unterminated string";
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

dotconfig - deserializing dotconfig formatted file

=head1 SYNOPSIS

  use dotconfig;
  my $config = load_config("path/to/app.config");

  # or
  
  my $config = decode_config(q| { foo: "bar" } |);

=head1 DESCRIPTION

dotconfig is a deserialization library for dotconfig formatted files.

dotconfig specification is a text format for the serialization of hand-written application configurations. See also L<https://github.com/dotconfig/spec>

Serializing methods are not supported currently.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- punytan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
