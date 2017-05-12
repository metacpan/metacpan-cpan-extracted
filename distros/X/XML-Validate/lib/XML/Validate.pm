# Factory class providing a common interface to different XML validators

package XML::Validate;

# Using XML::Validate::Base here is cheating somewhat. We do this because we're
# dynamically loading the validation module, but we still want to be able to
# use Log::Trace's deep import feature. Any better ideas welcomed.

use strict;
use XML::Validate::Base;
use vars qw($VERSION);

$VERSION = sprintf"%d.%03d", q$Revision: 1.25 $ =~ /: (\d+)\.(\d+)/;

# Xerces is preferred over MSXML as we've found in practice that MSXML4's schema validation occasionally
# lets through invalid documents which Xerces catches.
# At the time of writing, LibXML didn't have schema validation support.
my $DEFAULT_PRIORITISED_LIST = [ qw( Xerces MSXML LibXML ) ];

sub new {
	my $class = shift;
	my %args = @_;
	
	DUMP("Arguments", %args);
	
	my $self = {
		backend => undef,
	};
	
	bless($self,$class);
	
	if (!$args{Type}) {
		die "Required argument Type missing\n";
	}
	
	if ($args{Type} !~ /^\w+$/) {
		die "Validator type name '$args{Type}' should only contain word characters.\n";
	}
	
	my $backend_class;
	if ($args{Type} eq 'BestAvailable') {
		my $list = $args{PrioritisedList} || $DEFAULT_PRIORITISED_LIST;
		my $type = $self->_best_available($list) or die sprintf("None of the listed backends (%s) are available\n",join(", ",@$list));
		$backend_class = "XML::Validate::" . $type;
	} else {
		$backend_class = "XML::Validate::" . $args{Type};
	}
	eval "use $backend_class";
	die "Validator $backend_class not loadable: $@" if $@;

	my $options = $args{Options};
	$self->{backend} = new $backend_class(%{$options});
	
	return $self;
}

sub validate {
	my $self = shift;
	$self->{backend}->validate(@_);
}

sub last_error {
	my $self = shift;
	$self->{backend}->last_error(@_);
}

sub type {
	my $self = shift;
	my $class = ref($self->{backend});
	$class =~ m/XML::Validate::(.*)/;
	return $1;
}

sub version {
	my $self = shift;
	return unless $self->{backend}->can('version');
	return $self->{backend}->version;
}

sub _best_available {
	my $self = shift;
	my ($list) = @_;
	foreach my $backend (@{$list}) {
		TRACE("Attempting to load $backend");
		eval "use XML::Validate::$backend";
		next if $@;
		TRACE("Loading succeeded. Returning $backend");
		return $backend;
	}
	return;
}

sub TRACE {}
sub DUMP {}

1;

__END__

=head1 NAME

XML::Validate - an XML validator factory

=head1 SYNOPSIS

  my $validator = new XML::Validate(Type => 'LibXML');
  
  if ($validator->validate($xml)) {
    print "Document is valid\n";
  } else {
    print "Document is invalid\n";
    my $message = $validator->last_error()->{message};
    my $line = $validator->last_error()->{line};
    my $column = $validator->last_error()->{column};
    print "Error: $message at line $line, column $column\n";
  }

=head1 DESCRIPTION

XML::Validate is a generic interface to different XML validation backends.
For a list of backend included with this distribution see the README.

If you want to write your own backends, the easiest way is probably to subclass
XML::Validate::Base. Look at the existing backends for examples.

=head1 METHODS

=over

=item new(Type => $type, Options => \%options)

Returns a new XML::Validate parser object of type $type. For available types see README or use 'BestAvailable' (see
L<BEST AVAILABLE>).

The optional argument Options can be used to supply a set of key-value pairs to
the backend parser. See the documentation for individual backends for details
of these options.

=item validate($xml_string)

Attempts a validating parse of the XML document $xml_string and returns a true
value on success, or undef otherwise. If the parse fails, the error can be
inspected using C<last_error>.

Note that documents which don't specify a DTD or schema will be treated as
valid.

For DOM-based parsers, the DOM may be accessed by instantiating the backend module directly and calling the C<last_dom> method - consult the documentation of the specific backend modules.
Note that this isn't formally part of the XML::Validate interface as non-DOM-based validators may added at some point.

=item last_error()

Returns the error from the last validate call. This is a hash ref with the
following fields:

=over

=item *

message

=item *

line

=item *

column

=back

Note that the error gets cleared at the beginning of each C<validate> call.

=item type()

Returns the type of backend being used.

=item version()

Returns the version of the backend

=back

=head1 ERROR REPORTING

When a call to validate fails to parse the document, the error may be retrieved using last_error.

On errors not related to the XML parsing methods will throw exceptions.
Wrap calls with eval to catch them.

=head1 BEST AVAILABLE

The BestAvailable backend type will check which backends are available and give
you the "best" of those. For the default order of preference see the README with this distribution, but this can be changed with the option PrioritisedList.

If Xerces and LibXML are available the following code will give you a LibXML backend:

  my $validator = new XML::Validate(
      Type => 'BestAvailable',
      Options => { PrioritisedList => [ qw( MSXML LibXML Xerces ) ] },
  );

=head1 KNOWN ISSUES

There is a bug in versions 1.57 and 1.58 of XML::LibXML that causes an issue
related to DTD loading. When a base parameter is used in conjunction with the
load_ext_dtd method the base parameter is ignored and the current directory
is used as the base parameter. In other words, when validating XML with LibXML
any base parameter option will be ignored, which may result in unexpected DTD
loading errors. This was reported as bug on November 30th 2005 and the bug
report can be viewed here http://rt.cpan.org/Public/Bug/Display.html?id=16213

=head1 VERSION

$Revision: 1.25 $ on $Date: 2006/04/19 10:16:19 $ by $Author: mattheww $

=head1 AUTHOR

Nathan Carr, Colin Robertson

E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
