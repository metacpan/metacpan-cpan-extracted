package Vim::Helper::Fennec;
use strict;
use warnings;

use Carp qw/croak/;
use Vim::Helper::Plugin(
    run_key  => {default => '<F8>'},
    less_key => {default => '<F12>'},
);

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command($opts);

    my $run_key  = $self->run_key;
    my $less_key = $self->less_key;

    return <<"    EOT";
function! RunFennecLine()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. %"
endfunction

function! RunFennecLineLess()
    let cur_line = line(".")
    exe "!FENNEC_TEST='" . cur_line . "' prove -v -Ilib -I. % 2>&1 | less"
endfunction

:map $less_key :w<cr>:call RunFennecLineLess()<cr>
:map $run_key :w<cr>:call RunFennecLine()<cr>

:imap $less_key <ESC>:w<cr>:call RunFennecLineLess()<cr>
:imap $run_key <ESC>:w<cr>:call RunFennecLine()<cr>
    EOT
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::Fennec - Keybindings for Fennec test suites

=head1 DESCRIPTION

Provides keybindings and functions for Fennec test suites.

=head1 SYNOPSIS

In your config file:

    use Vim::Helper qw/
        Fennec
    /;

    Fennec {
        run_key  => '<F8>',
        less_key => '<F12>',
    };

=head1 ARGS

None

=head1 OPTS

None

=head1 CONFIGURATION OPTIONS

=over 4

=item run_key

key sequence to bind for running a Fennec test block.

=item less_key

key sequence to bind for running a Fennec test block, output is piped to
'less'.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

