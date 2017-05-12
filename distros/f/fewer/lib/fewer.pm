use 5.12.0;
use warnings;
package fewer;
# ABSTRACT: use fewer units of a countable resource
$fewer::VERSION = '0.203';
use less 0.03 ();
use parent 'less';

sub stash_name { 'less' }

1;

=pod

=encoding UTF-8

=head1 NAME

fewer - use fewer units of a countable resource

=head1 VERSION

version 0.203

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

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# =head1 SYNOPSIS
#
#   use fewer 'top level namespaces';
#
# =head1 DESCRIPTION
#
# As of perl5 version 10, the long-useless pragma L<less> became a usable tool
# for indicating that less I<something> could be used.  For example, the user
# could specify that less memory should be used, and other libraries could then
# choose between multiple algorithms based on that choice.
#
# In the user's program:
#
#   use less 'memory';
#
#   my $result = Analyzer->analyze( $large_data_set );
#
# In the library:
#
#   sub analyze {
#     my ($self, $data) = @_;
#
#     my $cache  = less->of('memory') ? 'disk' : 'ram';
#     my $method = "analyze_with_${cache}_cache";
#
#     return $self->$method($data);
#   }
#
# This allowed for an explosion of highly adaptive implementions, accounting for
# a complex matrix of "less" interactions.  Unfortunately, with the introduction
# of new strictures in perl5 version 18, the following code will stop working:
#
#   use strict 'English';
#   use less 'filehandles';
#
# To clarify the matter for our foreign readership, "less" is used for things
# which are uncounted, while "fewer" is used for counted resources.
#
# This library corrects this error by allowing the user to write:
#
#   use fewer 'filehandles';
#
# Then, both of the following conditions will be true:
#
#   if ( less->of('filehandles') ) { ... }
#
#   if ( fewer->of('filehandles') ) { ... }
#
