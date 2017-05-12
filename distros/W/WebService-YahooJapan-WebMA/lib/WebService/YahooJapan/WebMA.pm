package WebService::YahooJapan::WebMA;
use 5.008001;
use strict;
use warnings;

use Carp;
use URI;
use LWP::UserAgent;
use XML::Simple ();

our $VERSION = '0.01';

our $APIBase = 'http://api.jlp.yahoo.co.jp/MAService/V1/parse';

sub new {
    my ($class, %args) = @_;
    my %self;
    $self{appid} = $args{appid} or croak 'appid is required.';
    $self{ua}    = $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
    bless \%self, $class;
}

sub parse {
    my ($self, %args) = @_;
    croak 'sentence is required.' unless $args{sentence};
    $self->error('');
    my %param = map { exists $args{$_} ? ( $_ => $args{$_} ) : () } qw(
        sentence results response filter ma_response ma_filter
        uniq_response uniq_by_baseform
    );
    utf8::is_utf8($param{$_}) and utf8::encode($param{$_}) for keys %param;
    my $uri = URI->new($APIBase);
    $uri->query_form(appid => $self->{appid}, %param);
    my $res = $self->{ua}->get($uri);
    unless ($res->is_success) {
        my $error = 'Request failed: ' . $res->status_line;
        if ($res->content) {
            my ($message) = $res->content =~ m!<Message>(.*)</Message>!;
            $error .= "\n$message" if defined $message;
        }
        $self->error($error);
        return;
    }
    XML::Simple::XMLin($res->content, GroupTags => { word_list => 'word' });
}

sub error {
    my $self = shift;
    if (@_) {
        $self->{error} = $_[0];
    }
    $self->{error};
}

1;
__END__

=head1 NAME

WebService::YahooJapan::WebMA - Easy-to-use Interface for Yahoo! Japan Web MA Web Service

=head1 SYNOPSIS

  use WebService::YahooJapan::WebMA;

  my $api = WebService::YahooJapan::WebMA->new(
      appid => 'your_appid',
  );

  my $result = $api->parse(sentence => 'sentence here') or die $api->error;
  my $ma_result = $result->{ma_result};
  print $ma_result->{total_count};
  print $ma_result->{filtered_count};

  for my $word (@{$ma_result->{word_list}}) {
      $word->{surface};
      $word->{reading};
      $word->{pos};
      $word->{baseform};
  }

=head1 DESCRIPTION

This module priovides you an Object Oriented interface for Yahoo! Japan Web MA Web Service.

You can do Japanese language morphological analysis with this module.

=head1 METHODS

=head2 new([%options])

Returns an instance of this module.
The following option can be set:

  appid # required
  ua    # optional. LWP::UserAgent instance

=head2 parse(%options)

Requests API with options and returns results.
The following option can be set:

  sentence # required
  results
  response
  filter
  ma_response
  ma_filter
  uniq_response
  uniq_by_baseform

See the official API documents about detail of options and return values.

=head2 error

Returns error message.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * http://developer.yahoo.co.jp/jlp/MAService/V1/parse.html

=back

=cut

