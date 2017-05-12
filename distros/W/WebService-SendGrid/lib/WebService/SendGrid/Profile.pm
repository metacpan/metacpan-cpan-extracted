package WebService::SendGrid::Profile;
$WebService::SendGrid::Profile::VERSION = '1.03';
# ABSTRACT: The Profile class for your SendGrid account
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'WebService::SendGrid';

use URI;
use Carp;
use JSON::XS;
use Mail::RFC822::Address qw(valid);

has 'first_name' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Your first name' );
has 'last_name' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Your last name' );
has 'address' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Company address 1' );
has 'address2' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Company address 2' );
has 'city' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'City where your company is located' );
has 'state' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'State where your company is located' );
has 'country' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Country where your company is located' );
has 'zip' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Zipcode where your company is located' );
has 'phone' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Valid phone number where we can reach you' );
has 'website' => ( is => 'rw', isa => 'Str', required => 0, documentation => 'Your company\'s website' );

has 'username' => ( is => 'ro', isa => 'Str', required => 0, writer => '_set_username' );
has 'email' => ( is => 'ro', isa => 'Str', required => 0, writer => '_set_email' );

method BUILD {
  
  my $req = $self->_generate_request('/api/profile.get.json', {});
  my $res = $self->_dispatch_request($req);
  return $self->_process_error($res) if $res->code != 100;
	my $content = ${ decode_json $res->content }[0];
	
	# iterate through the values of the class, and assign them if defined
	for my $attr ( $self->meta->get_all_attributes ) {
	  next unless __PACKAGE__ eq $attr->definition_context->{package};
	  my $name = $attr->name;
	  my $method = $attr->get_write_method;
	  $self->$method($content->{$name}) if defined $content->{$name};
	}
	
	# there are two undocumented attributes that come back in this content
	# - website_access (true|false)
	# - active (true|false)
	# - username
	# - email
	warn 'This user is inactive' if $content->{active} ne 'true';
  
}

method set {
  
  my %data;	
	for my $attr ( $self->meta->get_all_attributes ) {
	  next unless __PACKAGE__ eq $attr->definition_context->{package};
	  my $name = $attr->name;
	  $data{$name} = $self->$name if $self->$name;
	}
  
  my $req = $self->_generate_request('/api/profile.set.json', \%data);
  my $res = $self->_dispatch_request($req);
	return $self->_process_error($res) if $res->code != 200;
	my $content = decode_json $res->content;
  
}

method setUsername (Str $username) {
  # Must not exceed 100 characters. The username cannot be already taken or contain the SendGrid.com domain
  croak 'Username too long' if length $username > 100;
  
  my $req = $self->_generate_request('/api/profile.setUsername.json', { username => $username });
  my $res = $self->_dispatch_request($req);
	return $self->_process_error($res) if $res->code != 200;
	my $content = decode_json $res->content;
  
}

method setPassword (Str $password) {
  # Must be at least 6 characters
  croak 'Password too short' if length $password < 6;
  
  my %data = (
    password  => $password,
    confirm_password => $password
  );
  
  my $req = $self->_generate_request('/api/profile.setPassword.json', \%data);
  my $res = $self->_dispatch_request($req);
	return $self->_process_error($res) if $res->code != 200;
	my $content = decode_json $res->content;
  
}

method setEmail (Str $email) {
  # Must be in email format and not more than 100 characters
  croak 'Email too long' if length $email > 100;
  croak 'Invalid email' if !valid($email);
  
  my $req = $self->_generate_request('/api/profile.setEmail.json', { email => $email });
  my $res = $self->_dispatch_request($req);
	return $self->_process_error($res) if $res->code != 200;
	my $content = decode_json $res->content;
  
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Profile - The Profile class for your SendGrid account

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  use WebService::SendGrid::Profile;
  my $profile = WebService::SendGrid::Profile->new(
    api_user =>  'jlloyd', # same username for logging into the website
    api_key => 'abcdefgh123456789', # same password for logging into the website
  );
  
  print 'The username for your account is ' . $profile->username;
  print 'The email for your account is ' . $profile->email;
  
  $profile->address('123 Fake Street');
  $profile->city('Faketown');
  $profile->set; # store the new profile to SendGrid

  # update the username on your account
  $profile->setUsername('jlloyd');
  
  # update the password on your account
  $profile->setPassword('123456789');
  
  # update the email address on your account
  $profile->setEmail('jlloyd@cpan.org');

1;

=head1 DESCRIPTION

Allows you to view/update your SendGrid profile using their Web API

=head1 AUTHOR

Jonathan Lloyd <webmaster@lifegames.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Lloyd <webmaster@lifegames.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
