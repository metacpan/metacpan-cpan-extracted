use 5.006;
use strict;
use warnings;

package Test::Net::LDAP::Mock;

use base 'Test::Net::LDAP';

use IO::Socket;
use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SUCCESS);

=head1 NAME

Test::Net::LDAP::Mock - A mock LDAP client with simulated search in memory

=cut

=head1 SYNOPSIS

All the LDAP operations are performed in memory, instead of connecting to the
real LDAP server.

    use Test::Net::LDAP::Mock;
    my $ldap = Test::Net::LDAP::Mock->new();

C<Test::Net::LDAP::Mock> is a subclass of L<Test::Net::LDAP>, which is
a subclass of L<Net::LDAP>.

In the actual test code, L<Test::Net::LDAP::Util/ldap_mockify> should be used to mock
all the C<Net::LDAP> instances in your application code.

    use Test::More tests => 1;
    use Test::Net::LDAP::Util qw(ldap_mockify);
    
    ldap_mockify {
        # Anywhere in this block, all the occurrences of Net::LDAP::new are
        # replaced by Test::Net::LDAP::Mock::new
        ok my_application_routine();
    };

Note: if no LDAP entries have been added to the in-memory directory, the
C<search> method will silently succeed with no entries found.

Below is an example to set up some fake data for particular test cases.

    use Test::More tests => 1;
    use Test::Net::LDAP::Util qw(ldap_mockify);
    
    ldap_mockify {
        my $ldap = Net::LDAP->new('ldap.example.com');
        
        $ldap->add('uid=user1, ou=users, dc=example, dc=com');
        $ldap->add('uid=user2, ou=users, dc=example, dc=com');
        $ldap->add('cn=group1, ou=groups, dc=example, dc=com', attrs => [
            member => [
                'uid=user1, ou=users, dc=example, dc=com',
                'uid=user2, ou=users, dc=example, dc=com',
            ]
        ]);
        
        ok my_application_routine();
    };

C<Test::Net::LDAP::Mock> maintains a shared LDAP directory tree for the same
host/port, while it separates the directory trees for different
host/port combinations.
Thus, it is important to specify a correct server location consistently.

=head1 DESCRIPTION

=head2 Overview

C<Test::Net::LDAP::Mock> provides all the operations of C<Net::LDAP>, while
they are performed in memory with fake data that are set up just for testing.

It is most useful for developers who write testing for an application that
uses LDAP search, while they do not have full control over the organizational
LDAP server.
In many cases, developers do not have write access to the LDAP data, and the
organizational information changes over time, which makes it difficult to write
stable test cases with LDAP.
C<Test::Net::LDAP::Mock> helps developers set up any fake LDAP directory tree
in memory, so that they can test sufficient varieties of senarios for the
application.

Without this module, an alternative way to test an application using LDAP is to
run a real server locally during testing. (See how C<Net::LDAP> is tested with
a local OpenLDAP server.)
However, it may not be always trivial to set up such a server with correct
configurations and schemas, where this module makes testing easier.

=head2 LDAP Schema

In the current version, the LDAP schema is ignored when entries are added or
modified, although a schema can optionally be specified only for the search
filter matching (based on L<Net::LDAP::FilterMatch>).

An advantage is that it is much easier to set up fake data with any arbitrary
LDAP attributes than to care about all the restrictions with the schema.
A disadvantage is that it cannot test schema-sensitive cases.

=head2 Controls

LDAPv3 controls are not supported (yet).
The C<control> parameter given as an argument of a method will be ignored.

=head1 METHODS

=head2 new

Creates a new object. It does not connect to the real LDAP server.
Each object is associated with a shared LDAP data tree in memory, depending on
the target (host/port/path) and scheme (ldap/ldaps/ldapi).

    Test::Net::LDAP::Mock->new();
    Test::Net::LDAP::Mock->new('ldap.example.com', port => 3389);

=cut

my $mock_map = {};
my $mock_target;

my $mockified = 0;
my @mockified_subclasses;

sub new {
    my $class = shift;
    $class = ref $class || $class;

    if ($mockified) {
        if ($class eq 'Net::LDAP') {
            # Net::LDAP
            $class = __PACKAGE__;
        } elsif (!$class->isa(__PACKAGE__)) {
            # Subclass of Net::LDAP (but not yet of Test::Net::LDAP::Mock)
            _mockify_subclass($class);
        }
    }

    my $target = &_mock_target;
    
    my $self = bless {
        mock_data  => undef,
        net_ldap_socket => IO::Socket->new(),
    }, $class;
    
    $self->{mock_data} = ($mock_map->{$target} ||= do {
        require Test::Net::LDAP::Mock::Data;
        Test::Net::LDAP::Mock::Data->new($self);
    });
    
    return $self;
}

sub _mockify_subclass {
    my ($class) = @_;
    no strict 'refs';
    {
        unshift @{$class.'::ISA'}, __PACKAGE__;
    }
    use strict 'refs';

    push @mockified_subclasses, $class;
}

sub _unmockify_subclasses {
    no strict 'refs';
    {
        for my $class (@mockified_subclasses) {
            @{$class.'::ISA'} = grep {$_ ne __PACKAGE__} @{$class.'::ISA'};
        }
    }
    use strict 'refs';

    @mockified_subclasses = ();
}

sub _mock_target {
    my $host = shift if @_ % 2;
    my $arg = &Net::LDAP::_options;

    if ($mock_target) {
        my ($new_host, $new_arg);

        if (ref $mock_target eq 'CODE') {
            ($new_host, $new_arg) = $mock_target->($host, $arg);
        } elsif (ref $mock_target eq 'ARRAY') {
            ($new_host, $new_arg) = @$mock_target;
        } elsif (ref $mock_target eq 'HASH') {
            $new_arg = $mock_target;
        } else {
            $new_host = $mock_target;
        }

        $host = $new_host if defined $new_host;
        $arg = {%$arg, %$new_arg} if defined $new_arg;
    }

    my $scheme = $arg->{scheme} || 'ldap';

    # Net::LDAP->new() can take an array ref as hostnames, where
    # the first host that we can connect to will be used.
    # For the mock object, let's just pick the first one.
    if (ref $host) {
        $host = $host->[0] || '';
    }
    
    if (length $host) {
        if ($scheme ne 'ldapi') {
            if ($arg->{port}) {
                $host =~ s/:\d+$//;
                $host .= ":$arg->{port}";
            } elsif ($host !~ /:\d+$/) {
                $host .= ":389";
            }
        }
    } else {
        $host = '';
    }

    return "$scheme://$host";
}

sub _mock_message {
    my $self = shift;
    my $mesg = $self->message(@_);
    $mesg->{resultCode} = LDAP_SUCCESS;
    $mesg->{errorMessage} = '';
    $mesg->{matchedDN} = '';
    $mesg->{raw} = undef;
    $mesg->{controls} = undef;
    $mesg->{ctrl_hash} = undef;
    return $mesg;
}

#override
sub _send_mesg {
    my $ldap = shift;
    my $mesg = shift;
    return $mesg;
}

=head2 mockify

    Test::Net::LDAP::Mock->mockify(sub {
        # CODE
    });

Inside the code block (recursively), all the occurrences of C<Net::LDAP::new>
are replaced by C<Test::Net::LDAP::Mock::new>.

Subclasses of C<Net::LDAP> are also mockified. C<Test::Net::LDAP::Mock> is inserted
into C<@ISA> of each subclass, only within the context of C<mockify>.

See also: L<Test::Net::LDAP::Util/ldap_mockify>.

=cut

sub mockify {
    my ($class, $callback) = @_;

    if ($mockified) {
        $callback->();
    } else {
        $mockified = 1;
        local *Net::LDAP::new = *Test::Net::LDAP::Mock::new;
        eval {$callback->()};
        my $error = $@;
        _unmockify_subclasses();
        $mockified = 0;
        die $error if $error;
    }
}

=head2 mock_data

Retrieves the currently associated data tree (for the internal purpose only).

=cut

sub mock_data {
    return shift->{mock_data};
}

=head2 mock_schema

Gets or sets the LDAP schema (L<Net::LDAP::Schema> object) for the currently
associated data tree.

In this version, the schema is used only for the search filter matching (based
on L<Net::LDAP::FilterMatch> internally).
It has no effect for any modification operations such as C<add>, C<modify>, and
C<delete>.

=cut

sub mock_schema {
    my $self = shift;
    $self->mock_data->schema(@_);
}

=head2 mock_root_dse

Gets or sets the root DSE (L<Net::LDAP::RootDSE>) for the currently associated
data tree.

This should be set up as part of the test fixture before any successive call to
the C<root_dse()> method, since L<Net::LDAP> will cache the returned object.

    $ldap->mock_root_dse(
        namingContexts => 'dc=example,dc=com'
    );

Note: the namingContexts value has no effect on the restriction with the
topmost DN. In other words, even if namingContexts is set to
'dc=example,dc=com', the C<add()> method still allows you to add an entry to
'dc=somewhere-else'.

=cut

sub mock_root_dse {
    my $self = shift;
    $self->mock_data->mock_root_dse(@_);
}

=head2 mock_bind

Gets or sets a LDAP result code (and optionally a message) that will be used as a message
returned by a later C<bind()> call.

    use Net::LDAP::Constant qw(LDAP_INVALID_CREDENTIALS);
    $ldap->mock_bind(LDAP_INVALID_CREDENTIALS);
    $ldap->mock_bind(LDAP_INVALID_CREDENTIALS, 'Login failed');
    # ...
    my $mesg = $ldap->bind(...);
    $mesg->code && die $mesg->error; #=> die('Login failed')

In the list context, it returns an array of the code and message. In the scalar
context, it returns the code only.

Alternatively, this method can take a callback subroutine:

    $ldap->mock_bind(sub {
        my $arg = shift;
        # Validate $arg->{dn} and $arg->{password}, etc.
        if (...invalid credentials...) {
            return LDAP_INVALID_CREDENTIALS;
        }
    });

The callback can return a single value as the LDAP result code or an array in the form
C<($code, $message)>. If the callback returns nothing (or C<undef>), it is regarded as
C<LDAP_SUCCESS>.

=cut

sub mock_bind {
    my $self = shift;
    $self->mock_data->mock_bind(@_);
}

=head2 mock_password

Gets or sets the password for the simple password authentication with C<bind()>.

    $ldap->mock_password('uid=test, dc=example, dc=com' => 'test_password');
    # Caution: Passwords should usually *not* be hard-coded like this. Consider to load
    # passwords from a config file, etc.

The passwords are stored with the entry node in the data tree.

Once this method is used, the C<bind()> call will check the credentials whenever the
C<password> parameter is passed. Anonymous binding and all the other authentication
methods are not affected.

=cut

sub mock_password {
    my $self = shift;
    $self->mock_data->mock_password(@_);
}

=head2 mock_target

Gets or sets the target scheme://host:port to normalize the way for successive
C<Test::Net::LDAP::Mock> objects to resolve the associated data tree.

It is useful when normalizing the target scheme://host:port for different
combinations. For example, if there are sub-domains (such as ldap1.example.com
and ldap2.example.com) that share the same data tree, the target host should be
normalized to be the single master server (such as ldap.example.com).

    Test::Net::LDAP::Mock->mock_target('ldap.example.com');
    Test::Net::LDAP::Mock->mock_target('ldap.example.com', port => 3389);
    Test::Net::LDAP::Mock->mock_target(['ldap.example.com', {port => 3389}]);
    Test::Net::LDAP::Mock->mock_target({scheme => 'ldaps', port => 3389});

Since this will affect all the successive calls to instantiate C<Test::Net::LDAP::Mock>,
it may not be ideal when your application uses connections to multiple LDAP
servers.  In that case, you can specify a callback that will be invoked each
time a C<Test::Net::LDAP::Mock> object is instantiated.

    Test::Net::LDAP::Mock->mock_target(sub {
        my ($host, $arg) = @_;
        # Normalize $host, $arg->{port}, and $arg->{scheme}
        $host = 'ldap.example1.com' if $host =~ /\.example1\.com$/;
        $host = 'ldap.example2.com' if $host =~ /\.example2\.com$/;
        return ($host, $arg);
    });

=cut

sub mock_target {
    my $class = shift;

    if (@_) {
        my $old = $mock_target;
        my $host = shift;

        if (@_ >= 2) {
            $mock_target = [$host, {@_}];
        } elsif (@_ == 1) {
            my $arg = shift;
            $mock_target = [$host, $arg];
        } else {
            $mock_target = $host;
        }

        return $old;
    } else {
        return $mock_target;
    }
}

=head2 search

Searches for entries in the currently associated data tree.

    $ldap->search(
        base => 'dc=example, dc=com', scope => 'sub',
        filter => '(cn=*)', attrs => ['uid', 'cn']
    );

See L<Net::LDAP/search> for more parameter usage.

=cut

sub search {
    my $ldap = shift;
    return $ldap->mock_data->search(@_);
}

=head2 compare

Compares an attribute/value pair with an entry in the currently associated data
tree.

    $ldap->compare('uid=test, dc=example, dc=com',
        attr => 'cn',
        value => 'Test'
    );

See L<Net::LDAP/compare> for more parameter usage.

=cut

sub compare {
    my $ldap = shift;
    return $ldap->mock_data->compare(@_);
}

=head2 add

Adds an entry to the currently associated data tree.

    $ldap->add('uid=test, dc=example, dc=com', attrs => [
        cn => 'Test'
    ]);

See L<Net::LDAP/add> for more parameter usage.

=cut

sub add {
    my $ldap = shift;
    return $ldap->mock_data->add(@_);
}

=head2 modify

Modifies an entry in the currently associated data tree.

    $ldap->modify('uid=test, dc=example, dc=com', add => [
        cn => 'Test2'
    ]);

See L<Net::LDAP/modify> for more parameter usage.

=cut

sub modify {
    my $ldap = shift;
    return $ldap->mock_data->modify(@_);
}

=head2 delete

Deletes an entry from the currently associated data tree.

    $ldap->delete('uid=test, dc=example, dc=com');

See L<Net::LDAP/delete> for more parameter usage.

=cut

sub delete {
    my $ldap = shift;
    return $ldap->mock_data->delete(@_);
}

=head2 moddn

Modifies DN of an entry in the currently associated data tree.

    $ldap->moddn('uid=test, dc=example, dc=com',
        newrdn => 'uid=test2'
    );

See L<Net::LDAP/moddn> for more parameter usage.

=cut

sub moddn {
    my $ldap = shift;
    return $ldap->mock_data->moddn(@_);
}

=head2 bind

Returns an expected result message if the bind result has previously been setup by the
C<mock_bind()> method. Otherwise, a success message is returned.

=cut

sub bind {
    my $ldap = shift;
    return $ldap->mock_data->bind(@_);
}

=head2 unbind

Returns a success message.

=cut

sub unbind {
    my $ldap = shift;
    return $ldap->mock_data->unbind(@_);
}

=head2 abandon

Returns a success message.

=cut

sub abandon {
    my $ldap = shift;
    return $ldap->mock_data->abandon(@_);
}

1;
