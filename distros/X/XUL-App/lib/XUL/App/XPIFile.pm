package XUL::App::XPIFile;

use strict;
use warnings;
use XUL::App::View::Install;
use File::Slurp;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw{
    id name display_name description version targets
    creator contributors developers
    homepageURL updateURL iconURL aboutURL
});

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    if ($self->id) {
        $XUL::App::ID = $self->id;
        if ($self->name =~ /\.xpi$/i) {
            die "You have to define a name for your plugin";
        }
        $XUL::App::APP_NAME = lc($self->name);
    }
    return $self;
}

sub go {
    my ($self, $file) = @_;
    # generate tmp/install.rdf here:
    Template::Declare->init( roots => ['XUL::App::View::Install'] );
    my $rdf = Template::Declare->show('main', $self);
    write_file('tmp/install.rdf', $rdf);
}

1;

