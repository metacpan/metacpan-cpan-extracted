package Web::JenkinsNotification;
use strict;
use warnings;
our $VERSION = '0.05';
use parent qw/Plack::Middleware/;
use Plack::Util;
use Plack::MIME;
use Plack::Util::Accessor qw(on_notify);
use Plack::Response;
use Plack::Request;
use Net::Jenkins;
use Jenkins::NotificationListener;

sub call { 
    my ($self,$env) = @_;

    my $req = Plack::Request->new($env);
    my $body = $req->raw_body;

    my $notification = parse_jenkins_notification $body;

    if( $self->on_notify ) {
        $self->on_notify->( $env, $notification );
    }
    $env->{ 'jenkins.notification' } = $notification;

    return $self->app->( $env );
}

1;
__END__

=head1 NAME

Web::JenkinsNotification -

=head1 SYNOPSIS

    use Web::JenkinsNotification;

    builder {
        mount "/jenkins" => builder {
            enable "+Web::JenkinsNotification";
            sub { 
                my $env = shift;
                my $notification = $env->{ 'jenkins.notification' };  # Jenkins::Notification

            };
        };

        mount "/jenkins" => Web::JenkinsNotification->new({ on_notify => sub {
            my ($env,$payload) = @_;
            
        }})->to_app;
    };

=head1 DESCRIPTION

Web::JenkinsNotification is

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
