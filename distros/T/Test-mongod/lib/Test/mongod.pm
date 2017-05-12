package Test::mongod;

our $VERSION = '0.05';

use Moose;
use File::Temp qw(tempdir);
use Net::EmptyPort qw(empty_port wait_port);
use Config::ZOMG;
use Hash::Merge qw(merge);
use Time::HiRes qw(sleep);
use POSIX qw(SIGTERM);
use FindBin qw($Bin);

use File::Which 'which';


has config => (
        is => 'ro',
        isa => 'HashRef',
        clearer => 'clear_config',
        predicate => 'has_config',
);
        

sub _build_config {
        my ($self, $path_to) = @_;
        $path_to //= "$Bin/etc/mongod.conf";
        return unless -f $path_to;
        
        my $config = Config::ZOMG->open($path_to) or die "Counld not open config";
        return $config ? $config : undef;
        
}


has bind_ip => (
        is => 'ro',
        isa => 'Str',
        default => '127.0.0.1',
);

has port => (
        is => 'ro',
        isa => 'Int',
        default => sub { empty_port() },
);

has dbpath => (
        is => 'ro',
        isa => 'Str',
        default => sub { tempdir(CLEANUP => $ENV{TEST_MONGOD_PRESERVE} ? undef : 1 ) },
);

has mongod => (
        is => 'ro',
        isa => 'Str',
        lazy => 1,
        builder  => '_build_mongod',
);

has quiet => (
        is => 'ro',
        isa => 'Int',
        default => '1',
);

has 'pid' => (
        is => 'rw',
        isa => 'Int',
        lazy => 1,
        default => undef,
        init_arg => undef,
);

sub _build_mongod {
        my $self = shift;
        my $mongod = which('mongod');
        chomp $mongod if $mongod;
        undef $mongod unless -x $mongod;
        return $mongod;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = shift;
    
    my $config = $class->_build_config($args->{config_file});
    $config = merge($args->{config}, $config) if ($args->{config});
    my %args = %{ merge($args, $config) } if $config; 
    $args{config} = $config if $config;
    return $class->$orig(%args);
};
        
    

sub BUILD {
        my $self = shift;
        return unless $self->mongod;
        my $pid = fork;
        die "fork failed:$!" unless defined $pid;

        if ($pid == 0) {
                my $logfile = ($self->has_config && $self->config->{logfile}) ? $self->config->{logfile} : 'mongod.log';
                my $logpath = $self->dbpath . "/$logfile";
    
                my $cmd = sprintf("%s --dbpath %s --port %u --logpath %s ", $self->mongod, $self->dbpath, $self->port, $logpath);
                $cmd .= sprintf(" --bind_ip %s", $self->bind_ip) unless ($self->bind_ip eq '127.0.0.1');
                $cmd .= ' --quiet' if $self->quiet;
                exec ( $cmd );
        }
        until ( wait_port($self->port, 1) ) { sleep 1; }
        $self->pid($pid);
}

sub stop {
        my ($self, $sig) = @_;
        return unless $self->pid;

        $sig ||= SIGTERM;
        kill $sig, $self->pid;

        sleep 0.1;
        waitpid $self->pid, 0;
    
        return 1;
}

sub DEMOLISH {
        my $self = shift;
        $self->stop;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=encoding utf-8

=head1 NAME

Test::mongod - run a temporrary instance of MongoDB

=head1 SYNOPSIS

  use Test::mongod;
  my $mongod = Test::mongod->new;  # thats it, you get a mongod server on a random port and in a /tmp dir

  ... more

  $mongod->port; # get the port the server is listening on
  $mongod->dbpath; # get the db dir
 
  

=head1 DESCRIPTION

Test::mongod automatically sets up a temporary instance of MongoDB and destroys it when the script ends.

The latest version of this is always at
L<https://github.com/jshy/Test-mongod>
This is C<ALPHA> code.

=head1 METHODS

=head2 C<new>

  my $mongod = Test::mongod->new;

This creates a new instance of C<Test::mongod> and instanciates a temporary MongoDB server
This uses the moose BUILD method to go ahead and launche the server. This method blocks till the server is listening and ready to work.

=head2 C<stop>

  $mongo->stop;

Stops the MongoDB instance and tears down the temporary directory. This method is called by DEMOLISH when the object goes out of scope.

=head1 ATTRIBUTES

=head2 bind_ip

The IP to bind the server on. Defaults to 127.0.0.1. Must be an IP on the localhost.

=head2 port

The port for the server to listen on. Defaults to a random port. Use this to get the port to feed to your client. 

=head2 dbpath

The diorectory for the database server to put ts files. This defaults to a /tmp directory that will be cleaned up when the script finishes. Changes this will cause the directory to persist. Must be a path on the localhost.

=head2 pid

Contains the pid of the forked child process.

=head2 config

a hashref of config options 
you can give ether 

    config => { } or 
    config_file => 'relative/path/to/conf/file'

config file must be something Config::Any recognizes. SEE EXAMPLE t/etc/mongo.conf
if you have a t/etc/mongod.conf file then it will get picked up automatically
NOTE: If you use config no config file gets read.

=head1 AUTHOR

Jesse Shy E<lt>jshy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Jesse Shy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
