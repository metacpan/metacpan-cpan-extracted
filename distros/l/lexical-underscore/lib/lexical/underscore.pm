package lexical::underscore;

use 5.008;
use strict;
use warnings;

BEGIN {
	$lexical::underscore::AUTHORITY = 'cpan:TOBYINK';
	$lexical::underscore::VERSION   = '0.004';
}

use if ($] >= 5.009 && $] < 5.023), PadWalker => qw( peek_my );
BEGIN {
	*peek_my = sub { +{} } unless __PACKAGE__->can('peek_my');
}

sub lexical::underscore
{
	my $level = @_ ? shift : 0;
	my $lexicals = peek_my($level + 2);
	exists $lexicals->{'$_'} ? $lexicals->{'$_'} : \$_;
}

1;

__END__

=head1 NAME

lexical::underscore - access your caller's lexical underscore

=head1 SYNOPSIS

   use 5.010;
   use lexical::underscore;
   use Test::More;
   
   sub is_uppercase {
      my $var = @_ ? shift : ${lexical::underscore()};
      return $var eq uc($var);
   }
   
   my $thing = 'FOO';
   my $works = 0;
   
   given ( $thing ) {
      when ( is_uppercase ) { $works++ }
   }
   
   ok($works);
   done_testing();

=head1 DESCRIPTION

Starting with Perl 5.10, it is possible to create a lexical version of the Perl
default variable C<< $_ >>. Certain Perl constructs like the C<given> keyword
automatically use a lexical C<< $_ >> rather than the global C<< $_ >>.

It is occasionallly useful for a sub to be able to access its caller's
C<< $_ >> variable regardless of whether it was lexical or not. The C<< (_) >>
sub prototype is the official way to do so, however there are sometimes
disadvantages to this; in particular it can only appear as the final required
argument in a prototype, and there is no way of the sub differentiating between
an explicitly passed argument and C<< $_ >>.

This caused me problems with L<Scalar::Does>, because I wanted to enable the
C<does> function to be called as either:

   does($thing, $role);
   does($role);  # assumes $thing = $_

With C<< _ >> in the prototype, C<< $_ >> was passed to the function at the end
of its argument list; effectively C<< does($role, $thing) >>, making it
impossible to tell which argument was the role.

Enter C<lexical::underscore> which allows you to access your caller's lexical
C<< $_ >> variable as easily as:

   ${lexical::underscore()}

You can access lexical C<< $_ >> further up the call stack using:

   ${lexical::underscore($level)}

If you happen to ask for C<< $_ >> at a level where no lexical C<< $_ >> is
available, you get the global C<< $_ >> instead.

This module does work on Perl 5.8 but as there is no lexical C<< $_ >>, always
returns the global C<< $_ >>.

=head2 Technical Details

The C<lexical::underscore> function returns a scalar reference to either a
lexical C<< $_ >> variable somewhere up the call stack (using L<PadWalker>
magic), or to the global C<< $_ >> if there was no lexical version.

Wrapping C<lexical::underscore> in C<< ${ ... } >> dereferences the scalar
reference, allowing you to access (and even assign to) it.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=lexical-underscore>.

=head1 SEE ALSO

L<PadWalker>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

