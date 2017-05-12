package VCS::Vss::File;

@ISA = qw(VCS::Vss VCS::File);

use VCS::Vss;
use Carp;

use strict;

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
	$self->_fix_path;
	#$self->{vss_object} = $self->_get_vss_item($self->path);
    return $self;
}

# evil assumption - no query strings on URL!
sub versions {
    my ($self, $lastflag) = @_;
    my $current_version = $self->vss_object->VersionNumber;
    map {
        VCS::Vss::Version->new("$self->{URL}/$_")
    } (1..$current_version);
}

sub url {
   my ($self) = @_;
   return $self->{URL};
}

sub tags {return ()}

#sub path {
#   my ($self) = @_;
#   print "Getting path...\n";
#   return $self->vss_object->Path;
#}

1;
