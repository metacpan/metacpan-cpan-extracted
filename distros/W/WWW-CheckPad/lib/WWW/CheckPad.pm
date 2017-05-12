package WWW::CheckPad;

use 5.008006;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(ua
                             base_url
                             has_logged_in
                         ));

our $VERSION = '0.035';

our $connection;


BEGIN {
    # use Jcode::convert if we have Jcode.pm.
    # otherwise, don't do anything.
    # TODO: We should be able to use other
    # character converter(ex, jcode.pl, Encode).
    my $have_jcode;
    eval { require Jcode; $have_jcode = 1 };

    if ($have_jcode) {
        *_jconvert = sub {
            Jcode::convert($_[1], $_[2]?$_[2]:'euc-jp')
        }
    }
    else {
        carp "Couldn't use Jcode.pm. WWW::CheckPad won't convert Japanese " .
            "character. We prefer to include Jcode.pm into your path.";
        *_jconvert = sub { $_[1] };
    }
}


sub connect {
    my ($class, %connect_info) = @_;

    $connection = $class->_new(
        user => {
            email => $connect_info{email},
            password => $connect_info{password},
        },
    );
    return $connection;
}


sub disconnect {
    my ($class) = @_;

    return if not defined $connection or not $connection->has_logged_in();

    $connection->_logout();
    $connection->has_logged_in(0);
}

###########################################################################

## DO NOT USE THIS FROM OUTSIDE OF THIS MODULE
sub _new {
    my ($class, %params) = @_;
    my $self = {};
    bless $self, $class;
    $self->base_url( ($params{base_url} ?
                          $params{base_url} :
                              'http://www.checkpad.jp/'));

    ## If user specified login info, save it.
    $self->user(%{$params{user}}) if $params{user};

    ## Set up LWP::UserAgent
    $self->ua(new LWP::UserAgent());
    $self->ua->cookie_jar(HTTP::Cookies->new(file => 'cookie.jar',
                                             autosave => 1));

    ## Login if user info was specified.
    if ($self->user->{email} and $self->user->{password}) {
        $self->_login();
    }

    return $self;
}


# returns domain of the base_url.
# TODO: It might be better to use URI::URL(cpan) module to 
#       control URL <-> Domain.
sub _domain {
    my ($self) = @_;
    $self->base_url =~ /http:\/\/(.*)\//;
    return $1;
}


# user info looks like this.
# {email => foo, password => hoge}
sub user {
    my ($self, %user_info) = @_;
    $self->{_user} = {} if not defined $self->{_user};
    $self->{_user}->{email} = $user_info{email} if $user_info{email};
    $self->{_user}->{password} = $user_info{password} if $user_info{password};
    return $self->{_user};
}


sub _login {
    my ($self) = @_;
    if (not $self->user->{email} or not $self->user->{password}) {
        croak('Have to specified email and password to CheckPad::user()');
        return undef;
    }

    my %form = (
        login_email => $self->user->{email},
        login_pwd => $self->user->{password},
        mode => 'sys',
        act => 'login'
    );
    my $response = $self->ua->request(POST $self->base_url(), \%form);

    ## Check the cookies to find out the login has succeed or not.
    $self->ua->cookie_jar->scan(
        sub {
            my ($domain, $key, $value) = @_[4, 1, 2];
            if ($domain eq $self->_domain and
                    $key eq 'kj_my_id' and
                        $value ne '') {
                $self->has_logged_in(1);
            }
        });
    return $self->has_logged_in();
}


sub _logout {
    my ($self) = @_;

    return if not $self->has_logged_in();

    my %form = (
        mode => 'sys',
        act => 'logout',
    );

    $self->_request(\%form);
}


sub _urldecode {
    my ($self, $data) = @_;
    $data =~ s/%([0-9a-f][0-9a-f])/pack("C",hex($1))/egi;
    return $data;
}


# Just simply access to server and returns response from the server.
sub _request {
    my ($self, $info) = @_;

    $info->{form} ||= {};
    $info->{path} ||= '';

    # Convert all form values to specified character encoding.
    foreach my $key (keys %{$info->{form}}) {
        my $value = $info->{form}->{$key};
        $info->{form}->{$key} = $self->_jconvert($value, $info->{encoding});
    }

    my $url = $self->base_url . $info->{path};
    my $res = $self->ua->request(POST $url, $info->{form});

#    print "*******************************************************************\n";
#    $self->dumper($res);

    croak "There was an error during accessing to the chech*pad:\n",
        $res->as_string if $res->code =~ /^[45]\d\d$/;

    return $res;
}


sub dumper {
    my ($self, $table, $indent) = @_;

    foreach my $key (keys %{$table}) {
        my $value = $table->{$key};
        if (ref $value eq 'HASH' or (ref $value) =~ /HTTP/) {
            $self->dumper($value, $indent + 4);
        }
        else {
            printf "%s%s = %s(%s)\n", ' ' x $indent, $key, $value, ref $value;
        }
    }
}



sub _get_cookie_of {
    my ($self, $search_key) = @_;
    my $result = undef;
    
    $self->ua->cookie_jar->scan(
        sub {
            my ($domain, $key, $value) = @_[4, 1, 2];
            return unless $domain eq $self->_domain;

            if ($key eq $search_key) {
                $result = $self->_urldecode($value);
            }
        }
    );
    return $result;
}

sub _clear_cookie_of {
  my ($self, $search_key) = @_;
  $self->ua->cookie_jar->clear($self->_domain, '/', $search_key);
}




##############################################################################
1;
__END__

=head1 NAME

WWW::CheckPad - An API to control the check*pad (http://www.checkpad.jp/)

=head1 SYNOPSIS

  use WWW::CheckPad;
  use WWW::CheckPad::CheckList;
  use WWW::CheckPad::CheckItem;

  ## Connect and login to the check*pad.
  WWW::CheckPad->connect({
    email => 'your email address',
    password => 'your password'
  });

  ## Add new checklist.
  my $new_checklist = WWW::CheckPad::CheckList->insert({
      title => 'Private Todo List'
  });

  ## Let's add todo items to the list.
  my $cut_my_nail = $new_checklist->add_checkitem('Cut my nail.');
   my $buy_a_cat_food = $new_checklist->add_checkitem('Buy a cat food.');

  ## ... After a few minutes ...

  ## OK! I cut my nail.
  $cut_my_nail->finish();

  ## Oh! I remember. I don't have a cat but I have a dog.
  $buy_a_cat_food->title('Buy a dog food');
  $buy_a_cat_food->update();

  ## I need to see all of my todo list and items which are not finished.
  foreach my $checklist (WWW::CheckPad::CheckList->retrieve_all) {
      foreach my $checkitem (grep {not $_->is_finished} $checklist->checkitems) {
          printf "[%s] %s\n", $checklist->title, $checkitem->title;
      }
  }


  ## Disconnecting from server is always good practice.
  WWW::CheckPad->disconnect();

=head1 DESCRIPTION

WWW::CheckPad will allow you to control check*pad (http://www.checkpad.jp/)
from your program. Before using this module, you need to have your account
for the check*pad (see the check*pad web site).

=item WWW::CheckPad->connect

  my $connection = WWW::CheckPad->connect({
    email => 'your email address',
    password => 'your password'
  })

You have to call this connect method before calling any methods in
WWW::CheckPad::CheckList or WWW::CheckPad::CheckItem. You can check
the login successed or not by calling has_logged_in method (see below).

=item has_logged_in

  $connection->has_logged_in()

This will return true if the user logged in to the check*pad.

=head1 SEE ALSO

WWW::CheckPad::CheckList

WWW::CheckPad::CheckItem

=head1 AUTHOR

Ken Takeshige, E<lt>ken.takeshige@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ken Takeshige

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
