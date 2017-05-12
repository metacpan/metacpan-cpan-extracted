package Test::Sweet::Exception::FailedMethod;
BEGIN {
  $Test::Sweet::Exception::FailedMethod::VERSION = '0.03';
}
# ABSTRACT: exception representing an exception thrown during testing
use Moose;
use namespace::autoclean;

with 'Test::Sweet::Exception';

1;



=pod

=head1 NAME

Test::Sweet::Exception::FailedMethod - exception representing an exception thrown during testing

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
