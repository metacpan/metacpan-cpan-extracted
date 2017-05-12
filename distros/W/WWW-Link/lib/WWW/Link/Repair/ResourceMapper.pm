package WWW::Link::Repair::Mapper;
$REVISION=q$Revision: 1.4 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

=head1 NAME 

WWW::Link::Repair::Mapper - map urls to objects which can fix resources

=head1 SYNOPSIS

NOT IMPLEMENTED

=head1 DESCRIPTION

B<This module is not yet in use.  It is a placeholder and I am not yet
convinced that it will be used, but it is likely that eventually I
will find reason for it.>

Mapper objects know about how to repair aned edit resources pointed to
by specific URLS.  

They match regular expressions against the given URLs in string
format.  They then apply a translation function if one is provided to
translate that url into a new URL.  This is repeated until a non
remappable translation is found (if more than a maximum number of
translations has been carried out the translation dies to detect
problems).  Finally they apply the functions registered against the
finaly translation and do the appropriate editing.

=cut


new {
  my $class = shift;
  my $self = bless {}, $class;
  my $self->{"translations"}=[];
}

add_translation ($) {
}


package WWW::Link::Repair::Mapper::Translation;

=head2 $trans->new()

We need a regexp, optionally followed by a list of functions that can
be applied.

convert_to_file
edit_file
convert_from_file
edit_in_place

=cut

sub new ($$@) {
  my $class=shift;
  my $self = bless {}, $class;
  my $self->{"regexp"}=shift;
}

=head1 apply

This applies the translation by checking the given url against the 


sub apply ($$) {




