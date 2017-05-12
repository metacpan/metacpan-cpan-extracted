package VCS::Rcs::Dir;

use Carp;

@ISA = qw(VCS::Rcs VCS::Dir);

use strict;

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
    my $path = $self->path;
    die "$class->new: $path: $!\n" unless -d $path;
    die "$class->new: $path not an RCS directory: $!\n"
        unless -d $path . 'RCS' or glob "$path*,v";
    $self;
}

# evil assumption - no query string!
sub content {
    my $self = shift;
    my $base_dir = $self->path;
    sort map {
        my $new_class = -d "$base_dir$_" ? 'VCS::Rcs::Dir' : 'VCS::Rcs::File';
        $new_class->new($self->url . $_);
    } grep {
        (!/^RCS$/) && (-f "$base_dir$_" || -d "$base_dir$_")
    } $self->read_dir($base_dir);
}

1;
