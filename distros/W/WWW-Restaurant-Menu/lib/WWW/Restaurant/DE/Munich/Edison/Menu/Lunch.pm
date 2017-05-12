#
# WWW::Restaurant::DE::Munich::Edison::Menu::Lunch class
#
# (C) 2004-2005 Julian Mehnle <julian@mehnle.net>
# $Id: Lunch.pm,v 1.8 2005/01/15 15:47:55 julian Exp $
#
##############################################################################

=head1 NAME

WWW::Restaurant::DE::Munich::Edison::Menu::Lunch - A Perl class for querying
the online lunch menu of the Munich restaurant "Edison".

=cut

package WWW::Restaurant::DE::Munich::Edison::Menu::Lunch;

=head1 VERSION

0.11

=cut

our $VERSION = '0.11';

use v5.8;

use utf8;
use warnings;
use strict;

use base qw(WWW::Restaurant::Menu);

use LWP;
#use HTML::HeadParser;
use HTML::TableExtract;
use HTML::TableExtract::Raw;
use Encode;

use WWW::Restaurant::Menu::Item;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant SOURCE_URI     => 'http://www.edisonundco.de/mittag.htm';

use constant SOURCE_RAW_TABLE_COORDS            => ( depth => 1, count => 1 );
use constant SOURCE_DATA_TABLE_COORDS_RELATIVE  => ( depth => 1, count => 1 );

use constant PRICE_THRESHOLD_MEAL               => 5.00;
use constant MENU_ITEM_STAGES                   => qw(Starter Meal Dessert);

use constant DEFAULT_CURRENCY                   => '€';

# Interface:
##############################################################################

=head1 SYNOPSIS

    use WWW::Restaurant::DE::Munich::Edison::Menu::Lunch;
    
    # Construction:
    my $menu = WWW::Restaurant::DE::Munich::Edison::Menu::Lunch->new();
    
    # Get all menu items, in order:
    my @items       = $menu->items;
    
    # Get menu items by class:
    my @starters    = $menu->starters;
    my @meals       = $menu->meals;
    my @desserts    = $menu->desserts;
    my @drinks      = $menu->drinks;  # Currently not supported by Edison.
    
    # Get currency of item prices:
    my $currency    = $menu->currency;  # "\x{20ac}" (Euro Sign)
    
    # Get relevant raw HTML part of the lunch menu web resource:
    my $raw         = $menu->raw;

=head1 DESCRIPTION

This is a Perl class for querying the online lunch menu of the Munich
restaurant "Edison", which is available at
L<http://www.edisonundco.de/mittag.htm>.

=cut

sub currency;
sub raw;

# Implementation:
##############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new>: RETURNS WWW::Restaurant::DE::Munich::Edison::Menu::Lunch

Creates a new C<WWW::Restaurant::DE::Munich::Edison::Menu::Lunch> object.

=back

=head2 Instance methods

The following instance methods are provided:

=over

=item B<items>

=item B<starters>

=item B<meals>

=item B<desserts>

=item B<drinks>

See L<WWW::Restaurant::Menu/"Instance methods"> for a description of these
instance methods.

=item B<currency>: RETURNS SCALAR

Returns "\x{20ac}" (Euro Sign).

=cut

sub currency {
    return "€";
}

=item B<raw>: RETURNS SCALAR

Returns a string containing the relevant raw HTML part of the lunch menu web
resource.  For instance, this could be useful for inclusion in another HTML web
resource or an HTML mail message.

=cut

sub raw {
    my ($self) = @_;
    $self->get()
        if not defined($self->{raw});
    return $self->{raw};
}

=back

=cut

sub query {
    my ($self) = @_;
    $self->parse();
    return @{ $self->{items} };
}

sub parse {
    my ($self) = @_;
    
    # Ugly hack for suppressing invisible text:
    my $raw = $self->raw;
    $raw =~ s/<font\s+[^>]*\bcolor=("?)#ffffff\b\1[^>]*>.*?<\/font>//gis;
    
    my $table_extractor = HTML::TableExtract->new(
        SOURCE_DATA_TABLE_COORDS_RELATIVE,
        keep_html   => TRUE
    );
    $table_extractor->parse($raw);
    
    my @items;
    
    my $stage = 0;
    foreach my $row ($table_extractor->rows) {
        my @columns = map($self->trim_text($_), @$row);
        
        next if not $columns[0];
        
        $columns[0] =~ s/^\d+-//;
        
        my $name  = $columns[0] . $columns[1];
        my $price = $columns[2] =~ /(\d+)[,\.](\d{2})/ ? "$1.$2" : undef;
        
        # Work around HTML::TableExtract Unicode deficiency? (Probably not needed.)
        #$name  = Encode::decode_utf8($name);
        #$price = Encode::decode_utf8($price);
        
        my $class;
        $class = (MENU_ITEM_STAGES)[  $stage];
        $class = (MENU_ITEM_STAGES)[++$stage]
            if  defined($price)
            and (
                ($class eq 'Starter' and $price >= PRICE_THRESHOLD_MEAL) or
                ($class eq 'Meal'    and $price <  PRICE_THRESHOLD_MEAL)
            );
        
        my $item = "WWW::Restaurant::Menu::Item::${class}"->new(
            name        => $name,
            price       => $price
        );
        push(@items, $item);
    }
    
    return $self->{items} = \@items;
}

sub get {
    my ($self) = @_;
    
    # Re-get source unconditionally, no caching.
    
    my $response = $self->user_agent->get(SOURCE_URI);
    die('Could not retrieve lunch menu page: ' . SOURCE_URI)
        if not $response->is_success;
    
    my $page = $response->content;
    
    my $encoding;
    
    #my $head_parser = HTML::HeadParser->new();
    #$head_parser->parse($page);
    #($encoding) = ($head_parser->header->content_type)[1] =~ /\bcharset=([\w-]+)/i;
    #($encoding) = ($response->content_type)[1]            =~ /\bcharset=([\w-]+)/i
    #    if not defined($encoding);
    
    # Override automatic charset recognition, as the Edison-provided charset is b0rken:
    $encoding = 'windows-1252';
    
    $page = Encode::decode($encoding, $page) if defined($encoding);
    
    my $table_extractor;
    
    $table_extractor = HTML::TableExtract::Raw->new(SOURCE_RAW_TABLE_COORDS);
    $table_extractor->parse($page);
    
    my $raw = $table_extractor->html;
    
    # Work around HTML::TableExtract::Raw Unicode deficiency:
    $raw = Encode::decode_utf8($raw);
    
    $raw =~ s/height=["']?[456789]\d\d["']?//gi;
    
    return $self->{raw} = $raw;
}

sub user_agent {
    my ($self) = @_;
    return $self->{user_agent} ||= LWP::UserAgent->new();
}

sub trim_text {
    my ($self, $text) = @_;
    $text =~ s/<.*?>//sg;  # Remove all HTML tags.
    $text =~ s/\.{2,}//sg;
    $text =~ s/\x{a0}/ /g;
    $text =~ s/^\s*|\s*$//sg;
    $text =~ s/\s+/ /sg;
    return $text;
}

=head1 SEE ALSO

For COPYRIGHT and LICENSE information, see L<WWW::Restaurant::Menu::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:tw=79
