package Yukki::Model::User;
{
  $Yukki::Model::User::VERSION = '0.140290';
}
use Moose;

extends 'Yukki::Model';

use Yukki::Types qw( LoginName );

use Path::Class;
use MooseX::Params::Validate;
use MooseX::Types::Path::Class;
use YAML qw( LoadFile );

# ABSTRACT: lookup users


sub find {
    my ($self, $login_name) = validated_list(\@_,
        login_name => { isa => LoginName },
    );

    my $user_file = $self->locate('user_path', $login_name);
    if (-e $user_file) {
        return LoadFile($user_file);
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Yukki::Model::User - lookup users

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  my $users = $app->model('User');
  my $user  = $users->find('bob');

  my $login_name = $user->{login_name};
  my $password   = $user->{password};
  my $name       = $user->{name};
  my $email      = $user->{email};
  my @groups     = @{ $user->{groups} };

=head1 DESCRIPTION

Read access to the current list of authorized users.

=head1 METHODS

=head2 find

  my $user = $users->find($login_name);

Returns a hash containing the information related to a specific user named by login name.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
