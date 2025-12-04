package Trickster::Logger;

use strict;
use warnings;
use v5.14;

use Time::Piece;

our %LEVELS = (
    debug => 0,
    info  => 1,
    warn  => 2,
    error => 3,
    fatal => 4,
);

sub new {
    my ($class, %opts) = @_;
    
    return bless {
        level => $opts{level} || 'info',
        output => $opts{output} || \*STDERR,
        formatter => $opts{formatter} || \&_default_formatter,
    }, $class;
}

sub debug { shift->_log('debug', @_) }
sub info  { shift->_log('info', @_) }
sub warn  { shift->_log('warn', @_) }
sub error { shift->_log('error', @_) }
sub fatal { shift->_log('fatal', @_) }

sub _log {
    my ($self, $level, $message, %context) = @_;
    
    return if $LEVELS{$level} < $LEVELS{$self->{level}};
    
    my $formatted = $self->{formatter}->($level, $message, \%context);
    
    my $fh = $self->{output};
    print $fh $formatted, "\n";
}

sub _default_formatter {
    my ($level, $message, $context) = @_;
    
    my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $level_str = uc($level);
    
    my $line = "[$timestamp] [$level_str] $message";
    
    if (%$context) {
        my @parts;
        for my $key (sort keys %$context) {
            push @parts, "$key=$context->{$key}";
        }
        $line .= " {" . join(', ', @parts) . "}";
    }
    
    return $line;
}

sub set_level {
    my ($self, $level) = @_;
    $self->{level} = $level;
}

sub middleware {
    my ($self) = @_;
    
    return sub {
        my $app = shift;
        
        return sub {
            my $env = shift;
            
            my $start = time;
            my $method = $env->{REQUEST_METHOD};
            my $path = $env->{PATH_INFO};
            
            $self->info("Request started", 
                method => $method,
                path => $path,
                remote_addr => $env->{REMOTE_ADDR},
            );
            
            my $res = $app->($env);
            
            my $duration = time - $start;
            my $status = ref($res) eq 'ARRAY' ? $res->[0] : 'unknown';
            
            my $level = $status >= 500 ? 'error' : 
                       $status >= 400 ? 'warn' : 'info';
            
            $self->$level("Request completed",
                method => $method,
                path => $path,
                status => $status,
                duration => sprintf('%.3fs', $duration),
            );
            
            return $res;
        };
    };
}

1;

__END__

=head1 NAME

Trickster::Logger - Logging for Trickster applications

=head1 SYNOPSIS

    use Trickster::Logger;
    
    my $logger = Trickster::Logger->new(
        level => 'info',
        output => \*STDERR,
    );
    
    $logger->info('Application started');
    $logger->error('Something went wrong', error => $@);
    
    # Use as middleware
    $app->middleware($logger->middleware);

=head1 DESCRIPTION

Trickster::Logger provides structured logging with multiple log levels
and context support.

=head1 LOG LEVELS

=over 4

=item * debug - Detailed debugging information

=item * info - General informational messages

=item * warn - Warning messages

=item * error - Error messages

=item * fatal - Fatal error messages

=back

=cut
