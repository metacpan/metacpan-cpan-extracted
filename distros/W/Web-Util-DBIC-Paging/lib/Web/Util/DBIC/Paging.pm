package Web::Util::DBIC::Paging;
{
  $Web::Util::DBIC::Paging::VERSION = '0.001003';
}

# ABSTRACT: Easily page, search, and sort DBIx::Class::ResultSets in a web context

use strict;
use warnings;

use Module::Runtime 'use_module';

use Sub::Exporter::Progressive -setup => {
   exports => [qw( search simple_deletion page_and_sort paginate sort_rs simple_sort simple_search )],
   groups => {
      default => [qw( search simple_deletion page_and_sort paginate sort_rs simple_sort simple_search )],
   },
};

sub page_and_sort {
   my ($type, $foo, $rs, $config) = @_;
   $rs = sort_rs($type, $foo, $rs);
   return paginate($type, $foo, $rs, $config);
}

sub paginate {
   my ($type, $foo, $resultset, $config) = @_;

   $config ||= {};

   # param names should be configurable
   my $params = _params_for($type, $foo);
   my $rows = $params->{limit} || $config->{page_size} || 25;
   my $page =
      $params->{start}
      ? ( $params->{start} / $rows + 1 )
      : 1;

   return $resultset->search_rs( undef, {
      rows => $rows,
      page => $page
   });
}

sub search {
   my ($type, $foo, $rs, $config) = @_;
   if ($rs->can('controller_search')) {
      my $q = _params_for($type, $foo);
      return $rs->controller_search($q);
   } else {
      return simple_search($type, $foo, $rs, $config);
   }
}

sub sort_rs {
   my ($type, $foo, $rs) = @_;
   if ($rs->can('controller_sort')) {
      my $q = _params_for($type, $foo);
      return $rs->controller_sort($q);
   } else {
      return simple_sort($type, $foo, $rs);
   }
}

sub simple_deletion {
   my ($type, $foo, $rs) = @_;

   my $params = _params_for($type, $foo);
   # param names should be configurable
   my $to_delete = $params->{to_delete}
      or die 'Required cgi parameter (to_delete) undefined!';
   my @pks = map $rs->current_source_alias.q{.}.$_, $rs->result_source->primary_columns;

   my $expression;
   if (@pks == 1) {
      $expression = { $pks[0] => { -in => $to_delete } };
   } else {
      $expression = [
         map {
            my %hash;
            @hash{@pks} = split /,/, $_;
            \%hash;
         } @{$to_delete}
      ];
   }
   $rs->search($expression)->delete();
   return $to_delete;
}

sub simple_search {
   my ($type, $foo, $rs, $config) = @_;

   $config ||= {};

   my %skips  = map { $_ => 1}
      @{$config->{skip}||[qw(limit start sort dir _dc rm xaction)]};
   my $searches = {};
   my $params = _params_for($type, $foo);
   foreach ( keys %{ $params } ) {
      my $v = $params->{$_};
      if ( $v and not $skips{$_} ) {

         my $src = $rs->result_source;
         if (
            $src->has_column($_) &&
            ($src->column_info($_)->{data_type}||'') =~ m/char|text/i
         ) {
            $searches->{$rs->current_source_alias.q{.}.$_} =
                { -like => ref $v ? [ map "%$_%", @$v ] : "%$v%" }
         } else {
            $searches->{$rs->current_source_alias.q{.}.$_} = $v
         }
      }
   }

   $rs = $rs->search($searches);

   return page_and_sort($type, $foo, $rs, $config);
}

sub simple_sort {
   my ($type, $foo, $rs) = @_;

   my $params = _params_for($type, $foo);
   my %order_by;
   if ( $params->{sort} ) {
      %order_by = (
         order_by => {
            q{-}.$params->{dir} =>
            $rs->current_source_alias.q{.}.$params->{sort}
         }
      );
   } else {
      %order_by = (
         order_by => [
            map $rs->current_source_alias.q{.}.$_,
            $rs->result_source->primary_columns
         ]
      )
   }
   return $rs->search_rs(undef, { %order_by });
}

sub _params_for {
   my ($type, $foo) = @_;

   return $foo->request->params
      if $type =~ m/ \A (?: c | ctx | context | catalyst ) \z/x;

   return +{
      map {
         my @x = $foo->get_all($_);
         $_ => @x > 1 ? \@x : $x[0]
      } keys %$foo
   } if $type =~ m/ \A (?: r | req | request ) \z/x;

   return _params_for(r => use_module('Plack::Request')->new($foo))
      if $type =~ m/ \A (?: e | env | psgi_env ) \z/x;

   return $foo if $type eq 'raw';

   die "unknown type"
}

1;

__END__

=pod

=head1 NAME

Web::Util::DBIC::Paging - Easily page, search, and sort DBIx::Class::ResultSets in a web context

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

 package MyApp::People;

 use Web::Simple;
 use JSON::MaybeXS;
 use Web::Util::ExtPaging;
 use Web::Util::DBIC::Paging;

 sub dispatch_request {
  my $people_rs = get_rs();

  sub (/people) {
    [
       200,
       [ 'Content-type', 'application/json' ],
       [
         encode_json(
            ext_paginate(
               search(
                  page_and_sort($rs)
               )
            )
         ) ],
    ]
  },
  sub () { [ 404, [ 'Content-type', 'text/plain' ], [ 'not found' ] ] }
 }

=head1 DESCRIPTION

This module helps you to map various L<DBIx::Class> features to CGI parameters.
For the most part that means it will help you search, sort, and paginate with a
minimum of effort and thought.

=head1 EXPORTED SUBS

All subs take a type, paramish thing, resultset, and optionally
a config.  All methods return a ResultSet.  Subs are exported with
L<Sub::Exporter::Progressive>, so should be fast and light for the
defaults but upgrade to actually using L<Sub::Exporter> if you need to
alias or prefix the subs.

The "paramish thing" is what the type is for and can be any of:

=over 2

=item C<< c | ctx | context | catalyst >>

for the C<$c> argument in a catalyst app

=item C<< r | req | request >>

for a L<Plack::Request> object

=item C<< e | env | psgi_env >>

for a L<PSGI Environment|PSGI/The Environment> hashref.

=item C<< raw >>

for a plain hashref.

=back

=head2 C<page_and_sort>

 my $result = page_and_sort(c => $c, $c->model('DB::Foo'));

This is a helper method that will first L<sort|/sort_rs> your data and
then L</paginate> it.  Valid configuration parameters are documented for each
of those methods.

=head2 paginate

 my $result = paginate(c => $c, $c->model('DB::Foo'));

Paginates the passed in resultset based on the following parameters:

=over 2

=item C<start> first row to display

=item C<limit> amount of rows per page

=back

The sole config param is C<page_size> which will be the page size if there is no
C<limit> parameter in the request.  The default C<page_size> is 25.

=head2 search

 my $searched_rs = search(c => $c, $c->model('DB::Foo'));

If the C<$resultset> has a C<controller_search> method it will call that method
on the passed in resultset with all of the CGI parameters.  I like to have this
method look something like the following:

 # Base search dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_search {
    my $self           = shift;
    my $dispatch_table = shift;
    my $q              = shift;

    my %search = ();
    my %meta   = ();

    foreach ( keys %{$q} ) {
       if ( my $fn = $dispatch_table->{$_} and $q->{$_} ) {
          my ( $tmp_search, $tmp_meta ) = $fn->( $q->{$_} );
          %search = ( %search, %{$tmp_search||{}} );
          %meta   = ( %meta,   %{$tmp_meta||{}} );
       }
    }

    return $self->search(\%search, \%meta);
 }

 # search method in specific resultset
 sub controller_search {
    my $self   = shift;
    my $params = shift;
    return $self->_build_search({
       status => sub {
          return { 'repair_order_status' => shift }, {};
       },
       part_id => sub {
          return {
             'lineitems.part_id' => { -like => q{%}.shift( @_ ).q{%} }
          }, { join => 'lineitems' };
       },
    },$params);
 }

If the C<controller_search> method does not exist, this method will call
L</simple_search> instead.

=head2 sort_rs

 my $result = sort_rs(c => $c, $c->model('DB::Foo'));

Exactly the same as L</search>, except calls C<controller_sort> or L</simple_sort>.
Here is how I use it:

 # Base sort dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_sort {
    my $self = shift;
    my $dispatch_table = shift;
    my $default = shift;
    my $q = shift;

    my %search = ();
    my %meta   = ();

    my $direction = $q->{dir};
    my $sort      = $q->{sort};

    if ( my $fn = $dispatch_table->{$sort} ) {
       my ( $tmp_search, $tmp_meta ) = $fn->( $direction );
       %search = ( %search, %{$tmp_search||{}} );
       %meta   = ( %meta,   %{$tmp_meta||{}} );
    } elsif ( $sort && $direction ) {
       my ( $tmp_search, $tmp_meta ) = $default->( $sort, $direction );
       %search = ( %search, %{$tmp_search||{}} );
       %meta   = ( %meta,   %{$tmp_meta||{}} );
    }

    return $self->search(\%search, \%meta);
 }

 # sort method in specific resultset
 sub controller_sort {
    my $self = shift;
    my $params = shift;
    return $self->_build_sort({
       first_name => sub {
          my $direction = shift;
          return {}, {
             order_by => { "-$direction" => [qw{last_name first_name}] },
          };
       },
    }, sub {
       my $param = shift;
       my $direction = shift;
       return {}, {
          order_by => { "-$direction" => $param },
       };
    },$params);
 }

=head2 simple_deletion

 simple_deletion(c => $c, $c->model('DB::Foo'));

Deletes from the passed in resultset based on the sole CGI parameter,
C<to_delete>, which must be a list of primary keys.

This is the only method that does not return a ResultSet.  Instead it returns an
arrayref of the id's that it deleted.  If the ResultSet has has a multipk this will
expect each tuple of PK's to be separated by commas.

Note that this method uses the C<< $rs->delete >> method, as opposed to
C<< $rs->delete_all >>

=head2 simple_search

 my $searched_rs = simple_search(c => $c, $c->model('DB::Foo'));

Searches the resultset based on all fields in the request.  Searches with
C<< $fieldname => { -like => "%$value%" } >> for char fields, everything else
gets basic equality searchs.  If there are multiple values for a CGI parameter
it will use all values via an C<or>.

The sole configuration value is C<skip> and it is used to skip unsearchable
parameters.  The default is C<< limit start sort dir _dc rm xaction >>.

=head2 simple_sort

 my $sorted_rs = simple_sort(c => $c, $c->model('DB::Foo'));

Sorts the passed in resultset based on the following CGI parameters:

=over 2

=item C<sort> field to sort by, defaults to primarky key
=item C<dir> direction to sort

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
