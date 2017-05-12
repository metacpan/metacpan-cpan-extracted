package Zed::Plugin::Sys::Set;
use Term::ReadPassword;

use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;

=head1 SYNOPSIS

    Set zed configuration
    ex:
        set username foo
        set password bar
=cut

invoke "set" => sub {
    my( $key, $value ) = @_ ;

    passwd(undef) and return if $key =~ /^(passwd|password)$/;

    unless($key) {
        my $env = env();
        info("config: ", $env);
    }elsif(!$value) {
        info( "key:[$key], value:[", env($key)||"", "]" );
    }else{
        env($key, $value);
        info( "key:[$key], value:[", env($key)||"", "]" );
    };
},sub{ qw(password username) };

1
