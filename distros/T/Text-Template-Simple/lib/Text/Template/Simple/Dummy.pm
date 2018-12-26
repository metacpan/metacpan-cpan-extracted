package Text::Template::Simple::Dummy;
$Text::Template::Simple::Dummy::VERSION = '0.91';
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.
use strict;
use warnings;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Util qw();

sub stack { # just a wrapper
   my $opt = shift || {};
   Text::Template::Simple::Util::fatal('tts.caller.stack.hash')
      if ref $opt ne 'HASH';
   $opt->{frame} = 1;
   return Text::Template::Simple::Caller->stack( $opt );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Dummy

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

All templates are compiled into this class.

=head1 NAME

Text::Template::Simple::Dummy - Container class

=head1 FUNCTIONS

C<Text::Template::Simple::Dummy> contains some utility functions
that are accessible by all templates.

=head2 stack

Issues a full stack trace and returns the output as string dump. Accepts
options as a hash reference:

   stack({ opt => $option, frame => $backtrace_level });

Can be used inside templates like this:

   <%= stack() %>

See L<Text::Template::Simple::Caller> for more information.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
