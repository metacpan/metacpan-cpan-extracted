package WWW::IndexParser::Entry;
use strict;
use warnings;
use overload '""' => \&_as_string;

BEGIN {
  our $VERSION = "0.6";
}


sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub filename {
  my $self = shift;
  if (@_) {
    $self->{filename} = shift;
  }
  return $self->{filename};
}

sub url {
  my $self = shift;
  if (@_) {
    my $new_url = shift;
    return unless $new_url =~ m!^\w+://[^:\s/]+(:\d+)?/!;
    $self->{url} = $new_url;
  }
  return $self->{url};
}

sub time {
  my $self = shift;
  if (@_) {
    my $new_time = shift;
    return unless $new_time =~ /^\d+$/;
    $self->{time} = $new_time;
  }
  return $self->{time};
}

sub type {
  my $self = shift;
  if (@_) {
    $self->{type} = shift;
  }
  return $self->{type};
}


sub size {
  my $self = shift;
  if (@_) {
    my $new_size = shift;
    return unless $new_size =~ /^\d+(\.\d+)?$/;
    $self->{size} = $new_size;
  }
  return $self->{size};
}

sub size_units {
  my $self = shift;
  if (@_) {
    $self->{size_units} = shift;
  }
  return $self->{size_units};
}

sub _as_string {
  my $self = shift;
  my $string;
  $string.= sprintf "Filename  : %s\n", $self->filename if defined $self->filename;
  $string.= sprintf "Size      : %s\n", $self->size if defined $self->size;
  $string.= sprintf "Size Units: %s\n", $self->size_units if defined $self->size_units;
  $string.= sprintf "Type      : %s\n", $self->type if defined $self->type;
  $string.= sprintf "URL       : %s\n", $self->url if defined $self->url;
  $string.= sprintf "Time      : %s\n", scalar localtime($self->time) if defined $self->time;
  return $string;
}

=head1 NAME

WWW::IndexParser::Entry - Object representing an item in a directory

=head1 SYNOPSIS

 my @files = WWW::IndexParser->new('http://www.james.rcpt.to/misc/');
 foreach my $file (@files) {
   print $file->url;
 }

=head1 DESCRIPTION


B<WWW::IndexParser::Entry> is not used directly, but is the class of 
items returned by B<WWW::IndexParser> when it successfully parses an 
auto index from a web server.


=head1 METHODS

=over 4

=item filename

=item url

=item size

=item size_units

=item type

=back


=head1 OSNAMES

any

=head1 AUTHOR

James Bromberger E<lt>james@rcpt.toE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 James Bromberger. All rights reserved. All rights 
reserved. This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

1;

1;
