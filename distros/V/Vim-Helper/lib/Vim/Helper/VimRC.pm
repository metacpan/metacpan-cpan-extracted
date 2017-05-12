package Vim::Helper::VimRC;
use strict;
use warnings;

use Vim::Helper::Plugin;

sub args {
    {
        vimrc => {
            handler     => \&generate,
            description => "Generate a vimrc for your config",
            help        => "Usage: $0 vimrc >> ~/.vimrc",
        }
    };
}

sub generate {
    my $helper = shift;
    my ( $name, $opts, @plugins ) = @_;

    @plugins = keys %{$helper->plugins}
        unless @plugins;

    my @out;

    for my $name (@plugins) {
        my $plugin = $helper->plugin($name);
        next unless $plugin->can('vimrc');

        my $content = $plugin->vimrc( $helper, $opts );
        next unless $content;

        my $head = "\" Start Vim-Helper plugin: $name\n";
        my $tail = "\" End Vim-Helper plugin: $name\n";

        push @out => (
            $head,
            $content,
            $tail,
            "\n"
        );
    }

    return {
        code   => 0,
        stdout => \@out,
    };
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::VimRC - Used to generate vimrc content.

=head1 DESCRIPTION

Loaded automatically. Used to generate vimrc content for all your plugins.

=head1 ARGS

=over 4

=item vimrc plugin1 plugin2 ...

Generate vimrc content for the specified plugin(s). If no plugins are specified
all those configured will be used.

=back

=head1 OPTS

NONE

=head1 CONFIGURATION OPTIONS

NONE

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

