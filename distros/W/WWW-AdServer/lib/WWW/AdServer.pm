package WWW::AdServer;
{
  $WWW::AdServer::VERSION = '1.01';
}
use Moo;
#use MooX::late;

#has dsn => (is => 'ro', required => 1);
#has db  => (is => 'ro', required => 1, isa => 'WWW::AdServer::Database');
use WWW::AdServer::Database;

#sub BUILDARGS {
#	my ($class, %args) = @_;
#	if ($args{dsn}) {
#		$args{db} = WWW::AdServer::Database->new(dsn => $args{dsn});
#	}
#	return \%args;
#}

1;

__END__

=pod

=head1 NAME

WWW::AdServer

=head1 VERSION

version 1.01

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
