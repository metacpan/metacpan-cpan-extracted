package lib::relative::to::ParentContaining;

use strict;
use warnings;
 
use parent 'lib::relative::to';

use File::Spec;
use Cwd qw(abs_path);

sub _find {
    my($class, $parent_contains, @args) = @_;
    my $caller = $lib::relative::to::called_from;

    my $candidate = $class->parent_dir(abs_path($caller));

    while($candidate) {
        my $target = File::Spec->catdir($candidate, $parent_contains);
        if(-e $target) {
            return map { File::Spec->catdir($candidate, $_) } @args
        } elsif($candidate eq $class->parent_dir($candidate)) {
            die(__PACKAGE__ . ": Couldn't _find $parent_contains in any parent directory of $caller\n");
        } else {
            $candidate = $class->parent_dir($candidate);
        }
    }
}

1;

=head1 NAME

lib::relative::to:ParentContaining:

=head1 SYNOPSIS

    use lib::relative::to
        ParentContaining => 'MANIFEST', qw(lib t/lib);

=head1 DESCRIPTION

A plugin for L<lib::relative::to> for finding a parent (or grandparent, or ...) directory which contains some particular file or directory and then adding some directories under it to C<@INC>. It is a fatal error to not find a suitable parent directory.
