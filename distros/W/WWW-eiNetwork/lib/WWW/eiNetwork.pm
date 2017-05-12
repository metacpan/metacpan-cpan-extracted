package WWW::eiNetwork;

use strict;
use warnings;
use Carp;
use HTML::TableContentParser;
use WWW::Mechanize;

our $VERSION = '0.02';

sub new
{
    my ($class, %args) = @_;

    croak "You must specify your library card number" unless $args{card_number};
    croak "You must specify your PIN number"          unless $args{pin_number};

    # Strip trailing slash from URL prefix
    my $prefix = $args{url_prefix} || '';
    $prefix =~ s/\/$//;

    my $self =
    {
        card_number => $args{card_number},
        pin_number  => $args{pin_number},
        url_prefix  => $prefix || 'https://iiisy1.einetwork.net/patroninfo~S1',
    };

    bless $self, $class;
    return $self;
};

sub _login
{
    my ($self, $name, $card) = @_;

    my $mech = WWW::Mechanize->new;
    $mech->get($self->{url_prefix});
    $mech->form_with_fields(qw(code pin));
    $mech->field('code', $self->{card_number});
    $mech->field('pin', $self->{pin_number});
    $mech->click('submit');

    my $uri = $mech->uri;
    if ($uri =~ /patroninfo~S1\/(\d+)\//)
    {
        $self->{patron_id} = $1;
        $self->{mech}      = $mech;
        return $self->{mech};
    }
    else
    {
        croak "Couldn't log in to eiNetwork!";
        return;
    }
}

sub holds
{
    my ($self, %args) = @_;

    my @classes = ('Title', 'Status', 'Pickup', 'Cancel');
    my @items = $self->_get_content(
        page    => 'holds',
        classes => \@classes,
        html    => $args{html},
    );

    return wantarray ? @items : \@items;
}

sub items
{
    my ($self, %args) = @_;

    my @classes = ('Title', 'Barcode', 'Status', 'CallNo');
    my @items = $self->_get_content(
        page    => 'items',
        classes => \@classes,
        html    => $args{html},
    );

    return wantarray ? @items : \@items;
}

sub _get_content
{
    my ($self, %args) = @_;

    my $page    = $args{page};
    my $classes = $args{classes};
    my $html    = $args{html};

    # Hack to facilitate unit tests
    $html ||= $self->_get_html($page);

    my $tables = $self->_get_tables($html);

    my @items;
    for my $table (@$tables)
    {
        next unless ($table->{class} and $table->{class} eq 'patFunc');
        for my $row (@{$table->{rows}})
        {
            next unless ($row->{class} and $row->{class} eq 'patFuncEntry');
            my %record;
            for my $cell (@{$row->{cells}})
            {
                for my $class (@$classes)
                {
                    if ($cell->{class} and $cell->{class} eq "patFunc$class")
                    {
                        my $data = $self->_cleanup_data($cell->{data});
                        $record{lc($class)} = $data;
                        next;
                    }
                }
            }
        
            push @items, \%record;
        }
    }
    
    return wantarray ? @items : \@items;
}

sub _get_html
{
    my ($self, $page) = @_;

    $self->_login or croak "Couldn't log in!";

    my $mech = $self->{mech};
    return unless $mech;

    my $patron_id = $self->{patron_id};
    return unless $patron_id;

    my $prefix = $self->{url_prefix};
    return unless $prefix;

    $mech->get("$prefix/$patron_id/$page");
    return $mech->content;
}

sub _get_tables
{
    my ($self, $html) = @_;

    my $tp     = HTML::TableContentParser->new();
    my $tables = $tp->parse($html);
    return $tables;
}

sub _cleanup_data
{
    my ($self, $data) = @_;
    
    # If the result is a link, strip the link tags and use the title.
    # Not the greatest regex, but works for these simple cases.
    if ($data =~ /"\>\s*(.*)\s*<\/a>/m)
    {
        $data = $1;
    }
        
    # If the data is a select and there's something selected, use the
    # title of the selected option.
    if ($data =~ /\<select/ and $data =~ /selected/)
    {
        $data =~ /selected="selected">\s*(.*)\s*<\/option>/m;
        $data = $1;
    }

    # Remove leading and trailing whitespace.
    $data =~ s/^\s*//;
    $data =~ s/\s*$//;

    return $data;
}

1;


=head1 NAME

WWW::eiNetwork - Perl interface to Allegheny County, PA libraries

=head1 SYNOPSIS

  use WWW::eiNetwork;

  my $ein = WWW::eiNetwork->new(
      card_number => '23456000000000',
      pin_number  => '1234',
      url_prefix  => 'https://iiisy1.einetwork.net/patroninfo~S1', #optional
  );

  my @holds = $ein->holds;
  my @items = $ein->items;

  for my $hold (@holds)
  {
      print qq(
          Title:                      $hold->{title}
          Status:                     $hold->{status}
          Pickup at:                  $hold->{pickup}
          Cancel if not picked up by: $hold->{cancel}\n\n
      );
  }
  
  for my $item (@items)
  {
      print qq(
          Title:   $item->{title}
          Barcode: $item->{barcode}
          Status:  $item->{status}
          CallNo:  $item->{callno}\n\n
      );
  }
  
=head1 DESCRIPTION

This module provides an object-oriented Perl interface to eiNetwork libraries in Allegheny County, Pennsylvania.

=head1 DEPENDENCIES

WWW::Mechanize, HTML::TableContentParser, Crypt::SSLeay or IO::Socket::SSL

=head1 BUGS

The eiNetwork doesn't provide a public API - this module uses screen scraping to pull data directly from the HTML on their site. While I made an effort to code this module in such a way that small changes to the site layout and table arrangement won't break the module, any number of changes to the EIN's site could break this module.

=head1 DISCLAIMER

The author of this module is not affiliated in any way with the EINetwork or any Allegheny County library.

=head1 ACKNOWLEDGMENTS

Thanks to:

Adam Foxson (L<http://search.cpan.org/~Fhoxh>) for the great newbie's tutorial to contributing to CPAN at the Pittsburgh Perl Workshop (L<http://pghpw.org/ppw2007/>).

Bob O'Neill (L<http://search.cpan.org/~BOBO>) for sharing his CPAN know-how.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Michael Aquilina. All rights reserved.

This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Michael Aquilina, aquilina@cpan.org

=cut
