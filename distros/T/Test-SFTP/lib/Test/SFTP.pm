use strict;
use warnings;
package Test::SFTP;
{
  $Test::SFTP::VERSION = '1.10';
}
# ABSTRACT: An object to help test SFTPs

use Carp;
use Moose;
use English '-no_match_vars';
use Test::Builder;
use Net::SFTP::Foreign;
use namespace::autoclean;

use parent 'Test::Builder::Module';

# variables for the connection
has 'host'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'user'     => ( is => 'ro', isa => 'Str'                );
has 'password' => ( is => 'ro', isa => 'Str'                );

has 'debug'    => ( is => 'ro', isa => 'Int', default => 0  );
has 'port'     => ( is => 'ro', isa => 'Int'                );
has 'timeout'  => ( is => 'ro', isa => 'Int'                );
has 'more'     => ( is => 'ro', isa => 'ArrayRef'           );

# this holds the object itself. that way, users can do:
# $t_sftp->object->get() in a raw manner if they want
has 'object' => (
    is         => 'rw',
    isa        => 'Net::SFTP::Foreign',
    lazy_build => 1,
);

has 'connected' => ( is => 'rw', isa => 'Bool', default => 0 );

my $CLASS = __PACKAGE__;

sub _build_object {
    my $self = shift;
    my @more = ();
    my %opts = ();

    $self->user     and $opts{'user'}     = $self->user;
    $self->password and $opts{'password'} = $self->password;
    $self->more     and push @more, @{ $self->more };
    $self->debug    and push @more, '-v';

    if ( my $timeout = $self->timeout ) {
        $opts{'timeout'} = $timeout;
        push @more, '-o', "ConnectTimeout=$timeout";
    }

    my $object = Net::SFTP::Foreign->new(
        host => $self->host,
        more => \@more,
        %opts,
    );

    $object->error ? $self->connected(0) : $self->connected(1);

    return $object;
}

sub BUILD {
    my $self  = shift;
    my $EMPTY = q{};
    $self->object;
}

sub can_connect {
    my ( $self, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->object( $self->_build_object );
    $tb->ok( ! $self->object->error(), $test );
}

sub cannot_connect {
    my ( $self, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->object( $self->_build_object );;
    $tb->ok( $self->object->error, $test );
}

sub is_status {
    my ( $self, $status, $test ) = @_;
    my $tb = $CLASS->builder;

    $tb->is_eq( $self->object->status, $status, $test );
}

sub is_error {
    my ( $self, $error, $test ) = @_;
    my $tb = $CLASS->builder;

    $tb->is_eq( $self->object->error, $error, $test );
}

sub can_get {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb    = $CLASS->builder;
    my $EMPTY = q{};

    $self->connected || $self->connect;

    $tb->ok( $self->object->get( $local, $remote ), $test );
}

sub cannot_get {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    $tb->ok( !$self->object->get( $local, $remote ), $test );
}

sub can_put {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    my $eval_error = eval { $self->object->put( $local, $remote ); };
    $tb->ok( $eval_error, $test );
}

sub cannot_put {
    my ( $self, $local, $remote, $test ) = @_;
    my $tb = $CLASS->builder;

    $self->connected || $self->connect;

    my $eval_error = eval { $self->object->put( $local, $remote ); };
    $tb->ok( !$eval_error, $test );
}

sub can_ls {
    my ( $self, $path, $test ) = @_;
    my $tb = $CLASS->builder;
    $self->connected || $self->connect;
    my $eval_error = eval { $self->object->ls($path); };
    $tb->ok( $eval_error, $test );
}

sub cannot_ls {
    my ( $self, $path, $test ) = @_;
    my $tb = $CLASS->builder;
    $self->connected || $self->connect;
    my $eval_error = eval { $self->object->ls($path); };
    $tb->ok( !$eval_error, $test );
}

no Moose;

1;



=pod

=head1 NAME

Test::SFTP - An object to help test SFTPs

=head1 VERSION

version 1.10

=head1 SYNOPSIS

    use Test::SFTP;

    my $t_sftp = Test::SFTP->new(
        host     => 'localhost',
        user     => 'sawyer',
        password => '2o7U!OYv',
        ...
    );

    $t_sftp->can_get( $remote_path, $local_path, "Getting $remote_path" );

    $t_sftp->can_put(
        $local_path,
        $remote_path,
        "Trying to copy $local_path to $remote_path",
    );

=head1 DESCRIPTION

Unlike most testing frameworks, I<Test::SFTP> provides an object oriented
interface. The reason is that it's simply easier to use an object than throw the
login information as command arguments each time.

=head1 ATTRIBUTES

Most attributes (at least those you can set on initialization) are read-only.
That means they cannot be set after the object was already created.

    $t_sftp->new(
        host     => 'localhost',
        user     => 'root'
        password => 'p455w0rdZ'
        debug    => 1     # default: 0
        more     => [ qw( -o PreferredAuthentications=password ) ]
        timeout  => 10    # 10 seconds timeout for the connection
    );

=head2 host

The host you're connecting to.

=head2 user

Username you're connecting with.

If you do not specify this explicitly, it will use the user who is running
the application.

=head2 password

Password for the username you're connecting with.

If you do not specify this explicitly, it will try other connection methods
such as SSH keys.

=head2 port

Port you're connecting to.

=head2 debug

This flag turns on verbose for I<Net::SFTP::Foreign>.

=head2 more

SSH arguments, such as used in I<Net::SFTP::Foreign>, I<Net::OpenSSH> or plain
OpenSSH.

=head2 timeout

This turns on both connection timeout (via I<-o ConnectTimeout=$time>) for ssh
and a timeout for every data request.

It is recommended to set a timeout, or the test might hang for a very long time
if the target is unavailable.

=head2 Sensitive Attributes

=over 4

=item connected

A boolean attribute to note whether the I<Net::SFTP::Foreign> object is
connected.

Most methods used need the object to be connected. This attribute is used
internally to check if it's not connected yet, and if it isn't, it reconnect.

You can use this attribute to check whether it's connected internally in your
test script or run it using I<< $t_sftp->is_connected >> as a test.

However, try not to set this attribute.

=item C<< $t_sftp->object($object) >>

This holds the object of I<Net::SFTP::Foreign>. It's there to allow users more
fingergrain access to the object. With that, you can do:

    is(
        $t_sftp->object->some_method( ... ),
        'Specific test not covered in the framework',
    );

Please refer to L<Net::SFTP::Foreign> for all the attributes and methods it
supports.

=back

=head1 SUBROUTINES/METHODS

=head2 $t_sftp->can_connect($test_name)

Checks whether we were able to connect to the machine.

=head2 $t_sftp->cannot_connect($test_name)

Checks whether we were B<not> able to connect to the machine.

=head2 $t_sftp->is_status( $string , $test_name )

Checks the status code returned from the SFTP server.

This is practicely the FX2TXT.

=head2 $t_sftp->is_error( $string , $test_name )

Checks for a certain SFTP error existing.

=head2 $t_sftp->can_get( $remote, $local, $test_name )

Checks whether we're able to get a file from C<$remote> to C<$local>.

=head2 $t_sftp->cannot_get( $remote, $local, $test_name )

Checks whether we're unable to get a file from C<$remote> to C<$local>.

=head2 $t_sftp->can_put( $local, $remote, $test_name )

Checks whether we're able to upload a file from C<$local> to C<$remote>.

=head2 $t_sftp->cannot_put( $local, $remote, $test_name )

Checks whether we're unable to upload a file from C<$local> to C<$remote>.

=head2 $t_sftp->can_ls( $path, $test_name )

Checks whether we're able to ls a folder or file. Can be used to check the
existence of files or folders.

=head2 $t_sftp->cannot_ls( $path, $test_name )

Checks whether we're unable to ls a folder or file. Can be used to check the
nonexistence of files or folders.

=head2 BUILD

Internal L<Moose> function used to initialize the object. Do not touch. :)

=head1 DEPENDENCIES

L<Moose>

L<Expect>

L<IO::Pty>

L<Net::SFTP::Foreign>.

L<Test::Builder>

L<namespace::autoclean>

L<parent>

=head1 DIAGNOSTICS

You can use the B<object> attribute to access the I<Net::SFTP::Foreign> object
directly.

=head1 CONFIGURATION AND ENVIRONMENT

Some tests in the module require creating and removing files. As long as we
don't have complete control over the environment we're going to connect to, it's
hard to know if we're gonna upload a file that perhaps already exists already.
We try hard to avoid it by creating a file with a random number as the filename.

So, in previous versions (actually, only 1), these tests were mixed with all the
other tests so if you had set the environment variable to testing, it would test
it with everything. If you don't, it would not test a bunch of other tests that
aren't dangerous at all.

To ask for this to be tested as well, set the environment variable
TEST_SFTP_DANG.

=head1 INCOMPATIBILITIES

The default backend in L<Net::SFTP::Foreign> uses L<Expect> for password
authentication. Unfortunately, on windows, it only works using Cygwin Perl.

So, if you're using Windows and need password authentication, you might want to
use I<plink> instead of OpenSSH SSH client or the Net_SSH2 backend.

=head1 BUGS AND LIMITATIONS

This module will have the same limitations that exist for
I<Net::SFTP::Foreign>, though probably more.

Please report any bugs or feature requests to C<bug-test-sftp at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-SFTP>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::SFTP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-SFTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-SFTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-SFTP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-SFTP/>

=back

=head1 ACKNOWLEDGEMENTS

Salvador Fandiño García for L<Net::SFTP::Foreign>, L<Net::OpenSSH>, being a
responsive dedicated author and a really nice guy! :)

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

