package XML::Liberal;

use strict;
use 5.008_001;
our $VERSION = '0.30';

use base qw( Class::Accessor );
use Carp;
use UNIVERSAL::require;
use Module::Pluggable::Fast
    name => 'remedies',
    search => [ 'XML::Liberal::Remedy' ],
    require => 1;

__PACKAGE__->remedies(); # load remedies now
__PACKAGE__->mk_accessors(qw( max_fallback guess_encodings ));

our $Debug;

sub debug {
    my $self = shift;
    $self->{debug} = shift if @_;
    $self->{debug} || $XML::Liberal::Debug;
}

sub new {
    my $class = shift;
    my $driver = shift || 'LibXML';

    my $subclass = "XML::Liberal::$driver";
       $subclass->require or die $@;

    my %param = @_;
    $param{max_fallback} = 15 unless defined $param{max_fallback};

    $subclass->new(%param);
}

sub globally_override {
    my $class = shift;
    my $driver = shift || 'LibXML';

    my $subclass = "XML::Liberal::$driver";
       $subclass->require or die $@;

    $subclass->globally_override;

    if (defined wantarray) {
        return XML::Liberal::Destructor->new(
            sub { $subclass->globally_unoverride },
        );
    }

    return;
}

sub parse_string {
    my $self = shift;
    my($xml) = @_;

  TRY:
    for (1 .. $self->max_fallback) {
        my $doc = eval { $self->{parser}->parse_string($xml) };
        return $doc if $doc;

        my $error = $self->extract_error($@, \$xml);
        for my $remedy (sort $self->remedies) {
            warn "considering $remedy\n" if $self->debug;
            $remedy->apply($self, $error, \$xml) or next;
            warn "--- remedy applied: $xml\n" if $self->debug;
            next TRY;
        }

        # We've considered all possible remedies for this error, and none
        # worked, so just throw an exception.
        Carp::croak($error->summary);
    }
}

sub parse_file {
    my($self, $file) = @_;
    open my $fh, "<", $file or croak "$file: $!";
    $self->parse_fh($fh);
}

sub parse_fh {
    my($self, $fh) = @_;
    my $xml = join '', <$fh>;
    $self->parse_string($xml);
}

our $AUTOLOAD;
sub AUTOLOAD {
    my($self, @args) = @_;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    $self->{parser}->$meth(@args);
}

sub DESTROY {
    my $self = shift;
    delete $self->{parser};
}

package XML::Liberal::Destructor;

sub new {
    my($class, $callback) = @_;
    bless { cb => $callback }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{cb}->();
}

package XML::Liberal;

1;
__END__

=head1 NAME

XML::Liberal - Super liberal XML parser that parses broken XML

=head1 SYNOPSIS

  use XML::Liberal;

  my $parser = XML::Liberal->new('LibXML');
  my $doc = $parser->parse_string($broken_xml);

  # or, override XML::LibXML->new globally
  use XML::LibXML;
  use XML::Liberal;

  XML::Liberal->globally_override('LibXML');
  my $parser = XML::LibXML->new; # isa XML::Liberal

  # revert the global overrides back
  XML::Liberal->globally_unoverride('LibXML');

  # override XML::LibXML->new globally in a lexical scope
  {
     my $destructor = XML::LibXML->globally_override('LibXML');
     my $parser = XML::LibXML->new; # isa XML::Liberal
  }

  # $destructor goes out of scope and global override doesn't take effect
  my $parser = XML::LibXML->new; # isa XML::LibXML

=head1 DESCRIPTION

XML::Liberal is a super liberal XML parser that can fix broken XML
stream and create a DOM node out of it.

B<This module is ALPHA SOFTWARE> and its API and internal class
layouts etc. are subject to change later.

=head1 METHODS

=over 4

=item new

  $parser = XML::Liberal->new('LibXML');

Creates an XML::Liberal object. Currently accepted driver is only I<LibXML>.

=item globally_override

  XML::Liberal->globally_override('LibXML');

Override XML::LibXML's new method globally, to create XML::Liberal
object instead of XML::LibXML parser.

This is considered B<so evil>, but would be useful if you have
existent software/library that uses XML::LibXML inside and change the
behaviour globally to use Liberal parser instead, with a single method
call.

For example, the following code lets XML::Atom's parser use Liberal
LibXML parser.

  use URI;
  use XML::Atom::Feed;
  use XML::Liberal;

  XML::Liberal->globally_override('LibXML');

  # XML::Atom calls XML::LibXML->new, which is aliased to Liberal now
  my $feed = XML::Atom::Feed->new(URI->new('http://example.com/atom.xml'));

If you want the original XML::LibXML->new back in business, you can
call I<globally_unoverride> method.

  XML::Liberal->globally_override('LibXML');
  # ... do something
  XML::Liberal->globally_unoverride('LibXML');

Or, you can hold the destructor object in a scalar variable and make
the global override take effect only in a lexical scope:

  {
    my $destructor = XML::Liberal->globally_override('LibXML');
    # ... do something
  }

  # now XML::LibXML::new is back as normal

=back

=head1 BUGS

This module tries to fix the XML data in various ways, some of which
might alter your XML content, especially bytes written in CDATA.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Aaron Crane

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML>

=cut
