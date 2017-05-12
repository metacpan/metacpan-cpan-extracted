package Janus::Sequence;

=head1 NAME

Janus::Sequence

=head1 SYNOPSIS

 use Janus::Sequence;

 my $seq = Janus::Sequence->new
 ( 
     name => 'alpha',
     conf => '/conf/file',
     code => '/code/file'
 );

 $seq->run( ctrl => sub { .. }, cache => {}, batch => [ .. ], .. );

=head1 CONFIGURATION

=head3 code

See Janus::Sequence::Code.

=head3 conf

See Janus::Sequence::Conf.

=cut
use strict;
use warnings;
use Carp;
use Time::HiRes qw( alarm sleep time stat );

use Janus::Sequence::Conf;
use Janus::Sequence::Code;

=head1 PARAMETERS

Default value in ().

 timeout : ( 0 = no timeout ) seconds allotted for a stage to run.
 retry : ( 0 ) number of retries when error occurs.
 redo : ( 0 ) number of redoes after a stage is released from error.

=cut
our %RUN = ( redo => 0, retry => 0, timeout => 0 );

sub new
{
    my ( $class, %self ) = splice @_; ## load path
    my $self = bless { stage => [], %self }, ref $class || $class;
    $self->load();
}

=head1 METHODS

=head3 load()

Loads code then conf. Returns invoking object.

=cut
sub load
{
    my $self = shift;
    $self->load_code()->load_conf();
}

=head3 load_code()

Loads code file. Returns invoking object.

=cut
sub load_code
{
    my $self = shift;
    return $self if $self->{static};

    my ( $name, $stage ) = @$self{ qw( name stage ) };
    my $error = "$name: name mismatch with existing code";
    my $code = Janus::Sequence::Code->load( $self->{code} );

    $self->{static} = $code->static;
    return $self unless $code = $code->dump( $name );

    for my $code ( @$code )
    {
        $code->{name} = ext( $code->{name}, ext => $name );
        next unless my $stage = shift @$stage;
        confess $error if $stage->{name} ne $code->{name};
    }

    $self->{stage} = $code;
    return $self;
}

=head3 load_conf()

Loads conf file. Returns invoking object.

=cut
sub load_conf
{
    my $self = shift;
    my $name = $self->{name};
    my $conf = Janus::Sequence::Conf->load( $self->{conf} );

    return $self unless $conf = $conf->dump( $name );

    for my $stage ( @{ $self->{stage} } )
    {
        my $name = ext( $stage->{name}, chop => $name );
        $stage->{conf} = $conf->{$name} || {};
    }

    return $self;
}

sub ext
{
    my ( $name, $action, $ext ) = splice @_;
    if ( $action eq 'ext' ) { $name .= ".$ext" }
    else { $name =~ s/\.$ext$// }
    return $name;
}

=head3 check()

=cut
sub check
{
    my $self = shift;
    @{ $self->{stage} };
}

=head3 run( %param )

Runs sequence. Returns invoking object. In addition to default paramaters,
the following may also be defined in %param.

 log : code that deals with logging.
 stuck : code that deals with stuck logic.
 exclude : code that deals with exclusion.
 batch : code required by PLUGIN.
 cache : a HASH reference, for passing context.
 alarm : SIGALRM handler.

=cut
sub run
{
    my $self = shift;

    $self->{run} = ## override default param
    {
        log => sub {}, ctrl => sub { 0 }, exclude => sub { shift },
        alarm => sub { die 'timeout' }, cache => {}, %RUN, @_
    };

    local $SIG{ALRM} = $self->{run}{alarm};
    map { $self->stage( $_ ) } 0 .. @{ $self->{stage} } - 1;
    return $self;
}

=head1 PLUGIN

a CODE reference, which can expect the following parameters:

 log : a CODE reference.
 param : if any, loaded from config.
 batch : if defined, loaded from run() parameter.
 cache : a HASH reference, that may be loaded from run() parameter.

=cut
sub stage
{
    my ( $self, $i ) = splice @_;
    my $stage = $self->{stage}[$i];
    my $name = $stage->{name};
    my $run = $self->{run};
    my ( $log, $stuck ) = @$run{ qw( log stuck ) };
    my %run = ( %$run, %{ $stage->{conf} || {} } ); ## override run param

    for my $i ( 0 .. $run{redo} )
    {
        &$log( $name, $i ? "redo #$i" : 'begin' );

        for my $j ( 0 .. $run{retry} )
        {
            &$stuck( $name ); ## block if stuck
            &$log( $name, "retry #$j" ) if $j;

            eval
            {
                $self->load(); ## reload
                alarm $run{timeout};
                &{ $stage->{code} }
                (
                    log => sub { &{ $run->{log} }( $stage->{name}, @_ ) },
                    param => $stage->{conf}{param},
                    batch => &{ $run->{exclude} }( $run->{batch} ),
                    map { $_ => $run->{$_} } qw( cache janus )
                );
                alarm 0;
            };

            last unless $@;
            alarm 0;
            &$log( $name, "error $@" );
        }

        last unless $@;
        &$stuck( $name, "$@", 'error' ); ## block until released
    }
}

1;
