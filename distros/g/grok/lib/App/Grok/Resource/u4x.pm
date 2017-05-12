package App::Grok::Resource::u4x;
BEGIN {
  $App::Grok::Resource::u4x::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::Resource::u4x::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';

use base qw(Exporter);
our @EXPORT_OK = qw(u4x_index u4x_fetch u4x_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %index;

sub u4x_fetch {
    my ($topic) = @_;
    _build_index() if !%index;

    return $index{$topic} if defined $index{$topic};
    return;
}

sub u4x_index {
    _build_index() if !%index;
    return keys %index;
}

sub u4x_locate {
    my ($topic) = @_;
    _build_index() if !%index;
    return __FILE__ if $index{$topic};
    return;
}

sub _build_index {
    my $pod = do { local $/ = undef; scalar <DATA> };
    my @entries = split /[\s\n]*(?==head3)/m, $pod;

    for my $entry (@entries) {
        my ($name) = $entry =~ /=head3\s*(.*)$/m;
        $index{$name} = $entry;
    }
    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok::Resource::u4x - u4x resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::u4x qw<:ALL>;

 # a list of all terms
 my @index = u4x_index();

 # documentation for a single term 
 my $pod = u4x_fetch('infix:<+>');

=head1 DESCRIPTION

This resource looks maintains an index of syntax items that can be looked up.
See L<http://svn.pugscode.org/pugs/docs/u4x/README>.

=head1 FUNCTIONS

=head2 C<u4x_index>

Takes no arguments. Lists all syntax items.

=head2 C<u4x_fetch>

Takes an syntax item as an argument. Returns the documentation for it.

=head2 C<u4x_locate>

Takes a syntax item as an argument. Returns the file where it was found.

=cut

__DATA__
=head3 infix:<+>

Adds two numbers together. If either of the things being added is not
a C<Num>, it will be converted to one before the addition. The result
will be of the narrowest type possible.

=head3 prefix:<+>

Converts an object into a C<Num>. In the case of C<List> and C<Map>, the
numeric value is the number of elements and C<Pair>s, respectively. Note
that it's commas and not parentheses alone do not create a C<List>, otherwise
the following might be a surprise:

 say +(4,5,6);  # 3
 say +(4);      # 4

The same surprise does not happen for arrays, though, since they convey
list context:

 my @a = 4;
 say +@a;       # 1

=head3 twigil:<+>

This twigil is deprecated. Use the C<*> twigil instead.

=head3 regex~quantifier:<+>

Means 'one or more of the previous atom'. In other words, it means the
same as C<< <{1..*}> >>.

=head3 regex~assertion:sym<+>

Used before and between character classes inside C<< <> >> assertions to 
indicate the characters included in the match. Thus

 <+digit-[02468]+[4]>

will match all odd digits and the digit 4. 

The plus at the start of an assertion is a no-op and can be left out.

=head3 version~postfix:<+>

The string form of a version recognizes the C<*> wildcard in place of any
position.  It also recognizes a trailing C<+>, so

    :ver<6.2.3+>

is short for

    :ver(v6.2.3 .. v6.2.*)

And saying

    :ver<6.2.0+>

specifically rules out any prereleases.

