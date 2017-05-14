package Text::vFile;

use strict;

=head1 NAME

Text::vFile - Generic module which can read and write "vFile" files such as vCard (RFC 2426) and vCalendar (RFC 2445).
The result of loading this data is a collection of objects which will grant you easy access to the properties. Then 
the module can write your objects back to a data file.

=head1 SYNOPIS

    use Text::vFile;

    my $objects = Text::vCard->load( "foo.vCard", "blort.vCard", "whee.vCard" );

    foreach my $card (@$objects) {
        spam ( $card->email('pref') );
    }

    # OR
    
    my $reader = Text::vFile->new( source_file => "foo.vCard" );
    while ( my $object = $reader->next ) {
        spam ( $object );
    }

    # OR
    
    my $reader = Text::vFile->new( source_text => $vcard_data );
    while ( my $vcard = <$reader> ) {
        spam ( $vcard );
    }


=head1 DETAILS

The way this processor works is that it reads the vFile line by line.

1 - BEGIN:(.*) tag

   $1 is looked up in classMap; class is loaded; new object of this class is created
   ie/ $Text::vFile::classMap{'VCARD'}="Text::vCard";
       $object=$classMap{'VCARD'}->new;

    n.b. classMap is a package variable for Text::vFile

2 - All lines are read and stored until a BEGIN tag (goto 1) or END tag (goto 3) is reached

3 - END:(.*) tag

   Signals that all entry data has been obtained and now the rows of data are processed

4 - Data is concatenated - thanks to Text::iCal for the strategy; the tag label and data are obtained

5 - The data handler is identified via $object->varHandler->{$label}

    There are some generic handlers for common data types such as simple strings, dates, etc. More
    elaborate data types such as N, ADR, etc. need special treatment and are declared explititly
    in classes as "load_XXX" such as "load_N"

You should be able to override and extend the processing by taking Text::vFile::Base.pm as your example
and adjusting as necessary.

The resulting data structure is a bit bulky - but is such that it can express vFile data completely and
reliably

  $VAR1 = bless( {

  'EMAIL' => [
    {
      'attr' => {
        'email' => [
          'HOME'
        ],
        'type' => []
      },
      'sequence' => 1,
      'type' => {
        'internet' => 1
      },
      'value' => 'email\\@domain.com'
    }
  ],
  'TITLE' => {
    'value' => 'Job Title'
  },
  'X-ICQ' => [
    {
      'attr' => {
        'type' => [
          'WORK',
          'pref'
        ]
      },
      'sequence' => 11,
      'type' => {
        'pref' => 1,
        'work' => 1
      },
      'value' => '12341234'
    }
  ],
  '_lines' => [
    'VERSION:2.1',
    'N:Person;Test,Given;;;',
    'FN:Test Person',
    ....
  ] 
  }, "Text::vCard");

=head1 METHODS

=over 4

=item \@objects = load( filename [, filename ... ] )

Loads the vFiles found in filenames supplied and returns all found items an array of objects.

=cut

sub load {

	my $self=shift;
       $self=$self->new unless ref($self);

    my @objects=();

	foreach my $fn (@_) {

        $self->source_file( $fn );
        while ( my $object = $self->next ) {
            push @objects, $object;
        }

    }

    return wantarray ? @objects : \@objects;

}

=item \@objects = parse( string [, string ... ] )

Loads the vFiles found in the strings passed in and returns all found items as objects.

=cut

sub parse {

	my $self=shift;
       $self=$self->new unless ref($self);

    my @objects=();

	foreach my $text (@_) {

        $self->source_text( $text );
        until ( $self->eod ) {
            push @objects, $self->next;
        }

    }

    return wantarray ? @objects : \@objects;

}

sub _open {

    my $self=shift;

    warn "No filename supplied" && return unless $self->{'source_file'};
    
    open ($self->{'fh'}, $self->{'source_file'}) or warn "Cannot open $self->{'source_file'}\n";

}

=item $loader->source_file( name )

Sets this filename to be the source of vfile data. Only one filename, can contain many vfile entries.

=cut

sub source_file {

    my $self=shift;

    if (@_) {
        $self->{'source_file'} = shift;
        delete $self->{'fh'}; 
        delete $self->{'source_text'}; 
    }

    return $self->{'source_file'};

}

=item $loader->source_text( $scalar )

Sets this scalar to be the source of vfile data. Can contain many vfile.

=cut

sub source_text {

    my $self=shift;

    if (@_) {
        $self->{'source_text'} = shift;
        delete $self->{'fh'}; 
        delete $self->{'source_file'}; 
    }

    return $self->{'source_text'};

}

# Classes inject their desired mappings
use vars qw(%classMap);
%classMap=(

    VFILE     => "Text::vFile::Base",

    # VCALENDAR => "Text::vCalendar",
    # VALARM    => "Text::vCalendar::vAlarm",
    # VEVENT    => "Text::vCalendar::vEvent",
    # VTODO     => "Text::vCalendar::vTodo",

);

=item $object = class->new( options )

Create a new vfile loader. You will need to set its source to either a source_file or source_text.
Then use the next method to get each next object.

=cut

sub new {

	my $class = ref($_[0]) ? ref(shift) : shift;
    my $opts = ref($_[0]) ? $_[0] : {@_};

	my $self = bless {}, $class;

    map { $self->$_( $opts->{$_} ) } keys %$opts;

	return $self;

}

=item \@objects = Class->next

Gets next object from vfile

=cut

use overload
        '<>' => \&next,
        fallback => 1,
;


sub next {

    my $self=shift;

    if ($self->{'source_file'}) {
        $self->_open unless $self->{'fh'};
    }
    my $fh=$self->{'fh'};

    if ($self->{'source_text'}) {
        $self->{'text'} = [ split (/[\r\n]+/, $self->{'source_text'}) ] unless $self->{'text'};
    }

    return () unless $fh || $self->{'text'};

    # my $parent=shift;
    # $self->{'_parent'}=$parent if ref $parent;

    my $line = $fh ? <$fh> : shift @{$self->{'text'}};
    return if $self->eod;
    
    my $decoder;

    # UTF-16/32 detection
    if ( $line =~ /\000/ ) {

        eval "use Encode;";
        die "Cannot decode this file - need the Encode module; $@\n" if $@;

        if ($line =~ /\000\000\000/) {

            if ($line =~ /^\000/) {
                $decoder=Encode::find_encoding("UTF-32BE");
            } else {
                $decoder=Encode::find_encoding("UTF-32LE");
            }

        } else {

            if ($line =~ /^\000/) {
                $decoder=Encode::find_encoding("UTF-16BE");
            } else {
                $decoder=Encode::find_encoding("UTF-16LE");
            }

        }

    }

    $line = $decoder->decode( $line ) if $decoder;

    # VFILE class detection
    #   - see BEGIN until found or return at EOD contition
    until ( $line =~ /^BEGIN:/i ) {
        $line = $fh ? <$fh> : shift @{$self->{'text'}};
        return if $self->eod;
        $line = $decoder->decode( $line ) if $decoder;
    }

    $line =~ /^BEGIN:(.*)/i;
    my $kind=uc $1;
    my $class=$classMap{ $kind };
    die "In parseable begin tag $line - unknown class\n" unless $class;

    eval "use $class";
    die "Cannot load $class\n" if $@;

    my $varHandler=$class->varHandler;
    my $thing=$class->new;

    my @lines=();
    my $ended=0;
    until ( $self->eod ) {

        $line = $fh ? <$fh> : shift @{$self->{'text'}};

        $line = $decoder->decode($line) if $decoder;
        $line =~ s/[\r\n]+$//;

        # Sub object - like EVENT, etc.
        if ($line =~ /^BEGIN:(.+)/) {
            # $thing=$1;
            # my $subclass= $classMap{uc $thing} || die "Don't know how to load ${thing}s\n";
            # eval "use $subclass"; die $@ if $@;
            # push @{$self->{$thing}}, $subclass->new->load($fh, $self);
            # next;
            die "sub object loading not done\n";
        } 

        if ($line =~ /^END:(.*)/) {
            warn "bad end of data block - found END:$1 instead of END:" . uc $kind . "\n" unless uc $1 eq $kind;
            $ended=1;
            last;
        }

        push @lines, $line;

    }
    warn "premature end of data block - missing end tag\n" unless $ended;

    $thing->{'_lines'}= [ @lines ];

    while ( @lines ) {

        my $line = shift @lines;
        while ( @lines && $lines[0] =~ /^\s(.*)/ ) {
            $line .= $1;
            shift @lines;
        }

        # Non-typed line data 
        if ( $line =~ /^([\w\-]+):(.*)/ ) {

            my ($var, $data)=(uc $1, $2);
            my $h;
            if (UNIVERSAL::can( $thing, "load_$var")) {
                $h="load_$var";
            } else {
                $h="load_singleText";
            }
            $h = "load_$varHandler->{$var}" if exists $varHandler->{$var};

            $thing->$h($var, undef, $data);
            next;
        }

        # ATTR OR Typed line data
        if ( $line =~ /^([\w\-]+);([^:]*):(.*)/ ) { 

            my ($var, $attr_dat, $data)=(uc $1, $2, $3);

            my %attr=();
            map { /([^=]+)=(.*)/; push @{$attr{lc $1}}, $2 } split (/(?<!\\);/, $attr_dat);

            my $h;
            
            if (UNIVERSAL::can( $thing, "load_$var")) {
                $h="load_$var";
            } else {
                $h = exists $attr{'type'} ? "load_singleTextTyped" : "load_singleText";
            }

            $h = "load_$varHandler->{$var}" if exists $varHandler->{$var};

            $thing->$h($var, \%attr, $data);
            next;
        }

        $self->error( $line );

    }

    return $thing;

}


=item $loader->eod

Returns true if loader is at end of data for current source.

=cut

sub eod {

    if ( $_[0]->{'fh'} ) {
        return eof $_[0]->{'fh'};
    }

    return 0 if exists $_[0]->{'text'} && @{$_[0]->{'text'}};
    return 1;

}

=item $object->error

Called when a line cannot be successfully decoded

=back

=cut

sub error  { warn ref($_[0]) . " ERRORLINE: $_[1]\n"; }

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

 Leo - for a very productive exchange on how this should work plus suffering
       through a few growing pains. 

 Net::iCal - whose loading code inspired me for mine

=head1 SEE ALSO

RFC 2425, 2426, 2445

=cut

1;

