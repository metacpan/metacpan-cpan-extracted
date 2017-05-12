package Tree::Lexicon;

use 5.006;
use strict;
use warnings FATAL => 'all';
use integer;
use Carp;

=head1 NAME

Tree::Lexicon - Object class for storing and retrieving a lexicon in a tree of affixes

=cut

require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( cs_regexp ci_regexp );

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tree::Lexicon;

    my $lexicon = Tree::Lexicon->new();

    $lexicon->insert( 'apply', '', 'Apple', 'Windows', 'Linux', 'app', 'all day' );
    # Warns of strings not matching /^\w+/ without inserting

    if ($lexicon->contains( 'WiNdOwS' )) {
        $lexicon->remove( 'wInDoWs' );
        $lexicon->insert( 'Vista' );
    }
    
    my @words = $lexicon->vocabulary;
    # Same as:
    @words = ( 'Apple', 'Linux', 'Windows', 'app', 'apply' );

    @words = $lexicon->auto_complete( 'ap' );
    # Same as:
    @words = ( 'app', 'apply' );
    
    my $regexp = $lexicon->as_regexp();
    # Same as:
    $regexp = qr/\b(?:Apple|Linux|Windows|app(?:ly)?)\b/;

    my $caseless->Tree::Lexicon->new( 0 )->insert( 'apply', '', 'Apple', 'Windows', 'Linux', 'app', 'all day' );
    # Warns of strings not matching /^\w+/ without inserting

    if ($caseless->contains( 'WiNdOwS' )) {
        $caseless->remove( 'wInDoWs' );
        $caseless->insert( 'Vista' );
    }
    
    @words = $caseless->vocabulary;
    # Same as:
    @words = ( 'APP', 'APPLE', 'APPLY', 'LINUX', 'VISTA' );
    
    @words = $caseless->auto_complete( 'ap' );
    # Same as:
    @words = ( 'APP', 'APPLE', 'APPLY' );
    
    my $regexp = $caseless->as_regexp();
    # Same as:
    $regexp = qr/\b(?:[Aa][Pp[Pp](?:[Ll](?:[Ee]|[Yy]))?|[Ll][Ii][Nn][Uu][X]|[Vv][Ii][Ss][Tt][Aa])\b/;
    
    use Tree::Lexicon qw( cs_regexp ci_regexp );
    
    my $cs_regexp = cs_regexp( @words );
    # Same as:
    $cs_regexp = Tree::Lexicon->new()->insert( @words )->as_regexp();
    
    my $ci_regexp = ci_regexp( @words );
    # Same as:
    $ci_regexp = Tree::Lexicon->new( 0 )->insert( @words )->as_regexp();


=head1 DESCRIPTION

The purpose of this module is to provide a simple and effective means to store a lexicon.  It is intended to aid parsers in identifying keywords and interactive applications in identifying user-provided words.

=head1 EXPORT

=head2 cs_regexp

Convenience function for generating a case sensitive regular expression from list of words.

    my $cs_regexp = cs_regexp( @words );
    # Same as:
    $cs_regexp = Tree::Lexicon->new( 1 )->insert( @words )->as_regexp();

=cut

sub cs_regexp {
    return Tree::Lexicon->new()->insert( @_ )->as_regexp();
}

=head2 ci_regexp

Convenience function for generating a case insensitive regular expression from list of words.

    my $ci_regexp = cs_regexp( @words );
    # Same as:
    $ci_regexp = Tree::Lexicon->new( 0 )->insert( @words )->as_regexp();

=cut

sub ci_regexp {
    return Tree::Lexicon->new( 0 )->insert( @_ )->as_regexp();
}

=head1 METHODS

Passing a string not matching C</^\w+/> as an argument to L<C<insert>|/insert>, L<C<remove>|/remove>, L<C<contains>|/contains> or L<C<auto_complete>|/auto_complete> yields a warning to STDERR and nothing else.

=head2 new

Returns a new empty C<Tree::Lexicon> object.  By default, the tree's contents are case-sensitive.  Passing a single I<false> argument to the constuctor makes its contents case-insensitive.

    $lexicon = Tree::Lexicon->new();
    # Same as:
    $lexicon = Tree::Lexicon->new( 1 );
    
    # or #
    
    $lexicon = Tree::Lexicon->new( 0 );

=cut

# Constructor

sub new {
    my  $class  = shift;
    my  $cs     = shift;
        $cs     = (defined $cs) ? $cs ? 1 : '' : 1;

    return bless { CASE => $cs, NODES => [] };
}

=head2 insert

Inserts zero or more words into the lexicon tree and returns the object.

    $lexicon->insert( 'list', 'of', 'words' );

If you already have an initial list of words, then you can chain this method up with the constructor.

    my $lexicon = Tree::Lexicon->new()->insert( @words );

=cut

# Insert words

sub insert {
    my $self = shift;

    if ($self->{CASE}) {
        foreach (@_) { _insert( $self->{NODES}, $_ ); }
    }
    else {
        foreach (@_) { _insert( $self->{NODES}, uc( $_ ) ); }
    }
    
    return $self;
}

=head2 remove

Removes zero or more words from the lexicon tree and returns them (or C<undef> if not found).

    @removed = $lexicon->remove( 'these', 'words' );

=cut

# Remove words

sub remove {
    my $self = shift;

    return  (wantarray or (@_ > 1)) ?
            ($self->{CASE}) ?
            map { _remove( $self->{NODES}, $_ ) } @_ :
            map { _remove( $self->{NODES}, uc( $_ ) ) } @_ :
            ($self->{CASE}) ?
            _remove( $self->{NODES}, shift ) :
            _remove( $self->{NODES}, uc( shift ));
}

=head2 contains

Returns C<1> or C<''> for each word as to its presence or absense, respectively.

    @verify = $lexicon->contains( 'these', 'words' );

=cut

# Verify words

sub contains {
    my $self    = shift;

    return  (wantarray or (@_ > 1)) ?
            ($self->{CASE}) ?
            map { _contains( $self->{NODES}, $_ ) } @_ :
            map { _contains( $self->{NODES}, uc( $_ ) ) } @_ :
            ($self->{CASE}) ?
            _contains( $self->{NODES}, shift ) :
            _contains( $self->{NODES}, uc( shift ));
}

=head2 auto_complete

Returns all words beginning with the string passed.

    @words = $lexicon->auto_complete( 'a' );

=cut

# Words beginning with

sub auto_complete {
    my $self    = shift;
    my $prefix  = shift;
    
    unless ($prefix and $prefix =~ /^\w+/) {
        carp "Cannot auto-complete non-word string.";
        return ();
    }

    ($self->{CASE}) or $prefix = uc $prefix;

    my ($node, $root) = _ac_first( $self->{NODES}, $prefix );

    (defined $node) or return ();

    my @words = _vocabulary( $node->[-1], $root );
    ($node->[1]) and unshift @words, $root;

    return @words;
}

=head2 vocabulary

Returns all words in the lexicon.

    @words = $lexicon->vocabulary();

=cut

# All words

sub vocabulary {
    my $self = shift;

    return _vocabulary( $self->{NODES} );
}

=head2 as_regexp

Returns a regular expression equivalent to the lexicon tree.  The regular expression has the form C<qr/\b(?: ... )\b/>.

    $regexp = $lexicon->as_regexp();

=cut

# Lexicon as regular expression

sub as_regexp {
    my $self    = shift;
    my $regexp  = $self->{CASE} ?
                  _cs_regexp( $self->{NODES} ) :
                  _ci_regexp( $self->{NODES} );

    return qr/\b(?:$regexp)\b/;
}

## Begin Private Functions ##

# Recursive backend for 'insert()'
sub _insert {
    my ($nodes,
        $string)  = @_;

    unless ($string and $string =~ /^\w+$/) {
        carp "Cannot insert non-word string into lexicon tree.";
        return;
    }

    # Node location and possible common root
    my ($node,
        $pos,
        $root)    = _locate( $nodes, $string );

    # Is there a common root to node's string and passed string?
    if ($root) {
        # Are they equal?
        if ($string eq $node->[0]) {
            $node->[1] = 1;
        }
        else {
            # Strip the common root from $string
            $string =~ s/^$root//;
            # Is common root same as node's string?
            unless ($node->[0] eq $root) {
                # No: split node upwards
                $node->[0] =~ s/^$root//;
                $node = [ $root, !$string, [ $node ] ];
                $nodes->[$pos] = $node;
            }
            # Recurse with what's left of $string
            _insert( $node->[-1], $string ) if ($string);
        }
    }
    else {
        # This is a node with no root in common with its neighbors
        splice( @{$nodes}, $pos, 0, [ $string, 1, [] ] );
    }
}

# Backend for 'remove()'
sub _remove {
    my ($nodes,
        $sought)  = @_;
    my  $found;
    my  @stack    = ();
    my ($node,
        $pos,
        $root);

    unless ($sought and $sought =~ /^\w+$/) {
        carp "Cannot remove non-word string from lexicon tree.";
        return undef;
    }

    # Search tree, stripping sought of roots and appending to found
    do {
        ($node, $pos, $root) = _locate( $nodes, $sought );
        # Is there a node whose string can be stripped from string?
        if ($root eq $node->[0]) {
            # Add to what was found
            $found .= $root;
            # Strip what was found
            $sought =~ s/^$root//;
            # Is there more to search?
            if ($sought) {
                # Record visit
                push @stack, [ $node, $nodes, $pos ];
                # Recurse
                $nodes = $node->[-1];
            }
            else {
                # Verify that $found is a "hit"
                ($node->[1]) or
                    $found = undef;
            }
        }
        else {
            $found = undef;
        }
    } while ($sought and $found);

    if ($found) {
        $node->[1] = '';
        until ($node->[1] || @{$node->[-1]}) {
            splice( @{$nodes}, $pos, 1 );
            last unless (@stack);
            ($node, $nodes, $pos) = @{pop @stack};
        }
    }

    return $found;
}

# Backend for 'contains()'
sub _contains {
    my ($nodes,
        $sought)  = @_;
    my ($node,
        $pos,
        $root);

    unless ($sought and $sought =~ /^\w+$/) {
        carp "Cannot find non-word string in lexicon tree.";
        return undef;
    }

    # Search tree, stripping string of roots
    while ($sought) {
        ($node, $pos, $root) = _locate( $nodes, $sought );
        # Is there a node whose string can be stripped from string?
        last unless ($node and $root eq $node->[0]);
        $sought =~ s/^$root//;
        # Recurse?
        ($sought) and $nodes = $node->[-1];
    }

    return (not $sought and $node->[1]);
}

# Recursive backend for 'vocabulary()'
sub _vocabulary {
    my $nodes = shift;
    my $root  = shift || '';
    my @vocab;
    
    foreach my $node (@{$nodes}) {
        my $ext_root = $root.$node->[0];
        ($node->[1]) and push @vocab, $ext_root;
        push @vocab, _vocabulary( $node->[-1], $ext_root );
    }

    return @vocab;
}

# Case sensitive recursive backend for 'as_regexp()'
sub _cs_regexp {
    join( '|', map {
        $_->[0].(
            (@{$_->[-1]}) ?
            '(?:'._cs_regexp( $_->[-1] ).')'.(
                ($_->[1]) ? '?' : ''
            ) : ''
        ) } @{$_[0]} )
}

# Case insensitive recursive backend for 'as_regexp()'
sub _ci_regexp {
    join( '|', map {
        _ci_seq( $_->[0] ).(
            (@{$_->[-1]}) ?
            '(?:'._ci_regexp( $_->[-1] ).')'.(
                ($_->[1]) ? '?' : ''
            ) : ''
        ) } @{$_[0]} )
}

# Begin Helper Functions #

# Greatest common root of two strings (called by '_locate()')
sub _gc_root {
    my ($string1,
        $string2) = @_; # ( $string1 le $string2 )

    # Does $string2 begin with $string1?
    ($string2 =~ /^$string1/) and
        return $string1;

    # First character of $string1
    my $root = substr( $string1, 0, 1 );

    # Does $string2 begin with the same character?
    ($string2 =~ /^$root/) or
        return '';

    # Append characters from $string1 to root ...
    for (my $i = 1; $i < length( $string1 ); $i++) {
        $root .= substr( $string1, $i, 1 );
        # ... until it no longer matches $string2.
        unless ($string2 =~ /^$root/) {
            $root = substr( $root, 0, $i );
            last;
        }
    }

    return $root;
}

# Get position within array and common root of node string and passed string
sub _locate {
    my ($nodes,
        $sought)  = @_;
    my ($min,
        $pos)     = ( -1, @{$nodes} - 1 );
    my  $root     = '';
    my  $node;

    # Binary search from above
    while ($pos > $min and
           $sought lt $nodes->[$pos]->[0]) {
        my $mid = $pos + ($min - $pos) / 2;
        if ($sought lt $nodes->[$mid]->[0]) {
            $pos = $mid - 1;
        }
        else {
            $min = $mid;
        }
    }

    # Value of $pos is position of greatest
    # less-than-or-equal node, possibly -1
    
    # Is there a less-than-or-equal node with a common root?
    unless ($pos >= 0 and $node = $nodes->[$pos] and
            $root = _gc_root( $node->[0], $sought )) {
        # No
        $pos++;
        # Value of $pos is position of least
        # greater-than-or-equal node, possibly scalar( @{$nodes} )

        # Is there a greater-than-or-equal node? with a common root?
        ($pos < scalar( @{$nodes} )) and
            $node = $nodes->[$pos] and
            $root = _gc_root( $sought, $node->[0] );
    }
    
    return ($node, $pos, $root);
}

# Recursive backend to seed 'auto_complete()'
sub _ac_first {
    my ($nodes,
        $string,
        $ext_root)  = @_;
    my ($node,
        $pos,
        $root)      = _locate( $nodes, $string );
       ($ext_root) or
        $ext_root   = '';

    # Is there a node in common to string?
    if ($root) {
        # Yes: extened the recorded root thus far
        $ext_root .= $node->[0];

        # Does string terminate in node's string?
        ($node->[0] =~ /^$string/) and
            return ( $node, $ext_root );

        # Does string exceed node's string?
        ($string =~ s/^$node->[0]//) and
            return _ac_first( $node->[-1], $string, $ext_root );

        # Else, fall through
    }

    return ();
}

# Convert string to case insensistive sequence (called by '_ci_regexp()')
sub _ci_seq {
    my $str = shift;
    my $lc  = lc $str;
    my $ci_seq;

    ($lc eq $str) and
        return $str;

    my @lc_chars = split( //, $lc, -1 );

    foreach my $uc_char (split( //, $str, -1 )) {
        my $lc_char = shift @lc_chars;
        $ci_seq .= ($lc_char eq $uc_char) ? $uc_char : "[$uc_char$lc_char]";
    }
    
    return $ci_seq;
}

# End Helper Functions #

## End Private Functions ##

=head1 AUTHOR

S. Randall Sawyer, C<< <srandalls at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-lexicon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Lexicon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Lexicon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Lexicon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Lexicon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Lexicon>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Lexicon/>

=back


=head1 ACKNOWLEDGMENTS

This module's framework generated with L<C<module-starter>|Module::Starter>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 S. Randall Sawyer.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;

__END__

# End of Tree::Lexicon
