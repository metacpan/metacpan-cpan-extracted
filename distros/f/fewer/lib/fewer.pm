use 5.12.0;
use warnings;
package fewer 0.204;
# ABSTRACT: use fewer units of a countable resource

use less 0.03 ();
use parent 'less';

sub stash_name { 'less' }

1;

=pod

=encoding UTF-8

=head1 NAME

fewer - use fewer units of a countable resource

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  use fewer 'top level namespaces';

=head1 DESCRIPTION

As of perl5 version 10, the long-useless pragma L<less> became a usable tool
for indicating that less I<something> could be used.  For example, the user
could specify that less memory should be used, and other libraries could then
choose between multiple algorithms based on that choice.

In the user's program:

  use less 'memory';

  my $result = Analyzer->analyze( $large_data_set );

In the library:

  sub analyze {
    my ($self, $data) = @_;

    my $cache  = less->of('memory') ? 'disk' : 'ram';
    my $method = "analyze_with_${cache}_cache";

    return $self->$method($data);
  }

This allowed for an explosion of highly adaptive implementions, accounting for
a complex matrix of "less" interactions.  Unfortunately, with the introduction
of new strictures in perl5 version 18, the following code will stop working:

  use strict 'English';
  use less 'filehandles';

To clarify the matter for our foreign readership, "less" is used for things
which are uncounted, while "fewer" is used for counted resources.

This library corrects this error by allowing the user to write:

  use fewer 'filehandles';

Then, both of the following conditions will be true:

  if ( less->of('filehandles') ) { ... }

  if ( fewer->of('filehandles') ) { ... }

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use fewer 'top level namespaces';
#pod
#pod =head1 DESCRIPTION
#pod
#pod As of perl5 version 10, the long-useless pragma L<less> became a usable tool
#pod for indicating that less I<something> could be used.  For example, the user
#pod could specify that less memory should be used, and other libraries could then
#pod choose between multiple algorithms based on that choice.
#pod
#pod In the user's program:
#pod
#pod   use less 'memory';
#pod
#pod   my $result = Analyzer->analyze( $large_data_set );
#pod
#pod In the library:
#pod
#pod   sub analyze {
#pod     my ($self, $data) = @_;
#pod
#pod     my $cache  = less->of('memory') ? 'disk' : 'ram';
#pod     my $method = "analyze_with_${cache}_cache";
#pod
#pod     return $self->$method($data);
#pod   }
#pod
#pod This allowed for an explosion of highly adaptive implementions, accounting for
#pod a complex matrix of "less" interactions.  Unfortunately, with the introduction
#pod of new strictures in perl5 version 18, the following code will stop working:
#pod
#pod   use strict 'English';
#pod   use less 'filehandles';
#pod
#pod To clarify the matter for our foreign readership, "less" is used for things
#pod which are uncounted, while "fewer" is used for counted resources.
#pod
#pod This library corrects this error by allowing the user to write:
#pod
#pod   use fewer 'filehandles';
#pod
#pod Then, both of the following conditions will be true:
#pod
#pod   if ( less->of('filehandles') ) { ... }
#pod
#pod   if ( fewer->of('filehandles') ) { ... }
#pod
