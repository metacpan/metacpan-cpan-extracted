package WebService::Raygun::Message::User;
$WebService::Raygun::Message::User::VERSION = '0.030';
use Mouse;

=head1 NAME

WebService::Raygun::Message::User - Represent the I<User> data in a raygun request.

=head1 SYNOPSIS

    use WebService::Raygun::Message::User;
    my $user = WebService::Raygun::User->new(
        identifier   => "123456",
        email        => 'test@test.com',
        is_anonymous => undef,
        full_name    => 'Firstname Lastname',
        first_name   => 'Firstname',
        uuid         => '783491e1-d4a9-46bc-9fde-9b1dd9ef6c6e'
    );


=head1 DESCRIPTION

The user data is all optional and may be left blank. This class just
initialises them with empty strings or 1s or 0s depending on the context. The
L<prepare_raygun> method may be called to retreive the structure in a form
that can be converted directly to JSON.


=head1 INTERFACE

=cut


use Data::GUID 'guid_string';
use Mouse::Util::TypeConstraints;

subtype 'RaygunUser' => as 'Object' => where {
    $_->isa('WebService::Raygun::Message::User');
};

coerce 'RaygunUser' => from 'Str' => via {
    return WebService::Raygun::Message::User->new(email => $_, identifier => $_) if $_ =~ /[^@]+\@[^\.]+\..*/;
    return WebService::Raygun::Message::User->new(identifier => $_);
} => from 'Int' => via {
    return WebService::Raygun::Message::User->new(identifier => "$_");
} =>  from 'HashRef' => via {
    return WebService::Raygun::Message::User->new(%{$_});
};
no Mouse::Util::TypeConstraints;

=head2 identifier

Something to identify the user.

=cut

has identifier => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    default => '',
);

=head2 email

Email address of logged in user.

=cut

has email => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=head2 is_anonymous

Indicates whether or not the user is logged into your app.

=cut

has is_anonymous =>
  ( is => 'rw', isa => 'Bool', default => sub { return 1; } );

=head2 full_name

User's full name.

=cut

has full_name => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

=head2 first_name

User's first name.

=cut

has first_name => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

=head2 uuid

Device unique identifier. Useful if sending from mobile device.

=cut

has uuid =>
  ( is => 'rw', isa => 'Str', default => sub { return guid_string; } );

=head2 prepare_raygun

Return the data structure that will be sent to raygun.io

=cut

sub prepare_raygun {
    my $self = shift;
    return {
        identifier => $self->identifier,
        isAnonymous => $self->is_anonymous,
        email => $self->email,
        fullName => $self->full_name,
        firstName => $self->first_name,
        uuid => $self->uuid,
    };

}

=head1 DEPENDENCIES


=head1 SEE ALSO

=cut

__PACKAGE__->meta->make_immutable();

1;

__END__
