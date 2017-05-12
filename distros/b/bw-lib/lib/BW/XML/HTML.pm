# BW::XML::HTML.pm
# Simple X/HTML output
#
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History
#

package BW::XML::HTML;
use strict;
use warnings;

use BW::Constants;
use base qw( BW::XML::Out );

our $VERSION = "1.5.1";
sub version { $VERSION }

sub select
{
    my ( $self, $name, $content, $attribs ) = @_;
    my $sn             = 'select';
    my $select_options = "\n";

    foreach my $h (@$content) {
        my $xparms = { indentLevel => 1, attribs => [] };
        my $text = $h->{text} || $h->{value} || '';
        my $value = $h->{value} || '';
        push( @{ $xparms->{attribs} }, { value => $value } );
        push( @{ $xparms->{attribs} }, { selected => 'selected' } ) if $h->{selected};
        $select_options .= $self->element( 'option', $text, $xparms );
    }

    $attribs = [] unless $attribs;
    push @$attribs, { name => $name };

    return $self->element(
        'select',
        $select_options,
        {
            xmlContent => TRUE,
            attribs    => $attribs
        } );
}

sub link
{
    my ( $self, $uri, $text, $attribs ) = @_;
    my $sn = 'link';

    $text    = '' unless $text;
    $attribs = [] unless $attribs;
    push @$attribs, { href => $uri };

    return $self->element( 'a', $text, { attribs => $attribs, noNewline => TRUE, xmlContent => TRUE, } );
}

sub input
{
    my ( $self, $type, $name, $value, $attribs ) = @_;
    my $sn = 'input';

    $type    = 'text' unless $type;
    $name    = ''     unless $name;
    $value   = ''     unless $value;
    $attribs = []     unless $attribs;
    push @$attribs, { type  => $type };
    push @$attribs, { name  => $name };
    push @$attribs, { value => $value };

    return $self->element( 'input', undef, { attribs => $attribs, noNewline => TRUE, emptyTag => TRUE } );
}

sub hidden
{
    my ( $self, $name, $value, $attribs ) = @_;
    my $sn = 'hidden';

    return $self->input( 'hidden', $name, $value, $attribs );
}

sub submit
{
    my ( $self, $name, $value, $attribs ) = @_;
    my $sn = 'submit';

    return $self->input( 'submit', $name, $value, $attribs );
}

1;

__END__

=head1 NAME

BW::XML::HTML - Simple X/HTML output

=head1 SYNOPSIS

  use BW::XML::HTML;
  my $errstr;

  my $x = BW::XML::HTML->new;
  error($errstr) if (($errstr = $x->error));

=head1 METHODS

In the methods that have an "attribs" paramater, it is an arrayref of attributes as used by BW::XML::Out::element. 

This is an incomplete subset of HTML/XHTML. It's mostly form elements and not even all of those. 
I may finish it someday, but it's like this for now because I tend to use templates for most XHMTL. 

=over 4

=item B<new>

Constructs a new object . . . 

=item B<select>( select_name, select_content, attribs )

Returns a select element. 

C<select_content> is an arrayref of hashrefs. Each hashref has three keys:

    * text
    * value
    * selected

=item B<link>( uri, text, attribs )

Returns an anchor element. 

=item B<input>( type, name, value, attribs )

Returns an input element. 

=item B<hidden>( name, value, attribs )

Returns a hidden field element. 

=item B<submit>( name, value, attribs )

Returns a submit button element. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-03-11 bw 1.5.1 -- released to CPAN as part of BW-Lib
    2009-12-21 bw 1.4   -- added some methods
    2008-04-12 bw 1.0   -- initial release

=cut

