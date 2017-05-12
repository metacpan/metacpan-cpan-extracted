package Dyatel;

use warnings;
use strict;

=head1 NAME

Dyatel - Internal

=head1 VERSION

Version 0.01

=head1 AUTHOR

andrey@kostenko.name

=head1 LICENSE

perl

=cut

our $VERSION = '0.01';
use 5.010;
use mro 'c3';

use Data::Dumper;
use Net::Twitter::Stream;
use WWW::Mechanize;
use YAML qw(LoadFile);
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors( qw(twitter vkontakte mech) );

=head2 new



=cut

sub new {
    my $class = shift;
    my @files = grep { -e $_ } map glob, qw(~/.dyatel /usr/local/etc/dyatelrc /etc/dyatelrc);
    die "No config found\n" unless @files;
    my $self = $class->next::method(LoadFile($files[0]));
    $self->mech( WWW::Mechanize->new );
    $self->mech->cookie_jar({});
    return $self;
}

=head2 auth

=cut

sub auth {
    my $self = shift;
    my $mech = $self->{mech};
    $mech->get('http://vkontakte.ru/');
    sleep 1;
    $mech->submit_form( form_number => 1, fields => $self->vkontakte );
    $mech->submit_form( form_number => 1 );
    ($mech->content =~ /<input type='hidden' id='activityhash' value='(\w+)'>/ ) or die "Not authorized!\n";
    Net::Twitter::Stream::Follow->new ( @{$self->twitter}{qw(login password)},
                  '9310862',
                  sub { $self->got_tweet_callback(@_) } );
}

=head2 run

=cut

sub run {
    Danga::Socket->EventLoop;
}

=head2 got_tweet_callback

=cut

sub got_tweet_callback {
    my $self = shift;
    my $tweet = shift;
    return if $tweet->{text} =~ /^\@/;
    $self->mech->get('http://vkontakte.ru/');
    sleep 1;
    ($self->{activity_hash}) = ($self->mech->content =~ /<input type='hidden' id='activityhash' value='(\w+)'>/ );
    sleep 1;
    $self->mech->post( 'http://vkontakte.ru/profile.php', { activityhash => $self->{activity_hash}, setactivity => $tweet->{text} } );
    sleep 1;
}

1; # End of Dyatel
