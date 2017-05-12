package YUI::Loader::List;

use Moose;

has loader => qw/is ro required 1 isa YUI::Loader weak_ref 1/;

sub name {
    my $self = shift;
    return $self->loader->name_list;
}

sub file { my $self = shift; my @list = map { $self->loader->file($_) } $self->name; return wantarray ? @list : \@list; }
sub uri { my $self = shift; my @list = map { $self->loader->uri($_) } $self->name; return wantarray ? @list : \@list; }
sub cache_file { my $self = shift; my @list = map { $self->loader->cache_file($_) } $self->name; return wantarray ? @list : \@list; }
sub cache_uri { my $self = shift; my @list = map { $self->loader->cache_uri($_) } $self->name; return wantarray ? @list : \@list; }
sub source_file { my $self = shift; my @list = map { $self->loader->source_file($_) } $self->name; return wantarray ? @list : \@list; }
sub source_uri { my $self = shift; my @list = map { $self->loader->source_uri($_) } $self->name; return wantarray ? @list : \@list; }
sub item_path { my $self = shift; my @list = map { $self->loader->item_path($_) } $self->name; return wantarray ? @list : \@list; }
sub item_file { my $self = shift; my @list = map { $self->loader->file($_) } $self->name; return wantarray ? @list : \@list; }

1;
