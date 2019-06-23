
=head1 NAME

Weasel::FindExpanders::HTML - Weasel FindExpanders HTML

=head1 VERSION

0.02

=head1 SYNOPSIS

  use Weasel::FindExpanders::HTML;

  my $button = $session->find($session->page, "@button|{text=>\"whatever\"}");

=cut

=head1 DEPENDENCIES



=cut

package Weasel::FindExpanders::HTML;

use strict;
use warnings;

use Weasel::FindExpanders qw/ register_find_expander /;

=head1 DESCRIPTION

=cut

=head1 SUBROUTINES/METHODS

=over

=item button_expander

Finds button tags or input tags of types submit, reset, button and image.

Criteria:
 * 'id'
 * 'name'
 * 'text' -- button: matches content between open and close tag
          -- input: matches 'value' attribute (shown on button),
                    or image button's 'alt' attribute

=cut

sub button_expander {
    my %args = @_;

    my @input_clauses;
    my @btn_clauses;
    if (defined $args{text}) {
        push @input_clauses, "(\@alt='$args{text}' or \@value='$args{text}')";
        push @btn_clauses, "normalize-space(text())=normalize-space('$args{text}')";
    }

    for my $clause (qw/ id name /) {
        if (defined $args{$clause}) {
            push @input_clauses, "\@$clause='$args{$clause}'";
            push @btn_clauses, "\@$clause='$args{$clause}'";
        }
    }

    my $input_clause =
        (@input_clauses) ? join ' and ', ('', @input_clauses) : '';
    my $btn_clause =
        (@input_clauses) ? join ' and ', @btn_clauses : '';
    ##no critic(ProhibitInterpolationOfLiterals)
    return ".//input[(\@type='submit' or \@type='reset'" .
                     "or \@type='image' or \@type='button') $input_clause]" .
            "| .//button[$btn_clause]";
}

=item checkbox_expander

Finds input tags of type checkbox

Criteria:
 * 'id'
 * 'name'
 * 'value'

=cut

sub checkbox_expander {
    my %args = @_;

    my @clauses;
    for my $clause (qw/ id name value /) {
        push @clauses, "\@$clause='$args{$clause}'"
            if defined $clause;
    }
    my $clause = @clauses ? join ' and ', ('', @clauses) : '';
    return ".//input[\@type='checkbox' $clause]";
}

=item contains_expander

Finds tags containing 'text'

=cut

sub contains_expander {
    my %args = @_;

    my $text = $args{text};
    return ".//*[contains(.,normalize-space('$text'))][not(.//*[contains(.,normalize-space('$text'))])]";
}

=item labeled_expander

Finds tags for which a label has been set (using the label tag)

Criteria:
 * 'text': text of the label
 * 'tag': tags for which the label has been set

=cut

sub labeled_expander {
    my %args = @_;

    my $tag = $args{tag_name} // q{*};
    my $text = $args{text};
    return ".//${tag}[\@id=//label[normalize-space(text())=normalize-space('$text')]/\@for]";
}

=item link_expander

Finds A tags with an href attribute whose text or title matches 'text'

Criteria:
 * 'text'

=cut

sub link_expander {
    my %args = @_;

    my $text = $args{text} // '';
    # A tags with not-"no href" (thus, with an href [any href])
    return ".//a[not(not(\@href)) and normalize-space(text())=normalize-space('$text') or \@title='$text']";
}

=item option_expander

Finds OPTION tags whose content matches 'text' or value matches 'value'

Criteria:
 * 'text'
 * 'value'

=cut

sub option_expander {
    my %args = @_;

    my $text = $args{text} // '';
    my $value = $args{value} // '';
    return ".//option[normalize-space(text())=normalize-space('$text') or \@value='$value']";
}

=item password_expander

Finds input tags of type password

Criteria:
 * 'id'
 * 'name'

=cut

sub password_expander {
    my %args = @_;

    my @clauses;
    for my $clause (qw/ id name /) {
        push @clauses, "\@$clause='$args{$clause}'"
            if defined $clause;
    }
    my $clause = @clauses ? join ' and ', ('', @clauses) : '';

    return ".//input[\@type='password' $clause]";
}

=item radio_expander

Finds input tags of type radio

Criteria:
 * 'id'
 * 'name'
 * 'value'

=cut

sub radio_expander {
    my %args = @_;

    my @clauses;
    for my $clause (qw/ id name value /) {
        push @clauses, "\@$clause='$args{$clause}'"
            if defined $args{$clause};
    }
    my $clause = join ' and ', @clauses;


    return ".//input[\@type='radio' $clause]";
}

=item select_expander

Finds select tags

Criteria:
 * 'id'
 * 'name'

=cut

sub select_expander {
    my %args = @_;

    my @clauses;
    for my $clause (qw/ id name /) {
        push @clauses, "\@$clause='$args{$clause}'"
            if defined $args{$clause};
    }
    my $clause = join ' and ', @clauses;
    return ".//select[$clause]";
}

=item text_expander

Finds input tags of type text or without type (which defaults to text)

Criteria:
 * 'id'
 * 'name'

=cut

sub text_expander {
    my %args = @_;

    my @clauses;
    for my $clause (qw/ id name /) {
        push @clauses, "\@$clause='$args{$clause}'"
            if defined $args{$clause};
    }
    my $clause = (@clauses) ? join ' and ', ('', @clauses) : '';
    return ".//input[(not(\@type) or \@type='text') $clause]";
}


register_find_expander($_->{name}, 'HTML', $_->{expander})
    for ({  name => 'button',   expander => \&button_expander   },
         {  name => 'checkbox', expander => \&checkbox_expander },
         {  name => 'contains', expander => \&contains_expander },
         {  name => 'labeled',  expander => \&labeled_expander },
         {  name => 'link',     expander => \&link_expander     },
         {  name => 'option',   expander => \&option_expander   },
         {  name => 'password', expander => \&password_expander },
         {  name => 'radio',    expander => \&radio_expander    },
         {  name => 'select',   expander => \&select_expander   },
         {  name => 'text',     expander => \&text_expander      },
    );

=back

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann
Yves Lavoie

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

1;
