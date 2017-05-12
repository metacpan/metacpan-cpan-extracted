# See Plugin.pod for documentation
package re::engine::Plugin;
use 5.010;
use strict;

our ($VERSION, @ISA);

BEGIN {
 $VERSION = '0.12';
 # All engines should subclass the core Regexp package
 @ISA = 'Regexp';
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

my $RE_ENGINE_PLUGIN = ENGINE();

sub import
{
    my ($pkg, %sub) = @_;

    # Valid callbacks
    my @callback = qw<comp exec free>;

    for (@callback) {
        next unless exists $sub{$_};
        my $cb = $sub{$_};

        unless (ref $cb eq 'CODE') {
            require Carp;
            Carp::croak("'$_' is not CODE");
        }
    }

    $^H |= 0x020000;

    $^H{+(__PACKAGE__)} = _tag(@sub{@callback});
    $^H{regcomp}        = $RE_ENGINE_PLUGIN;

    return;
}

sub unimport
{
    # Delete the regcomp hook
    delete $^H{regcomp}
        if $^H{regcomp} == $RE_ENGINE_PLUGIN;

    delete $^H{+(__PACKAGE__)};

    return;
}

sub callbacks
{
    my ($re, %callback) = @_;

    my %map = map { $_ => "_$_" } qw<exec free>;

    for my $key (keys %callback) {
        my $name = $map{$key};
        next unless defined $name;
        $re->$name($callback{$key});
    }
}

sub num_captures
{
    my ($re, %callback) = @_;

    for my $key (keys %callback) {
        $key =~ y/a-z/A-Z/; # ASCII uc
        my $name = '_num_capture_buff_' . $key;
        $re->$name( $callback{$key} );
    }
}

1;
