package Tie::Syslog;

$Tie::Syslog::VERSION = '2.04.03';

use 5.006;
use strict;
use warnings;
use Carp qw/carp croak confess/;
use Sys::Syslog qw/:standard :macros/;

# ------------------------------------------------------------------------------
# Define all default handle-tying subs, so that they can be autoloaded if 
# necessary.
use subs qw(
    TIEHANDLE
    WRITE
    PRINT
    PRINTF
    READ
    READLINE
    GETC
    CLOSE
    OPEN
    BINMODE
    EOF
    TELL
    SEEK
    UNTIE
    FILENO
);

# --- 'Public' Globals - DEFAULTS ----------------------------------------------
$Tie::Syslog::ident = (split '/', $0)[-1];
$Tie::Syslog::logopt = 'pid,ndelay';

# --- 'Private' Globals --------------------------------------------------------
my @mandatory_opts = ('facility', 'priority');
# Since calling openlog() twice for the same facility makes it croak, we will 
# keep a list of already-open-facility-connections. This will also be useful to 
# know if we must call closelog().
my %open_connections;


# ------------------------------------------------------------------------------
# 'Private' functions
# ------------------------------------------------------------------------------

########################
# sub _parse_config(@) #
########################
# This sub is responsible of setting up the configuration for the subsequent 
# openlog() and syslog() calls. It returns a reference to a hash that contains
# configuration parameters for our Tie::Syslog object. 
sub _parse_config(@) {

    my $params;

    if (ref($_[0]) eq 'HASH') {
        # New-style configuration 
        # Copy values so we don't risk changing an existing reference.
        # NOTE: this configuration has no defaults defined. 'priority' and 
        # 'facility' must be explicitly set.
        $params = { 
            %{ shift() },
        };
    } else {
        # Old-style configuration, parameters are: 
        # 'facility.loglevel', 'identity', 'logopt', 'setlogsock options'
        # Old-style config provided local0.error as default, in case nothing
        # else was specified. We keep this defaults only for old-style config.
        my ($facility, $priority) = 
            @_ ? split '\.', shift : ('LOG_LOCAL0', 'LOG_ERR');
        $Tie::Syslog::ident  = shift if @_;
        $Tie::Syslog::logopt = shift if @_;
        # There can still be one option: socket type for setlogsock. Since we
        # do not call setlogsock (according to Sys::Syslog rules), we 
        # may (safely?) ignore this option.
        $params = {
            facility => $facility,
            priority => $priority,
        };
    }

    # Normalize names
    for ('facility', 'priority') {
        next unless $params->{ $_ };
        $params->{ $_ } =  uc( $params->{ $_ } );
        $params->{ $_ } =~ s/EMERGENCY/EMERG/;
        $params->{ $_ } =~ s/ERROR/ERR/;
        $params->{ $_ } =~ s/CRITICAL/CRIT/;
        $params->{ $_ } =  'LOG_' . $params->{ $_ }
            unless $params->{ $_ } =~ /^LOG_/;
    }

    return $params;
}

# ------------------------------------------------------------------------------
# Accessors/mutators
# ------------------------------------------------------------------------------

# Because writing $self->facility() is better than writing $self->{'facility'}
for my $opt (@mandatory_opts) {
    no strict 'refs';
    *$opt = sub {
        my $self = shift;
        $self->{$opt} = shift if @_;
        return $self->{$opt};
    };
}

# ------------------------------------------------------------------------------
# Handle tying methods - see 'perldoc perltie' and 'perldoc Tie::Handle'
# ------------------------------------------------------------------------------

# This is the method called by the 'tie' function. 
# It returns a hash reference blessed to Tie::Syslog package.
sub TIEHANDLE {
    my $self;

    # Set log mask as permissive as possible - masking will be done at syslog 
    # level
    eval {
        setlogmask(
            LOG_MASK(LOG_EMERG)|
            LOG_MASK(LOG_ALERT)|
            LOG_MASK(LOG_CRIT)|
            LOG_MASK(LOG_ERR)|
            LOG_MASK(LOG_WARNING)|
            LOG_MASK(LOG_NOTICE)|
            LOG_MASK(LOG_INFO)|
            LOG_MASK(LOG_DEBUG)
        );
    }; 
    carp "Call to setlogmask() failed: $@"
        if $@;

    # See if we were called as an instance method, or as a class method. 
    # In the first case, we provide a copy-constructor that takes the invocant 
    # as a prototype and uses the same configuration. 
    if (my $pkg = ref($_[0])) {
        # Use a copy-constructor, providing support for 
        # single-parameter-override via the @_
        my $prototype = shift;
        my $other_parameters = _parse_config @_;
        $self = bless {
                %$prototype, 
                %$other_parameters,
            }, $pkg;
    } else {
        # Called as a class method
        $pkg = shift;
    
        my $parameters = _parse_config @_;

        $self = bless $parameters, $pkg;
    }

    # Check for all mandatory values
    for (@mandatory_opts) {
        croak "You must provide value for '$_' option"
            unless $self->{$_};
    }

    # Now openlog() if needed, by calling our own open()
    $self->OPEN();

    # Finally return 
    return $self;
}

sub OPEN {
    # Ignore any parameter passed, since we just call openlog() with parameters
    # got from initialization
    my $self = shift;
    my $f = $self->facility;
    eval { 
        openlog($Tie::Syslog::ident, $Tie::Syslog::logopt, $self->facility)
            unless $open_connections{ $f };
    };
    croak "openlog() failed with errors: $@"
        if $@;
    $open_connections{ $f } = 1;
    return $self->{'is_open'} = 1;
}

# Usually, we should have just one connection to syslog. It may happen, though,
# that multiple connections have been established, if multiple facilities have 
# been used (but please NOTE that this is AGAINST Sys::Syslog rules). 
# In the latter case, closelog() will just close the last connection, which may
# be completely unrelated to the handle we're closing here. In case of multiple
# connections, just skip closelog(). 
sub CLOSE {
    my $self = shift;
    return 1 unless $self->{'is_open'};
    $self->{'is_open'} = 0;
    unless (scalar(keys(%open_connections)) > 1) {
        eval {
            closelog();
        };
        croak "Call to closelog() failed with errors: $@" 
            if $@;
        delete $open_connections{ $self->facility };
    }
    return 1;
}

sub PRINT {
    my $self = shift;
    carp "Cannot PRINT to a closed filehandle!" unless $self->{'is_open'};
    eval { syslog $self->facility."|".$self->priority, "@_" };
    croak "PRINT failed with errors: $@"
        if $@;
}

sub PRINTF {
    my $self = shift;
    carp "Cannot PRINTF to a closed filehandle!" unless $self->{'is_open'};
    my $format = shift;
    eval { syslog $self->facility."|".$self->priority, $format, @_ };
    croak "PRINTF failed with errors: $@"
        if $@;
}

# Provide a fallback method for write
sub WRITE {
    my $self = shift;
    my $string = shift;
    my $length = shift || length $string;
    my $offset = shift; # Ignored

    $self->PRINT(substr($string, 0, $length));

    return $length;
}

# This peeks a little into Sys:Syslog internals, so it might break sooner or 
# later. Expect this to happen. 
#   fileno() of socket if available
#   -1 if we have an open handle
#   undef if we're not connected
# When Sys::Syslog uses 'native' connection, *Sys::Syslog::SYSLOG is not
# defined, and $Sys::Syslog::connected is a lexical, so it's not accessible
# by us. In other words, we have to try and guess.
sub FILENO {
    my $self = shift;
    my $fd = fileno(*Sys::Syslog::SYSLOG);
    return defined($fd) ? $fd  
        : $self->{'is_open'} ? -1 : undef;
}

sub DESTROY {
    my $self = shift;
    return 1 unless $self;
    $self->CLOSE();
    undef $self;
}

sub UNTIE {
    my $self = shift;
    return 1 unless $self;
    $self->DESTROY;
}


# ------------------------------------------------------------------------------
# Provide a graceful fallback for not(-yet?)-implemented methods
# ------------------------------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;
    my $name = (split '::', our $AUTOLOAD)[-1];
    return if $name eq 'DESTROY';

    my $err = "$name operation not (yet?) supported";

    # See if errors are fatals
    my $errors_are_fatal = ref($self) ? $self->{'errors_are_fatal'} : 1;
    confess $err if $errors_are_fatal;

    # Install a handler for this operation if errors are nonfatal
    {
        no strict 'refs';
        *$name = sub {
            print "$name operation not (yet?) supported";
        }
    }

    $self->$name;
}


# ------------------------------------------------------------------------------
# Compatibility with Tie::Syslog v1.x
# ------------------------------------------------------------------------------
# die() and warn() print to STDERR
sub ExtendedSTDERR {
    return 1;
}

'End of Tie::Syslog'
__END__
