package Wildling::Cli;

use strict;
use warnings;

use Wildling;
use Wildling::Json;

sub parse_range {
    my ($value) = @_;
    my @parts = split /-/, $value, 2;
    return undef if @parts != 2 || $parts[0] !~ /\A\d+\z/ || $parts[1] !~ /\A\d+\z/;
    my $start  = 0 + $parts[0];
    my $finish = 0 + $parts[1];
    return $start <= $finish ? [ $start, $finish ] : undef;
}

sub load_dictionary_file {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die $!;
    local $/;
    my $content = <$fh>;
    close $fh;
    my @lines;
    for my $line ( split /\r?\n/, $content ) {
        $line =~ s/^\s+|\s+$//g;
        push @lines, $line if length $line;
    }
    return \@lines;
}

sub apply_dictionary {
    my ( $result, $name, $value ) = @_;
    if ( ref($value) eq 'ARRAY' ) {
        $result->{dictionaries}{$name} = [ map {"$_"} @$value ];
        push @{ $result->{dictionary_names} }, $name
          unless grep { $_ eq $name } @{ $result->{dictionary_names} };
        return;
    }
    return unless defined $value && !ref($value) && -e $value;
    eval {
        $result->{dictionaries}{$name} = load_dictionary_file($value);
        push @{ $result->{dictionary_names} }, $name
          unless grep { $_ eq $name } @{ $result->{dictionary_names} };
        1;
    } or do {
        # ignore unreadable dictionary files
    };
}

sub _to_nonneg_int {
    my ($val) = @_;
    return undef unless defined $val;
    if ( !ref($val) && $val =~ /\A(?:0|[1-9][0-9]*)\z/ ) {
        return 0 + $val;
    }
    if ( !ref($val) && $val =~ /\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/ ) {
        my $n = 0 + $val;
        return undef unless int($n) == $n;
        return int($n);
    }
    return undef;
}

sub apply_template {
    my ( $result, $path ) = @_;
    unless ( -e $path ) {
        print STDERR "Template file not found: $path\n";
        exit 1;
    }

    my $template;
    eval {
        open my $fh, '<:encoding(UTF-8)', $path or die $!;
        local $/;
        my $text = <$fh>;
        close $fh;
        $template = Wildling::Json::parse_object($text);
        1;
    } or do {
        print STDERR "Invalid JSON template: $path\n";
        exit 1;
    };

    $result->{check} = 1 if Wildling::Json::is_true( $template->{check} );

    my $select = $template->{select};
    if ( ref($select) eq 'ARRAY' ) {
        for my $val (@$select) {
            my $number = _to_nonneg_int($val);
            next unless defined $number;
            push @{ $result->{selects} }, $number if $number >= 0;
        }
    }

    my $ranges = $template->{range};
    if ( ref($ranges) eq 'ARRAY' ) {
        for my $range_str (@$ranges) {
            my $parsed = parse_range("$range_str");
            push @{ $result->{ranges} }, $parsed if $parsed;
        }
    }

    my $dictionaries = $template->{dictionaries};
    if ( ref($dictionaries) eq 'HASH' ) {
        for my $name ( keys %$dictionaries ) {
            my $value = $dictionaries->{$name};
            if ( !ref($value) || ref($value) eq 'ARRAY' ) {
                apply_dictionary( $result, "$name", $value );
            }
        }
    }

    my $patterns = $template->{patterns};
    if ( ref($patterns) eq 'ARRAY' ) {
        push @{ $result->{patterns} }, map {"$_"} @$patterns;
    }
}

sub parse_args {
    my ($args) = @_;
    $args ||= [];
    my $result = {
        selects           => [],
        ranges            => [],
        check             => 0,
        dictionaries      => {},
        dictionary_names  => [],
        patterns          => [],
        help              => 0,
        version           => 0,
    };
    my $i = 0;
    while ( $i < @$args ) {
        my $arg = $args->[$i];

        if ( $arg eq '--help' || $arg eq '-h' ) {
            $result->{help} = 1;
            $i++;
        }
        elsif ( $arg eq '--version' || $arg eq '-v' ) {
            $result->{version} = 1;
            $i++;
        }
        elsif ( $arg eq '--check' ) {
            $result->{check} = 1;
            $i++;
        }
        elsif ( $arg eq '--select' ) {
            $i++;
            last if $i >= @$args;
            my $number = _to_nonneg_int( $args->[$i] );
            push @{ $result->{selects} }, $number
              if defined $number && $number >= 0;
            $i++;
        }
        elsif ( $arg eq '--range' ) {
            $i++;
            last if $i >= @$args;
            my $parsed = parse_range( $args->[$i] );
            push @{ $result->{ranges} }, $parsed if $parsed;
            $i++;
        }
        elsif ( $arg eq '--dictionary' ) {
            $i++;
            last if $i >= @$args;
            my ( $name, $path ) = split /:/, $args->[$i], 2;
            apply_dictionary( $result, $name, $path )
              if defined $name && defined $path && length($name) && length($path);
            $i++;
        }
        elsif ( $arg eq '--template' ) {
            $i++;
            if ( $i >= @$args ) {
                print STDERR "Missing path for --template\n";
                exit 1;
            }
            apply_template( $result, $args->[$i] );
            $i++;
        }
        else {
            push @{ $result->{patterns} }, $arg;
            $i++;
        }
    }
    return $result;
}

sub load_help_text {
    my $here = ( caller(0) )[1];
    $here =~ s{/[^/]+\z}{};
    my @candidates = (
        "$here/help.txt",
        "$here/../../docs/help.txt",
    );

    # Also try relative to this module under lib/Wildling
    my $mod = $INC{'Wildling/Cli.pm'};
    if ($mod) {
        my $dir = $mod;
        $dir =~ s{/[^/]+\z}{};
        push @candidates, "$dir/help.txt", "$dir/../../docs/help.txt";
    }

    for my $path (@candidates) {
        if ( open my $fh, '<:encoding(UTF-8)', $path ) {
            local $/;
            my $text = <$fh>;
            close $fh;
            return $text;
        }
    }
    return "wildling - pattern based string generator\n\nHelp text unavailable.\n";
}

sub format_list {
    my ($values) = @_;
    return '' if !defined $values || !@$values;
    return ' ' . join( ' ', map {"$_"} @$values );
}

sub format_check_output {
    my ( $args, $total, $generators ) = @_;
    my @range_strs =
      map { $_->[0] . '-' . $_->[1] } @{ $args->{ranges} };
    my @lines = (
        'patterns:' . format_list( $args->{patterns} ),
        'dictionaries:' . format_list( $args->{dictionary_names} ),
        'select:' . format_list( $args->{selects} ),
        'range:' . format_list( \@range_strs ),
        "total: $total",
    );
    for my $gen (@$generators) {
        push @lines, 'generator: ' . $gen->source() . ' ' . $gen->count();
    }
    return join( "\n", @lines );
}

sub main {
    my ($argv) = @_;
    $argv = [@ARGV] unless defined $argv;
    my $args = parse_args($argv);

    if ( $args->{help} ) {
        my $help = load_help_text();
        $help =~ s/\s+\z//;
        print "$help\n";
        exit 0;
    }

    if ( $args->{version} ) {
        print "wildling $Wildling::VERSION\n";
        exit 0;
    }

    if ( !@{ $args->{patterns} } ) {
        print STDERR "No pattern provided. Use --help for usage information.\n";
        exit 1;
    }

    my $wildcard = Wildling::create( $args->{patterns}, $args->{dictionaries} );

    if ( $args->{check} ) {
        print format_check_output( $args, $wildcard->count(), $wildcard->generators() ), "\n";
        exit 0;
    }

    if ( @{ $args->{selects} } || @{ $args->{ranges} } ) {
        my $oor = 0;
        for my $index ( @{ $args->{selects} } ) {
            my $value = $wildcard->get($index);
            if ( Wildling::is_false($value) ) {
                print STDERR "out of range: $index\n";
                $oor = 1;
            }
            else {
                print "$value\n";
            }
        }
        for my $range ( @{ $args->{ranges} } ) {
            for my $index ( $range->[0] .. $range->[1] ) {
                my $value = $wildcard->get($index);
                if ( Wildling::is_false($value) ) {
                    print STDERR "out of range: $index\n";
                    $oor = 1;
                }
                else {
                    print "$value\n";
                }
            }
        }
        exit $oor ? 1 : 0;
    }

    my $value = $wildcard->next();
    while ( !Wildling::is_false($value) ) {
        print "$value\n";
        $value = $wildcard->next();
    }
}

1;
