package VCS::Vss::Dir;

use Carp;
use VCS::Vss;
use Win32::OLE;

@ISA = qw(VCS::Vss VCS::Dir);

use strict;

use Win32::OLE::Enum;

sub new {
    my($class, $url) = @_;
    my $self = $class->init($url);
	$self->_fix_path;
	#$self->{vss_object} = $self->_get_vss_item($self->path);
    return $self;
}


sub content {
    my ($self) = @_;
    my @return;
	my $vss_proj = $self->vss_object;
	my @items = Win32::OLE::Enum->All($vss_proj->Items(0));
	foreach my $item (@items) {
        my $type = $item->{Type};
        my $path = $item->{Name};
        next unless $path;
        my $new_class = ($type eq 0) ? 'VCS::Vss::Dir' : 'VCS::Vss::File';
        push @return, $new_class->new($self->url . $path);
    }
    return sort { $a->path cmp $b->path } @return;
}

1;
