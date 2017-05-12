package Test::Groonga;
use strict;
use warnings;
use File::Spec ();
use File::Temp ();
use File::Which ();
use Test::TCP 1.10;

our $VERSION = '0.06';

sub create {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    
    my $command_version = delete $args{default_command_version} || undef;

    my $protocol = delete $args{protocol}
      or Carp::croak("Missing params 'protocol'");
 
    $protocol =~ m/(?:gqtp|http)/
      or Carp::croak('protocol must be gqtp or http');

    my $preload = delete $args{preload} || undef;

    $class->_get_test_tcp(
        protocol                => $protocol,
        preload                 => $preload,
        default_command_version => $command_version,
    );

}

sub gqtp {
    my $class  = shift;
    my %args   = @_ == 1 ? %{ $_[0] } : @_;
    
    warn 'deprecated..';
    
    $class->_get_test_tcp( %args, protocol => 'gqtp');
}

sub http {
    my $class  = shift;
    my %args   = @_ == 1 ? %{ $_[0] } : @_;
    
    warn 'deprecated..';
    
    $class->_get_test_tcp( %args, protocol => 'http');
}

sub _get_test_tcp {
    my ($class, %args) = @_;
    
    my $preload  = $args{preload} || undef;
    my $protocol = $args{protocol} or die;
    my $cmd_version = $args{default_command_version};
 
    ### load data from dump file if you specified it.
    if ($preload and not -e $preload) {
        Carp::croak("Couldn't find file: $preload");
    }

    my $bin = _find_groonga_bin();
    Carp::croak('groonga binary is not found') unless $bin;

    ### groonga create some shard files. 
    ### ex. tmp/test.groonga.db, tmp/test.groonga.db.0000000, ...
    
    my $db =
      File::Spec->catfile( File::Temp::tempdir( CLEANUP => 1 ), 'test.db' );
    
    return my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            
            `$bin --default-command-version $cmd_version -n $db < $preload` if $preload;
            
            # -s : server mode
            # -n : create a new db
            my @cmd = (
                $bin,                        '-s',
                $cmd_version ? ('--default-command-version', $cmd_version) : (),
                '--port',                    $port,
                '--protocol',                $protocol,
                $preload ? $db : ( '-n', $db )
            );

            exec @cmd;
            die "cannot execute $bin: $!";
        },  
    ); 
}

sub _find_groonga_bin { scalar File::Which::which('groonga'); }

1;

__END__

=head1 NAME

Test::Groonga - Server runner for testing Groonga full-text search engine

=head1 SYNOPSIS

    use Test::Groonga;

    {
        my $server = Test::Groonga->create(protocol=>'http');
        # testing
    }

    {
        my $server = Test::Groonga->create(protocol=>'gqtp');
        # testing
    }

    {
        my $server = Test::Groonga->create(protocol=>'http', preload => 'foo.grn');
        # testing
    }

=head1 DESCRIPTION

Test::Groonga provides you temporary groonga server.

=head1 METHODS

=head2 create

return Test::TCP instance as groonga server.

=head2 gqtp

=head2 http

=head2 _get_test_tcp

=head2 _find_groonga_bin

=head1 AUTHOR

Okamura

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


