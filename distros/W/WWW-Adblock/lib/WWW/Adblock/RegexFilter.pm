package WWW::Adblock::RegexFilter;

use strict;
use warnings;
use 5.006;

our $VERSION = "0.02";

=head1 NAME

WWW::Adblock::RegexFilter - implement a single Adblock filter

=head1 DESCRIPTION

Used by WWW::Adblock to implement a single filter.  Should not be called by an end user.

=head2 Methods

=head3 new

 my $f = WWW::Adblock::Filter->new();

Creates a new object.  Returns undef on failure or itself on success.

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = bless( {}, $class );

    # Create a blocking rule by default
    $self->{type}           = 'blocking';
    $self->{case_sensitive} = 0;
    $self->{domains}        = undef;
    $self->{regex}          = undef;

    return unless exists $args{text};
    return unless $self->_from_text( $args{text} );

    return $self;
}

=head3

  $f->_from_text("filter text");

Called by new to setup the filter.

=cut

sub _from_text {
    my ( $self, $text ) = @_;

    return 0 unless defined $text;

    if ( $text =~ m/^@@(.+)$/ ) {
        $text = $1;
        $self->{type} = 'whitelist';
    }

    # If this rule has options, parse them out
    if ( $text =~ /\$(~?[\w\-]+(?:=[^,\s]+)?(?:,~?[\w\-]+(?:=[^,\s]+)?)*)$/ ) {
        $text = $`;
        my @options = split( /,/, $1 );

        foreach my $o (@options) {
            my ( $option, $value ) = split( /=/, $o, 2 );
            $option = uc($option);

            # TODO: Add content type matching too.  For URI filtering it
            #       doesn't help but it would be necessary for element
            #       filtering.
            if ( $option eq "MATCH_CASE" ) {
                $self->{case_sensitive} = 1;

            }
            elsif ( $option eq "DOMAIN" && defined $value ) {
                $self->{domains} = [ split( /\|/, $value ) ];

            }

            # Other options that aren't implemented
            # "THIRD_PARTY", "~THIRD_PARTY", "COLLAPSE", "~COLLAPSE"
        }
    }

    $text =~ s/\*+/*/g;        # Remove multiple wildcards
    $text =~ s/^\*+//;         # Remove leading wildcards
    $text =~ s/\*+$//;         # Remove trailing wildcards
    $text =~ s/\^\|$/\^/;      # Remove anchors following separator
    $text =~ s/(\W)/\\$1/g;    # Escape special symbols
    $text =~ s/\\\*/.*/g;      # Replace wildcards with .*

    # Separator placeholders (all ANSI characters but alpha or _%.-)
    $text =~
      s/\\\^/(?:[\x00-\x24\x26-\x2C\x2F\x3A-\x40\x5B-\x5E\x60\x7B-\x80]|\$)/g;

    # Extended anchor
    $text =~ s/^\\\|\\\|/^[\\w\\-]+:\/+(?!\/)(?:[^\/]+\.)?/;

    $text =~ s/^\\\|/^/;       # Start anchor
    $text =~ s/\\\|$/\$/;      # End anchor

    $self->{regex} = qr/$text/;
    return 1;
}

sub matches {
    my ( $self, $uri, $domain ) = @_;

    # TODO: Should support the other options (contentType, thirdParty)

    # If the domain is given and this rule is constrained to domains, check
    # whether we should proceed
    if ( defined $domain && defined $self->{domains} ) {
        if ( !grep /^$domain$/, $self->{domains} ) {
            return 0;
        }
    }

    if ( $uri =~ $self->{regex} ) {

        #print "$uri matched $r (mode " . $self->{type} . ")\n";
        return 1 if $self->{type} eq 'blocking';
        return 2 if $self->{type} eq 'whitelist';
    }

    return 0;
}

1;
