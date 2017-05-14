package Form::Processor::Field::Template;
use strict;
use warnings;
our $VERSION = '0.03';

# This doesn't work because need to transform the input data before can validate
# and the Form module doesn't support this.
# Also, not all template snippets are valid HTML
# Since it doesn't work then can simply use Template::Parser to validate
# the templates.

# use base 'Form::Processor::Field::HtmlArea';


use base 'Form::Processor::Field::TextArea';
# use HTML::Tidy;
use Template::Parser;


# Checks that the template compiles and validates.


sub validate {
    my $field = shift;

    return unless $field->SUPER::validate;

    my $parser = Template::Parser->new;

    return $field->add_error( 'Template Error: [_1]', $parser->error )
        unless $parser->parse( $field->input );

    return 1;

}



=head1 NAME

Form::Processor::Field::Template - Tests that Template-Toolkit can parse the content

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a subclass of a TextArea field and the content of the field is parsed with
L<Template::Parser> for validation.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "textarea".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "TextArea".

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


__END__

# Another approach, that doesn't quite work.


package Form::Processor::Field::HtmlArea::Provider;
use strict;
use warnings;
use base 'Template::Provider';

sub _template_mtime { 1 }

sub _fetch_content {
    my ( $self, $file ) = @_;

    my $content = "<included $file>";
    return wantarray ? ( $content, '', 1 ) : $content;
}


package Form::Processor::Field::HtmlArea::Stash;
use strict;
use warnings;
use base 'Template::Stash';

sub get {
    my ($self, $arg ) = @_;
    my $value = ref $arg ? join( '.', @$arg ) : $arg;
    return "[ Template var '$value' ]";
}

package Form::Processor::Field::Template;
use strict;
use warnings;

my $template = Template->new(
    LOAD_TEMPLATES  => Form::Processor::Field::HtmlArea::Provider->new( INCLUDE_PATH => '/include/path' ),
    STASH           => Form::Processor::Field::HtmlArea::Stash->new( {} ),
) || die $Template::ERROR;





my $tidy;

sub validate {
    my $field = shift;
    return unless $field->SUPER::validate(@_);

    # Make sure template compiles
    my $output = '';
    my $value = $field->value;

    unless ( $template->process( \$value, {}, \$output ) ) {
        $field->add_error( $template->error );
        return;
    }

}




1;
