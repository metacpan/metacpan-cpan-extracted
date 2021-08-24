package oCLI::Request;
use Moo;
use Scalar::Util qw( looks_like_number );

has [qw( overrides command stdin )] => (
    is => 'ro',
);

has args => (
    is      => 'ro',
    default => sub { return [] },
);

has settings => (
    is      => 'ro',
    default => sub { return +{} },
);

has command_class => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ( $self ) = @_;

        return "" unless index($self->command, ':') >= 0;

        my @parts = split /:/, $self->command;
        delete $parts[-1];

        return join "::", map { ucfirst(lc($_)) } @parts;
    },
);

has command_name => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ( $self ) = @_;

        return lc( (split( /:/, $self->command ))[-1] );
    }
);

sub new_from_command_line {
    my ( $class, @command_line ) = @_;

    my $data;

    my ( $overrides, $command, @arguments, $switches );

    # Process over rides
    while ( @command_line && substr($command_line[0],0,1) eq '/' ) {
        my $command = shift @command_line;

        if ( $command =~ /^\/([^= ]+)=(.+)$/ ) { # /key=value
            $data->{overrides}->{$1} = $2;
        } elsif ( $command =~ /^\/([^ ]+)$/ ) {
            $data->{overrides}->{$1} = 1;
        } else {
            die "Could not parse command line argument: $command\n";
        }
    }

    # Process command if one exists.
    $data->{command} = shift @command_line if @command_line and $command_line[0] !~ /^--/;

    while ( @command_line && substr($command_line[0],0,2) ne '--' ) {
        my $command = shift @command_line;

        # Expand filenames into their content in arguments prefixed with @.
        if ( substr($command,0,1) eq '@' ) {
            open my $lf, "<", substr($command,1)
                or die "Failed to read $command: $!";
            $command = do { local $/; <$lf> };
            close $lf;
        } 
        push @{$data->{args}}, $command;
    }

    # Process arguments
    #
    # --foo                { foo => 1 }
    # --no-foo             { foo => 0 }
    # --foo bar            { foo => 'bar' }
    # --foo bar --foo blee { foo => [ 'bar', 'blee' ] }
    # --foo=bar            { foo => 'bar' }
    # --foo=bar --foo=blee { foo => [ 'bar', 'blee' ] }
    # --foo @path          { foo => contents_of_file(<path>) }
    while ( defined( my $command = shift @command_line )) {


        if ( $command =~ /^--no-([^ ]+)$/ ) {
            $data->{settings}->{$1} = 0;
        } elsif ( ( ! @command_line or $command_line[0] =~ /^--/ ) && $command =~ /^--([^ =]+)$/ ) {
            $data->{settings}->{$1} = 1;
        } else {
            $command =~ s/^--//;

            my $argument;
            if ( $command =~ /^([^=]+)=(.+?)$/ ) {
                ( $command, $argument ) = ( $1, $2 );
            } else {
                $argument = shift @command_line;
            }

            if ( substr($argument,0,1) eq '@' ) {
                open my $lf, "<", substr($argument,1)
                    or die "Failed to read $argument: $!";
                $data->{settings}->{$command} = do { local $/; <$lf> };
                close $lf;
            } else {
                # If we have nothing, this becomes a string...
                if ( ! $data->{settings}->{$command} ) {
                    $data->{settings}->{$command} = $argument;
                # If we have an array ref there already...
                } elsif ( ref($data->{settings}->{$command}) eq 'ARRAY' ) {
                    push @{$data->{settings}->{$command}}, $argument;
                # Otherwise we promote to an array ref
                } else {
                    $data->{settings}->{$command} = [ $data->{settings}->{$command}, $argument ];
                }
            }
        }
    }

    # Process STDIN
    if ( ! -t STDIN ) {
        $data->{stdin} = do { local $/; <STDIN> };
    }

    return $class->new($data);
}

1;
