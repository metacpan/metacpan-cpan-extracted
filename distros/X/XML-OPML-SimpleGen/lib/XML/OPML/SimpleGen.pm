package XML::OPML::SimpleGen;

use strict;
use warnings;

use base 'Class::Accessor';

use DateTime;

use POSIX qw(setlocale LC_TIME LC_CTYPE);

__PACKAGE__->mk_accessors(qw|groups xml_options outline group xml_head xml_outlines xml|);

# Version set by dist.ini; do not change here.
our $VERSION = '0.07'; # VERSION

sub new {
    my $class = shift;
    my @args = @_;

    my $args = {
	    groups  => {},

	    xml     => {
	        version     => '1.1',
	        @args,
	        },			

	    # XML::Simple options
	    xml_options => {
	        RootName    => 'opml', 
	        XMLDecl     => '<?xml version="1.0" encoding="utf-8" ?>',
	        AttrIndent  => 1,
	    },

	    # default values for nodes
	    outline => {
	        type        => 'rss',
	        version     => 'RSS',
	        text        => '',
	        title       => '',
	        description => '',
	    },

	    group => {
	        isOpen      => 'true',
	    },

	    xml_head        => {},
	    xml_outlines    => [],

	    id              => 1,
    };

    my $self = bless $args, $class;

    # Force locale to 'C' rather than local, then reset after setting times.
    # Fixes RT51000.  Thanks to KAPPA for the patch.
    my $old_loc = POSIX::setlocale(LC_TIME, "C");
    my $ts_ar = [ localtime() ];
    $self->head(
        title => '',
        $self->_date( dateCreated  => $ts_ar ),
        $self->_date( dateModified => $ts_ar ),
    );
    POSIX::setlocale(LC_TIME,$old_loc);

    return $self;
}

sub _date {
  my $self  = shift;
  my $type  = shift; # dateCreated or dateModified.
  my $ts_ar = shift; # e.g [ localtime() ]

  my %arg;
  @arg{qw(second minute hour day month year)} = (
      @{$ts_ar}[0..3],
      $ts_ar->[4]+1,
      $ts_ar->[5]+1900 );
  my $dt = DateTime->new( %arg );
  return ( $type => $dt->strftime('%a, %e %b %Y %H:%M:%S %z') );
}

sub id {
    my $self = shift;
    
    return $self->{id}++;
}

sub head {
    my $self = shift;
    my $data = {@_};

    #this is necessary, otherwise XML::Simple will just generate attributes
    while (my ($key,$value) = each %{ $data }) {
	    $self->xml_head->{$key} = [ $value ];
    }
}

sub add_group {
    my $self = shift;
    my %defaults = %{$self->group};
    my $data = {
        id => $self->id,
        %defaults,
        @_ };
 
    die "Need to define 'text' attribute" unless defined $data->{text};

    $data->{outline} = [];

    push @{$self->xml_outlines}, $data;
    $self->groups->{$data->{text}} = $data->{outline};
}

sub insert_outline {
    my $self = shift;
    my %defaults = %{$self->outline};
    my $data = {
        id => $self->id,
        %defaults,
        @_};

    my $parent = $self->xml_outlines;

    if (exists $data->{group}) {
	    if (exists $self->groups->{$data->{group}}) {
	        $parent = $self->groups->{$data->{group}};
	        delete($data->{group});
	    }
        else {
	        $self->add_group('text' => $data->{group});
	        $self->insert_outline(%$data);
	        return;
	    }
    }

    push @{$parent}, $data;
}

sub add_outline {
    my $self = shift;
    $self->insert_outline(@_);
}

sub as_string {
    my $self = shift;

    require  XML::Simple;
    my $xs = XML::Simple->new();

    return $xs->XMLout( $self->_mk_hashref, %{$self->xml_options} );
}

sub _mk_hashref {
    my $self = shift;

    my $hashref =  {
	    %{$self->xml},
	    head => $self->xml_head,
	    body => { outline => $self->xml_outlines },
    };

    return $hashref;
}

sub save {
    my $self = shift;
    my $filename = shift;

    require  XML::Simple;
    my $xs = XML::Simple->new();

    $xs->XMLout( $self->_mk_hashref, %{$self->xml_options}, OutputFile => $filename );
}

1;

# ABSTRACT:  create OPML using XML::Simple

__END__

=pod

=head1 NAME

XML::OPML::SimpleGen - create OPML using XML::Simple

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    require XML::OPML::SimpleGen;

    my $opml = new XML::OPML::SimpleGen();

    $opml->head(
             title => 'FIFFS Subscriptions',
           );

    $opml->insert_outline(
        group => 'news',  # groups will be auto generated
        text =>  'some feed',
        xmlUrl => 'http://www.somepage.org/feed.xml',
    );

    # insert_outline and add_outline are the same

    $opml->add_group( text => 'myGroup' ); # explicitly create groups
   
    print $opml->to_string;

    $opml->save('somefile.opml');

    $opml->xml_options( $hashref ); # XML::Simple compatible options

    # See XML::OPML's synopsis for more knowledge

=head1 DESCRIPTION

XML::OPML::SimpleGen lets you simply generate OPML documents
without having too much to worry about. 
It is a drop-in replacement for XML::OPML
in regards of generation. 
As this module uses XML::Simple it is rather
generous in regards of attribute or element names.

=head1 NAME

XML::OPML::SimpleGen - create OPML using XML::Simple

=head1 COMMON METHODS

=over

=item new( key => value )

Creates a new XML::OPML::SimpleGen instance. All key values will be
used as attributes for the <atom> element. The only thing you might
want to use here is the version => '1.1', which is default anyway.

=item head( key => value ) 

XML::OPML compatible head method to change header values. 

=item id ( )

Returns (and increments) a counter.

=item add_group ( text => 'name' )

Method to explicitly create a group which can hold multiple outline
elements.

=item insert_outline ( key => value )

XML::OPML compatible method to add an outline element. See
L<XML::OPML> for details. The group key is used to put elements in a
certain group. Non existent groups will be created automagically. 

=item add_outline ( key => value )

Alias to insert_outline for XML::OPML compatibility.

=item as_string 

Returns the given OPML XML data as a string

=item save ( $filename )

Saves the OPML data to a file

=back

=head1 ADVANCED METHODS

=over

=item xml_options ( $hashref ) 

$hashref may contain any XML::Simple options.

=item outline ( $hashref )

The outline method defines the 'template' for any new outline
element. You can preset key value pairs here to be used
in all outline elements that will be generated by XML::OPML::SimpleGen.

=item group ( $hashref )

This method is similar to outline, it defines the template for a
grouping outline element. 

=back

=head1 MAINTAINER 

Stephen Cardie C<< <stephenca@cpan.org> >>

=head1 REPOSITORY

L<https://github.com/stephenca/XML-OPML-SimpleGen>

=head1 CONTRIBUTORS

=over 4

=item KAPPA C<< <kappa@cpan.org> >> contributed a patch to close RT51000
L<https://rt.cpan.org/Public/Bug/Display.html?id=51000>

=item gregoa@debian.org contributed a patch to close RT77725
L<https://rt.cpan.org/Public/Bug/Display.html?id=77725>

=back

=head1 REPO

  The git repository for this module is at
L<https://github.com/stephenca/XML-OPML-SimpleGen>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-opml-simlegen@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-OPML-SimleGen>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<XML::OPML> L<XML::Simple>

=head1 AUTHOR

Marcus Theisen <marcus@thiesen.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Marcus Thiesen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
