package lib::relative::to::HgRepository;

use strict;
use warnings;
 
use parent 'lib::relative::to::ParentContaining';

sub _find {
    my($class, @args) = @_;
    $class->SUPER::_find('.hg/store', @args);
}

1;

=head1 NAME

lib::relative::to::HgRepository

=head1 SYNOPSIS

    use lib::relative::to HgRepository => qw(lib t/lib);

=head1 DESCRIPTION

A plugin for L<lib::relative::to> for finding the root of a Mercurial repository and then adding some directories under it to C<@INC>.

It works by looking for the parent directory containing C<.hg/store>.
