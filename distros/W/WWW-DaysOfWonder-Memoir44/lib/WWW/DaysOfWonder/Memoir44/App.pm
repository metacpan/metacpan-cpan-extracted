#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::App;
# ABSTRACT: mem44's App::Cmd
$WWW::DaysOfWonder::Memoir44::App::VERSION = '3.000';
use App::Cmd::Setup -app;

sub allow_any_unambiguous_abbrev { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::App - mem44's App::Cmd

=head1 VERSION

version 3.000

=head1 DESCRIPTION

This is the main application, based on the excellent L<App::Cmd>.
Nothing much to see here, see the various subcommands available for more
information, or run one of the following:

    mem44 commands
    mem44 help

Note that each subcommand can be abbreviated as long as the abbreviation
is unambiguous.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
