package WWW::Google::Notebook;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Carp;
use URI;
use URI::Escape ();
use LWP::UserAgent;
use WWW::Google::Notebook::Note;
use WWW::Google::Notebook::Notebook;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw/username password/);

my $BaseURI = 'http://www.google.com/notebook/';

sub new {
    my ($class, %param) = @_;
    bless {
        username => $param{username} || '',
        password => $param{password} || '',
    }, $class;
}

sub ua {
    my $self = shift;
    if (@_) {
        $self->{ua} = shift;
    } else {
        $self->{ua} and return $self->{ua};
        $self->{ua} = LWP::UserAgent->new;
        $self->{ua}->agent(__PACKAGE__."/$VERSION");
    }
    $self->{ua};
}

sub login {
    my ($self, %param) = @_;
    my $uri = URI->new('https://www.google.com/accounts/ServiceLoginAuth');
    $uri->query_form(
        Email    => $self->username,
        Passwd   => $self->password,
        service  => 'notebook',
        continue => $BaseURI,
        source   => __PACKAGE__."/$VERSION",
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    my $cookie = $res->header('Set-Cookie');
    $self->ua->default_header(Cookie => $cookie);
    $res = $self->ua->post($BaseURI.'token?&pv=2');
    croak($res->status_line) if $res->is_error;
    my ($token) = $res->content =~ m!/\*(.*)\*/!;
    $self->{_token} = $token;
    return 1;
}

sub notebooks {
    my $self = shift;
    my $uri = sprintf(
        $BaseURI.'read?pv=2&ident=fp&tok=%s&cmd=u&zx=%d',
        $self->{_token},
        time,
    );
    my $res = $self->ua->get($uri);
    croak($res->status_line) if $res->is_error;
    my $notebooks = $self->_parse($res->content);
    $notebooks;
}

sub add_notebook {
    my ($self, $title) = @_;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=b&contents=%s',
        $self->{_token},
        _uri_escape($title),
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    my $notebook = $self->_parse($res->content);
    $notebook;
}

sub _delete_notebook {
    my ($self, $notebook) = @_;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=trshn&nbid=%s',
        $self->{_token},
        $notebook->id,
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    undef %$notebook;
    bless $notebook, 'WWW::Google::Notebook::Object::Has::Been::Deleted';
    1;
}

sub _update_notebook {
    my ($self, $notebook) = @_;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=b&nbid=%s&contents=%s',
        $self->{_token},
        $notebook->id,
        _uri_escape($notebook->title),
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    $notebook = $self->_parse($res->content);
    1;
}

sub _notes {
    my ($self, $notebook) = @_;
    my $uri = sprintf(
        $BaseURI.'read?pv=2&ident=fp&tok=%s&cmd=b&nbid=%s&zx=%d',
        $self->{_token},
        $notebook->id,
        time,
    );
    my $res = $self->ua->get($uri);
    croak($res->status_line) if $res->is_error;
    print $res->content;
    $notebook = $self->_parse($res->content);
    my @notes;
    for my $note (@{$notebook->{_notes}}) {
        $note->notebook($notebook);
        push @notes, $note;
    }
    undef $notebook->{_notes};
    \@notes;
}

sub _add_note {
    my ($self, $notebook, $content) = @_;
    $content =~ s/\r?\n/<br>/g;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=n&nbid=%s&contents=%s&qurl=null&nmeth=fp',
        $self->{_token},
        $notebook->id,
        _uri_escape($content),
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    my $note = $self->_parse($res->content);
    $note->notebook($notebook);
    $note;
}

sub _delete_note {
    my ($self, $note) = @_;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=trsh&nid=%s&nbid=%s',
        $self->{_token},
        $note->id,
        $note->notebook->id,
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    undef %$note;
    bless $note, 'WWW::Google::Notebook::Object::Has::Been::Deleted';
    1;
}

sub _update_note {
    my ($self, $note) = @_;
    my $uri = sprintf(
        $BaseURI.'write?pv=2&ident=fp&tok=%s&cmd=n&nbid=%s&nid=%s&contents=%s&qurl=null',
        $self->{_token},
        $note->notebook->id,
        $note->id,
        _uri_escape($note->content),
    );
    my $res = $self->ua->post($uri);
    croak($res->status_line) if $res->is_error;
    $note = $self->_parse($res->content);
    1;
}

sub _parse {
    my ($self, $json) = @_;
    no warnings 'once';
    local *F = sub {};
    local *U = sub { $_[0] };
    local *B = sub {
        WWW::Google::Notebook::Notebook->new({
            id      => $_[0],
            title   => $_[1],
            api     => $self,
            _notes  => $_[11]->[0] || [],
        });
    };
    local *N = sub {
        WWW::Google::Notebook::Note->new({
            id            => $_[0],
            content       => $_[1],
            created_on    => $_[5],
        });
    };
    local *S = sub { $_[3] };
    eval $json;
}

sub _uri_escape {
    my $val = shift;
    $val =~ s/\r?\n/<br>/g;
    URI::Escape::uri_escape($val);
}

1;
__END__

=head1 NAME

WWW::Google::Notebook - Perl interface for Google Notebook

=head1 SYNOPSIS

  use WWW::Google::Notebook;
  my $google = WWW::Google::Notebook->new(
      username => $username,
      password => $password,
  );
  $google->login;
  my $notebooks = $google->notebooks; # WWW::Google::Notebook::Notebook object as arrayref
  for my $notebook (@$notebooks) {
      print $notebook->title, "\n";
      my $notes = $notebook->notes; # WWW::Google::Notebook::Note object as arrayref
      for my $note (@$notes) {
          print $note->content, "\n";
      }
  }
  my $notebook = $google->add_notebook('title'); # WWW::Google::Notebook::Notebook object
  print $notebook->title;
  $notebook->rename('title2');
  my $note = $notebook->add_note('note'); # WWW::Google::Notebook::Note object
  print $note->content;
  $note->edit('note2');
  $note->delete;
  $notebook->delete;

=head1 DESCRIPTION

This module priovides you an Object Oriented interface for Google Notebook, using unofficial API.

=head1 METHODS

=head2 new(username => $username, password => $password)

Returns an instance of this module.

=head2 login

Login to Google.

=head2 notebooks

Returns your notebooks as L<WWW::Google::Notebook::Notebook> objects.

=head2 add_notebook($title)

Adds notebook.
Returns a created notebook as L<WWW::Google::Notebook::Notebook> object.

=head1 ACCESSOR

=over 4

=item username

=item password

=item ua

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<http://www.google.com/notebook/>

=back

=cut
