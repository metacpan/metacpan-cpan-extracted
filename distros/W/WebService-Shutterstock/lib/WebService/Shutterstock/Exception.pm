package WebService::Shutterstock::Exception;
{
  $WebService::Shutterstock::Exception::VERSION = '0.006';
}

# ABSTRACT: Exception object to allow for easy error handling on HTTP errors

use strict;
use warnings;

use Moo;
use overload q("") => \&to_string;


has request  => ( is => 'lazy', required => 0, handles => ['uri', 'method'] );
sub _build_request {
	my $self = shift;
	return $self->response ? $self->response->request : undef;
}


has response => ( is => 'ro', required => 0, handles => ['code'] );


has error    => ( is => 'ro', required => 1 );


has caller_info => ( is => 'ro', required => 1 );


sub BUILDARGS {
	my $class = shift;
	my $args = $class->SUPER::BUILDARGS(@_);
	my $level = 0;
	while(!$args->{caller_info} || $args->{caller_info}->{package} =~ /^(Sub::Quote|WebService::Shutterstock)/){
		my @info = caller($level++) or last;
		$args->{caller_info} = { package => $info[0], file => $info[1], line => $info[2] };
	}
	$args->{caller_info} ||= { package => 'N/A', file => 'N/A', line => -1 };
	return $args;
}


sub to_string {
	my $self = shift;
	return sprintf("%s at %s line %s.\n", $self->error, $self->caller_info->{file}, $self->caller_info->{line});
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::Exception - Exception object to allow for easy error handling on HTTP errors

=head1 VERSION

version 0.006

=head1 SYNOPSIS

	# better safe than sorry
	try {
		my $license = $customer->license($image_id)
		$license->save('/path/to/my/photos');
	} catch {
		my $error = $_;
		# handle error...
	};

=head1 DESCRIPTION

This class provides more context for an error message than just a simple
string (although it stringifies to make it act like your typical C<$@>
value).

=head1 ATTRIBUTES

=head2 request

The L<HTTP::Request> object for the API request that died.

=head2 response

The L<HTTP::Response> object for the API request that died.

=head2 error

String error message.  Often, the body of the HTTP response that errored out.

=head2 caller_info

A HashRef of information (package, file, line) of where this exception
originated (in non-WebService-Shutterstock land).

=head1 METHODS

=head2 to_string

Stringifies to error message, used by overloaded stringification.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
