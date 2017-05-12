package Form::Processor::Field::HtmlArea;
use strict;
use warnings;
use base 'Form::Processor::Field::TextArea';
use HTML::Tidy;
use File::Temp;
our $VERSION = '0.03';

my $tidy;

sub init_widget { 'textarea' }

sub validate {
    my $field = shift;

    return unless $field->SUPER::validate;

    $tidy ||= $field->tidy;
    $tidy->clear_messages;


    # parse doesn't pass the config file in HTML::Tidy.
    $tidy->clean( $field->input );

    my $ok = 1;

    for ( $tidy->messages ) {
        $field->add_error( $_->as_string );
        $ok = 0;
    }

    return $ok;
}


# Parses config file.  Do it once.

my $tidy_config;
sub tidy {
    my $field = shift;
    $tidy_config ||= $field->init_tidy;
    my $t = HTML::Tidy->new( { config_file => $tidy_config } );


    $t->ignore( text => qr/DOCTYPE/ );
    $t->ignore( text => qr/missing 'title'/ );
    # $t->ignore( type => TIDY_WARNING );

    return $t;
}


sub init_tidy {

    my $tidy_conf = <<EOF;
char-encoding: utf8
input-encoding: utf8
output-xhtml: yes
logical-emphasis: yes
quiet: yes
show-body-only: yes
wrap: 45
EOF



    my $tidy_file = File::Temp->new( UNLINK => 1 );
    print $tidy_file $tidy_conf;
    close $tidy_file;

    return $tidy_file;


}


=head1 NAME

Form::Processor::Field::HtmlArea - Input HTML in a textarea

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Field validates using HTML::Tidy.  A simple Tidy configuration file
is created and written to disk each time the field is validated.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "textarea".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Textarea".

=head1 DEPENDENCIES

L<HTML::Tidy>  L<File::Temp>

=head1 AUTHORS

Bill Moseley

=head1 COPYRIGHT

See L<Form::Processor> for copyright.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=cut


1;
