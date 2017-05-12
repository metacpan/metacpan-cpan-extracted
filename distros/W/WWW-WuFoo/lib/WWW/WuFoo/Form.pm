package WWW::WuFoo::Form;
{
  $WWW::WuFoo::Form::VERSION = '0.007';
}

use diagnostics;
use Moose;
use WWW::WuFoo::Field;
use WWW::WuFoo::Entry;
use JSON;
use Data::Dumper;

# ABSTRACT: The Forms API is used to gather details about the forms you have permission to access. This API can be used to create a list of all forms belonging to a user and dynamically generate a form embed snippet to use in your application.

has '_wufoo'            => (is => 'rw', isa => 'WWW::WuFoo');
has 'datecreated'       => (is => 'rw', isa => 'Str');
has 'entrylimit'        => (is => 'rw', isa => 'Str');
has 'ispublic'          => (is => 'rw', isa => 'Str');
has 'email'             => (is => 'rw', isa => 'Str');
has 'startdate'         => (is => 'rw', isa => 'Str');
has 'enddate'           => (is => 'rw', isa => 'Str');
has 'linkfields'        => (is => 'rw', isa => 'Str');
has 'language'          => (is => 'rw', isa => 'Str');
has 'hash'              => (is => 'rw', isa => 'Str');
has 'linkentries'       => (is => 'rw', isa => 'Str');
has 'url'               => (is => 'rw', isa => 'Str');
has 'dateupdated'       => (is => 'rw', isa => 'Str');
has 'description'       => (is => 'rw', isa => 'Str');
has 'name'              => (is => 'rw', isa => 'Str');
has 'redirectmessage'   => (is => 'rw', isa => 'Str');
has 'linkentriescount'  => (is => 'rw', isa => 'Str');

sub all_entry_values {
    my ($self) = @_;
    my @arr;
    my $ref = $self->entries;
    foreach my $entry (@$ref) {
        push(@arr,$entry->val_hash);
    }
    
    return \@arr;
}


sub entries {
    my ($self) = @_;
    
    my $pagestart = 0;
    my $ref;
    my @arr;
    my $entries = 0;

    while ($pagestart == 0 || $entries > 0) {
        my $url = '/api/v3/forms/' . $self->hash . '/entries.json?pageSize=100&pageStart=' . $pagestart;
        my $ref = $self->_wufoo->do_request($url)->{Entries};
        foreach my $entry (@$ref) {
            my $hash;
            foreach my $key (keys %$entry) {
                $hash->{lc $key} = $entry->{$key} || '';
            }

            $hash->{_form} = $self;
            $hash->{_original} = $entry;
            push(@arr,WWW::WuFoo::Entry->new($hash));
        }
        
        $entries = scalar @$ref;
        $pagestart += 100;
    }

    return \@arr;
}

sub fields {
    my ($self) = @_;
    
    my @arr;
    my $url = '/api/v3/forms/' . $self->hash . '/fields.json';
    my $ref = $self->_wufoo->do_request($url)->{Fields};

#    my $orderby = 0;
    foreach my $field (@$ref) {
        my $hash;
        foreach my $key (keys %$field) {
            $hash->{lc $key} = $field->{$key} || '';
        }

#        $hash->{orderby} = $orderby;
        $hash->{_form} = $self;
        push(@arr,WWW::WuFoo::Field->new($hash));
#        $orderby++;
    }

    return \@arr;
}

sub create_webhook {
    my ($self, $p) = @_;

    my $url = '/api/v3/forms/' . $self->hash . '/webhooks.json';
    my $data = '"' . 'url=' . $p->{url} . '&handshakeKey=' . $p->{handshakeKey} . '&metadata=true' . '"';
    my $command = 'curl -i -H "Accept: application/json" -X PUT -d ' . $data . ' -u ' . $self->_wufoo->apikey . ':footastic https://' . $self->_wufoo->subdomain . '.wufoo.com' . $url;
    my $output = `$command`;
#    my $obj = from_json($output);
#    return $obj;
}

1;
