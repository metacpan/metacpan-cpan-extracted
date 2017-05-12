package lib::ini::plugin;
{
  $lib::ini::plugin::VERSION = '0.002';
}

# ABSTRACT: Base class for lib::ini plugins

use lib ();

sub import {
    my ($class, %args) = @_;
    my @dirs = $class->generate_inc(%args);
    lib->import(@dirs) if @dirs;
}

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

lib::ini::plugin - Base class for lib::ini plugins

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

