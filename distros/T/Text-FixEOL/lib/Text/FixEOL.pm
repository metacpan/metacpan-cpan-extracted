package Text::FixEOL;

use strict;

$Text::FixEOL::VERSION = '1.06';

##########################################################################################

sub DEBUG () { 0; }

##########################################################################################

my %_Platform_Defaults = (
        lf   => {
            'fixlast' => 'no',
            'eof'     => 'asis',
            'eol'     => "\012",
        },
        cr   => {
            'fixlast' => 'no',
            'eof'     => 'asis',
            'eol'     => "\015",
        },
        crlf   => {
            'fixlast' => 'no',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        asis   => {
            'fixlast' => 'no',
            'eof'     => 'asis',
            'eol'     => "asis",
        },
        network => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\015\012",
        },
        mac   => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\015",
        },
        macos   => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\015",
        },
        windows => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        mswin32 => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        os2     => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        vms     => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\015\012",
        },
        netware => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        dos     => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        cygwin  => {
            'fixlast' => 'yes',
            'eof'     => 'asis',
            'eol'     => "\015\012",
        },
        unix  => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\012",
        },
        'unknown' => {
            'fixlast' => 'yes',
            'eof'     => 'remove',
            'eol'     => "\n",
        },
);

##########################################################################################

sub new {
    my $proto   = shift;
    my $proto_ref = ref($proto);
    my $package   = __PACKAGE__;
    my $class;
    if    ($proto_ref) { $class = $proto_ref;  }
    elsif ($proto)     { $class = $proto;      }
    else               { $class = $package; }
    my $self = bless {},$class;

    $self->eol_handling('platform');
    $self->eof_handling('platform');
    $self->fix_last_handling('platform');

    my %raw_properties = ();
    if    (1 < @_)  { %raw_properties = @_;    }
    elsif (1 == @_) {
        my $parm = shift;
        my $parm_type = ref($parm);
        if ($parm_type eq 'HASH') {
            %raw_properties = %$parm;
        } else {
            require Carp;
            Carp::croak("${package}::new() - Unexpected parameter type passed to constructor: $parm_type");
        }
    } else {
        return $self;
    }

    my %properties = map { lc($_) => $raw_properties{$_} } keys %raw_properties;

    if ($properties{'eol'}) {
        $self->eol_handling($properties{'eol'});
        delete $properties{'eol'};
    }
    if ($properties{'eof'}) {
        $self->eof_handling($properties{'eof'});
        delete $properties{'eof'};
    }
    if ($properties{'fixlast'}) {
        $self->fix_last_handling($properties{'fixlast'});
        delete $properties{'fixlast'};
    }
    my @extra_properties = keys %properties;
    if (0 < @extra_properties) {
        require Carp;
        Carp::croak("${package}::new() - Unexpected attributes passed: " . join(', ',sort @extra_properties) . "\n");
    }

    return $self;
}

##########################################################################################

sub eol_to_unix {
    my $self = shift;

    my $to_unix = $self->new({
                    'EOL'     => 'unix',
                    'EOF'     => 'unix',
                    'FixLast' => 'unix',
                  })->fix_eol(@_);
    return $to_unix;
}

##########################################################################################

sub eol_to_dos {
    my $self = shift;

    my $to_dos = $self->new({
                    'EOL'     => 'dos',
                    'EOF'     => 'dos',
                    'FixLast' => 'dos',
                  })->fix_eol(@_);
    return $to_dos;
}

##########################################################################################

sub eol_to_mac {
    my $self = shift;

    my $to_mac = $self->new({
                    'EOL'     => 'mac',
                    'EOF'     => 'mac',
                    'FixLast' => 'mac',
                  })->fix_eol(@_);
    return $to_mac;
}

##########################################################################################

sub eol_to_network {
    my $self = shift;

    my $to_network= $self->new({
                    'EOL'     => 'network',
                    'EOF'     => 'network',
                    'FixLast' => 'yes',
                  })->fix_eol(@_);
    return $to_network;
}

##########################################################################################

sub eol_to_crlf {
    my $self = shift;

    my $to_crlf = $self->new({
                    'EOL'     => 'crlf',
                    'EOF'     => 'remove',
                    'FixLast' => 'yes',
                  })->fix_eol(@_);
    return $to_crlf;
}

##########################################################################################

sub fix_eol {
    my $self = shift;

    unless (1 == @_) {
        require Carp;
        my $package = __PACKAGE__;
        Carp::croak("${package}::fix_eol() -  Incorrect number of parameters passed. One string (only) is required.");
    }

    my ($string) = @_;
    my $eol_mode = $self->eol_mode;
    if ($eol_mode ne 'asis') {
        $string      = $self->_eol_to_base_lf($string);
    }
    my $fix_last = $self->fix_last_mode;
    if ($fix_last eq 'yes') {
        my $old_eof = '';
        if ($string =~ s/(\032+)$//s) { # \032 is Ctrl-Z
            $old_eof = "\032";
        }
        if (($string ne '') and ($eol_mode ne 'asis')) {
            if ($string !~ m/\012$/s) {
                $string .= "\012";
            }

        } else {
            if ($eol_mode ne 'asis') {
                $string = "\012";
            }
        }
        $string .= $old_eof;
    }

    my $eof_handling = $self->eof_mode;
    if ($eof_handling eq 'remove') {
        $string =~ s/\032+$//s;

    } elsif (($eof_handling eq 'add') and ($string !~ m/\032$/s)) {
        $string .= "\032";
    }

    if ($eol_mode ne 'asis') {
        my $eol_replacement = $eol_mode;
        $string =~ s/\012/$eol_replacement/gs;
    }
    return $string;
}

##########################################################################################

sub eol_mode {
    my $self = shift;
    my $eol_handling = $self->eol_handling;

    if ($eol_handling =~ m/^literal:(.+)$/s) {
        return $1;

    } else {
        my $default_eol = $self->_platform_defaults($eol_handling, 'EOL');
        return $default_eol;
    }
}

##########################################################################################

sub eof_mode {
    my $self = shift;

    my $eof_handling = $self->eof_handling;
    my $default_eof  = $self->_platform_defaults($eof_handling, 'EOF');
    return $default_eof;
}

##########################################################################################

sub fix_last_mode {
    my $self = shift;

    my $fix_last      = $self->fix_last_handling;
    my $fix_last_mode = $self->_platform_defaults($fix_last, 'FixLast');
    return $fix_last_mode;
}

##########################################################################################

sub _platform_defaults {
    my $self = shift;
    my $package = __PACKAGE__;

    my ($platform_name, $property) = @_;

    $platform_name = lc ($platform_name);
    $property      = lc ($property);

    return $platform_name if (($property eq 'fixlast') and ($platform_name =~ m/^(yes|no)$/));
    return $platform_name if (($property eq 'eof') and ($platform_name =~ m/^(asis|remove|add)$/));

    if ($platform_name eq 'platform') {
        $platform_name = lc ($^O);
    }

    my $platform_defaults = $_Platform_Defaults{$platform_name};
    unless (defined ($platform_defaults)) {
        $platform_defaults =  $_Platform_Defaults{'unknown'};
    }
    my $property_value = $platform_defaults->{$property};
    unless (defined ($property_value)) {
        require Carp;
        Carp::croak("${package}::_platform_defaults() - Unknown property of $property");
    }
    return $property_value;
}

##########################################################################################

sub _eol_to_base_lf {
    my $self = shift;

    my ($string) = @_;

    # Undef converts to ''
    return '' unless (defined $string);

    # If there are not any DOS EOLs (\015 characters), return the original string
    return $string unless ($string =~ m/\015/s);

    # If there is nothing except DOS EOL, convert them to \012 directly
    if ($string !~ m/\012/s) {
        $string =~ s/\015/\012/gs;
        return $string;
    }

    # If the EOLs are all 'singletons', do in-place cleanup of the DOS EOLs
    if (($string !~ m/\015\012/s) and ($string !~ m/\012\015/s)) {
        $string =~ s/\015/\012/gs;
        return $string;
    }

    my @eols = $string =~ m/([\012\015]+)/sg;
    my %replacement_map = ();
    foreach my $eol_mode (@eols) {
        next if (defined $replacement_map{$eol_mode});
        my $replace_with = $eol_mode;
        $replace_with    =~ s/(\015\012|\012\015)/\012/gs;
        $replace_with    =~ s/\015/\012/gs;
        $replacement_map{$eol_mode} = $replace_with;
    }
    $string =~ s/([\012\015]+)/$replacement_map{$1}/gse;

    return $string;
}

##########################################################################################

sub eol_handling      { return shift->_property('eol_handling',      @_); }
sub eof_handling      { return shift->_property('eof_handling',      @_); }
sub fix_last_handling { return shift->_property('fix_last_handling', @_); }

##########################################################################################
# _property('property_name' => $property_value)
#
# get/set base accessor for property values

sub _property {
    my $self    = shift;

    my $property = shift;

    my $package = __PACKAGE__;
    if (0 == @_) {
        my $output = $self->{$package}->{$property};
        return $output;

    } elsif (1 == @_) {
        my $input = shift;
        $self->{$package}->{$property} = $input;
        return;
    } else {
        die ("Bad calling parameters to ${package}::${property}()\n");
    }
}

##########################################################################################

1;
