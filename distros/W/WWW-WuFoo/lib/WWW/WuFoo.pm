package WWW::WuFoo;
{
  $WWW::WuFoo::VERSION = '0.007';
}

use strict;
use warnings;
use Moose;
use LWP::UserAgent;
use JSON;

use WWW::WuFoo::Form;
use WWW::WuFoo::User;
use Data::Dumper;

# ABSTRACT: Interface to WuFoo.com's online forms

has 'subdomain' => (is => 'rw', isa => 'Str');
has 'apikey'    => (is => 'rw', isa => 'Str');

sub login {
    my ($self) = @_;
}


##Get a specific form - search by name

sub form {
    my ($self, %opts) = @_;
    my $ref = $self->forms;
    foreach my $form (@$ref) {
        return $form if $form->name eq $opts{name};
        return $form if $form->hash eq $opts{hash};
    }
}

sub forms {
    my ($self, $opts) = @_;
    my $url = '/api/v3/forms.json?IncludeTodayCount=true';

    my @arr;
    my $obj = $self->do_request($url)->{Forms};

    foreach my $form (@$obj) {
        my $hash;
        foreach my $key (keys %$form) {
            $hash->{lc $key} = $form->{$key} || '';
        }
        
        $hash->{_wufoo} = $self;
        
        my $obj = WWW::WuFoo::Form->new($hash);
        push(@arr,$obj);
    }

    return \@arr;
}

sub users {
    my ($self) = @_;
    
    my @arr;
    my $url = '/api/v3/users.json';
    my $users = $self->do_request($url)->{Users};
    foreach my $user (@$users) {
        my $hash;
        foreach my $key (keys %$user) {
            $hash->{lc $key} = $user->{$key} || '';
        }
        
        $hash->{_wufoo} = $self;
        push(@arr,WWW::WuFoo::User->new($hash));
    }
    
    return \@arr;
}

sub do_request {
    my ($self, $url) = @_;

    $url = 'https://' . $self->subdomain . '.wufoo.com' . $url;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(120);
    $ua->credentials($self->subdomain . '.wufoo.com:443','Wufoo Secret Lab',$self->apikey,'footastic');
  
#    print "Getting url: $url\n";
    my $content = $ua->get($url)->content;
#    print Dumper($content);

#    my $command = 'curl -u ' . $self->apikey . ':footastic https://' . $self->subdomain . '.wufoo.com' . $url;
#    print Dumper("COMMAND: " . $command);
#    my $output = `$command`;
#    print Dumper($output);
    my $obj = from_json($content);
    return $obj;
}

1;
