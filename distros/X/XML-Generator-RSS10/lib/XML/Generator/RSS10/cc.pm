package XML::Generator::RSS10::cc;
{
  $XML::Generator::RSS10::cc::VERSION = '0.02';
}

use strict;

use base 'XML::Generator::RSS10::Module';

use Params::Validate qw( validate SCALAR );

sub NamespaceURI { 'http://web.resource.org/cc/' }

use constant CONTENTS_SPEC => {
    license => { type => SCALAR },
};

my %Licenses = (
    'http://creativecommons.org/licenses/by/2.0/' => {
        permits  => [qw( Reproduction Distribution DerivativeWorks )],
        requires => [qw( Attribution Notice )],
    },

    'http://creativecommons.org/licenses/by-nd/2.0/' => {
        permits  => [qw( Reproduction Distribution )],
        requires => [qw( Attribution Notice )],
    },

    'http://creativecommons.org/licenses/by-nc-nd/2.0/' => {
        permits   => [qw( Reproduction Distribution )],
        requires  => [qw( Attribution Notice )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-nc/2.0/' => {
        permits   => [qw( Reproduction Distribution DerivativeWorks )],
        requires  => [qw( Attribution Notice )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-nc-sa/2.0/' => {
        permits   => [qw( Reproduction Distribution DerivativeWorks )],
        requires  => [qw( Attribution Notice ShareAlike )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-sa/2.0/' => {
        permits  => [qw( Reproduction Distribution DerivativeWorks )],
        requires => [qw( Attribution Notice ShareAlike )],
    },

    'http://creativecommons.org/licenses/by/3.0/us/' => {
        permits  => [qw( Reproduction Distribution DerivativeWorks )],
        requires => [qw( Attribution Notice )],
    },

    'http://creativecommons.org/licenses/by-nd/3.0/us/' => {
        permits  => [qw( Reproduction Distribution )],
        requires => [qw( Attribution Notice )],
    },

    'http://creativecommons.org/licenses/by-nc-nd/3.0/us/' => {
        permits   => [qw( Reproduction Distribution )],
        requires  => [qw( Attribution Notice )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-nc/3.0/us/' => {
        permits   => [qw( Reproduction Distribution DerivativeWorks )],
        requires  => [qw( Attribution Notice )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-nc-sa/3.0/us/' => {
        permits   => [qw( Reproduction Distribution DerivativeWorks )],
        requires  => [qw( Attribution Notice ShareAlike )],
        prohibits => ['CommercialUse'],
    },

    'http://creativecommons.org/licenses/by-sa/3.0/us/' => {
        permits  => [qw( Reproduction Distribution DerivativeWorks )],
        requires => [qw( Attribution Notice ShareAlike )],
    },
);

sub contents {
    my $class = shift;
    my $rss   = shift;
    my %p     = validate( @_, CONTENTS_SPEC );

    if ( exists $p{license} ) {
        die "Unknown license: $p{license}\n"
            unless exists $Licenses{ $p{license} };

        $rss->_element( 'cc', 'license', [ 'rdf', 'about', $p{license} ] );
        $rss->_newline_if_pretty;

        $rss->{__cc_licenses__}{ $p{license} } = 1;
    }
}

sub channel_hook {
    my $class = shift;
    my $rss   = shift;

    foreach my $license ( keys %{ $rss->{__cc_licenses__} } ) {
        $rss->_start_element(
            'cc', 'License',
            [ 'rdf', 'about', $license ],
        );
        $rss->_newline_if_pretty;

        foreach my $elt ( keys %{ $Licenses{$license} } ) {
            foreach my $val ( @{ $Licenses{$license}{$elt} } ) {
                $rss->_element(
                    'cc', $elt,
                    [ 'rdf', 'resource', "http://web.resource.org/cc/$val" ],
                );
                $rss->_newline_if_pretty;
            }
        }

        $rss->_end_element( 'cc', 'License' );
        $rss->_newline_if_pretty;
    }
}

1;

# ABSTRACT: Support for the Creative Commons (cc) RSS 1.0 module



=pod

=head1 NAME

XML::Generator::RSS10::cc - Support for the Creative Commons (cc) RSS 1.0 module

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use XML::Generator::RSS10;

    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler );

    $rss->item( title => 'Exciting News About my Pants!',
                link  => 'http://pants.example.com/my/news.html',
                description => 'My pants are full of ants!',
                cc => { license => 'http://creativecommons.org/licenses/by/3.0/us/' }
              );

    $rss->channel( title => 'Pants',
                   link  => 'http://pants.example.com/',
                   description => 'A fascinating pants site',
                 );

=head1 DESCRIPTION

This module provides support for the Creative Commons (cc) RSS 1.0 module.

=head1 PARAMETERS

This module allows expects one parameter, "license", which can be
passed to any method.  It will automatically add channel subelements
for each license used.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

