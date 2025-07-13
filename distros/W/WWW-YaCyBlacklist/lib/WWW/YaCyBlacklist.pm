use strict;
use warnings;

package WWW::YaCyBlacklist;
# ABSTRACT: a Perl module to parse and execute YaCy blacklists

our $AUTHORITY = 'cpan:IBRAUN';
$WWW::YaCyBlacklist::VERSION = '0.4';

use Moose;
use Moose::Util::TypeConstraints;
use IO::All;
use URI::URL;
require 5.6.0;


# Needed if RegExps do not compile
has 'use_regex' => (
    is  => 'ro',
    isa => 'Bool',
    default => 1,
);


has 'filename' => (
    is  => 'rw',
    isa => 'Str',
    default => 'ycb.black',
);

has 'file_charset' => (
    is  => 'ro',
    isa => 'Str',
    default => 'cp1252', # YaCy files are encoded in ANSI
    init_arg => undef,
);

has 'origorder' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    init_arg => undef,
);


has 'sortorder' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);


has 'sorting' => (
    is  => 'rw',
    isa => enum([qw[ alphabetical length origorder random reverse_host ]]),
    default => 'origorder',
);

has 'patterns' => (
    is=>'rw',
    isa => 'HashRef',
    traits  => [ 'Hash' ],
    default => sub { {} },
    init_arg => undef,
);

sub _check_host_regex {

    my ($self, $pattern) = @_;

    return 0 if $pattern =~ /^[\w\-\.\*]+$/; # underscores are not allowed in domain names but sometimes happen in subdomains
    return 1;
}


sub read_from_array {

    my ($self, @lines) = @_;
    my %hash;

    foreach my $line ( @lines ) {
        if ( CORE::length $line > 0 ) {
            $hash{ $line }{ 'origorder' } = $self->origorder( $self->origorder + 1 );
            ( $hash{ $line }{ 'host' }, $hash{ $line }{ 'path' } ) = split /(?!\\)\/+?/, $line, 2;
            $hash{ $line }{ 'host_regex' } = $self->_check_host_regex( $hash{ $line }{ 'host' } );
        }
    }

    $self->patterns( \%hash );
}


sub read_from_files {

    my ($self, @files) = @_;
    my @lines;

    grep { push( @lines, io( $_ )->encoding( $self->file_charset )->chomp->slurp ) } @files;
    $self->read_from_array( @lines );
}


sub length {

    my $self = shift;
    return scalar keys %{ $self->patterns };
}


sub check_url {

    my $self = shift;
    my $url = new URI $_[0];
    my $pq = ( defined $url->query ) ? $url->path.'?'.$url->query : $url->path;
    $pq = substr $pq, 1;

    foreach my $pattern ( keys %{ $self->patterns } ) {

        my $path = '^' . ${ $self->patterns }{ $pattern }{ path } . '$';
        next if $pq !~ /$path/;
        my $host = ${ $self->patterns }{ $pattern }{ host };

        if ( !${ $self->patterns }{ $pattern }{ host_regex } ) {
            $host =~ s/\*/.*/g;

            if ( ${ $self->patterns }{ $pattern }{ host } =~ /\.\*$/ ) {
                return 1 if $url->host =~ /^$host$/;
            }
            else {
                return 1 if $url->host =~ /^([\w\-]+\.)*$host$/;
            }
        }
        else {
            return 1 if $self->use_regex && $url->host  =~ /^$host$/;
        }
    }
    return 0;
}


sub find_matches {

    my $self = shift;
    my @urls;
    grep { push( @urls, $_ ) if $self->check_url( $_ ) } @_;
    return @urls;
}


sub find_non_matches {

    my $self = shift;
    my @urls;
    grep { push( @urls, $_ ) if !$self->check_url( $_ ) } @_;
    return @urls;
}


sub delete_pattern {

    my $self = shift;
    my $pattern = shift;
    delete( ${ $self->patterns }{ $pattern } ) if exists( ${ $self->patterns }{ $pattern } ) ;
}


sub sort_list {

    my $self = shift;
    return keys %{ $self->patterns } if $self->sorting eq 'random';
    my @sorted_list;

    @sorted_list = sort keys %{ $self->patterns } if $self->sorting eq 'alphabetical';
    @sorted_list = sort { CORE::length $a <=> CORE::length $b } keys %{ $self->patterns } if $self->sorting eq 'length';
    @sorted_list = sort { ${ $self->patterns }{ $a }{ origorder } <=> ${ $self->patterns }{ $b }{ origorder } } keys %{ $self->patterns } if $self->sorting eq 'origorder';
    @sorted_list = sort { reverse( ${ $self->patterns }{ $a }{ host } ) cmp reverse( ${ $self->patterns }{ $b }{ host } ) } keys %{ $self->patterns }  if $self->sorting eq 'reverse_host';

   return @sorted_list if $self->sortorder;
   return reverse( @sorted_list );
}


sub store_list {

    my $self = shift;
    join( "\n", $self->sort_list ) > io(  $self->filename )->encoding( $self->file_charset )->all;
}

1;
no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YaCyBlacklist - a Perl module to parse and execute YaCy blacklists

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    use WWW::YaCyBlacklist;

    my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
    $ycb->read_from_array(
        'test1.co/fullpath',
        'test2.co/.*',
    );
    $ycb->read_from_files(
        '/path/to/1.black',
        '/path/to/2.black',
    );

    print "Match!" if $ycb->check_url( 'http://test1.co/fullpath' );
    my @urls = (
        'https://www.perlmonks.org/',
        'https://metacpan.org/',
    );
    my @matches = $ycb->find_matches( @urls );
    my @nonmatches = $ycb->find_non_matches( @urls );

    $ycb->sortorder( 1 );
    $ycb->sorting( 'alphabetical' );
    $ycb->store_list( '/path/to/new.black' );

=head1 METHODS

=head2 C<new(%options)>

=head2 C<use_regex =E<gt> 0|1> (default C<1>)

Can only be set in the constructor and never be changed any later. If C<false>, the pattern will not get checked if the
C<host> part is a regular expression (but the patterns remain in the list).

=head2 C<filename =E<gt> '/path/to/file.black'> (default C<ycb.black>)

This is the file printed by C<store_list>

=head2 C<sortorder =E<gt>  0|1> (default C<0>)

0 ascending, 1 descending
Configures C<sort_list>

=head2 C<sorting =E<gt> 'alphabetical|length|origorder|random|reverse_host'> (default C<'origorder>)

Configures C<sort_list>

=head2 C<void read_from_array( @patterns )>

Reads a list of YaCy blacklist patterns.

=head2 C<void read_from_files( @files )>

Reads a list of YaCy blacklist files.

=head2 C<int length( )>

Returns the number of patterns in the current list.

=head2 C<bool check_url( $URL )>

1 if the URL was matched by any pattern, 0 otherwise.

=head2 C<@URLS_OUT find_matches( @URLS_IN )>

Returns all URLs which was matches by the current list.

=head2 C<@URLS_OUT find_non_matches( @URLS_IN )>

Returns all URLs which was not matches by the current list.

=head2 C<void delete_pattern( $pattern )>

Removes a pattern from the current list.

=head2 C<@patterns sort_list( )>

Returns a list of patterns configured by C<sorting> and C<sortorder>.

=head2 C<void store_list( )>

Prints the current list to a file. Executes C<sort_list( )>.

=head1 OPERATIONAL NOTES

The error

    ^* matches null string many times in regex; marked by <-- HERE in m/^^* <-- HERE

is probably caused by a corrupted path part of a pattern in your list (C<*> instead of C<.*>).

=head1 BUGS

YaCy does not allow host patterns with to stars at the time being. C<WWW::YaCyBlacklist> does not check for this but simply executes. This is rather a YaCy bug.

If there is something you would like to tell me, there are different channels for you:

=over

=item *

L<GitHub issue tracker|https://github.com/CarlOrff/WWW-YaCyBlacklist/issues>

=item *

L<CPAN issue tracker|https://rt.cpan.org/Public/Dist/Display.html?WWW-YaCyBlacklist>

=item *

L<Project page on my homepage|https://ingram-braun.net/erga/the-www-yacyblacklist-module/>

=item *

L<Contact form on my homepage|https://ingram-braun.net/erga/legal-notice-and-contact/>

=back

=head1 SOURCE

=over

=item *

L<De:Blacklists|https://wiki.yacy.net/index.php/De:Blacklists> (German).

=item *

L<Dev:APIlist|https://wiki.yacy.net/index.php/Dev:APIlist>

=back

=head1 SEE ALSO

=over

=item *

L<YaCy homepage|https://yacy.net/>

=item *

L<YaCy community|https://community.searchlab.eu/>

=back

=head1 AUTHOR

Ingram Braun <carlorff1@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ingram Braun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
