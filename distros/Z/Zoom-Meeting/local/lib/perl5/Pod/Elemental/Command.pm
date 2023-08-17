package Pod::Elemental::Command 0.103006;
# ABSTRACT: a =command paragraph

use Moose::Role 0.90;
with 'Pod::Elemental::Paragraph' => { -excludes => [ 'as_pod_string' ] };

#pod =head1 OVERVIEW
#pod
#pod This is a role to be included by paragraph classes that represent Pod commands.
#pod It defines C<as_pod_string> and C<as_debug_string> methods.  Most code looking
#pod for commands will check for the inclusion of this role, so be sure to use it
#pod even if you override the provided methods.  Classes implementing this role must
#pod also provide a C<command> method.  Generally this method will implemented by
#pod an attribute, but this is not necessary.
#pod
#pod =cut

requires 'command';

sub as_pod_string {
  my ($self) = @_;

  my $content = $self->content;

  sprintf "=%s%s", $self->command, ($content =~ /\S/ ? " $content" : $content);
}

sub as_debug_string {
  my ($self) = @_;
  my $str = $self->_summarize_string($self->content);
  return sprintf '=%s %s', $self->command, $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Command - a =command paragraph

=head1 VERSION

version 0.103006

=head1 OVERVIEW

This is a role to be included by paragraph classes that represent Pod commands.
It defines C<as_pod_string> and C<as_debug_string> methods.  Most code looking
for commands will check for the inclusion of this role, so be sure to use it
even if you override the provided methods.  Classes implementing this role must
also provide a C<command> method.  Generally this method will implemented by
an attribute, but this is not necessary.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

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
