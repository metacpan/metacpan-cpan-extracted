package UR::Object::Command::List::Style;

our $VERSION = "0.47"; # UR $VERSION;

sub new {
    my ($class, %args) = @_;
    foreach (qw/iterator show noheaders output/){
        die "no value for $_!" unless defined $args{$_};
    }
    return bless(\%args, $class);
}

sub _get_next_object_from_iterator {
    my $self = shift;

    my $obj;
    for (1) {
        $obj = eval { $self->{'iterator'}->next };
        if ($@) {
            UR::Object::Command::List->warning_message($@);
            redo;
        }
    }
    return $obj;
}

sub _object_properties_to_string {
    my ($self, $o, $char) = @_;
    my @v;
    return join(
        $char,
        map { defined $_ ? $_ : '<NULL>' }
        map {
            $self->_object_property_to_string($o,$_)
        } @{$self->{show}}
    );
}

sub _object_property_to_string {
    my ($self, $o, $property) = @_;

    my @v;
    if (substr($property,0,1) eq '(') {
        @v = eval $property;
        if ($@) {
            @v = ('<ERROR>'); # ($@ =~ /^(.*)$/);
        }
    }
    else {
        @v = ();
        foreach my $i ($o->__get_attr__($property)) {
            if (! defined $i) {
                push @v, "<NULL>";
            } 
            elsif (Scalar::Util::blessed($i) and $i->isa('UR::Value') and $i->can('create_view')) {
                # Here we allow any UR::Values that have their own views to present themselves.
                my $v = $i->create_view( perspective => 'default', toolkit => 'text' );
                push @v, $v->content();
            }
            elsif (Scalar::Util::blessed($i) and $i->can('__display_name__')) {
                push @v, $i->__display_name__;
            } 
            else {
                push @v, $i;
            }
        }
    }

    if (@v > 1) {
        no warnings;
        return join(' ',@v);
    }
    else {
        return $v[0];
    }
}

sub format_and_print{
    my $self = shift;

    unless ( $self->{noheaders} ) {
        $self->{output}->print($self->_get_header_string. "\n");
    }

    my $count = 0;
    while (my $object = $self->_get_next_object_from_iterator()) {
        $self->{output}->print($self->_get_object_string($object), "\n");
        $count++;
    }

}

package UR::Object::Command::List::Html;
use base 'UR::Object::Command::List::Style';

sub _get_header_string{
    my $self = shift;
    return "<tr><th>". join("</th><th>", map { uc } @{$self->{show}}) ."</th></tr>";
}

sub _get_object_string{
    my ($self, $object) = @_;
    
    my $out = "<tr>";
    for my $property ( @{$self->{show}} ){
        $out .= "<td>" . $object->$property . "</td>";
    }
    
    return $out . "</tr>";
}

sub format_and_print{
    my $self = shift;
    
    $self->{output}->print("<table>");
    
    #cannot use super because \n screws up javascript
    unless ( $self->{noheaders} ) {
        $self->{output}->print($self->_get_header_string);
    }

    my $count = 0;
    while (my $object = $self->_get_next_object_from_iterator()) {
        $self->{output}->print($self->_get_object_string($object));
        $count++;
    }
    
    $self->{output}->print("</table>");
}

package UR::Object::Command::List::Csv;
use base 'UR::Object::Command::List::Style';

sub _get_header_string{
    my $self = shift;

    my $delimiter = $self->{'csv_delimiter'};
    return join($delimiter, map { lc } @{$self->{show}});
}

sub _get_object_string {
    my ($self, $object) = @_;

    return $self->_object_properties_to_string($object, $self->{'csv_delimiter'});
}

package UR::Object::Command::List::Tsv;
use base 'UR::Object::Command::List::Csv';

sub _get_header_string{
    my $self = shift;

    my $delimiter = "\t";
    return join($delimiter, map { lc } @{$self->{show}});
}

sub _get_object_string {
    my ($self, $object) = @_;

    return $self->_object_properties_to_string($object, "\t");
}


package UR::Object::Command::List::Pretty;
use base 'UR::Object::Command::List::Style';

sub _get_header_string{
    return '';
}

sub _get_object_string{
    my ($self, $object) = @_;

    my $out;
    for my $property ( @{$self->{show}} )
    {
        my $value = join(', ', $self->_object_property_to_string($object,$property));
        $out .= sprintf(
            "%s: %s\n",
            Term::ANSIColor::colored($property, 'red'),
            Term::ANSIColor::colored($value, 'cyan'),
        );
    }

    return $out;
}

package UR::Object::Command::List::Xml;
use base 'UR::Object::Command::List::Style';

sub format_and_print{
    my $self = shift;
    my $out;

    eval "use XML::LibXML";
    if ($@) {
        die "Please install XML::LibXML (run sudo cpanm XML::LibXML) to use this tool!";
    }

    my $doc = XML::LibXML->createDocument();
    my $results_node = $doc->createElement("results");
    $results_node->addChild( $doc->createAttribute("generated-at",$UR::Context::current->now()) );

    $doc->setDocumentElement($results_node);

    my $count = 0;
    while (my $object = $self->_get_next_object_from_iterator()) {
        my $object_node = $results_node->addChild( $doc->createElement("object") );

        my $object_reftype = ref $object;
        $object_node->addChild( $doc->createAttribute("type",$object_reftype) );
        $object_node->addChild( $doc->createAttribute("id",$object->id) );

        for my $property ( @{$self->{show}} ) {

             my $property_node = $object_node->addChild ($doc->createElement($property));

             my @items = $self->_object_property_to_string($object, $property);

             my $reftype = ref $items[0];

             if ($reftype && $reftype ne 'ARRAY' && $reftype ne 'HASH') {
                 foreach (@items) {
                     my $subobject_node = $property_node->addChild( $doc->createElement("object") );
                     $subobject_node->addChild( $doc->createAttribute("type",$reftype) );
                     $subobject_node->addChild( $doc->createAttribute("id",$_->id) );
                     #$subobject_node->addChild( $doc->createTextNode($_->id) );
                     #xIF
                 }
             } else {
                 foreach (@items) {
                     $property_node->addChild( $doc->createTextNode($_) );
                 }
             }

         }
        $count++;
    }
    $self->{output}->print($doc->toString(1));
}

package UR::Object::Command::List::Text;
use base 'UR::Object::Command::List::Style';

sub _get_header_string{
    my $self = shift;
    return join (
        "\n",
        join("\t", map { uc } @{$self->{show}}),
        join("\t", map { '-' x length } @{$self->{show}}),
    );
}

sub _get_object_string{
    my ($self, $object) = @_;
    $self->_object_properties_to_string($object, "\t");
}

sub format_and_print{
    my $self = shift;
    my $tab_delimited;
    unless ($self->{noheaders}){
        $tab_delimited .= $self->_get_header_string."\n";
    }

    my $count = 0;
    while (my $object = $self->_get_next_object_from_iterator()) {
        $tab_delimited .= $self->_get_object_string($object)."\n";
        $count++;
    }

    $self->{output}->print($self->tab2col($tab_delimited));
}

sub tab2col{
    my ($self, $data) = @_;

    #turn string into 2d array of arrayrefs ($array[$rownum][$colnum])
    my @rows = split("\n", $data);
    @rows = map { [split("\t", $_)] } @rows;

    my $output;
    my @width;

    #generate array of max widths per column
    foreach my $row_ref (@rows) {
        my @cols = @$row_ref;
        my $index = $#cols;
        for (my $i = 0; $i <= $index; $i++) {
            my $l = (length $cols[$i]) + 3; #TODO test if we need this buffer space
            $width[$i] = $l if ! defined $width[$i] or $l > $width[$i];
        }
    }
    
    #create a array of blanks to use as a templatel
    my @column_template = map { ' ' x $_ } @width;

    #iterate through rows and cols, substituting in the row entry in your template
    foreach my $row_ref (@rows) {
        my @cols = @$row_ref;
        my $index = $#cols;
        #only apply template for all but the last entry in a row 
        for (my $i = 0; $i < $index; $i++) {
            my $entry = $cols[$i];
            my $template = $column_template[$i];
            substr($template, 0, length $entry, $entry);
            $output.=$template;
        }
        $output.=$cols[$index]."\n"; #Don't need traling spaces on the last entry
    }
    return $output;
}

package UR::Object::Command::List::Newtext;
use base 'UR::Object::Command::List::Text';

sub format_and_print{
    my $self = shift;
    my $tab_delimited;

    unless ($self->{noheaders}){
        $tab_delimited .= $self->_get_header_string."\n";
    }

    my $view = UR::Object::View->create(
                       subject_class_name => 'UR::Object',
                       perspective => 'lister',
                       toolkit => 'text',
                       aspects => [ @{$self->{'show'}} ],
                  );

    my $count = 0;
    while (my $object = $self->_get_next_object_from_iterator()) {
        $view->subject($object);
        $tab_delimited .= $view->content() . "\n";
        $count++;
    }

    $self->{output}->print($self->tab2col($tab_delimited));
}

1;
=pod

=head1 NAME

UR::Object::Command::List - Fetches and lists objects in different styles.

=head1 SYNOPSIS

 package MyLister;

 use strict;
 use warnings;

 use above "UR";

 class MyLister {
     is => 'UR::Object::Command::List',
     has => [
     # add/modify properties
     ],
 };

 1;

=head1 Provided by the Developer

=head2 subject_class_name (optional)

The subject_class_name is the class for which the objects will be fetched.  It can be specified one of two main ways:

=over

=item I<by_the_end_user_on_the_command_line>

For this do nothing, the end user will have to provide it when the command is run.

=item I<by_the_developer_in the_class_declartion>

For this, in the class declaration, add a has key w/ arrayref of hashrefs.  One of the hashrefs needs to be subject_class_name.  Give it this declaration:

 class MyFetchAndDo {
     is => 'UR::Object::Command::FetchAndDo',
     has => [
         subject_class_name => {
             value => <CLASS NAME>,
             is_constant => 1,
         },
     ],
 };

=back

=head2 show (optional)

Add defaults to the show property:

 class MyFetchAndDo {
     is => 'UR::Object::Command::FetchAndDo',
     has => [
         show => {
             default_value => 'name,age', 
         },
     ],
 };

=head2 helps (optional)

Overwrite the help_brief, help_synopsis and help_detail methods to provide specific help.  If overwiting the help_detail method, use call '_filter_doc' to get the filter documentation and usage to combine with your specific help.

=head1 List Styles

text, csv, html, xml, pretty (inprogress)

=cut


#$HeadURL: svn+ssh://svn/srv/svn/gscpan/perl_modules/trunk/UR/Object/Command/List.pm $
#$Id: List.pm 50329 2009-08-25 20:10:00Z abrummet $
