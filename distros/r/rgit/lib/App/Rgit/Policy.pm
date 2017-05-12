package App::Rgit::Policy;

use strict;
use warnings;

=head1 NAME

App::Rgit::Policy - Base class for App::Rgit policies.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

Base class for L<App::Rgit> policies.

This is an internal class to L<rgit>.

=head1 METHODS

=head2 C<< new policy => $policy >>

Creates a new policy object of type C<$policy> by requiring and redispatching the method call to the module named C<$policy> if it contains C<'::'> or to C<App::Rgit::Policy::$policy> otherwise.
The class represented by C<$policy> must inherit this class.

=cut

sub new {
 my $class = shift;
 $class = ref $class || $class;

 my %args = @_;

 if ($class eq __PACKAGE__) {
  my $policy = delete $args{policy};
  $policy = 'Default' unless defined $policy;
  $policy = __PACKAGE__ . "::$policy" unless $policy =~ /::/;
  eval "require $policy" or die $@;
  return $policy->new(%args);
 }

 bless { }, $class;
}

=head2 C<handle $cmd, $config, $repo, $status, $signal>

Make the policy handle the end of execution of the L<App::Rgit::Command> object C<$cmd> with L<App::Rgit::Config> configuration C<$config> in the L<App::Rgit::Repository> repository C<$repo> that exited with status C<$status> and maybe received signal C<$sigal>.

This method must be implemented when subclassing.

=cut

sub handle;

=head1 SEE ALSO

L<rgit>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Policy

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Policy
