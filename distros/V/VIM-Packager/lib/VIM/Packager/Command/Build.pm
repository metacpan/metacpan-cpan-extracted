package VIM::Packager::Command::Build;
use warnings;
use strict;
use base qw(App::CLI::Command);

=head1 NAME

VIM::Packager::Command::Build - build vim package

=head1 init

=head2 SYNOPSIS

    $ vim-packager build

=head2 OPTIONS

=over 4

=item --pure | -p

=back

=cut

sub options {
    (
        'p|pure'      => 'pure',
    );
}


use YAML;
use VIM::Packager::MakeMaker;

sub run {
    my ( $self, @args ) = @_;
    my $make = VIM::Packager::MakeMaker->new( $self );
}


1;
