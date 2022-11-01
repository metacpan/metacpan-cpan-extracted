use 5.12.0;
use warnings;
package more 0.204;
# ABSTRACT: use more of a resource

use less 0.03 ();
use parent 'less';

1;

=pod

=encoding UTF-8

=head1 NAME

more - use more of a resource

=head1 VERSION

version 0.204

=head1 SYNOPSIS

  use more 'variables';

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
a complex matrix of "less" interactions.  Unfortunately, there is no mechanism
for requesting that I<more> of something be used, to help do our part as good
consumers.  The often-heard advice to simply write C<< no less 'spending' >> is
insufficient.  That only means we should maintain our current levels.  We want
to request an increase.

This library corrects this deficiency by allowing the user to write:

  use more 'spending';

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use more 'variables';
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
#pod a complex matrix of "less" interactions.  Unfortunately, there is no mechanism
#pod for requesting that I<more> of something be used, to help do our part as good
#pod consumers.  The often-heard advice to simply write C<< no less 'spending' >> is
#pod insufficient.  That only means we should maintain our current levels.  We want
#pod to request an increase.
#pod
#pod This library corrects this deficiency by allowing the user to write:
#pod
#pod   use more 'spending';
#pod
