package Text::Filter::URI;

use warnings;
use strict;

use Text::Unidecode;

use base qw(Exporter Text::Filter);

our @EXPORT_OK;

BEGIN {
  @EXPORT_OK = qw(filter_uri);
}

=encoding utf8

=head1 NAME

Text::Filter::URI - Filter a string to meet URI requirements

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Use either the exported function or the OO interface:

    use Text::Filter::URI qw( filter_uri );

    my $uri = filter_uri("A text which needs to   be filtered  ");
    # $uri = "a-text-which-needs-to-be-filtered"

    my $f = Text::Filter::URI->new(input => $input, output => $output);
    $f->filter;

See L<Text::Filter> for details on C<$input> and C<$output>.

=head1 EXPORT

=cut

sub filter_uri {
  my @input = @_;
  my $output = [];
  my $f = Text::Filter::URI->new( input => [@input], output => $output);
  $f->filter;
  return wantarray ? @{$output} : $output->[0];
}

=head2 filter_uri

This method can be exported using
  use Text::Filter::URI qw( filter_uri );

It expects a string or an array of strings and returns the filtered strings accordingly.

=head1 METHODS

These methods are used for the OO interface. This allows you to use the full power of L<Text::Filter>.

=head2 new

The constructor C<new> takes a hash for configuration. See L<Text::Filter/CONSTRUCTOR> for more information on these settings.

There is one additional parameter:

=head3 separator

Define an individual string for separating the words. Defaults to C<->.

=cut

sub new {
   my $class = shift;
   my %backup = @_;
   my %param = (separator => '-', @_);
   delete $backup{separator};
   my $self = $class->SUPER::new(%backup);
   $self->{separator} = $param{separator};
   bless($self, $class);
   return $self;
}

=head2 filter

Call this method after calling C<new> to actually filter the C<$input>.

Unicode characters get encoded to their ascii equivalents using the L<Text::Unidecode>. This module maps characters like C<ä> to the ascii character C<a>.
This method contains several regular expressions which convert every not word character (C<\W>) and the underscore to a blank. Blanks at the beginning and the end are removed. All remaining blanks are replaced by the separator (defaults to C<->). Then it creates a lowercased version of the string.


=cut

sub filter {
  my $self = shift;
  { no locale;
    my $line;
    while ( defined($line = $self->readline) ) {
      $line = unidecode($line);
      $line =~ s/[\W_]/ /g;
      $line =~ s/^\s*|\s*$//g;
      $line =~ s/\s+/$self->{separator}/g;
      $line = lc($line);
      $self->writeline($line);
    }
  }
}



=head1 AUTHOR

Moritz Onken, C<< <onken@netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-filter-uri at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Filter-URI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2008 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::Filter::URI
