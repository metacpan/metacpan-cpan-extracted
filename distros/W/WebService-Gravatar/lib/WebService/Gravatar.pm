package WebService::Gravatar;

use warnings;
use strict;

use Carp;
use Digest::MD5 qw/md5_hex/;
use RPC::XML::Client;

=head1 NAME

WebService::Gravatar - Perl interface to Gravatar API

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';


=head1 SYNOPSIS

WebService::Gravatar provides an interface to Gravatar XML-RPC API.

    use WebService::Gravatar;
    use MIME::Base64;

    # Create a new instance of WebService::Gravatar
    my $grav = WebService::Gravatar->new(email => 'your@email.address',
                                         apikey => 'your_API_key');

    # Get a list of addresses
    my $addresses = $grav->addresses;

    if (defined $addresses) {
        # Print the userimage URL for each e-mail address
        foreach my $email (keys %$addresses) {
            print $addresses->{$email}->{'userimage_url'} . "\n";
        }
    }
    else {
        # We have a problem
        print STDERR "Error: " . $grav->errstr . "\n";
    }

    # Read image file data
    my $data;
    {
        local $/ = undef;
        open(F, "< my_pretty_face.png");
        $data = <F>;
        close(F);
    }
    
    # Save the image as a new userimage
    $grav->save_data(data => encode_base64($data), rating => 0);

    ...

=head1 DESCRIPTION

WebService::Gravatar is a Perl interface to Gravatar API. It aims at providing a
close representation of the basic XML-RPC API, as documented on Gravatar
website: L<http://en.gravatar.com/site/implement/xmlrpc/>. All the method names,
parameter names, and data structures are the same as in the API -- the only
exception is that in the API the methods are named with camelCase, while the
module uses lowercase_with_infix_underscores.

=head1 METHODS

All the instance methods return C<undef> on failure. More detailed error
information can be obtained by calling L<"err"> and L<"errstr">.

=head2 new

Creates a new instance of WebService::Gravatar.

    my $grav = WebService::Gravatar->new(email => 'your@email.address',
                                         apikey => 'your_API_key');

Parameters:

=over 4

=item * email

B<(Required)> E-mail address.

=item * apikey

B<(Required)> API key. Can be ommitted if C<password> is defined.

=item * password

B<(Required)> Account password. Can be ommitted if C<apikey> is defined.

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless($self, $class);
    
    if (!defined $args{'email'}) {
        carp "Required parameter 'email' is not defined";
    }
    
    if (!defined $args{'apikey'} && !defined $args{'password'}) {
        carp "Either the 'apikey' or 'password' parameter must be defined";
    }
    
    $self->{'err'} = undef;
    $self->{'errstr'} = undef;
    
    $self->{'apikey'} = $args{'apikey'};
    $self->{'password'} = $args{'password'};
    
    (my $email = $args{'email'}) =~ s/^\s+|\s+$//g;
    
    $self->{'cli'} = RPC::XML::Client->new(
        'https://secure.gravatar.com/xmlrpc?user=' . md5_hex(lc $email));
    
    return $self;
}

sub _call {
	my $self = shift;
	my $method = shift;
	my %args = (
	    'apikey'   => $self->{'apikey'},
	    'password' => $self->{'password'},
	    @_
	);
	
    $self->{'err'} = undef;
    $self->{'errstr'} = undef;
    
    my $ret = $self->{'cli'}->send_request('grav.' . $method, \%args);
    
    if ($ret->is_fault) {
    	$self->{'err'} = $ret->{'faultCode'}->value;
    	$self->{'errstr'} = $ret->{'faultString'}->value;
    	return undef;
    }
    else {
    	return $ret->value;
    }
}

=head2 exists

Checks whether a hash has a gravatar.

    $result = $grav->exists(hashes => ['e52beb5a6966554a02a56072cafebabe',
        '62345cdd79773f62a87fcbc6abadbabe'])

Parameters:

=over 4

=item * hashes

B<(Required)> An array of email hashes to check.

=back

Returns: A reference to a hash that maps email hashes to statuses. Example: 

    $result = {
        'e52beb5a6966554a02a56072cafebabe' => '1',
        '62345cdd79773f62a87fcbc6abadbabe' => '0'
    };

=cut

sub exists {
	my $self = shift;
	my %args = @_;
	
	if (!defined $args{'hashes'}) {
        carp "Required parameter 'hashes' is not defined";
	}
	
    return $self->_call('exists', %args);
}

=head2 addresses

Gets a list of addresses for this account.

    $addresses = $grav->addresses;

Returns: A reference to a hash that maps addresses to userimage data. Example:

    $addresses = {
        'some@email.address' => {
            'rating' => '0',
            'userimage' => '8bfc8da2562a53ddd7e630a68badf00d',
            'userimage_url' => 'http://en.gravatar.com/userimage/123456/8bfc8da2562a53ddd7e630a68badf00d.jpg'
        },
        'another@email.address' => {
            'rating' => '1',
            'userimage' => '90f269fe7b67d0ce49f96427deadbabe',
            'userimage_url' => 'http://en.gravatar.com/userimage/123456/90f269fe7b67d0ce49f96427deadbabe.jpg'
        }
    };

=cut

sub addresses {
	my $self = shift;

    return $self->_call('addresses');
}

=head2 userimages

Gets a list of userimages for this account.

    $userimages = $grav->userimages;

Returns: A reference to a hash that maps userimages to data. Example:

    $userimages = {
    	'8bfc8da2562a53ddd7e630a68badf00d' => [
            '0',
            'http://en.gravatar.com/userimage/123456/8bfc8da2562a53ddd7e630a68badf00d.jpg'
        ],
        '90f269fe7b67d0ce49f96427deadbabe' => [
            '1',
            'http://en.gravatar.com/userimage/123456/90f269fe7b67d0ce49f96427deadbabe.jpg'
        ]
    };

=cut

sub userimages {
	my $self = shift;
	
	return $self->_call('userimages');
}

=head2 save_data

Saves binary image data as a userimage for this account. 

    $grav->save_data(data => $data, rating => 1);

Parameters:

=over 4

=item * data

B<(Required)> A base64 encoded image.

=item * rating

B<(Required)> Rating.

=back

Returns: Userimage string.

=cut

sub save_data {
	my $self = shift;
    my %args = @_;
    
    if (!defined $args{'data'}) {
        carp "Required parameter 'data' is not defined";
    }
	
	if (!defined $args{'rating'}) {
		carp "Required parameter 'rating' is not defined";
	}
	
	return $self->_call('saveData', %args);
}

=head2 save_url

Reads an image via its URL and saves that as a userimage for this account.

    $grav->save_url(url => 'http://some.domain.com/image.png', rating => 0);

Parameters:

=over 4

=item * url

B<(Required)> A full URL to an image.

=item * rating

B<(Required)> Rating.

=back

Returns: Userimage string.

=cut

sub save_url {
    my $self = shift;
    my %args = @_;
    
    if (!defined $args{'url'}) {
        carp "Required parameter 'url' is not defined";
    }
    
    if (!defined $args{'rating'}) {
        carp "Required parameter 'rating' is not defined";
    }
    
    return $self->_call('saveUrl', %args);
}

=head2 use_userimage

Uses the specified userimage as a gravatar for one or more addresses on this
account.

    $grav->use_userimage(userimage => '9116aa83a568563290a681df61c0ffee'.
        addresses => ['some@email.address', 'another@email.address']);

Parameters:

=over 4

=item * userimage

B<(Required)> The userimage to be used.

=item * addresses

B<(Required)> An array of email addresses for which this userimage will be used.

=back

Returns: 1 on success, undef on failure.

=cut

sub use_userimage {
	my $self = shift;
	my %args = @_;
	
    if (!defined $args{'userimage'}) {
        carp "Required parameter 'userimage' is not defined";
    }
    
    if (!defined $args{'addresses'}) {
        carp "Required parameter 'addresses' is not defined";
    }
	
	return $self->_call('useUserimage', %args);
}

=head2 remove_image

Removes the userimage associated with one or more email addresses.

    $result = $grav->remove_image(addresses => ['some@email.address',
        'another@email.address'])
    
Parameters:

=over 4

=item * addresses

B<(Required)> An array of email addresses to remove userimages for.

=back

Returns: A reference to a hash that maps email addresses to statuses. Example:

    result = {
        'some@email.address' => 1,
        'another@email.address' => 0
    };

=cut

sub remove_image {
	my $self = shift;
	my %args = @_;
	
    if (!defined $args{'addresses'}) {
        carp "Required parameter 'addresses' is not defined";
    }
    
    return $self->_call('removeImage', %args);
}

=head2 delete_userimage

Removes a userimage from the account and any email addresses with which it is
associated.

    $grav->delete_userimage(userimage => '292ed56ce849657d47b04105deadbeef');

Parameters:

=over 4

=item * userimage

B<(Required)> The userimage to be removed from the account.

=back

Returns: 1 on success, undef on failure.

=cut

sub delete_userimage {
	my $self = shift;
	my %args = @_;
	
    if (!defined $args{'userimage'}) {
        carp "Required parameter 'userimage' is not defined";
    }
    
    return $self->_call('deleteUserimage', %args);
}

=head2 test

API test method.

    $result = $grav->test(param => 1);

Returns: A reference to a hash which represents the parameters passed to the
test method.

=head2 err

Returns the numeric code of last error.

    $err_code = $grav->err;

=cut

sub err {
	my $self = shift;
	
	return $self->{'err'};
}

=head2 errstr

Returns the human readable text for last error.

    $err_description = $grav->errstr;

=cut

sub errstr {
	my $self = shift;
	
    return $self->{'errstr'};
}

=head1 AUTHOR

Michal Wojciechowski, C<< <odyniec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-gravatar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Gravatar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Gravatar


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Gravatar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Gravatar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Gravatar>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Gravatar>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michal Wojciechowski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item * Gravatar XML-RPC API Documentation

L<http://en.gravatar.com/site/implement/xmlrpc/>

=back

=cut

1; # End of WebService::Gravatar
