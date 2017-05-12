package builder::UR;

use warnings FATAL => 'all';
use strict;

use parent 'Module::Build';

sub ACTION_build {
    my $self = shift;
    foreach my $metadb_type ( qw(sqlite3 sqlite3n sqlite3-dump sqlite3n-dump sqlite3-schema sqlite3n-schema) ) {
        $self->add_build_element($metadb_type);
    }
    return $self->SUPER::ACTION_build(@_);
}

sub ACTION_docs {
    # ensure docs get man pages and html
    my $self = shift;
    $self->depends_on('code');
    $self->depends_on('manpages', 'html');
}

sub man1page_name {
    # without this we have "man ur-init.pod" instead of "man ur-init"
    my ($self, $file) = @_;
    $file =~ s/.pod$//;
    return $self->SUPER::man1page_name($file);
}

1;
