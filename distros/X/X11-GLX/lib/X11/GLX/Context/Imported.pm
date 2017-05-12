package X11::GLX::Context::Imported;
$X11::GLX::Context::Imported::VERSION = '0.02';
require X11::GLX;

# ABSTRACT: Wrapper for GLXContext which were imported using glXImportContextEXT


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

X11::GLX::Context::Imported - Wrapper for GLXContext which were imported using glXImportContextEXT

=head1 VERSION

version 0.02

=head1 DESCRIPTION

A GLXContext imported using L<X11::GLX::glXImportContextEXT>, since it needs
special cleanup.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
