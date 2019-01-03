package Git::Repository::Log::Iterator;
$Git::Repository::Log::Iterator::VERSION = '1.314';
use strict;
use warnings;
use 5.006;
use Carp;
use Scalar::Util qw( blessed );

use Git::Repository;
use Git::Repository::Command;
use Git::Repository::Log;

sub new {
    my ( $class, @cmd ) = @_;

    # pick up unsupported log options
    my @badopts = do {
        my $options = 1;
        grep {/^--(?:(?:pretty|format)=(?!raw).*|graph|oneline)$/}
            grep { $options = 0 if $_ eq '--'; $options } @cmd;
    };
    croak "log() cannot parse @badopts. "
        . 'Use run( log => ... ) to parse the output yourself'
        if @badopts;

    # note: there is no --color option to git log  before 1.5.3.3
    my ($r) = grep blessed $_ && $_->isa('Git::Repository'), @cmd;
    $r ||= 'Git::Repository';    # no Git::Repository object given
    unshift @cmd, '--no-color' if $r->version_ge('1.5.3.3');

    # enforce the format
    @cmd = ( 'log', '--pretty=raw', @cmd );

    # run the command (@cmd may hold a Git::Repository instance)
    my $cmd = Git::Repository::Command->new(@cmd);
    bless { cmd => $cmd, fh => $cmd->stdout }, $class;
}

sub new_from_fh {
    my ( $class, $fh ) = @_;
    bless { fh => $fh }, $class;
}

sub new_from_file {
    my ( $class, $file ) = @_;
    open my $fh, '<', $file or die "Can't open $file: $!";
    bless { fh => $fh }, $class;
}

sub next {
    my ($self) = @_;
    my $fh = $self->{fh};

    # get records
    my @records = defined $self->{record} ? ( delete $self->{record} ) : ();
    {
        local $/ = "\n\n";
        while (<$fh>) {
            $self->{record} = $_, last if /\Acommit / && @records;
            push @records, $_;
        }
    }

    # EOF
    if ( !@records ) {
        if ( $self->{cmd} ) {    # might catch some git errors
            $self->{cmd}->final_output();
        }
        else {                   # just close the filehandle
            $self->{fh}->close;
        }
        return;
    }

    # the first two records are always the same, with --pretty=raw
    local $/ = "\n";
    my ( $header, $message, $extra ) = ( @records, '', '' );
    chomp $header;
    my @headers = map { chomp; split / /, $_, 2 } split /^(?=\S)/m, $header;
    s/\n /\n/g for @headers;
    chomp( $message, $extra ) if exists $self->{record};

    # create the log object
    return Git::Repository::Log->new(
        @headers,
        message => $message,
        extra   => $extra,
    );
}

1;

__END__

=pod

=head1 NAME

Git::Repository::Log::Iterator - Split a git log stream into records

=head1 SYNOPSIS

    use Git::Repository::Log::Iterator;

    # use a default Git::Repository context
    my $iter = Git::Repository::Log::Iterator->new('HEAD~10..');

    # or provide an existing instance
    my $iter = Git::Repository::Log::Iterator->new( $r, 'HEAD~10..' );

    # get the next log record
    while ( my $log = $iter->next ) {
        ...;
    }

=head1 DESCRIPTION

C<Git::Repository::Log::Iterator> initiates a B<git log> command
from a list of paramaters and parses its output to produce
L<Git::Repository::Log> objects represening each log item.

=head1 METHODS

=head2 new

    my $iter = Git::Repository::Log::Iterator->new( @args );

Create a new B<git log> stream from the parameter list in C<@args>
and return a iterator on it.

C<new()> will happily accept any parameters, but note that
C<Git::Repository::Log::Iterator> expects the output to look like that
of C<--pretty=raw>, and so will force the the C<--pretty> option
(in case C<format.pretty> is defined in the Git configuration).
It will also forcibly remove colored output (using C<--color=never>).

Extra output (like patches) will be stored in the C<extra> parameter of
the L<Git::Repository::Log> object. Decorations will be lost.

When unsupported options are recognized in the parameter list, C<new()>
will C<croak()> with a message advising to use C<< run( 'log' => ... ) >>
to parse the output yourself.

The object is really a blessed hash reference, with only two keys:

=over 4

=item cmd

The L<Git::Repository::Command> object running the actual B<git log>
command. It might not be defined in some cases (see below L</new_from_fh>
and L</new_from_file>).

=item fh

The filehandle from which the output of B<git log> is actually read.
This is the only attribute needed to run the L</next> method.

=back

=head2 new_from_fh

This constructor makes it possible to provide the filehandle directly.

The C<cmd> key is not defined when using this constructor.

=head2 new_from_file

This constructor makes it possible to provide a filename that will be
C<open()>ed to produce a filehandle to read the log stream from.

The C<cmd> key is not defined when using this constructor.

=head2 next

    my $log = $iter->next;

Return the next log item as a L<Git::Repository::Log> object,
or nothing if the stream has ended.

=head1 COPYRIGHT

Copyright 2010-2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
