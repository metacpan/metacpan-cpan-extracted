use strict;
use warnings;

package WebService::Shippo::Config;
require WebService::Shippo::Request;
use Cwd;
use Carp          ( 'croak' );
use File::HomeDir ();
use Path::Class   ();
use YAML::XS      ();

#<<< PerlTidy, leave this:
( my $temp = __FILE__ ) =~ s{\.\w+$}{.yml};

our @SEARCH_PATH = (
    Path::Class::Dir->new( getcwd )->file( '.shipporc' )->stringify,
    Path::Class::Dir->new( File::HomeDir->my_home )->file( '.shipporc' )->stringify,
    Path::Class::Dir->new( '', 'etc' )->file( 'shipporc' )->stringify,
    $temp
);
#>>>

{
    my $value = undef;

    sub config_file
    {
        my ( $invocant, $new_value ) = @_;
        unless ( $value ) {
            for my $candidate ( @SEARCH_PATH ) {
                if ( -e $candidate ) {
                    $value = $candidate;
                    last;
                }
            }
        }
        return $value unless @_ > 1;
        $value = $new_value;
        return $invocant;
    }
}

{
    my $config = undef;

    sub reload_config
    {
        my ( $invocant ) = @_;
        $invocant->load_config_file;
        return $invocant;
    }

    sub config
    {
        my ( $invocant, $new_value ) = @_;
        return $config unless @_ > 1;
        my $class = ref( $invocant ) || $invocant;
        $config = $new_value;
        my $default_token = $config->{default_token} || 'private_token';
        my $api_key       = $config->{$default_token};
        my $user          = $config->{username} || $config->{email};
        my $pass          = $config->{password};
        Shippo::Resource->api_private_token( $config->{private_token} );
        Shippo::Resource->api_public_token( $config->{public_token} );
        Shippo::Resource->api_key( $api_key )
            if $api_key;
        Shippo::Resourse->api_credentials( $user, $pass )
            if $user && !$api_key;
        bless $config, $class;
        return $invocant;
    }

    sub load_config_file
    {
        my ( $invocant ) = @_;
        my $class = ref( $invocant ) || $invocant;
        my $config_file = $class->config_file;
        # Return empty config if no config file exists
        return bless( {}, $class )
            unless $config_file && -e $config_file;
        # Fetch the config content. By default, this should be defined in a
        # file called Config.yml, located in the same folder as the Config.pm
        # module.
        open my $fh, '<:encoding(UTF-8)', $config_file
            or croak "Can't open file '$config_file': $!";
        my $config_yaml = do { local $/ = <$fh> };
        close $fh;
        # Return empty config if no YAML content was found
        return bless( {}, $class )
            unless $config_yaml;
        # Parse the YAML content; use an empty config if that yields nothing.
        $class->config( YAML::XS::Load( $config_yaml ) || {} );
        return $invocant;
    }
}

__PACKAGE__->load_config_file;

BEGIN {
    no warnings 'once';
    # Forcing the dev to always use CPAN's perferred "WebService::Shippo"
    # namespace is just cruel; allow the use of "Shippo", too.
    *Shippo::Config:: = *WebService::Shippo::Config::;
}

1;
