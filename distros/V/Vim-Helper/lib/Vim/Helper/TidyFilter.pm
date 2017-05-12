package Vim::Helper::TidyFilter;
use strict;
use warnings;
use File::Temp qw/tempfile/;
use Carp qw/croak/;

#<pippijn> :let o=system("echo echo \"'hello'\"")
#<pippijn> :execute o
#<pippijn> :execute system("echo echo ...etc

use Vim::Helper::Plugin (
    save_rc => {required => 1},
    load_rc => {required => 1},
);

sub args {
    {
        tidy_load => {
            handler     => \&load,
            description => "Read perl content from stdin, tidy it, return to stdout",
            help        => "Usage: INPUT | $0 load > OUTPUT",
        },
        tidy_save => {
            handler     => \&save,
            description => "Read perl content from stdin, tidy it, return to stdout",
            help        => "Usage: INPUT | $0 save > OUTPUT",
        },
    };
}

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command($opts);

    return <<"    EOT";
function! LoadTidyFilter()
    let cur_line = line(".")
    :silent :%!$cmd tidy_load
    exe ":" . cur_line
endfunction

function! SaveTidyFilter()
    let cur_line = line(".")
    :silent :%!$cmd tidy_save
    exe ":" . cur_line
endfunction

augroup type
  auto BufReadPost  *.psgi :call LoadTidyFilter()
  auto BufWritePre  *.psgi :call SaveTidyFilter()
  auto BufWritePost *.psgi :call LoadTidyFilter()

  auto BufReadPost  *.pl :call LoadTidyFilter()
  auto BufWritePre  *.pl :call SaveTidyFilter()
  auto BufWritePost *.pl :call LoadTidyFilter()

  auto BufReadPost  *.pm :call LoadTidyFilter()
  auto BufWritePre  *.pm :call SaveTidyFilter()
  auto BufWritePost *.pm :call LoadTidyFilter()

  auto BufReadPost  *.t :call LoadTidyFilter()
  auto BufWritePre  *.t :call SaveTidyFilter()
  auto BufWritePost *.t :call LoadTidyFilter()
augroup END
    EOT
}

sub load {
    my $helper = shift;
    my $self   = $helper->plugin('TidyFilter');
    my ( $name, $opts ) = @_;
    $self->_tidy( $self->load_rc );
}

sub save {
    my $helper = shift;
    my $self   = $helper->plugin('TidyFilter');
    my ( $name, $opts ) = @_;
    $self->_tidy( $self->save_rc );
}

sub _tidy {
    my $self = shift;
    my ($rc) = @_;

    my ( $fhi, $tmpin )  = tempfile( UNLINK => 1 );
    my ( $fho, $tmpout ) = tempfile( UNLINK => 1 );
    close($fho);

    my $content = join "" => <STDIN>;
    print $fhi $content;
    close($fhi);

    # We need to unlink any existing perltidy.ERR file
    # We will run perltidy, if something unreasonable happens we abort
    unlink "perltidy.ERR";
    my $cmd = "cat '$tmpin' | perltidy -pro=\"$rc\" 1>'$tmpout' 2>/dev/null";
    system($cmd ) && return $self->abort($content);

    # If everything goes well we will output the tidy version, if there was a
    # problem we will output the original.

    return $self->abort($content)
        if -e "perltidy.ERR";

    open( $fho, "<", $tmpout ) && $self->abort($content);
    $content = join "" => <$fho>;
    close($fho);

    return {code => 0, stdout => $content};
}

sub abort {
    my $self = shift;
    my ($content) = @_;
    return {
        code   => 1,
        stdout => $content,
    };
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::TidyFilter - Run perltidy on the buffer when files are loaded or
saved.

=head1 DESCRIPTION

Used to run perltidy on files as you edit them. Can have different tidy configs
for loading and saving.

=head1 SYNOPSIS

In your config file:

    use Vim::Helper qw/
        TidyFilter
    /;

    TidyFilter {
        save_rc => 'PATH/TO/perltidy.rc',
        load_rc => 'PATH/TO/perltidy.rc',
    };

=head1 ARGS

=over 4

=item tidy_load

Read perl content from stdin, tidy it, return to stdout. Uses your load_rc.

=item tidy_save

Read perl content from stdin, tidy it, return to stdout. Uses your save_rc.

=back

=head1 OPTS

None

=head1 CONFIGURATION OPTIONS

=over 4

=item save_rc => 'PATH/TO/perltidy.rc'

=item load_rc => 'PATH/TO/perltidy.rc'

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

