package Text::Beautify;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        beautify enable_feature disable_feature features enabled_features
        enable_all disable_all
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.08';

=head1 NAME

Text::Beautify - Beautifies text

=head1 SYNOPSIS

  use Text::Beautify;

  $text = "badly written text ,,you know ?"

  $new_text = beautify($text);
  # $new_text now holds "Badly written text, you know?"

  # or

  $text = Text::Beautify->new("badly written text ,,you know ?");
  $new_text = $text->beautify;

  # and also

  enable_feature('repeated_punctuation'); # enables the feature
  disable_feature('trailing_space');      # disables the feature

  @features_enables = enabled_features();

  @all_features = features();

  enable_all();
  disable_all();

=head1 DESCRIPTION

Beautifies text. This involves operations like squeezing double spaces,
removing spaces from the beginning and end of lines, upper casing the
first character in a string, etc.

You can enable / disable features with I<enable_feature> /
I<disable_feature>. These commands return a true value if they
are successful.

To know which features are beautified, see FEATURES

=head1 FEATURES

All features are enabled by default

=over 4

=item * heading_space

        Removes heading spaces

=item * trailing_space

        Removes trailing spaces

=item * double_spaces

        Squeezes double spaces

=item * repeated_punctuation

        Squeezes repeated punctuation

=item * space_in_front_of_punctuation

        Removes spaces in front of punctuation

=item * space_after_punctuation

        Puts a spaces after punctuation

=item * uppercase_first

        Uppercases the first character in the string

=back

=cut

my $debug = 0;
my (%features,@features,%status);

BEGIN {
  my $empt = '\'\'';
  %features = (
    heading_space                 => [[qr/^ +/                    , $empt    ]],
    trailing_space                => [[qr/ +$/                    , $empt    ]],
    space_in_front_of_punctuation => [[qr/ +(?=[,!?]|[:;](?![-)(]))/,$empt   ]],
    double_spaces                 => [[qr/  +/                    , '\' \''  ]],
    repeated_punctuation          => [[qr/([;:,!?])(?=\1)/        , $empt    ],
                                      [qr/\.{3,}/                 , '\'...\''],
                                      [qr/(?<!\.)\.\.(?!\.)/      , '\'.\''  ]],

    space_after_punctuation       =>[[qr/([;:,!?])(?=[[:alnum:]])/, '"$1 "'  ]],
    uppercase_first               => [[qr/([.!?]+\s*[a-z])/i      , 'uc($1)' ],
                                      [qr/^(\s*[[:alnum:]])/      , 'uc($1)' ],
                                      [qr/(?<=[!?] )([a-z])/      , 'uc($1)' ],
                                      [qr/(?<=[^.]\. )([a-z])/    , 'uc($1)' ]],
  );

  @features = qw(
    heading_space
    trailing_space
    double_spaces
    repeated_punctuation
    space_in_front_of_punctuation
    space_after_punctuation
    uppercase_first
  );

  %status = map { ( $_ , 1 ) } @features; # all features enabled by default
}

=head1 METHODS

=head2 new

Creates a new Text::Beautify object

=cut

sub new {
  my ($self,@text) = @_;
  bless \@text, 'Text::Beautify';
}

=head2 beautify

Applies all the enabled features

=cut

sub beautify {

  my @text;
  if (ref($_[0]) eq 'Text::Beautify') {
    my $self = shift;
    @text = @$self;
  }
  else {
    @text = wantarray ? @_ : $_[0];
  }

  for (join "\n", @text) {

    for my $feature (@features) {
      next unless $status{$feature};
      my ($str,$end) = ('','');
      ($str,$end) = ("<$feature>","</$feature>") if $debug;

      for my $f (@{$features{$feature}}) {
        s/$$f[0]/$str . (eval $$f[1]) . $end/ge;
      }
    }

    return $_;
  }

}

=head2 enabled_features

Returns a list with the enabled features

=cut

sub enabled_features { grep $status{$_}, keys %features; }

=head2 features

Returns a list containing all the features

=cut

sub features         { keys %features; }

=head2 enable_feature

Enables a feature

=cut

sub enable_feature   { _auto_feature(1,@_); }

=head2 disable_feature

Disables a feature

=cut

sub disable_feature  { _auto_feature(0,@_); }

=head2 enable_all

Enables all features

=cut

sub enable_all       { _auto_feature(1,features()) }

=head2 disable_all

Disables all features

=cut

sub disable_all      { _auto_feature(0,features()) }

sub _auto_feature {
  my $newstatus = shift;
  for (@_) { defined $features{$_} || return undef; }
  for (@_) { $status{$_} = $newstatus; }
  1
}

1;
__END__

=head1 TO DO

=over 6

=item * Allow the user to select the order in which features are applied

=item * Allow creation of new features

=back

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
