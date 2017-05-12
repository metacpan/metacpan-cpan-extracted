package WWW::CybozuOffice6;


#                        !!! ATTENTION !!!
# 
#          This package is NOT a product of Cybozu, Inc.
#     DO NOT CONTACT CYBOZU, INC. for the use of the software.
# 
# For support, please visit http://labs.cybozu.co.jp/blog/kazuho/


use 5.006;
use strict;
use warnings;
use fields qw(url user id pass ua response ocode);
use vars qw($VERSION);

use Carp;
use Jcode;
use LWP;
use Text::CSV_XS;
use URI::Escape;


$VERSION = 0.04;


# instantiation
sub new {
    # setup
    my WWW::CybozuOffice6 $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
    # set params
    while ($#_ >= 0) {
        croak('CybozuOffice65->new() called with odd number of option parameters - should be of the form option => value') if ($#_ == 0);
        my $n = lc(shift);
        my $v = shift;
        $self->_init_param($n, $v);
    }
    # set default
    $self->{ua} = LWP::UserAgent->new() unless defined($self->{ua});
    $self->{ocode} = 'utf8' unless defined($self->{ocode});
    
    return $self;
}

# accessors
sub url (\$@) {
    my $self = shift;
    return $self->_accessor('url', @_);
}

sub user (\$@) {
    my $self = shift;
    return $self->_accessor('user', @_);
}

sub id (\$@) {
    my $self = shift;
    return $self->_accessor('id', @_);
}

sub password (\$@) {
    my $self = shift;
    return $self->_accessor('pass', @_);
}

sub ua (\$@) {
    my $self = shift;
    return $self->_accessor('ua', @_);
}

sub response (\$) {
    # no setter
    my $self = shift;
    return $self->{response};
}

sub ocode (\$@) {
    my $self = shift;
    return $self->_accessor('ocode', @_);
}

# checks if username/password is valid
sub test_credentials (\$) {
    my $self = shift;
    my $items = $self->externalAPINotify;
    return defined($items) && ref($items) eq 'ARRAY';
}

# returns new items
sub externalAPINotify (\$) {
    my $self = shift;
    # get RSS
    if (! $self->_request('ExternalAPINotify')) {
        return;
    }
    # parse and return the result
    my $content = Jcode::convert($self->{response}->content, $self->{ocode});
    return $self->parse_externalAPINotify($content);
}

sub parse_externalAPINotify (\$$) {
    my ($self, $content) = @_;
    my @items;
    # split into lines
    my @lines = split(/\x0d\x0a/, $content);
    # check first line
    if ($#lines == -1 || $lines[0] !~ /ts\./) {
        return;
    }
    shift(@lines);
    # parse the rest (but not the last line)
    my $csv = Text::CSV_XS->new({ binary => 1 });
    while ($#lines > 0) {
        my $line = shift(@lines);
        if (! $csv->parse($line)) {
            croak 'failed to parse CSV input';
        }
        my @fields = $csv->fields;
        if ($#fields < 6) {
            croak 'unexpected number of fields in CSV';
        }
        my $item = {
            app => $fields[0],
            app_jp => $fields[1],
            timestamp => $fields[3],
            title => $fields[4],
            description => $fields[5],
            from => $fields[6],
            link => $fields[7] };
        $item->{timestamp} =~ s/^ts\.//;
        push(@items, $item);
    }
    
    return \@items;
}

# initialization
sub _init_param (\$$$) {
    my ($self, $n, $v) = @_;
    $self->{$n} = $v;
}

# general accessor
sub _accessor (\$$@) {
    my $self = shift;
    my $name = shift;
    if ($#_ <=> -1) {
        $self->{$name} = $_[0];
    }
    return $self->{$name};
}

# request handler
sub _request (\$$) {
    my ($self, $page) = @_;
    croak 'url not set' unless defined($self->{url});
    croak 'user/id not set' unless defined $self->{user} or defined $self->{id};
    croak 'password not set' unless defined($self->{pass});
    $self->{response} =
        $self->{ua}->post($self->{url} . '?page=' . uri_escape($page),
                          { _System => 'login',
                            _Login => '1',
                            GuideNavi => '1',
                            defined $self->{user} ? (_Account => $self->{user}) : (),
                            defined $self->{id} ? (_Id => $self->{id}) : (),
                            Password => $self->{pass} });
    return $self->{response}->is_success;
}


1;
__END__

=head1 NAME

WWW::CybozuOffice6 - Perl extension for accessing Cybozu Office 6

=head1 SYNOPSIS

 use WWW::CybozuOffice6;

 # create a new object  
 $office6 =
     WWW::CybozuOffice6->new(url => 'http://server/scripts/cbag/ag.exe',
                             user => 'username',
                             pass => 'password');

 # check if username/password is correct
 $office6->test_credentials;
 
 # get list of new items
 $new_items = $office6->externalAPINotify;

=head1 DESCRIPTION

WWW::CybozuOffice6 is a perl extension for accessing Cybozu Office 6.

=head1 FUNCTIONS

=over 4

=item new(%attr)

Returns a new instance of WWW::CybozuOffice6.  Following attributes are available.

=over 8

=item url

The URL of the Cybozu Office 6.

=item user

Username for the Cybozu Office.

=item pass

Password for the Cybozu Office.

=item ua

(optional) An LWP::UserAgent object used for access.

=item ocode

Output encoding, default is utf8.

=back

=item url([$new_url])

Gets/sets the Cybozu Office 6 URL.

=item user([$new_user])

Gets/sets the Cybozu Office 6 username.

=item password([$new_password])

Gets/sets the Cybozu Office 6 password.

=item ua([$new_ua])

Gets/sets the LWP::UserAgent object used to access the Cybozu Office 6.

=item response()

Returns the last response from Cybozu Office 6.

=item ocode([$new_ocode])

Gets/sets the output encoding.

=item test_credentials()

Checks if username/password is correct.

=item externalAPINotify()

Obtains a list of new items from the Cybozu Office 6.  If successful, an array of new items is returned, of which the keys for each item are:

=over 8

=item app

Name of the application (ex. message, forum)

=item app_jp

Name of the application in Japanese printable form

=item timestamp

Creation(?) time of the item, in unix time.

=item title

Title of the item.

=item description

Description of the item.  May contain '\x0a's.

=item from

Creator of the item, in Japanese printable form.

=item link

URL of the item, only the query portion is included.

=back

=back

=head1 EXPORT

None by default.



=head1 AUTHOR

Kazuho Oku E<lt>kazuho ___at___ labs.cybozu.co.jpE<gt>

Copyright (C) 2005 Cybozu Labs, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


This package is NOT a product of Cybozu, Inc.
DO NOT CONTACT CYBOZU, INC. for the use of the software.
 
For support, please visit http://labs.cybozu.co.jp/blog/kazuho/



=cut
