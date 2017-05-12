package WWW::Google::API::Base;

use strict;
use warnings;

=head1 NAME

WWW::Google::API::Base - Perl client to the Google Base API C<< <http://code.google.com/apis/base/> >>

=head1 VERSION

version 0.001

  $Id$

=head1 SYNOPSIS

  use WWW::Google::API::Base;

  my $file_conf = LoadFile($ENV{HOME}.'/.gapi');

  my $api_key  = $ENV{gapi_key};
  my $api_user = $ENV{gapi_user};
  my $api_pass = $ENV{gapi_pass};

  my $gbase = WWW::Google::API::Base->new( { auth_type => 'ProgrammaticLogin',
                                             api_key   => $api_key,
                                             api_user  => $api_user,
                                             api_pass  => $api_pass  },
                                           { } );

=head1 METHODS

=cut

our $VERSION = '0.001';

use base qw(Class::Accessor);

use HTTP::Request;
use LWP::UserAgent;
use WWW::Google::API;
use XML::Atom::Entry;
use XML::Atom::Util qw( nodelist );

__PACKAGE__->mk_ro_accessors(qw(namespaces));
__PACKAGE__->mk_accessors(qw(client));

sub new {         
  my $class = shift;
  
  my $client;
  eval {
    $client = WWW::Google::API->new('gbase', @_);
  };
  if ($@) {
    my $e = $@;
    warn $e;
  }
  my $self = { client     => $client,
               namespaces => {
                 gm    => XML::Atom::Namespace->new( gm    => 'http://base.google.com/ns-metadata/1.0'),
                 g     => XML::Atom::Namespace->new( g     => 'http://base.google.com/ns/1.0'         ),
                 batch => XML::Atom::Namespace->new( batch => 'http://schemas.google.com/gdata/batch' ),
               }
             };

  bless($self, $class);
  return $self;
}

sub _load_item_type { 
  my $self = shift;
  my $type = shift;

  
  my $ua      = LWP::UserAgent->new( agent => 'WWW::Google::API' );
  
  my $response = $ua->get($type);
  
  die $response->status_line unless $response->is_success;
  
  my $entry = XML::Atom::Entry->new(\$response->content);
  
  $type = $entry->get($self->{namespaces}{gm}, 'item_type'); 
  my @attributes = nodelist($entry->elem, $self->{namespaces}{gm}{uri}, 'attribute'); 
  my $attribute_types;
  foreach my $attribute (@attributes) {
    my $name = $attribute->getAttribute('name');
    my $type = $attribute->getAttribute('type');
    $name =~ s/\s/_/g;
    $attribute_types->{$name} = $type;
  }
  $attribute_types->{'label'} = 'text';
  return $type, $attribute_types;
}

=head2 insert

  $insert_entry = $gbase->insert( 
    'http://www.google.com/base/feeds/itemtypes/en_US/Recipes',
    { -title      => 'He Jingxian\'s chicken',
      -content    => "<div xmlns='http://www.w3.org/1999/xhtml'>Delectable Sichuan specialty</div>",
      -link       => [ 
        { rel  => 'alternate',
          type => 'text/html',
          href => 'http://localhost/uniqueid'
        },
      ],
      cooking_time    => 30,
      label           => [qw(foo bar baz)],
      main_ingredient => [qw(chicken chili peanuts)],
      servings        => 5,
    },
  );

  $new_id = $insert_entry->id;

=cut

sub insert {
  my $self       = shift;
  my $item_type  = shift;
  my $item_parts = shift;

  my ($type, $gpart_types) = $self->_load_item_type($item_type);

  $self->client->ua->default_header('content-type', 'application/atom+xml');

  my $xml = <<EOF;
<?xml version='1.0'?>
<entry xmlns='http://www.w3.org/2005/Atom'
       xmlns:g='http://base.google.com/ns/1.0'>
  <category scheme='http://base.google.com/categories/itemtypes' term='Recipes'/>
  <g:item_type>$type</g:item_type>
EOF

  for my $key (keys %$item_parts) {
    if ($key =~ /^-/) {
      if ($key eq '-content') {
        $xml .= "<content type='xhtml'>\n";
        $xml .= "$item_parts->{$key}\n";
        $xml .= "</content>\n";
      } elsif ($key eq '-link') {
        if (ref $item_parts->{$key} eq 'ARRAY') {
          foreach (@{$item_parts->{$key}}) {
            $xml .= "<link rel='$_->{rel}' type='$_->{type}' href='$_->{href}'/>\n";
          }
        } else {
          $xml .= "<link rel='$item_parts->{$key}{rel}' type='$item_parts->{$key}{type}' href='$item_parts->{$key}{href}'/>\n";
        }
      } elsif (ref $item_parts->{$key} eq 'ARRAY') {
        for my $item (@{$item_parts->{$key}}) {
          $key =~ s/^-//;
          $xml .= "<$key type='text'>$item</$key>\n";
        }
      } else {
        $key =~ s/^-//;
        $xml .= "<$key type='text'>".$item_parts->{"-$key"}."</$key>\n";
      }
    } else {
      if (ref $item_parts->{$key} eq 'ARRAY') {
        for my $item (@{$item_parts->{$key}}) {
          $xml .= "<g:$key type='$gpart_types->{$key}'>$item</g:$key>\n";
        }
      } else {
        $xml .= "<g:$key type='$gpart_types->{$key}'>$item_parts->{$key}</g:$key>\n";
      }
    }
  }
  $xml .= "</entry>\n";
  
  my $insert_request = HTTP::Request->new( POST => 'http://www.google.com/base/feeds/items',
                                          $self->client->ua->default_headers,
                                          $xml);
  my $response;
  eval {
    $response = $self->client->do($insert_request);
  };
  if ($@) {
    my $error = $@;
    die $error;
  }

  my $atom = $response->content;
  
  my $entry = XML::Atom::Entry->new(\$atom);

  return $entry
}

=head2 update
 
  $update_entry = $gbase->update( 
    $new_id,
    { -title      => 'He Jingxian\'s chicken',
      -content    => "<div xmlns='http://www.w3.org/1999/xhtml'>Delectable Sichuan specialty</div>",
      -link       => [ 
        { rel  => 'alternate',
          type => 'text/html',
          href => 'http://localhost/uniqueid'
        },
      ],
      cooking_time    => 60,
      label           => [qw(fio bir biz)],
      main_ingredient => [qw(chicken chili peanuts)],
      servings        => 15,
    },
  );

=cut

sub update {
  my $self       = shift;
  my $item_id    = shift;
  my $item_parts = shift;

  my $item = $self->select($item_id);

  my $item_type = 'http://www.google.com/base/feeds/itemtypes/en_US/';
  $item_type   .= $item->get($self->{namespaces}{g}, 'item_type'); 

  my ($type, $gpart_types) = $self->_load_item_type($item_type);

  $self->client->ua->default_header('content-type', 'application/atom+xml');

  my $xml = <<EOF;
<?xml version='1.0'?>
<entry xmlns='http://www.w3.org/2005/Atom'
       xmlns:g='http://base.google.com/ns/1.0'>
  <category scheme='http://base.google.com/categories/itemtypes' term='Recipes'/>
  <g:item_type>$type</g:item_type>
EOF

  for my $key (keys %$item_parts) {
    if ($key =~ /^-/) {
      if ($key eq '-content') {
        $xml .= "<content type='xhtml'>\n";
        $xml .= "$item_parts->{$key}\n";
        $xml .= "</content>\n";
      } elsif ($key eq '-link') {
        if (ref $item_parts->{$key} eq 'ARRAY') {
          foreach (@{$item_parts->{$key}}) {
            $xml .= "<link rel='$_->{rel}' type='$_->{type}' href='$_->{href}'/>\n";
          }
        } else {
          $xml .= "<link rel='$item_parts->{$key}{rel}' type='$item_parts->{$key}{type}' href='$item_parts->{$key}{href}'/>\n";
        }
      } elsif (ref $item_parts->{$key} eq 'ARRAY') {
        for my $item (@{$item_parts->{$key}}) {
          $key =~ s/^-//;
          $xml .= "<$key type='text'>$item</$key>\n";
        }
      } else {
        $key =~ s/^-//;
        $xml .= "<$key type='text'>".$item_parts->{"-$key"}."</$key>\n";
      }

    } else {
      if (ref $item_parts->{$key} eq 'ARRAY') {
        for my $item (@{$item_parts->{$key}}) {
          $xml .= "<g:$key type='$gpart_types->{$key}'>$item</g:$key>\n";
        }
      } else {
        $xml .= "<g:$key type='$gpart_types->{$key}'>$item_parts->{$key}</g:$key>\n";
      }
    }
  }
  $xml .= "</entry>\n";

  my $update_request = HTTP::Request->new( PUT => $item_id,
                                          $self->client->ua->default_headers,
                                          $xml);
  my $response;
  eval {
    $response = $self->client->do($update_request);
  };
  if ($@) {
    my $error = $@;
    die $error;
  }

  my $atom = $response->content;
  
  my $entry = XML::Atom::Entry->new(\$atom);

  return $entry;
}

=head2 delete

  my $delete_response;
  eval {
    $delete_response =$gbase->delete($new_id);
  };
  if ($@) { 
    my $e = $@;
    die $e->status_line;  # HTTP::Response
  }

  die "Successfully deleted if $delete_response->code == 200; # HTTP::Response

=cut

sub delete {
  my $self    = shift;
  my $item_id = shift;
  my $delete_request = HTTP::Request->new( DELETE => $item_id,
                                           $self->client->ua->default_headers );
  my $response;
  eval {
    $response = $self->client->do($delete_request);
  };
  if ($@) {
    my $error = $@;
    die $error;
  } 
  return $response;
}

=head2 select

Currently only supports querying by id

  my $select_inserted_entry;
  eval {
    $select_inserted_entry =$gbase->select($new_id);
  };
  if ($@) {
    my $e = $@;
    die $e->status_line;  # HTTP::Response
  }

=cut

sub select {
  my $self    = shift;
  my $item_id = shift;
  
  my $select_request = HTTP::Request->new( GET => $item_id,
                                           $self->client->ua->default_headers );
  my $response;
  eval {
    $response = $self->client->do($select_request);
  };
  if ($@) {
    my $error = $@;
    die $error;
  }

  my $atom = $response->content;
  
  my $entry = XML::Atom::Entry->new(\$atom);

  return $entry;
}

1;
