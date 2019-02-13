package Test::TempFile;
use strict;
use warnings;

our $VERSION = "0.92";

use Carp;
use Path::Tiny ();
use YAML::Tiny ();
use JSON::MaybeXS ();
use Test::Builder::Module;
use Test::More ();

my $Builder = Test::Builder::Module->builder;

=head1 NAME

 Test::TempFile - compact way to use tempfiles in unit tests

=head1 SYNOPSIS

 # Under Test::More

 my $t = Test::TempFile->new([content]);
 
 download_file($url, $t->path);
 $t->exists_ok
    ->content_is("Expected content", 'test message')
    ->json_is({ foo => 'bar' }, 'expect file to be JSON' );

 my $t = Test::TempFile->to_json({ a => 1 });
 run_some_script( config_file => $t->path );

=head1 DESCRIPTION

This is a simple module for creating temporarily files with optional initial
content, then running various tests on the state of the tempfile.

It is intended for testing code that uses files as input or output.

B<UTF-8 is assumed everywhere>. In the future a binary/raw subclass of this
module may be released.

=head1 CONSTRUCTORS

=over

=item new ( [content] )

Create a new tempfile. Upon creation the file will exist but be empty. When
this object is destroyed, the file will be deleted if it still exists.

C<content> may be a string or an arrayref of strings (which will be joined
using the empty string). The tempfile will be populated with this content.

=cut

sub new {
    my ($class, $content) = @_;

    my $pt = Path::Tiny->tempfile;
    my $self = { pt => $pt };
    bless $self, $class;

    if (defined $content) {
        $self->set_content($content);
    }

    return $self;
}

=item to_json ( data )

Create a new tempfile, with content set to the JSON representation of C<data>.

=cut

sub to_json {
    my ($class, $data) = @_;
    my $json = JSON::MaybeXS->new(utf8 => 1)->encode($data);
    return $class->new($json);
}

=item to_yaml ( data )

Create a new tempfile, with content set to the YAML representation of C<data>.

=cut

sub to_yaml {
    my ($class, $data) = @_;
    my $yaml = YAML::Tiny->new($data)->write_string;
    return $class->new($yaml);
}

=back

=head1 INSTANCE METHODS

=over

=item path

Returns the string path to this tempfile.

=cut

sub path {
    my ($self) = @_;
    return "$self->{pt}";
}

=item absolute

As C<path> but guaranteed to be absolute.

=cut

sub absolute {
    my ($self) = @_;
    return $self->{pt}->absolute;
}

=item content

Returns the content of this tempfile as a string.

=cut

sub content {
    my ($self) = @_;
    return $self->{pt}->slurp_utf8;
}

=item set_content ( content )

Sets the content of this tempfile. C<content> may be a string, or an
arrayref of strings (which are passed to C<join('', ...)>.

Returns the L<Test::TempFile> object to allow chaining.

=cut

sub set_content {
    my ($self, $content) = @_;
    $self->{pt}->spew_utf8($content);
    return $self;
}

=item append_content ( content )

Appends C<content> to the end of the tempfile. C<content> must be a
string.

Returns the L<Test::TempFile> object to allow chaining.

=cut

sub append_content {
    my ($self, $content) = @_;
    $self->{pt}->append_utf8($content);
    return $self;
}

=item exists

Returns whether or not the tempfile currently exists.

=cut

sub exists {
    my ($self) = @_;
    return $self->{pt}->exists;
}

=item empty

Returns true if the file is non-existent or existent but empty.

=cut

sub empty {
    my ($self) = @_;
    return !$self->exists || -z $self->{pt}->path;
}

=item filehandle ( [mode] )

Returns a filehandle to the tempfile. The default C<mode> is '>'
(read-only) but others may be used ('<', '>>' etc.)

=cut

sub filehandle {
    my ($self, $mode) = @_;
    $mode = '>' if !defined $mode;
    return $self->{pt}->filehandle($mode, ':raw:encoding(UTF-8)');
}

=item unlink

Unlinks (deletes) the tempfile if it exists.

=cut

sub unlink {
    my ($self) = @_;
    return $self->{pt}->remove;
}

=item from_json

Interprets the tempfile contents as JSON and returned the decoded
Perl data.

=cut

sub from_json {
    my ($self) = @_;
    return JSON::MaybeXS->new(utf8 => 1)->decode($self->content);
}

=item from_yaml

Interprets the tempfile contents as JSON and returned the decoded
Perl data.

=cut

sub from_yaml {
    my ($self) = @_;
    return YAML::Tiny->read($self->path)->[0];
}

=back

=head1 TEST METHODS

These methods can be used inside unit tests. They always return the
L<Test::TempFile> object itself, so multiple tests can be chained.

=over

=item exists_ok ( [message] )

Asserts that the tempfile exists.

=cut

sub exists_ok {
    my ($self, $message) = @_;
    $Builder->ok($self->exists, $message);
    return $self;
}

=item not_exists_ok ( [message] )

Asserts that the tempfile does not exist.

=cut

sub not_exists_ok {
    my ($self, $message) = @_;
    $Builder->ok(!$self->exists, $message);
    return $self;
}

=item empty_ok ( [message] )

Asserts that the tempfile is empty.

=cut

sub empty_ok {
    my ($self, $message) = @_;
    $Builder->ok($self->empty, $message);
    return $self;
}

=item not_empty_ok ( [message] )

Asserts that the tempfile is not empty.

=cut

sub not_empty_ok {
    my ($self, $message) = @_;
    $Builder->ok(!$self->empty, $message);
    return $self;
}

=item content_is ( expected [, message] )

Asserts that the tempfile contents are equal to C<expected>.

=cut

sub content_is {
    my ($self, $expected, $message) = @_;
    $Builder->is_eq($self->content, $expected, $message);
    return $self;
}

=item content_like ( expected [, message] )

Asserts that the tempfile contents match the regex C<expected>.

=cut

sub content_like {
    my ($self, $expected, $message) = @_;
    $Builder->like($self->content, $expected, $message);
    return $self;
}

=item json_is ( expected [, message] )

Asserts that the tempfile contains JSON content equivalent to the Perl data in
C<expected>.

=cut

sub json_is {
    my ($self, $expected, $message) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is_deeply($self->from_json, $expected, $message);

    return $self;
}

=item yaml_is ( expected [, message] )

Asserts that the tempfile contains YAML content equivalent to the Perl data in
C<expected>.

=cut

sub yaml_is {
    my ($self, $expected, $message) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is_deeply($self->from_yaml, $expected, $message);

    return $self;
}

=item assert ( coderef, message )

Calls C<coderef> with C<$_> set to this object. Asserts that the C<coderef>
returns true. Returns the original object.

Is useful when chaining multiple tests together:

 $t->not_empty_ok
   ->assert(sub { $_->content =~ /foo/ })
   ->assert(sub { $_->content !~ /bar/ });

=cut

sub assert {
    my ($self, $coderef, $message) = @_;

    $coderef
        or croak "missing coderef";

    ref $coderef eq 'CODE'
        or croak "first argument to assert() must be a code reference";

    local $_ = $self;
    $Builder->ok( $coderef->(), $message );

    return $self;
}

=back

=cut

1;
