package lib::relative::to::SvnCheckout;

use strict;
use warnings;
 
use parent 'lib::relative::to::ParentContaining';

sub _find {
    my($class, @args) = @_;
    $class->SUPER::_find('.svn/entries', @args);
}

1;

=head1 NAME

lib::relative::to::SvnCheckout

=head1 SYNOPSIS

    use lib::relative::to SvnCheckout => qw(lib t/lib);

=head1 DESCRIPTION

A plugin for L<lib::relative::to> for finding the root of a Subversion checkout and then adding some directories under it to C<@INC>.

It works by looking for the parent directory containing C<.svn/entries>.
