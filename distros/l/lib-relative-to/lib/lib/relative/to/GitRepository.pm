package lib::relative::to::GitRepository;

use strict;
use warnings;
 
use parent 'lib::relative::to::ParentContaining';

# if $ENV{GIT_CONFIG} is set look for
# that, otherwise for .git/config
sub _find {
    my($class, @args) = @_;
    $class->SUPER::_find('.git/config', @args);
}

1;

=head1 NAME

lib::relative::to::GitRepository

=head1 SYNOPSIS

    use lib::relative::to GitRepository => qw(lib t/lib);

=head1 DESCRIPTION

A plugin for L<lib::relative::to> for finding the root of a git repository and then adding some directories under it to C<@INC>.

It works by looking for the parent directory containing C<.git/config>.
