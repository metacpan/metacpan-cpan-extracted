package Variable::OnDestruct;
$Variable::OnDestruct::VERSION = '0.05';
use strict;
use warnings FATAL => 'all';
use Exporter 5.57 'import';
use XSLoader;

##no critic (ProhibitAutomaticExportation)
our @EXPORT = qw/on_destruct/;

XSLoader::load('Variable::OnDestruct', __PACKAGE__->VERSION);

1;    # End of Variable::OnDestruct

#ABSTRACT: Call a subroutine on destruction of a variable.

__END__

=pod

=encoding UTF-8

=head1 NAME

Variable::OnDestruct - Call a subroutine on destruction of a variable.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Variable::OnDestruct;

	on_destruct $var, sub { do_something() };
	on_destruct @array, sub { do_something_else() };
	on_destruct %array, sub { hashes_work_too() };
	on_destruct &$sub, sub { so_do_closures($but_not_normal_subs) };
	on_destruct *$glob, sub { and_even_globs($similar_caveats_as_subs_though) };

=head1 DESCRIPTION

This module allows you to let a function be called when a variable gets destroyed. The destructor will work not only on scalars but also on arrays, hashes, subs and globs. For the latter two you should realize that most of them aren't scoped like normal variables. Subs for example will only work like you expect them to when they are closures.

=head1 FUNCTIONS

=head2 on_destruct $variable, \&sub;

This function adds a destructor to a variable. It is exported by default.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
