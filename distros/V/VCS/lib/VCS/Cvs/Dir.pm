package VCS::Cvs::Dir;

use Carp;
use VCS::Cvs;

@ISA = qw(VCS::Cvs VCS::Dir);

use strict;

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
    my $path = $self->path;
    die "$class->new: $path: $!\n" unless -d $path;
    die "$class->new: $path not a CVS directory: $!\n"
        unless -d $path . 'CVS';
    $self;
}

sub content {
    my $self = shift;
    my @return;
    local *CONTENTS;
    open(CONTENTS, $self->path . 'CVS/Entries');
    while (defined(my $entry = <CONTENTS>)) {
        my ($type, $path) = $entry =~ m|^([^/]*)/([^/]*)/|;
        next unless $path;
        my $new_class = ($type eq 'D') ? 'VCS::Cvs::Dir' : 'VCS::Cvs::File';
        push @return, $new_class->new($self->url . $path);
    }
    close CONTENTS;
    return sort { $a->path cmp $b->path } @return;
}

1;
