package WebService::LogDNA::Body;

use strict;
use warnings;

use Moo;
use Time::HiRes;
use JSON::MaybeXS qw/encode_json/;

has 'line' => ( 
	is => 'ro', 
	required => 1,
	isa => sub {
		die "Requires a line" unless $_[0] =~ /\S/;
	}
);
has 'level' => ( is => 'ro', required => 1 );
has 'env' => ( is => 'ro', required => 1 );
has 'timestamp' => ( 
	is => 'ro', 
	default => sub { int(Time::HiRes::time() * 1000) }
);
has 'meta' => ( is => 'ro' );


sub to_json {
	my( $self ) =  @_;

	return encode_json({
		line => $self->line,
		level => $self->level,
		env => $self->env,
		timestamp => $self->timestamp,
		meta => $self->meta,
	});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogDNA::Body

=head1 VERSION

version 0.001

=head1 AUTHOR

Robert Grimes <rmzgrimes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Robert Grimes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
