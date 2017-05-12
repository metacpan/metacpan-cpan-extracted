package WWW::HatenaDiary;
use strict;
use warnings;
use Carp;
use URI;
use Web::Scraper;
use WWW::Mechanize;
use WWW::HatenaLogin;
use JSON::Syck 'Load';

our $VERSION = '0.02';

sub new {
    my ($class, $args) = @_;
    my $base     = $args->{group} ? "http://$args->{group}.g.hatena.ne.jp/" :
                                    'http://d.hatena.ne.jp/';
    my $self     = bless {
        base     => $base,
        group    => $args->{group},
        login    => $args->{login} || WWW::HatenaLogin->new({ nologin => 1, %{ $args } }),
        verbose  => $args->{verbose},
    }, $class;

    if ($self->is_loggedin) {
        my $username = scraper {
            process '//td[@class="username"]/a', 'username' => 'TEXT';
            result 'username';
        }->scrape($self->{login}->mech->content, $self->{login}->login_uri);
        $self->{login}->username($username) if !$self->{login}->username;
        $self->{diary}    = $self->{base}.$self->{login}->username.'/';
    }

    $self;
}

sub is_loggedin {
    my $self = shift;
    $self->{login}->is_loggedin;
}

sub login {
    my ($self, $args) = @_;

    $self->{login}->login($args);
    $self->{diary} = $self->{base}.$self->{login}->username.'/';

    !!($self->{rkm} = $self->get_rkm) ||
        croak 'Login failed. Please confirm your username/password';
}

sub get_rkm {
    my $self = shift;
    my $rkm;

    $self->{login}->mech->get("$self->{diary}?mode=json");
    eval {
        $rkm = Load($self->{login}->mech->content)->{rkm};
    };

    $rkm;
}

sub create {
    my ($self, $args) = @_;
    $self->_post_entry($args);
}

sub create_day {
    shift->update_day(@_);
}

sub retrieve {
    my ($self, $args) = @_;

    croak('URI for the entry is required')
        if !$args->{uri};

    $self->{login}->mech->get("$args->{uri}?mode=json");
    Load($self->{login}->mech->content);
}

sub retrieve_day {
    my ($self, $args) = @_;

    croak('Date is required')
        if !$args->{date};

    if ($args->{date} =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        my ($y, $m, $d) = ($1, $2, $3);

        my $uri = "$self->{diary}edit?date=$y$m$d";
        $self->{login}->mech->get($uri);
        my $form = $self->{login}->mech->form_name('edit');

        {
            title => $form->value('title'),
            body  => $form->value('body'),
        };
    } else {
        carp "Invalid ymd format: $args->{date}. YYYY-MM-DD formatted date is required.";
    }
}

sub update {
    my ($self, $args) = @_;

    croak('URI for the entry is required')
        if !$args->{uri};

    $self->_post_entry($args);
    $args->{uri};
}

sub update_day {
    my ($self, $args) = @_;

    croak('Date is required')
        if !$args->{date};

    if ($args->{date} =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        my ($y, $m, $d) = ($1, $2, $3);

        my $uri = "$self->{diary}edit?date=$y$m$d";
        $self->{login}->mech->get($uri);
        $self->{login}->mech->submit_form(
            form_name => 'edit',
            fields => {
                title => $args->{title},
                body  => $args->{body},
                year  => $y,
                month => $m,
                day   => $d,
            },
        );
    }
    else {
        carp "Invalid ymd format: $args->{date}. YYYY-MM-DD formatted date is required.";
    }

    $self->{login}->mech->success;
}

# XXX: It's dubious if this implementation is correct...
sub delete {
    my ($self, $args) = @_;

    croak('URI for the entry is required')
        if !$args->{uri};

    my ($y, $m, $d, $slag) = $args->{uri} =~ m|^$self->{diary}(\d{4})(\d{2})(\d{2})/(.+)$|;
    my $body = $self->retrieve_day({date => join('-', $y, $m, $d)})->{body};

    croak "Entry for $args->{uri} not found"
        if !$body;

    my @update_body = ();
    my $delete_flag = 0;
    my $match       = qr/\*$slag\*/;
    my $unmatch     = qr/\*(.+)\*/;

    for ($body =~ /^(.*)$/mg) {
        $delete_flag = 0 if /$unmatch/ && $delete_flag;
        $delete_flag = 1 if /$match/;
        push @update_body, $_ if !$delete_flag;
    }

    $self->update_day({
        date => join('-', $y, $m, $d),
        body => join("\n", @update_body),
    });
}

sub delete_day {
    my ($self, $args) = @_;

    croak('Date is required')
        if !$args->{date};

    if ($args->{date} =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        my ($y, $m, $d) = ($1, $2, $3);
        my $uri = "$self->{diary}edit?date=$y$m$d";

        $self->{login}->mech->get($uri);

        if ($self->{group}) {
            for my $form ($self->{login}->mech->forms) {
                if ($form->action =~ /deletediary$/) {
                    $self->{login}->mech->request($form->click);
                }
            }
        }
        else {
            $self->{login}->mech->submit_form(form_number => 2);
        }
    }
    else {
        carp "Invalid ymd format: $args->{date}. YYYY-MM-DD formatted date is required.";
    }

    $self->{login}->mech->success;
}

sub _post_entry {
    my ($self, $args) = @_;
    my $uri = $args->{uri} || $self->{diary};

    $self->{login}->mech->post($uri, {
        rkm => $self->{rkm},
        %$args,
    });

    $self->{login}->mech->get($uri);

    scraper {
        process '//div[@class="section"][1]/h3[1]/a[1]', 'uri' => '@href';
        result 'uri';
    }->scrape($self->{login}->mech->content, URI->new($self->{diary}));
}

1;

__END__

=head1 NAME

WWW::HatenaDiary - CRUD interface to Hatena::Diary

=head1 SYNOPSIS

  use WWW::HatenaDiary;

  my $diary = WWW::HatenaDiary->new({
      username => $username,
      password => $password,
      group    => $group,
      mech_opt => {
          timeout    => $timeout,
          cookie_jar => HTTP::Cookies->new(...),
      },
  });

  # Or just pass a WWW::HatenaLogin object like below if you already have it.
  # See the POD of it for details
  my $diary = WWW::HatenaDiary->new({
      login => $login                 # it's a WWW::HatenaLogin object
  });

  # Check if already logged in to Hatena::Diary
  # If you have a valid cookie, you can omit this process
  if (!$diary->is_loggedin) {
      $diary->login({
          username => $username,
          password => $password,
      });
  }

  # Create
  my $edit_uri = $diary->create({
      title => $title,
      body  => $body,
  });

  $diary->create_day({
      date  => $date,     # $date must be YYYY-MM-DD formatted string
      title => $title,
      body  => $body,
  });

  # Retrieve
  my $post = $diary->retrieve({
      uri  => $edit_uri,
  })

  my $day  = $diary->retrieve_day({
      date => $date,     # $date must be YYYY-MM-DD formatted string
  });

  # Update
  $edit_uri = $diary->update({
      uri   => $edit_uri,
      title => $new_title,
      body  => $new_body,
  });

  $diary->update_day({
      date  => $date,     # $date must be YYYY-MM-DD formatted string
      title => $new_title,
      body  => $new_body,
  });

  # Delete
  $diary->delete({
      uri => $edit_uri,
  });

  $diary->delete_day({,
      date => $date,     # $date must be YYYY-MM-DD formatted string
  });

=head1 DESCRIPTION

WWW::HatenaDiary provides a CRUD interface to Hatena::Diary, aiming to
help you efficiently communicate with the service with programmatic
ways.

This module is, so far, for those who want to write some tools not
only to retrieve data from diaries, but also to create/update/delete
the posts at the same time. Which is why I adopted the way as if this
module treats such API like AtomPub, and this module retrieves and
returns a raw formatted post content not a data already converted to
HTML.

=head1 METHODS

=head2 new ( I<\%args> )

=over 4

  my $diary = WWW::HatenaDiary->new({
      username => $username,
      password => $password,
      group    => $group,
      mech_opt => {
          timeout    => $timeout,
          cookie_jar => HTTP::Cookies->new(...),
      },
  });

  # or...

  my $diary = WWW::HatenaDiary->new({
      login => $login                 # it's a WWW::HatenaLogin object
  });


Creates and returns a new WWW::HatenaDiary object. If you have a valid
cookie and pass it into this method as one of C<mech_opt>, you can
omit C<username> and C<password>. Even in that case, you might want to
check if the user agent already logs in to Hatena::Diary using
C<is_loggedin> method below.

C<group> field is optional, which will be required if you want to work
with your diary on Hatena::Group.

C<mech_opt> field is optional. You can use it to customize the
behavior of this module in the way you like. See the POD of
L<WWW::Mechanize> for more details.

C<login> field is also optional. If you already have a
L<WWW::HatenaLogin> object, you can use it to communicate with
Hatena::Diary after just passing it as the value of the field. See the
POD of L<WWW::HatenaLogin> for more details.

=back

=head2 is_loggedin ()

=over 4

  if(!$diary->is_loggedin) {
      ...
  }

Checks if C<$diary> object already logs in to Hatena::Diary.

=back

=head2 login ( [I<\%args>] )

=over 4

  $diary->login({
      username => $username,
      password => $password,
  });

Logs in to Hatena::Diary using C<username> and C<password>. If either
C<username> or C<password> isn't passed into this method, the values
which are passed into C<new> method above will be used.

=back

=head2 create ( I<\%args> )

=over 4

  my $edit_uri = $diary->create({
      title => $title,
      body  => $body,
  });

Creates a new post and returns a URI as a L<URI> object for you to
retrieve/update/delete the post later on.

=back

=head2 create_day ( I<\%args> )

=over 4

  $diary->create_day({
      date  => $date,   # $date must be YYYY-MM-DD formatted string
      title => $title,
      body  => $body,
  });

Creates a new date-based container of the C<date>.

C<body> must be a Hatena::Diary style formatted data, that is, this
method emulates the way when you write a post on your browser and send
it via the form.

This method is actually only an alias of C<update_day> method
described below, so that you should be sure this method erases and
updates your existing entries against your expectation if the
container of C<date> already exists.

=back

=head2 retrieve ( I<\%args> )

=over 4

  my $post = $diary->retrieve({
      uri => $edit_uri,
  })

Retrieves the post for C<uri>.

=over 4

=item * title

Title of the post.

=item * body

Content of the post as a raw formatted data.

=item * editable

Flag if you're authorized to edit the post or not.

=item * rkm

Token which is internally used when this module sends a request. You
needn't care about it.

=back

=back

=head2 retrieve_day ( I<\%args> )

=over 4

  my $day  = $diary->retrieve_day({
      date => $date, # $date must be YYYY-MM-DD formatted string
  });

Retrieves the title and body for C<date> as a reference to a hash that
contains C<title> and C<body> field. So far, this method gets only
the raw formatted content of the post.

=back

=head2 update ( I<\%args> )

=over 4

  $edit_uri = $diary->update({
      uri   => $edit_uri,
      title => $new_title,
      body  => $new_body,
  });

Updates the post for C<uri> and returns the URI as a L<URI> object for
you to do with the post still more.

=back

=head2 update_day ( I<\%args> )

=over 4

  $diary->update_day({
      date  => $date,     # $date must be YYYY-MM-DD formatted string
      title => $new_title,
      body  => $new_body,
  });

Updates whole the posts of the C<date>.

C<body> must be a Hatena::Diary style formatted data, that is, this
method emulates the way when you write a post on your browser and send
it via the form.

=back

=head2 delete ( I<\%args> )

=over 4

  $diary->delete({
      uri => $edit_uri,
  });

Deletes the post for C<uri>.

=back

=head2 delete_day ( I<\%args> )

=over 4

  $diary->delete_day({
      date => $date, # $date must be YYYY-MM-DD formatted string
  });

Deletes whole the posts of the C<date>.

=back

=head1 SEE ALSO

=over 4

=item * Hatena::Diary (Japanese)

L<http://d.hatena.ne.jp/>

=item * L<WWW::HatenaLogin>

=item * L<WWW::Mechanize>

=back

=head1 ACKNOWLEDGMENT

typester++ for some codes copied from L<Fuse::Hatena>.

Yappo++ for improving this module using L<WWW::HatenaLogin>

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom gmail comE<gt>

Kentaro Kuribayashi E<lt>kentaro cpan orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
