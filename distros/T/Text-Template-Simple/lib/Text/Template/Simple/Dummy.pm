package Text::Template::Simple::Dummy;
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

our $VERSION = '0.90';

sub stack { # just a wrapper
   my $opt = shift || {};
   Text::Template::Simple::Util::fatal('tts.caller.stack.hash')
      if ref $opt ne 'HASH';
   $opt->{frame} = 1;
   return Text::Template::Simple::Caller->stack( $opt );
}

1;

__END__

=head1 NAME

Text::Template::Simple::Dummy - Container class

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

This document describes version C<0.90> of C<Text::Template::Simple::Dummy>
released on C<5 July 2016>.

All templates are compiled into this class.

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

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
