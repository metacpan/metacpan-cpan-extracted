package Vonage::Click2Call;

use 5.00503;
use strict;
use LWP::UserAgent;
use Carp;
use vars qw($VERSION);

$VERSION = '0.11';

sub new {
    my ($class,%args) = @_;
    if (! exists($args{login}) || ! exists($args{password}) ) {
        croak("Failed to provide login and/or password to constructor.");
    }
    my %hash = (
       baseURL => 'https://secure.click2callu.com',
       user => $args{login},
       pass => $args{password},
       error => undef,
       skipHttpsCheck => $args{no_https_check},
    );
    $hash{_userAgent} = LWP::UserAgent->new;

    # Do we have HTTPS support ?
    if (! $hash{skipHttpsCheck}) {
        my $req = HTTP::Request->new(GET => $hash{baseURL});
        my $res = $hash{_userAgent}->request($req);
        if (! $res->is_success && $res->code == 501) {
            $Vonage::Click2Call::errstr = "Error while testing HTTPS : " . $res->status_line;
        }
    }

    return(bless(\%hash,$class||__PACKAGE__));
}

sub fromNumbers {
    my ($self) = @_;
    my $uri = sprintf("%s/tpcc/getnumbers?username=%s&password=%s",
                      $self->{baseURL},$self->{user},$self->{pass});
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->{_userAgent}->request($req);
    if ($res->is_success) {
        return(split(/,/,$res->as_string));
    } else {
        $self->{error} = "Failed to GET '$uri': " . $res->status_line;
        carp("Failed to GET '$uri': " . $res->status_line);
        return();
    }
}

sub errstr {
    my ($self) = @_;
    return($self->{error});
}

# return undef on failure. true otherwise.
sub call {
    my ($self,$from,$to) = @_;
    my $uri = sprintf("%s/tpcc/makecall?username=%s&password=%s&fromnumber=%s&tonumber=%s",
                      $self->{baseURL},$self->{user},$self->{pass},_validPhone($from),_validPhone($to));
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->{_userAgent}->request($req);
    if ($res->is_success) {
        my ($res_code,$message) = split(/,/,$res->as_string);
        if ($res_code == 0) {
            # success.
            return(1);
        } else {
            $self->{error} = sprintf("Error %03d : %s",$res_code,$message);
            return();
        }  
    } else {
        $self->{error} = "Failed to GET '$uri': " . $res->status_line;
        carp("Failed to GET '$uri': " . $res->status_line);
        return();
    }
}

# reformat to all numbers.
sub _validPhone {
    my ($phone) = @_;
    $phone =~ s/\D//g;
    return($phone);
}

1;
__END__

=head1 NAME

Vonage::Click2Call - Perl extension for using the Vonage Click2Call service (https://secure.click2callu.com/)

=head1 SYNOPSIS

  use Vonage::Click2Call;

  my $vonage = Vonage::Click2Call->new(login => 'user',
                                       password => 'pass',
                                       no_https_check => 1, # wasteful after the first time. turn it off.
                                       );
  if (! $vonage) {
      # no $vonage for errstr...
      die "Failed during initilization : " . $Vonage::Click2Call::errstr;
  }

  # get my phone numbers
  my @phoneNumbers = $vonage->fromNumbers();
  if (! defined($phoneNumbers[0])) {
      die "No phone numbers found : " . $vonage->errstr;
  }
  printf("I have %d numbers configured.",scalar(@phoneNumbers));

  # call someone. don't forget the leading 1.
  my $rc = $vonage->call($phoneNumbers[0],'12125551234');
  if (! $rc) {
      die "Failed to place a call : " . $vonage->errstr;
  }

=head1 DESCRIPTION

Use the Vonage™ Click-2-Call third party interface (https://secure.click2callu.com/) to
place a call from your Vonage line to another party.

=head1 HISTORY

=over 8

=item 0.11

Fixed string formatting bug (%d on phone numbers over 2.1billion numeric value). Thanks to Bill Smargiassi

=item 0.10

Original version; created by h2xs 1.23 with options

  -A
	-C
	-X
	-b
	5.5.3
	-n
	Vonage::Click2Call
	--skip-exporter
	--skip-autoloader
	-v
	0.10

=back



=head1 SEE ALSO

perl, LWP::UserAgent, SSL

=head1 AUTHOR

Matt Sanford, E<lt>mzsanford@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Matt Sanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
