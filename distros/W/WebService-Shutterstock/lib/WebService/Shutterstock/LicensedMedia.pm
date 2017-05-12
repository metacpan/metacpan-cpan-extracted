package WebService::Shutterstock::LicensedMedia;
{
  $WebService::Shutterstock::LicensedMedia::VERSION = '0.006';
}

# ABSTRACT: Role for providing common functionality for licensed media

use strict;
use warnings;
use Moo::Role;
use Carp qw(croak);
use WebService::Shutterstock::Exception;
use LWP::UserAgent;


has download_url => ( is => 'ro' );


sub download {
	my $self = shift;
	my %args = @_;
	my @unknown_args = grep { !/^(file|directory)$/ } keys %args;

	croak "Invalid args: @unknown_args (expected either 'file' or 'download')" if @unknown_args;

	my $url = $self->download_url;
	my $destination;
	if($args{directory}){
		$destination = $args{directory};
		$destination =~ s{/$}{};
		my($basename) = $url =~ m{.+/(.+)};
		$destination .= "/$basename";
	} elsif($args{file}){
		$destination = $args{file};
	}
	if(!defined $destination && !defined wantarray){
		croak "Refusing to download media in void context without specifying a destination file or directory (specify ->download(file => \$some_file) or ->download(directory => \$some_dir)"; 
	}
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get( $url, ( $destination ? ( ':content_file' => $destination ) : () ) );
	if(my $died = $response->header('X-Died') ){
		die WebService::Shutterstock::Exception->new(
			response => $response,
			error    => "Unable to save media to $destination: $died"
		);
	} elsif($response->code == 200){
		return $destination || $response->content;
	} else {
		die WebService::Shutterstock::Exception->new(
			response => $response,
			error    => $response->status_line . ": unable to retrieve media",
		);
	}
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::LicensedMedia - Role for providing common functionality for licensed media

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 download_url

=head1 METHODS

=head2 download

Downloads media.  See examples and additional details in consumers of this role.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
