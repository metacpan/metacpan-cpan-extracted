##
# name:      YamlTime::Conf
# abstract:  YamlTime Configuration Object Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - YamlTime

#-----------------------------------------------------------------------------#
package YamlTime::Conf;
use Mouse;
use YAML::XS;
use DateTime;
# use XXX;

sub BUILD {
    my ($self) = @_;
    my $base = $self->base;
    die "YamlTime is not configured in '$base'\n"
        unless -e "conf/yt.yaml";
    my $hash = YAML::XS::LoadFile('conf/yt.yaml');
    $self->{$_} = $hash->{$_} for keys %$hash;
    die <<"..." if $self->unconfigured;
It appears you have not configured YamlTime yet.
Edit conf/yt.yaml and remove the 'unconfigured' key.
Edit the file correctly, and edit the other conf files too.
Then retry your command.
...
    for (qw[cust proj rate refs tags]) {
        $self->{$_} = YAML::XS::LoadFile("conf/$_.yaml");
    }
}

has base => ( is => 'ro', required => 1 );
has timezone => ( is => 'ro' );
has unconfigured => ( is => 'ro' );
has be_serious => ( is => 'ro' );

has now => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        return DateTime->now->set_time_zone($self->timezone);
    },
);

1;
