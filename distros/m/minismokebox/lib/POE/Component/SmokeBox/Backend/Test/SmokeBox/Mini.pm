package POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini;
$POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini::VERSION = '0.68';
#ABSTRACT: a backend to App::SmokeBox::Mini.

use strict;
use warnings;
use base qw(POE::Component::SmokeBox::Backend::Base);

sub _data {
  my $self = shift;
  $self->{_data} =
  {
	check => [ '-e', 1 ],
	index => [ '-e', 1 ],
	smoke => [ '-e', '$|=1; if ( $ENV{PERL5LIB} ) { require App::SmokeBox::Mini::Plugin::Test; } else { my $module = shift; print $module, qq{\n}; } sleep 5; exit 0;' ],
  };
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini - a backend to App::SmokeBox::Mini.

=head1 VERSION

version 0.68

=head1 DESCRIPTION

POE::Component::SmokeBox::Backend::Test::SmokeBox::Mini is a L<POE::Component::SmokeBox::Backend> plugin used during the
L<App::SmokeBox::Mini> tests.

It contains no moving parts.

=head1 SEE ALSO

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
