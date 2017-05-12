package Web::Util::ExtPaging;
$Web::Util::ExtPaging::VERSION = '0.001003';
# ABSTRACT: Paginate DBIx::Class::ResultSets for ExtJS consumption

use strict;
use warnings;

use Sub::Exporter::Progressive -setup => {
  exports => [qw( ext_paginate ext_parcel )],
  groups => {
    default => [qw( ext_paginate ext_parcel )],
  },
};

sub ext_paginate {
   my $resultset = shift;
   my $method    = shift || 'TO_JSON';
   my $config    = shift;

   if (ref $method && ref $method ne 'CODE') {
      $config = $method;
      $method = 'TO_JSON';
   }

   return ext_parcel(
      $resultset->result_class->isa('DBIx::Class::ResultClass::HashRefInflator') && !ref $method ?
         [$resultset->all] :
         [map $_->$method, $resultset->all],
      $resultset->is_paged
         ? ($resultset->pager->total_entries)
         : (),
      ($config ? $config : () ),
   );
}

sub ext_parcel {
   my ($values, $total, $config) = @_;

   if (ref $total) {
      $config = $total;
      $total = undef;
   }

   $total  ||= @$values;
   $config ||= {};

   return {
      ($config->{root}||'data') => $values,
      ($config->{total_property}||'total') => $total,
   };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Util::ExtPaging - Paginate DBIx::Class::ResultSets for ExtJS consumption

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

  package MyApp::People;

  use Web::Simple;
  use JSON::MaybeXS;
  use Web::Util::ExtPaging;

  sub dispatch_request {
    my $people_rs = get_rs();

    sub (/people) {
      [
         200,
         [ 'Content-type', 'application/json' ],
         [ encode_json(ext_paginate($rs->search(undef, { rows => 25 }))) ],
      ]
    },
    sub (/people_lite) {
      [
         200,
         [ 'Content-type', 'application/json' ],
         [
            encode_json(ext_paginate(
               $rs->search(undef, { rows => 25 }), sub {
                  my $person = shift;
                  return {
                     first_name => $person->first_name,
                     last_name => $person->last_name,
                  }
               },
            ))
         ],
      ]
    },
    sub (/people_more_different) {
      [
         200,
         [ 'Content-type', 'application/json' ],
         [
            # this will call the 'foo' method on each person and put the
            # returned value into the datastructure
            encode_json(ext_paginate(
               $rs->search(undef, { rows => 25 }), 'foo',
            ))
         ],
      ]
    },
    sub (/programmers_do_it_by_hand) {
      [
         200,
         [ 'Content-type', 'application/json' ],
         [ encode_json(ext_parcel([qw( foo bar baz )], 10)) ],
      ]
    },
    sub (/programmers_do_it_by_hand_partially) {
      [
         200,
         [ 'Content-type', 'application/json' ],
         # defaults total to amount of items passed in
         [ encode_json(ext_parcel([qw( foo bar baz )])) ],
      ]
    },
    sub () { [ 404, [ 'Content-type', 'text/plain' ], [ 'not found' ] ] }
  }

=head1 DESCRIPTION

This module is mostly for sending L<DBIx::Class> paginated data to ExtJS based javascript code.

=head1 METHODS

=head2 ext_paginate

  my $json      = ext_paginate($resultset, { root => 'root' });
  my $json_str  = json_encode($json);

=head3 Description

Returns a structure like the following from the ResultSet:

  {
     data  => \@results,
     total => $count_before_pagination
  }

=head3 Valid arguments are:

  rs - paginated ResultSet to get the data from
  (optional) coderef - any valid scalar that can be called on the result object
  (optional) config - passed to ext_parcel

=head2 ext_parcel

  my $items    = [qw{foo bar baz}];
  my $total    = 7;
  my $json     = $self->ext_parcel($data, $total, { root => 'root' });
  my $json_str = to_json($json);

=head3 Description

Returns a structure like the following:

  {
     data  => [@{$items}],
     total => $total || scalar @{$items}
  }

=head3 Valid arguments are:

  list  - a list of anything you want to be in the data structure
  total - whatever you want to say the total is.  Defaults to size of
          the list passed in.
  (optional) config - a hashref containing root or total_property.  root is the
          key used to store the data under, total_property is the key used to
          store the total under

=head1 SEE ALSO

L<Catalyst::TraitFor::Controller::DoesExtPaging>, which this module was factored
out of.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
