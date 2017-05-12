package Variable::OnDestruct::Scoped;
$Variable::OnDestruct::Scoped::VERSION = '0.001';
use 5.010;
use strict;
use warnings;

use Exporter 5.57 'import';
use XSLoader;

##no critic (ProhibitAutomaticExportation)
our @EXPORT = qw/on_destruct/;

XSLoader::load('Variable::OnDestruct::Scoped', __PACKAGE__->VERSION);

1;    # End of Variable::OnDestruct::Scoped

# ABSTRACT: Call a subroutine on destruction of a variable.

__END__

=pod

=encoding UTF-8

=head1 NAME

Variable::OnDestruct::Scoped - Call a subroutine on destruction of a variable.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Variable::OnDestruct::Scoped;

 my @handle = on_destruct $var, sub { do_something() };
 push @handle, on_destruct @array, sub { do_something_else() };
 push @handle, on_destruct %array, sub { hashes_work_too() };
 push @handle, on_destruct &$sub, sub { so_do_closures($but_not_normal_subs) };
 push @handle, on_destruct *$glob, sub { and_even_globs($similar_caveats_as_subs_though) };
 
 @handle = () if $want_to_cancel_destructor;

=head1 DESCRIPTION

This module allows you to let a function be called when a variable gets destroyed. The destructor will work not only on scalars but also on arrays, hashes, subs and globs. For the latter two you should realize that most of them aren't scoped like normal variables. Subs for example will only work like you expect them to when they are closures (otherwise they're immortal).

=head1 FUNCTIONS

=head2 on_destruct $variable, \&sub;

This function adds a destructor callback to a variable. This callback will be called when the variable is destroyed, but only if the canary it returns is still alive (meaning it's stored somewhere). If the canary is destructed first the callback will not be called. This function is exported by default.

=head2 SEE ALSO

=over 4

=item * L<Variable::OnDestruct|Variable::OnDestruct>

=item * L<Variable::Magic|Variable::Magic>

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
