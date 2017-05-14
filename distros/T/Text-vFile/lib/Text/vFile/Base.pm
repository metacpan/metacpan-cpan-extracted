package Text::vFile::Base;

use strict;

=head1 NAME

Text::vFile::Base - Base class for most of the functional classes based on the vCard/vCalendar etc spec.
Most of the hard work in breaking apart lines of data happens using methods in here.

=head1 SYNOPSIS

    package Text::vFoo;

    use Text::vFile::Base;
    use vars qw(@ISA);
    push @ISA, qw(Text::vCard::Base);

    # Tell vFile that BEGIN:VFOO line creates one of these objects
    $Text::vFile::classMap{'VCARD'}=__PACKAGE__;
   
    # Then you will need to create a varHandler - although there are defaults to try
    # and get you going.
    #
    # As well you will need to define more exotic, type specific loaders
    #
    # And finally accessors are your responsibility

=head1 END USAGE

To tell your users how to use this module:

    use Text::vFoo;
    my $loader = Text::vFoo->loader( source => "youppi.vfoo" );

    while (my $vfoo = $loader->next) {
        $vfoo->all_night;
    }

    # or even sexier
    
    while (my $vfoo = <$loader> ) {
        $vfoo->all_night;
    }

It may sound silly, but it should be mentioned. Just becase the user
says:

    my $loader = Text::vFoo->loader( );

Does not mean there will be any complaints if they try to load non-vfoo data.
If the source has vcards in it - that's what they're going to get.

=cut


use Carp; $SIG{__DIE__} = \&Carp::confess;
use Data::Dumper; $Data::Dumper::Indent=1; $Data::Dumper::Sortkeys=1;

use lib qw(lib);
use Text::vFile;

my $typeSequence=1;

sub _nextSequence {
    return $typeSequence++;
}

=head1 CONVENIENCE METHODS

=over 4

=item @objects = $class->load( key => value )

Calls the Text::vFile load routine. Should slurp all the objects
and return as an array/array ref.

=cut

sub load {
    shift;
    Text::vFile->load(@_);
}

=item $loader = $class->loader( key => value )

Returns an object which can return back objects one at a time. Nice
if you want to iterate through a stack of vcards at your leisure.

=cut

sub loader {
    shift;
    return Text::vFile->new(@_);
}

=item $object = class->new

Make a new object object that represents this vFile data being parsed.

=cut

sub new {

	my $class = ref($_[0]) ? ref(shift) : shift;
    my $opts = ref($_[0]) ? $_[0] : {@_};

	my $self = bless {}, $class;

    map { $self->$_( $opts->{$_} ) } keys %$opts;

	return $self;

}

=back

=head1 DATA HANDLERS

=over 4

=item varHandler

Returns a hash ref mapping the item label to a handler name. Ie:

   {
        'FN'          => 'singleText',
        'NICKNAME'    => 'multipleText',
        'PHOTO'       => 'singleBinary',
        'BDAY'        => 'singleText',
        'ADR'         => 'ADR',           # Not really necessary
    };

By default if there is no explicit handler then the vFile loader will

   - is there a method called  "load_NAME"?
   - test does the item have type attributes or not
       - yes?   singleTextTyped
       - no?    singleText
   

=cut
 
sub varHandler {
    return {};
}

=item typeDefault

Additional information where handlers require type info. Such as ADR - is this
a home, postal, or whatever? If not supplied the RFC specifies what types they should
default to.

     from vCard:

     {
        'ADR'     => [ qw(intl postal parcel work) ],
        'LABEL'   => [ qw(intl postal parcel work) ],
        'TEL'     => [ qw(voice) ],
        'EMAIL'   => [ qw(internet) ],
    };

=cut

sub typeDefault {
    return {};
}

=item load_singleText

Loads a single text item with no processing other than unescape text

=cut

sub load_singleText { 

	my $val=$_[3];
	$val=~s/\\([\n,])/$1/gs;
    # $val=~s/\\n/\n/gs;
	$_[0]->{$_[1]}{'value'}=$val;
	$_[0]->{$_[1]}{'attr'}=$_[2] if $_[2] && ref($_[2]) eq "HASH" && keys %{$_[2]};

    return $_[0]->{$_[1]};

}

=item load_singleDate

Loads a date creating a DateTime::Format::ICal object. Thanks Dave!

=cut

sub load_singleDate { 

	my $val=$_[3];
    unless (%DateTime::Format::ICal::) {
        eval "use DateTime::Format::ICal";
        warn "Cannot create date/time objects: $@\n" and return if $@;
    }

    eval {
	    $_[0]->{$_[1]}{'value'}=DateTime::Format::ICal->parse_datetime( iso8601 => $val );
    }; if ($@) {
        warn "$val; $@\n";
    }

	$_[0]->{$_[1]}{'attr'}=$_[2] if $_[2] && ref($_[2]) eq "HASH" && keys %{$_[2]};

    return $_[0]->{$_[1]};

}

=item load_singleDuration

Loads a data duration using DateTime::Format::ICal.

=cut

sub load_singleDuration { 

	my $val=$_[3];

    unless (%DateTime::Format::ICal::) {
        eval "use DateTime::Format::ICal";
        warn "Cannot create date/time objects: $@\n" and return if $@;
    }

    eval {
	    $_[0]->{$_[1]}{'value'}=DateTime::Format::ICal->parse_duration( $val );
    }; if ($@) {
        warn "$val; $@\n";
    }

	$_[0]->{$_[1]}{'attr'}=$_[2] if $_[2] && ref($_[2]) eq "HASH" && keys %{$_[2]};

    return $_[0]->{$_[1]};

}

=item load_multipleText

This is text that is separated by commas. The text is then unescaped. An array
of items is created.

=cut

sub load_multipleText {

	my @vals=split /(?<!\\),/, $_[3];
	map { s/\\,/,/ } @vals;

	$_[0]->{$_[1]}{'value'}=\@vals;
	$_[0]->{$_[1]}{'attr'}=$_[2] if $_[2] && ref($_[2]) eq "HASH" && keys %{$_[2]};

    return $_[0]->{$_[1]};

}

=item load_singleTextType

Load text that has a type attribute. Each text of different type attributes
will be handled independantly in as a hash entry. If no type attribute is supplied
then the typeDefaults types will be used. A line can have multiple types. In the
case where multiple types have the same value "_alias" indicators are created.
The preferred type is stored in "_pref"

=cut

sub load_singleTextTyped {
    
    my $typeDefault=$_[0]->typeDefault;

    my $attr=$_[2];

    my %type=();
    map { map { $type{lc $_}=1 } (split /,/, $_) } @{$attr->{'type'}};
    # delete $attr->{'type'};
    map { $type{ lc $_ }=1 } @{$typeDefault->{$_[1]}} unless scalar(keys %type);

    my $item={};
    push @{$_[0]->{$_[1]}}, $item;
    $item->{'value'}=$_[3];
    $item->{'type'}=\%type;
	$item->{'attr'}=$attr if keys %$attr;
    $item->{'sequence'}=_nextSequence();

    return $item;

}

=item load_singleBinary

Not done as I don't have example data yet.

=cut

sub load_singleBinary {
    my ($self, $name, $attr, $value) = @_;

    my $encoding = $attr->{'encoding'} || $attr->{'ENCODING'};

    # type=b means Base64; I don't know about others
    if ($encoding) {

        if (lc $encoding eq "b") {
            eval "use MIME::Base64";
            warn "Cannot decode binary MIME encoded objects: $@\n" and return if $@;
            $self->{$name}{'value'} = MIME::Base64::decode_base64($value);
        } else {
            warn "Unknown encoding $encoding for $name\n";
            return undef;
        }

    } else {
        
        # This must be an URL

    }
	$self->{$name}{'attr'}=$attr if $attr && ref($attr) eq "HASH" && keys %{$attr};

	die "_singleBinary not done\n";
}


=item @split = $self->split_value($line [, $delimiter]);

This method returns a array ref containing the $line elements
split by the delimiter, but ignores escaped delimiters.
If no $delimiter is supplied then a comma "," is used by default.

=cut

sub split_value {
	my ($self, $line, $delim) = @_;

	$delim = ',' unless $delim;

	my @list = split(/(?<!\\)$delim/,$line);

	return wantarray ? @list : \@list;
}

=back

=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "Text::vFile" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

=cut


1;

