package Yancy::Command::backend;
our $VERSION = '1.032';
# ABSTRACT: Commands for working with Yancy backends

#pod =head1 SYNOPSIS
#pod
#pod     Usage: APPLICATION backend COMMAND
#pod
#pod         ./myapp.pl backend copy sqlite:prod.db users
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Commands';

has description => 'Work with Yancy backend';
has usage => sub { shift->extract_usage };
has hint => sub { "\nSee 'APPLICATION backend help COMMAND' for more information on a specific command.\n" };
has message => sub { shift->usage . "\nCommands:\n" };

# Mojolicious::Commands delegates to a module in this namespace
has namespaces => sub { [ 'Yancy::Command::backend' ] };

sub help { shift->run( @_ ) }

1;

__END__

=pod

=head1 NAME

Yancy::Command::backend - Commands for working with Yancy backends

=head1 VERSION

version 1.032

=head1 SYNOPSIS

    Usage: APPLICATION backend COMMAND

        ./myapp.pl backend copy sqlite:prod.db users

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
