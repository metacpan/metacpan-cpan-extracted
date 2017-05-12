package Tie::Log4perl;

use warnings;
use strict;

our $VERSION = '0.1';

use Log::Log4perl;
use Log::Log4perl::Level;

sub TIEHANDLE { 
    my $class = shift;
    my $self = ref $_[0] eq 'HASH' ? shift : { @_ };
    $self->{logger} ||= Log::Log4perl::get_logger;
    $self->{level}  ||= $DEBUG;
    bless $self, $class;
}

sub PRINT {
    my $self = shift;
    unless ($self->{called}) {
        local $self->{called} = 1;

        my ($logger, $level, $prefix) = @{$self}{qw(logger level prefix)};
        $Log::Log4perl::caller_depth++;
        $logger->log($level, $prefix, @_);
        $Log::Log4perl::caller_depth--;
    }
}

1;

__END__

=head1 NAME

Tie::Log4perl

=head1 DESCRIPTION

Tie a filehandle so that whatever is printed to it is instead logged via
Log4perl, as recommended by L<Log::Log4Perl::FAQ>, except that using the
filehandle you tie as an appender will not cause infinite recursion.

=head1 SYNOPSIS

    tie *STDERR, 'Tie::Log4perl';

    # This will be logged, instead
    warn "Parbleu, an error!\n";

=head1 OPTIONS

The following options may be passed to tie after the class name either as a
list or as a hash reference.

=head2 level

The level to log at.  Defaults to $Log::Log4perl::Level::Debug.

=head2 logger

The logger category object log with.  Optional.

=head2 prefix

An optional string to prefix to messages.

=head1 AUTHOR

Paul Driver E<lt>frodwith@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2009 Paul Driver

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
