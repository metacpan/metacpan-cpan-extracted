
=head1 NAME

Weasel::FindExpanders::Dojo - XPath mnemonic hooks for Dojo 1.x widgets

=head1 VERSION

0.02

=head1 SYNOPSIS

  use Weasel::FindExpanders::Dojo;

  my $button = $session->find($session->page, "@button|{text=>\"whatever\"}");

=cut

package Weasel::FindExpanders::Dojo;

use strict;
use warnings;

use Weasel::FindExpanders qw/ register_find_expander /;

=head1 DESCRIPTION

=over

=item button_expander

Finds button tags or input tags of types submit, reset, button and image.

Criteria:
 * 'id'
 * 'name'
 * 'text' matches content between open and close tag

=cut

sub button_expander {
    my %args = @_;

    my @clauses;
    if (defined $args{text}) {
        push @clauses, "text()='$args{text}'";
    }

    for my $clause (qw/ id name /) {
        if (defined $args{$clause}) {
            push @clauses, "\@$clause='$args{$clause}'";
        }
    }

    my $clause =
        (@clauses) ? ('and .//*[' . join(' and ', @clauses) . ']'): '';

    # dijitButtonNode has a click handler
    # (its parent is has the dijitButton class, but only has a submit handler)
    return ".//*[contains(concat(' ',normalize-space(\@class),' '),
                                 ' dijitButtonNode ') $clause]"


}

=item option_expander

Finds options for dijit.form.Select, after the drop down has been invoked
at least once (the options don't exist in the DOM tree before that point).

Because of that, it's best to search the options through the C<select> tag,
which offers a C<find_option> method which specifically compensates for the
issue.

Additionally, it's impossible to search options by the value being submitted;
these don't exist in the DOM tree unlike with the C<option> tags of
C<select>s.

Criteria:
 * 'id'
 * 'text' matches the visible description of the item

=cut

sub option_expander {
    my %args = @_;

    my @clauses;
    if (defined $args{text}) {
        push @clauses, "text()='$args{text}'";
    }

    for my $clause (qw/ id /) {
        if (defined $args{$clause}) {
            push @clauses, "\@$clause='$args{$clause}'";
        }
    }

    my $clause =
        (@clauses) ? ('and .//*[' . join(' and ', @clauses) . ']'): '';
    return ".//*[\@role='option' $clause]";
}


=back

=cut



register_find_expander($_->{name}, 'Dojo', $_->{expander})
    for ({  name => 'button',   expander => \&button_expander   },
         {  name => 'option',   expander => \&option_expander   },
    );


1;
