package WWW::Scroogle::Result;

use strict;
use warnings;
use Carp;

our $VERSION = '0.004';

sub new
{
     my $class = shift;
     my $options = shift;
     if (not ref $options eq "HASH") { croak 'no options hash provided!'; }
     if (not exists $ {$options}{url}) { croak 'url expected!'; }
     if (not exists $ {$options}{position}) { croak 'position expected!'; }
     if (not exists $ {$options}{searchstring}) { croak 'searchstring expected!'; }
     if (not exists $ {$options}{language}) { croak 'language expected!'; }

     my $self;
     $self->{url} = $ {$options}{url};
     $self->{position} = $ {$options}{position};
     $self->{searchstring} = $ {$options}{searchstring};
     $self->{language} = $ {$options}{language};
     bless $self, $class;

     return $self
}

sub searchstring
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     return $self->{searchstring};
}

sub language
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     return $self->{language};
}

sub position
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     return $self->{position};
}

sub url
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     return $self->{url};
}
1;

__END__

=head1 NAME

WWW::Scroogle::Result - A Subclass for Search Results from WWW::Scroogle

=head1 SYNOPSIS

   my @results = $scroogle->get_results;

   print $_->position, ' ', $_->url, "\n" for @results;

=head1 DESCRIPTION

WWW::Scroogle::Result provides a object layer for search results from WWW::Scroogle

=head1 METHODS

=head2 WWW::Scroogle::Result->new(\%options)

Returns a new WWW::Scroogle::Result object from the given options
the required options are:

=over

=item * url

=item * position

=item * searchstring

=item * language

=back

croaks if errors occur

=head2 $result->url

returns the url of the result

=head2 $result->position

returns the position of the result

=head2 $result->searchstring

returns the searchstring used in WWW::Scroogle while performing the search

=head2 $result->language

returns the language used in WWW::Scroogle while performing the search

=head1 CAVEATS

This is just a alpha release so dont expect it to work properly.

=head1 AUTHOR

Written by Lars Hartmann, <lars (at) chaotika (dot) org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Lars Hartmann, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
