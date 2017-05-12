package WebService::SendGrid::Mail;
$WebService::SendGrid::Mail::VERSION = '1.03';
# ABSTRACT: An email class for sending a message through SendGrid
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'WebService::SendGrid';

use URI;
use Carp;
use JSON::XS;
use DateTime::Format::HTTP;

use Mail::RFC822::Address qw(valid);
subtype 'Email', as 'Str', where { valid($_) };

has 'to' => ( is => 'rw', isa => 'Email | ArrayRef[Email]', required => 1 );
has 'toname' => ( is => 'rw', isa => 'Str | ArrayRef', required => 0 );
has 'bcc' => ( is => 'rw', isa => 'Email | ArrayRef[Email]', required => 0 );
has 'from' => ( is => 'rw', isa => 'Email', required => 1 );
has 'fromname' => ( is => 'rw', isa => 'Str', required => 0 );
has 'replyto' => ( is => 'rw', isa => 'Email', required => 0 );
has 'x-smtpapi' => ( is => 'rw', isa => 'Str', required => 0 );
has 'subject' => ( is => 'rw', isa => 'Str', required => 1 );
has 'files' => ( is => 'rw', isa => 'HashRef', required => 0 ); 
# Must be less than 7MB
# files[file1.doc]=example.doc&files[file2.pdf]=example.pdf
has 'headers' => ( is => 'rw', isa => 'HashRef', required => 0 );
# A collection of key/value pairs in JSON format
has 'date' => ( is => 'rw', isa => 'Str', required => 1, default => sub {
  DateTime::Format::HTTP->format_datetime(DateTime->now)
  # RFC 2822 formatted date
});
has 'text' => ( is => 'rw', isa => 'Str', required => 0 );
has 'html' => ( is => 'rw', isa => 'Str', required => 0 );

method send {
  # must have text and/or HTML
  croak "No content" unless ( $self->text || $self->html );

  my %data;	
	for my $attr ( $self->meta->get_all_attributes ) {
	  next unless __PACKAGE__ eq $attr->definition_context->{package};
	  my $name = $attr->name;
	  $data{$name} = $self->$name if $self->$name;
	}
	
	my $req = $self->_generate_request('/api/mail.send.json', \%data);
  my $res = $self->_dispatch_request($req);
	return $self->_process_error($res) if $res->code != 100;
	my $content = decode_json $res->content;
	
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Mail - An email class for sending a message through SendGrid

=head1 VERSION

version 1.03

=head1 SYNOPSIS

  use WebService::SendGrid::Mail;
  my $mail = WebService::SendGrid::Mail->new(
    api_user =>  'jlloyd', # same username for logging into the website
    api_key => 'abcdefgh123456789', # same password for logging into the website
    to => 'jlloyd@cpan.org',
    from => 'jlloyd@cpan.org',
    subject => 'This is a test',
    text => 'This is a test message',
    html => '<html><head></head><body>This is a test HTML message</body></html>'
  );
  
  $mail->send;

1;

=head1 DESCRIPTION

Allows you to send an email through the SendGrid Web API

=head1 AUTHOR

Jonathan Lloyd <webmaster@lifegames.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Lloyd <webmaster@lifegames.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
