
package App::WWW::CPAN;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.013';

use parent qw( Class::Accessor );

__PACKAGE__->mk_accessors(qw( cpan home cache ));

use WWW::CPAN ();
use Data::Dump::Streamer qw( Dump );
use Path::Class qw( dir file );
use Pod::Usage;

sub parse_args {
    my $self = shift;
    my @args = @_;
    my %hash;
    for (@args) {
        if (/\A ([^=]+) = (.*) \z/x) {
            $hash{$1} = $2;
        }
        else {
            # FIXME warn if @args > 1
            return $_;
        }
    }
    return \%hash;
}

sub do_cmd {
    my $self = shift;
    my $cmd  = shift;
    my $args = shift;
    my $val  = $self->cpan->$cmd($args);
    return defined $val ? Dump($val)->Out() : undef;
}

sub _home {
    require File::HomeDir;
    my $h = dir( File::HomeDir->my_home, '.cpanq' );
    $h->mkpath( 0, 0744 );    # quiet, rwxr--r--
    return $h;
}

sub _cache {
    my $self = shift;
    require Cache::FileCache;
    return Cache::FileCache->new(
        {
            default_expires_in => '10 minutes',
            cache_root         => dir( $self->home, 'cache2' ),
        }
    );
}

# save last arguments and answer
sub _store {
    my $self   = shift;
    my $args   = shift;
    my $answer = shift;

    my $k = "@{$args}";
    $self->cache->set( $k, $answer );

}

# retrieve last answer if args are the same
sub _retrieve {
    my $self = shift;
    my $args = shift;

    my $k = "@{$args}";
    return $self->cache->get($k);

}

my %method_for = (
    'meta'     => 'fetch_distmeta',
    'distmeta' => 'fetch_distmeta',
    'query'    => 'search',
    'search'   => 'search'
);

sub run {
    my $self = shift;
    $self->home(_home);
    $self->cache( $self->_cache );
    $self->cpan( WWW::CPAN->new );

    if ( @_ == 0 ) {
        pod2usage(1);
    }

    if ( defined( my $c = $self->_retrieve( \@_ ) ) ) {

        #warn "cache hit\n";
        print $c;
        return;
    }
    my $cmd = shift;
    if ( exists $method_for{$cmd} ) {
        my $cmd_args = $self->parse_args(@_);
        my $ans = $self->do_cmd( $method_for{$cmd}, $cmd_args );
        if ( defined $ans ) {
            $self->_store( [ $cmd, @_ ], $ans );
            print $ans;
        }
    }
    else {
        die "unsupported command: $cmd\n";
    }
}

1;
