package XML::Conf;

use XML::Simple;
use strict;
use warnings;
use vars qw($VERSION @ISA);
use Tie::DeepTied;
use Tie::Hash;
use Carp;

$VERSION = 0.07;

sub new {
    my ($class, $filename, %opts) = @_;
    my $xml;
    my $fn;

    if (ref($filename) eq 'SCALAR') { #Internal use (TIEHASH)
        $xml = $$filename;
    } elsif ($filename =~ m/^\s*\<.*\>\s*$/s) { #internal use (TIEHASH)
        $xml = $filename;
    } else { #internal use (ReadConfig)
        $filename = "./$filename" if ($filename !~ /^[\/\.]/ && -e "./$filename");
        open(I, $filename) || croak "Could not open $filename: $!";
        $xml = join("", <I>);
        close(I);
        $fn = $filename;
    }
    my $hash = XML::Simple::XMLin($xml) || return undef;
    my $case = $opts{'case'}?$opts{'case'}:'_dummysub';
    #my $case = $opts{'case'};
    $hash = &_trans($hash, eval "sub { $case(\$_);} ") if ($case);
    #$hash = &_trans($hash, $case) if ($case);
    my $self = {'data' => $hash, 'case' => $case, 'fn' => $fn};
    my $sig = $opts{'sig'};
    if ($sig) {
        $SIG{$sig} = sub { $self->ReadConfig; };
    }
    bless $self, $class;
}

sub _dummysub {
	my $val = shift; 
}

sub _trans {
    my ($tree, $case) = @_;
    return $tree unless (UNIVERSAL::isa($tree, 'HASH'));
    my %hash;
    no strict 'refs';
    foreach (keys %$tree) {
        $hash{ &$case($_) } = &_trans($tree->{$_}, $case);
    }
    use strict 'refs';
    \%hash;
}

sub _val {
    my $self = shift;
    my $data = $self->{'data'};

    foreach (@_) {
        $data = $data->{$_};
    }
    wantarray ? split("\n", $data) : $data;
}

sub _setval {
    my $self = shift;
    my $data = \$self->{'data'};
    while (@_ > 1) {
        $data = \($$data->{shift()});
    }
    $$data = shift;
}

sub _newval {
    my $self = shift;
    $self->_setval(@_);
}

sub _delval {
    my $self = shift;
    my $data = $self->{'data'};
    while (@_ > 1) {
        $data = $data->{shift()};
    }
    delete $data->{shift()};
}

sub ReadConfig {
    my $self = shift;
    my $fn = $self->{'fn'};
    return undef unless ($fn);
    my $new = &new(__PACKAGE__, $fn, 'case' => $self->{'case'});
    %$self = %$new;
    1;
}

sub Sections {
    my $self = shift;
    $self->Parameters(@_);
}

sub Parameters {
    my $self = shift;
    my $val = $self->_val(@_);
    my $case = $self->{'case'};
    no strict 'refs';
    map { &$case($_); } keys %$val;
    use strict 'refs';
}

sub RewriteConfig {
    my $self = shift;
    my $fn = $self->{'fn'};
    croak "No filename" unless ($fn);
    $self->WriteConfig($fn);
}

sub WriteConfig {
    my ($self, $name) = @_;
    my $xml = XMLout($self->{'data'}, xmldecl => 1);
    open(O, ">$name") || croak "Can't rewrite $name: $!";
    print O $xml;
    close(O);
}

sub TIEHASH {
    my $class = shift;
    $class->new(@_);
}

sub FETCH {
    my ($self, $key) = @_;
    my $val = $self->_val($key);
    if (UNIVERSAL::isa($val, 'HASH') && !tied(%$val)) {
        my %h = %$val;
        tie %$val, 'Tie::StdHash', $self, $key;
        %$val = %h;
        tie %$val, 'Tie::DeepTied', $self, $key;
    }
    $val;
}

sub STORE {
    my ($self, $key, $val) = @_;
    $self->_setval($key, $val);
}

sub DELETE {
    my ($self, $key) = @_;
    $self->_delval($key);
}

sub CLEAR {
    my $self = shift;
    $self->{'data'} = {};
}

sub EXISTS {
    my ($self, $key) = @_;
    exists $self->{'data'}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    keys %{$self->{'data'}};
    each %{$self->{'data'}};
}

sub NEXTKEY {
    my $self = shift;
    each %{$self->{'data'}};
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/XML-Conf.svg)](http://badge.fury.io/pl/XML-Conf)
[![Build Status](https://travis-ci.org/jonasbn/XML-Conf.svg?branch=master)](https://travis-ci.org/jonasbn/XML-Conf)
[![Coverage Status](https://coveralls.io/repos/jonasbn/XML-Conf/badge.png)](https://coveralls.io/r/jonasbn/XML-Conf)

=end markdown

=head1 NAME

XML::Conf - a simple configuration module based on XML

=cut

=head1 SYNOPSIS

Here follows some examples as the tests are done.

use XML::Conf;

my $c = XML::Conf->new($filename);

$w = $c->FIRSTKEY();

$v = $c->NEXTKEY();

$c->EXISTS($v);

$c->DELETE($v);

$c->CLEAR();

=cut

=head1 DESCRIPTION

This is the description of the class, currently it only containg only
the descriptions of the private and public methods and attributes.

=head2 Attributes

=over 4

=item *

data

The attribute holding the reference to the actual configuration
structure, the top-node so to speak.

=item * 

case

This is the attribute for holding the case parameter (see named
parameteres to the constructor below).

=item *

fn (filename), the attribute holding the filename of current
configuration, no matter whether it exists or not.

=back

=head2 Public Methods

=over 4

=item *

new

This is the constructor of the class. It takes a B<filename> as a
parameter, and additionally some named parameters:

=over 4

=item *

case

The argument given to case is used during the construction of the
objects by the B<_trans> function, to traverse and utilize on all
elements encountered during the traversal through the configuration
tree.

=item *

sig

This is a signal flag indicating whether a configuration should be read
from file (See B<ReadConfig>). If set a newly blessed object will be
initialized by B<ReadConfig>.

...missing docs...

=back

=back

Apart from the public interface of the B<new> method, the method is
also used internally from some of the other methods, the methods usings
the constructor are described below.

=over 4

=item *

Sections

This method calls B<Parameters> and returns all the sections in the object.

...missing docs...

=item *

Parameters

...missing docs...

=item *

ReadConfig

This method reads a file pointed to by the B<fn> attribute and returns
a true value upon successful read and initialization (which overides
self) by using the B<new> method (constructor).

=item *

WriteConfig

The WriteConfig method can be used to write the contents of the
configuration object to a file. This method takes a filename as
argument. The B<WriteConfig> method is used internally by the
B<RewriteConfig> method.

=item *

RewriteConfig

The method is used to overwrite a serialized configuration object to a
file. It writes to the contents of the B<fn> attribute and used the
B<WriteConfig> method (see above).

=item *

TIEHASH

The B<TIEHASH> is just a wrapper for the B<new> method (the constructor).

=item *

FETCH

...missing docs...

=item *

STORE

The B<STORE> method takes 2 parameters, a key and a value. The value is
stored under the key. The method uses the private method B<_setval>.

=item *

DELETE

Deletes/removes the element specified as the argument, uses the private
method B<_delval>.

=item *

CLEAR

Empties/flushes the configuration object. Works with values underneath
the B<data> attribute.

=item *

EXISTS

Returns true if the element specified as a the parameter exists, else
it returns false. Works with values underneath the B<data> attribute.

=item *

FIRSTKEY

Retrieves the first element in the configuration object (tied hash).
Works with values underneath the B<data> attribute.

=item *

NEXTKEY

Retrieves the next element in the configuration object (tied hash), the
first element if none have been retrieved. Works with values underneath
the B<data> attribute.

=back

=head2 Private Methods

=over 4

=item *

_val

Returns the complete config object as a hashref in scalar context.

In list context the method returns a hash.

=item *

_setval

Sets a value in the structure. The method can be given a list of
parameters, the longer the list, the deeper the structure. The
B<_setval> method works from the B<data> attribute and below.

=item *

_newval

This method is just an 'alias' of the B<_setval> method. It is
currently now used anywhere in the class.

=item *

_delval

This method does the opposite of B<_setval>, meaning given a list it
can remove values at all levels of the configuration tree. The
B<_setval> method works from the B<data> attribute and below.

=back

=head2 Private Functions

This paragraf contains functions which are not related to the class in
public use, these functions are used during construction of the object.

=over 4

=item *

_trans

The B<_trans> function takes the B<case> argument given to the constructor
and traverses the complete configuration tree and used the sub provided
as argument on the elements encountered.

=back

=cut

=head1 TODO

=over 4

=item *

Write documentation, figure out general uses etc.

=item *

_val (list and scalar context), examples and clarification.

=item *

sig parameter to B<new>, examples and clarification.

=item *

case parameter to B<new>, examples and clarification.

=item *

Make regression tests to find minimum versions of Tie::Hash and
Tie::DeepTied

=back

=head1 COPYRIGHT

XML::Conf is free software and is released under the Artistic License.
See <http://www.perl.com/language/misc/Artistic.html> for details.

=head1 AUTHOR

This is originally the work of Ariel Brosh, a member of Israel.pm and
author of several contributions to CPAN. He has unfortunately passed
away and have left behind several Perl modules where this is just one
of them.

I volunteered to contribute further to the development of the module,
but it is still kept under the name of Ariel Brosh - the original
author.

Jonas B. Nielsen <jonasbn@cpan.org>

=cut

