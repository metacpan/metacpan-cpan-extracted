package WebService::Klout;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use JSON;

our $VERSION = '1.0.1';

our %API_URI = (
    'score'         => 'http://api.klout.com/1/klout.json',
    'users_show'    => 'http://api.klout.com/1/users/show.json',
    'users_topics'  => 'http://api.klout.com/1/users/topics.json',
    'influenced_by' => 'http://api.klout.com/1/soi/influenced_by.json',
    'influencer_of' => 'http://api.klout.com/1/soi/influencer_of.json',
);

sub new {
    my ($class, %arg) = @_;

    unless ( $arg{'api_key'} ||= $ENV{'KLOUT_API_KEY'} ) {
        croak 'api_key is empty';
    }

    my $ua = LWP::UserAgent->new('agent' => "WebService-Klout/$VERSION");

    bless { 'ua' => $ua, %arg }, $class;
}

sub score         { _request(@_) }
sub users_show    { _request(@_) }
sub users_topics  { _request(@_) }
sub influenced_by { _request(@_) }
sub influencer_of { _request(@_) }

sub _request {
    my ($self, @users) = @_;

    return unless @users;

    my $caller   = (caller 1)[3];
    my ($action) = $caller =~ /([^:]+)$/o;

    # parameter example http://developer.klout.com/docs/read/api/API
    my $url   = $API_URI{ $action };
    my $key   = $self->{'api_key'};
    my $users = encode_json(\@users);

    my $res = $self->{'ua'}->post($url, { 'key' => $key, 'users' => $users });

    unless ( $res->is_success ) {
        $self->{'lwp.error'} = $res->status_line;

        if ( $res->code eq 403 ) {
            carp '403 Developer Inactive. Check your API key.';
        }
        else {
            carp $res->status_line;
        }

        return;
    }

    my $json = $res->decoded_content;
    my $data = decode_json($json);

    $self->{'klout.status'} = $data->{'status'};
    $self->{'klout.json'}   = $json;
    $self->{'klout.raw'}    = $data;

    return $data->{'users'};
}

sub json   { shift->{'klout.json'}   }
sub raw    { shift->{'klout.raw'}    }
sub status { shift->{'klout.status'} }
sub error  { shift->{'lwp.error'}    }

1;

__END__

=head1 NAME

WebService::Klout - Easy-to-use Interface for Klout API

=head1 SYNOPSIS

   use WebService::Klout;

   my $klout = WebService::Klout->new(
       api_key => 'YOUR KLOUT API KEY'
   );

   # or $ENV{'KLOUT_API_KEY'}

   my $scores = $klout->score(@users);

   my %usres;
   for my $user (@$scores) {
       $users{ $user->{'twitter_screen_name'} } = $user->{'kscore'};
   }

=head1 METHODS

=over 4

=item score

=item users_show

=item users_topics

=item influenced_by

=item influencer_of

=item json

=item raw

=item status

=item error

=back

=head1 AUTHOR

Craftworks E<lt>craftwork at cpan.orgE<gt>

=head1 SEE ALSO

http://klout.com/

http://developer.klout.com/iodocs

=head1 COPYRIGHT

Copyright (c) 2011, Craftworks. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlgpl> and L<perlartistic>.

=cut
