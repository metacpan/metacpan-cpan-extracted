package Test::DocClaims::Line;

# Copyright (c) Scott E. Lee

use 5.008009;
use strict;
use warnings;

# Keys in the blessed hash
#   {text}     text of the line
#   {path}     path of the file
#   {lnum}     line number of the line
#   {...}      other attributes

use overload
    '""'   => 'text',
    'bool' => sub { 1 },
    ;

=head1 NAME

Test::DocClaims::Line - Represent one line from a text file

=head1 SYNOPSIS

  use Test::DocClaims::Line;
  my %hash = ( text => 'package Foo;', lnum => 1 );
  $hash{file} = { path => 'foo/bar.pm', has_pod => 1 };
  $line = Test::DocClaims::Line->new(%hash);
  say $line->lnum();         # 1
  say $line->path();         # foo/bar.pm
  say $line->text();         # package Foo;

=head1 DESCRIPTION

This object represents a single line from a source file, documentation file
or test suite file.
It knows what file it came from and the line number in that file.
It also records other attributes.

=head1 CONSTRUCTOR

=head2 new I<HASH>

This method creates a new object from the I<HASH>.
The I<HASH> must have as a minimum the following keys:

  file    hash of information about the file containing this line
  text    the text of the line
  lnum    the line number in the file

The hash in the "file" key must have as a minimum the following keys:

  path     path of the file
  has_pod  true if this file supports POD (*.pm vs. *.md)

If the above minimum keys are not present the method will die.
Additional keys may be present in either hash.

=cut

sub new {
    my $class = shift;
    my %attr  = @_;
    my $self  = bless \%attr, ref($class) || $class;
    foreach my $k (qw< file text lnum >) {
        die "missing $k key in " . __PACKAGE__ . "->new"
            unless exists $self->{$k};
    }
    die "'file' key in " . __PACKAGE__ . "->new is not hash"
        unless exists $self->{file} && ref $self->{file} eq "HASH";
    foreach my $k (qw< path has_pod >) {
        die "missing $k key in " . __PACKAGE__ . "->new file hash"
            unless exists $self->{file}{$k};
    }
    return $self;
}

=head1 ACCESSORS

The following accessors simply return a value from the constructor.
The meaning of all such values is determined by the caller of the
constructor.
No logic is present to calculate or validate these values.
If the requested value was not passed to the constructor then the returned
value will be undef.

=head2 path

Return the path of the file.

=head2 has_pod

Return true if the file supports POD, false otherwise.

=head2 lnum

Return the line number in the file that this line came from.

=head2 text

Return the text of the line.

=head2 is_doc

Return true if this line is a line of documentation (e.g., a POD line) or
false if not (e.g., code).

=head2 code

Return true if this line is from a DC_CODE section, false otherwise.

=head2 todo

Return true if this line is a "=for DC_TODO" command paragraph.

=cut

sub path    { $_[0]->{file}{path} }
sub has_pod { $_[0]->{file}{has_pod} }

sub lnum   { $_[0]->{lnum} }
sub text   { $_[0]->{text} }
sub is_doc { $_[0]->{is_doc} }
sub code   { $_[0]->{code} }
sub todo   { $_[0]->{todo} }

=head1 COPYRIGHT

Copyright (c) Scott E. Lee

=cut

1;

