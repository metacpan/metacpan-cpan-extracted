package XML::XMetaL::Factory;

use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);
use Switch;
use Win32::OLE;

use constant XMETAL_NO_SAVE => 2;

sub new {
    my ($class) = @_;
    my $self;
    eval {
        $self = bless {
            _xmetal    => undef,
        }, ref($class) || $class;
        lock_keys(%$self, keys %$self);
        $self->_create_xmetal();
    };
    croak $@ if $@;
    return $self;
}

sub get_xmetal_path {
    my ($self) = @_;
    my $xmetal = $self->_get_xmetal();
    my $path = $xmetal->{Path};
    return $path;
}
sub _get_xmetal {$_[0]{_xmetal}}
sub _set_xmetal {$_[0]{_xmetal} = $_[1]}

sub _get_documents {
    my ($self) = @_;
    my $xmetal = $self->_get_xmetal();
    return $xmetal->{Documents};
}

sub create_xmetal {
    my ($self, @documents) = @_;
    eval {
        my $documents = $self->_get_documents();
        my $document;
        foreach my $document (@documents) {
            chomp $document;
            if ( $document =~ /^<\?xml/i) {
                $document = $self->_create_document_from_string($document);
            } elsif (-f $document) {
                $document = $self->_create_document_from_path($document);
            };
            die "Could not open document" unless ref($document);
        }
    };
    croak $@ if $@;
    return $self->_get_xmetal();
}

sub _create_document_from_string {
    my ($self, $document_string) = @_;
    my ($document);
    eval {
        my $documents = $self->_get_documents();
        $document = $documents->OpenString($document_string);
        $self->_die_on_ole_error();
    };
    croak $@ if $@;
    return $document;
}

sub _create_document_from_path {
    my ($self, $document_path) = @_;
    my ($document);
    eval {
        my $documents = $self->_get_documents();
        $document = $documents->Open($document_path, -1);
        $self->_die_on_ole_error();
    };
    croak $@ if $@;
    return $document;    
}

sub tear_down {
    my ($self) = @_;
    croak "Tear down method is not implemented yet."
    #$self->_destroy_xmetal();
}

sub _create_xmetal {
    my ($self) = @_;
    eval {
        my $xmetal = Win32::OLE->new('XMetaL.Application', sub {$self->_destroy_xmetal()});
        $self->_die_on_ole_error();
        do {sleep 1} until $xmetal->InitComplete();
        $self->_set_xmetal($xmetal);
    };
    die $@ if $@;
}

sub _destroy_xmetal {
    my ($self) = @_;
    my $xmetal = $self->_get_xmetal();
    eval {
        undef $self->{_xmetal};
        $xmetal->Quit(&XMETAL_NO_SAVE);
        $self->_die_on_ole_error();
    };
    croak $@ if $@;
}

sub _die_on_ole_error {
    my ($self) = @_;
    my $error = "".Win32::OLE->LastError();
    die $error if $error;
}

1;
__END__

=head1 NAME

XML::XMetaL::Factory - XMetaL factory class

=head1 SYNOPSIS

 use XML::XMetaL::Factory;
 my $factory = XML::XMetaL::Factory->new();
 my $xml_doc_1 = '...';# A serialized XML document
 my $xml_doc_2 = 'd:\documents\xml\my_doc.xml';# Path to XML file
 my $xmetal = $factory->create_xmetal($xml_doc_1, $xml_doc_2);


=head1 DESCRIPTION

C<XML::XMetaL::Factory> is a factory class for creating XMetaL instances.

C<XML::XMetaL::Factory> creates XMetaL instances, ensures that processing
does not continue until initialization is complete, and provides XMetaL
with a basic lean-up routine that will be implemented automatically when
XMetaL is closed.

C<XML::XMetaL::Factory> is meant for use by external scripts that need to
instantiate an XMetaL application object. The most obvious use is by
test scripts.

Using C<XML::XMetaL::Factory> it is possible to write unit and function
tests for XMetaL customization packages. This is important for more
reasons than good programming style. Coupled with the capability
to do object oriented development, it becomes possible to develop XMetaL
applications using agile development methodologies such as
Extreme Programming. You can find out more about Extreme Programming
at http://www.xprogramming.com.

=head1 Public methods

=head2 Constructor and initialization

 my $factory = XML::XMetaL::Factory->new()

The constructor takes no arguments. It returns a factory object
that can be used to create XMetaL application objects.

=head2 create_xmetal

 my $xmetal_application = $factory->create_xmetal(@document_list);

The C<create_xmetal> method takes a list of scalar variables as arguments.
An element in the list must either contain an XML document as a string,
or a file path.

There is currently no support for filehandles, URLs, filepaths, or DOM
document objects of any kind.

The C<create_xmetal> method returns an XMetaL Application object.

=head1 Private Methods

None you want to mess with. The implementation is likely to change in
future versions.


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

Currently, the XMetaL application object is created when the factory
object is created. The C<create_xmetal> method merely opens documents
and returns the already existing application object.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.

=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
