package Test::Requires::Scanner::Result;
use strict;
use warnings;

use version 0.77 ();

use Class::Accessor::Lite (
    new => 1,
);

sub modules {
    shift->{modules} ||= {};
}

sub save_module {
    my ($self, $module, $version) = @_;

    if (exists $self->modules->{$module}) {
        return unless $version;

        my $stored_version = $self->modules->{$module};

        if (
            !$stored_version ||
            version->parse($version) > version->parse($stored_version)
        ) {
            $self->modules->{$module} = $version;
        }
    }
    else {
        $self->modules->{$module} = $version;
    }
}

1;
