package VCS::Hms::Dir;

use VCS::Dir;

@ISA = qw(VCS::Hms VCS::Dir);

use strict;
use Carp;

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
    my $path = $self->path;
    die "$class->new: $path not an HMS directory: $!\n"
        if system("fls $path >/dev/null") != 0;
    $self;
}

sub content {
    my $self = shift;
    my @result;
    foreach (split "\n",`fll -l $self->{NAME}`) {
        my ($mode,$lock,$size,$month,$date,$h_y,$name,$locked_rev) =
            split /\s+/;
        my $new_class = ($mode =~ /^d/) ? 'VCS::Hms::Dir' : 'VCS::Hms::File';
        push @result, $new_class->new($self->url . $name);
    }
    return @result;
}

1;
