#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2016 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::HTML::TreeBuilder;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %CGI_TAG_WEBDYNE %CGI_TAG_IMPLICIT %CGI_TAG_SPECIAL);
use warnings;
no warnings qw(uninitialized redefine once);


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Base;


#  External Modules. Keep HTML::Entities or nullification of encode/decode
#  subs will not work below
#
use HTML::TreeBuilder;
use HTML::Entities;
use HTML::Tagset;
use IO::File;
use Data::Dumper;


#  Inheritance
#
@ISA=qw(HTML::TreeBuilder);


#  Version information
#
$VERSION='1.246';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Make a hash of our implictly closed tags. TODO, expand to full list,
#  instead of most used.
#
#%CGI_TAG_IMPLICIT=map { $_=>1 } (
#
#    'popup_menu',
#    'textfield',
#    'textarea',
#    'radio_group',
#    'password_field',
#    'filefield',
#    'scrolling_list',
#    'checkbox_group',
#    'checkbox',
#    'hidden',
#    'submit',
#    'reset',
#    'dump'
#
#   );


#  Update - get from CGI module, add special dump tag
%CGI_TAG_IMPLICIT=map {$_ => 1} (

    @{$CGI::EXPORT_TAGS{':form'}},
    'dump'

);


#  Get WebDyne tags from main module
#
%CGI_TAG_WEBDYNE=%WebDyne::CGI_TAG_WEBDYNE;


#  The tags below need to be handled specially at compile time - see the method
#  associated with each tag below.
#
map {$CGI_TAG_SPECIAL{$_}++} qw(perl script style start_html end_html include);


#  Nullify Entities encode & decode
#
*HTML::Entities::encode=sub { };
*HTML::Entities::decode=sub { };


#  Add to islist items in TreeBuilder
#
map {$HTML::TreeBuilder::isList{$_}++} keys %CGI_TAG_WEBDYNE;


#  Need to tell HTML::TagSet about our special elements so
#
map {$HTML::Tagset::isTableElement{$_}++} keys %CGI_TAG_WEBDYNE;


#  And that we also block <p> tag closures
#
push @HTML::TreeBuilder::p_closure_barriers, keys %CGI_TAG_WEBDYNE;


#  Local vars neeeded for cross sub comms
#
our ($Text_fg, $Line_no, $Line_no_next, $Line_no_start, $HTML_Perl_or, @HTML_Wedge);


#  All done. Positive return
#
1;


#==================================================================================================


sub parse_fh {


    #  Get self ref, file handle
    #
    my ($self, $html_fh)=@_;
    debug("parse $html_fh");


    #  Turn off HTML_Perl object global, in case left over from a __PERL__ segment
    #  at the bottom of the last file parsed. Should never happen, as we check in
    #  delete() also
    #
    $HTML_Perl_or && ($HTML_Perl_or=$HTML_Perl_or->delete());
    undef $Text_fg;
    undef $Line_no;
    undef $Line_no_start;
    undef $Line_no_next;
    undef @HTML_Wedge;


    #  Return closure code ref that understands how to count line
    #  numbers and wedge in extra code
    #
    my $parse_cr=sub {

        #$Line_no++;
        my $line;
        my $html=@HTML_Wedge ? shift @HTML_Wedge : ($line=<$html_fh>);
        if ($line) {
            debug("line $line");
            my @cr=($line=~/\n/g);
            $Line_no=$Line_no_next || 1;
            $Line_no_next=$Line_no+@cr;
            debug("Line $Line_no, Line_no_next $Line_no_next, Line_no_start $Line_no_start cr %s", scalar @cr);
        }
        return $html;

    };
    return $parse_cr;

}


sub delete {


    #  Destroy tree, reset any globals
    #
    my $self=shift();
    debug('delete');


    #  Get rid of inline HTML object, if still around
    #
    $HTML_Perl_or && ($HTML_Perl_or=$HTML_Perl_or->delete());


    #  Reset script and line number vars
    #
    undef $Text_fg;
    undef $Line_no;
    undef $Line_no_next;
    undef $Line_no_start;
    undef @HTML_Wedge;


    #  Run real deal from parent
    #
    $self->SUPER::delete(@_);


}


sub tag_parse {


    #  Get our self ref
    #
    my ($self, $method)=(shift, shift);


    #  Get the tag, tag attr
    #
    my ($tag, $attr_hr)=@_;


    #  Debug
    #
    debug("tag_parse $method, $tag, line $Line_no, line_no_start $Line_no_start");


    #  Get the parent tag
    #
    my $pos;
    my $tag_parent=(
        $pos=$self->{'_pos'} || $self
    )->{'_tag'};
    debug("tag $tag, tag_parent $tag_parent");


    #  Var to hold returned html object ref
    #
    my $html_or;


    #  If it is an below an implicit parent tag close that tag now.
    #
    if ($CGI_TAG_IMPLICIT{$tag_parent} || $tag_parent=~/^start_/i || $tag_parent=~/^end_/i) {

        #  End implicit parent if it was an implicit tag
        #
        debug("ending implicit parent tag $tag_parent");
        $self->end($tag_parent);
        $html_or=$self->$method(@_);

    }


    #  Special case where <perl/block/etc> wraps <head> or <body> tags. HTML::TreeBuilder assumes
    #  head is always under html - we have to hack.
    #
    elsif ($CGI_TAG_WEBDYNE{$tag_parent} && ($tag eq 'head')) {

        #  Debug and modify tree
        #
        debug("found $tag_parent above $tag, modifying tree");
        $self->{'_head'}->preinsert($pos);
        $self->{'_head'}->detach();
        $pos->push_content($self->{'_head'});
        $self->$method(@_);

    }


    #  Same for body tag as above
    #
    elsif ($CGI_TAG_WEBDYNE{$tag_parent} && ($tag eq 'body')) {

        debug("found $tag_parent above $tag, modifying tree");
        $self->{'_body'}->preinsert($pos);
        $self->{'_body'}->detach();
        $pos->push_content($self->{'_body'});
        $self->$method(@_);

    }


    #  If it is an custom webdyne tag, massage with methods below
    #  before processing
    #
    elsif ($CGI_TAG_SPECIAL{$tag} && ($method ne 'SUPER::text')) {


        #  Yes, is WebDyne tag
        #
        debug("webdyne tag ($tag) dispatch");
        $html_or=$self->$tag($method, $tag, $attr_hr);

    }


    #  If it is an custom CGI tag that we need to close implicityly
    #
    elsif ($CGI_TAG_IMPLICIT{$tag_parent} || $tag=~/^start_/i || $tag=~/^end_/) {


        #  Yes, is CGI tag
        #
        debug("webdyne tag ($tag) dispatch");
        $html_or=$self->$method(@_);
        $self->end($tag)

    }


    #  If its parent was a custom webdyne tag, the turn off implicitness
    #  before processing
    #
    elsif ($CGI_TAG_WEBDYNE{$tag_parent}) {


        #  Turn off implicitness here to stop us from being moved
        #  around in the parse tree if we are under a table or some
        #  such
        #
        debug('turning off implicit tags');
        $self->implicit_tags(0);


        #  Run the WebDyne tag method.
        #
        debug("webdyne tag_parent ($tag_parent) dispatch");
        $html_or=$self->$tag_parent($method, $tag, $attr_hr);


        #  Turn implicitness back on again
        #
        debug('turning on implicit tags');
        $self->implicit_tags(1);


    }
    else {


        #  Pass onto our base class for further processing
        #
        debug("base class method $method");
        $html_or=$self->$method(@_);


    }


    #  Insert line number if possible
    #
    debug("insert line_no $Line_no, line_no_start $Line_no_start into object ref $html_or");
    ref($html_or) && (@{$html_or}{'_line_no', '_line_no_tag_end'}=($Line_no_start, $Line_no));


    #  Returm object ref
    #
    $html_or;


}


sub block {


    #  No special handling needed, just log for debugging purposes
    #
    my ($self, $method)=(shift, shift);
    debug("block self $self, method $method, @_ text_fg $Text_fg");
    $self->$method(@_);

}


sub script {

    my ($self, $method, $tag, $attr_hr)=@_;
    debug('script');
    $Text_fg='script';
    my $or=$self->$method($tag, $attr_hr, @_);
    $or->postinsert('</script>') if $attr_hr->{'src'};
    $or;

}


sub style {

    my ($self, $method)=(shift, shift);
    debug('style');
    $Text_fg='style';
    $self->$method(@_);

}


sub perl {


    #  Special handling of perl tag
    #
    my ($self, $method, $tag, $attr_hr)=@_;
    debug("$tag $method");


    #  Call SUPER method, check if inline
    #
    my $html_perl_or=$self->$method($tag, $attr_hr);
    my $inline;
    if ($tag eq 'perl') {
        unless (grep {exists $attr_hr->{$_}} qw(package class method)) {
            $html_perl_or->attr(inline => ++$inline);
        }
    }
    if ($inline) {

        #  Inline tag, set global var to this element so any extra text can be
        #  added here
        #
        $HTML_Perl_or=$html_perl_or;
        $Text_fg='perl';


        #  And return it
        #
        return $html_perl_or;

    }
    else {


        #  Not inline, just return object
        #
        return $html_perl_or;

    }


}


sub process {

    #  Rough and ready process handler, try to handle perl code in <? .. ?>. Not sure if I really
    #  want to support this yet ...
    #
    my ($self, $text)=@_;
    debug("process $text");
    my $or=HTML::Element->new('perl', inline => 1, perl => $text);
    debug("insert line_no $Line_no into object ref $or");
    @{$or}{'_line_no', '_line_no_tag_end'}=($Line_no_start, $Line_no);
    $self->tag_parse('SUPER::text', $or)

}


sub start {


    #  Ugly, make sure if in perl or script tag, whatever we see counts
    #  as text
    #
    my ($self, $tag)=(shift, shift);
    my $text=$_[2];
    ref($tag) || ($tag=lc($tag));
    debug("start $tag Line_no $Line_no, @_, %s", Data::Dumper::Dumper(\@_));
    my $html_or;
    if ($Text_fg) {
        $html_or=$self->text($text)
    }
    else {
        my @cr=($text=~/\n/g);
        $Line_no_start=$Line_no-@cr;
        debug("tag $tag line_no $Line_no, line_no_start $Line_no_start");
        $html_or=$self->tag_parse('SUPER::start', $tag, @_);

    }
    $html_or;

}


sub end {


    #  Ugly special case conditions, ensure end tag between perl or script
    #  blocks are treated as text
    #
    my ($self, $tag)=(shift, shift);
    ref($tag) || ($tag=lc($tag));
    debug("end $tag, text_fg $Text_fg, line $Line_no");
    my $html_or;
    if ($Text_fg && ($tag eq $Text_fg)) {
        $Text_fg=undef;
        $html_or=$self->SUPER::end($tag, @_)
    }
    elsif ($Text_fg) {
        $html_or=$self->text($_[0])
    }
    else {
        $html_or=$self->SUPER::end($tag, @_)
    }
    $html_or;


}


#  Reminder to self. Keep this in, or implicit CGI tags will not be closed
#  if text block follows implicit CGI tag immediately
#
sub text {


    #  get self ref, text we will process
    #
    my ($self, $text)=@_;
    debug("text *$text*, text_fg $Text_fg, pos %s", $self->{'_pos'});


    #  Are we in an inline perl block ?
    #
    if ($Text_fg eq 'perl') {


        #  Yes. We have inline perl code, not text. Just add to perl attribute, which
        #  is treated specially when rendering
        #
        debug('in __PERL__ tag, appending text to __PERL__ block');

        #  Strip leading CR from Perl code so line numbers in errors make sense
        #unless ($HTML_Perl_or->{'perl'}) { $text=~s/^\n// }
        $HTML_Perl_or->{'perl'}.=$text;
        $HTML_Perl_or->{'_line_no_tag_end'}=$Line_no;


    }

    #  Used to do this so __PERL__ block would only count if at end of file.
    #elsif (($text=~/^\W*__CODE__/ || $text=~/^\W*__PERL__/) && !$self->{'_pos'}) {

    elsif (($text=~/^\W*__CODE__/ || $text=~/^\W*__PERL__/)) {


        #  Close off any HTML
        #
        delete $self->{'_pos'} if $self->{'_pos'};


        #  Perl code fragment. Will be last thing we do, as __PERL__ must be at the
        #  bottom of the file.
        #
        debug('found __PERL__ tag');
        $Text_fg='perl';
        $self->implicit(0);
        $self->push_content($HTML_Perl_or=HTML::Element->new('perl', inline => 1));
        debug("insert line_no $Line_no into object ref $HTML_Perl_or");
        @{$HTML_Perl_or}{'_line_no', '_line_no_tag_end'}=($Line_no, $Line_no);
        $HTML_Perl_or->{'_code'}++;

    }
    elsif ($text=~/^\W*__END__/) {


        #  End of file
        #
        debug('found __END__ tag, running eof');
        $self->eof();

    }
    else {

        #  Normal text, process by parent class after handling any subst flags in code
        #
        #if ($text=~/([$|!|+|^|*]+)\{([$|!|+]?)(.*?)\2\}/gs) {
        if ($text=~/([$|!|+|^|*]+)\{([$|!|+]?)(.*?)\2\}/s) {

            #  Meeds subst. Get rid of cr's at start and end of text after a <perl> tag, stuffs up formatting in <pre> sections
            #
            debug("found subst tag line_no_start $Line_no_start, line_no $Line_no, text '$text'");
            my @cr=($text=~/\n/g);
            if (my $html_or=$self->{'_pos'}) {
                debug("parent %s", $html_or->tag());
                if (($html_or->tag() eq 'perl') && !$html_or->attr('inline')) {
                    debug('hit !');

                    #$text=~s/^\n//;
                    #$text=~s/\n$//;
                }
            }

            my $or=HTML::Element->new('subst');
            my $line_no_start=$Line_no;
            debug("insert line_no $Line_no_start, line_no_tag_end $Line_no into object ref $or for text $text, cr %s", scalar @cr);
            @{$or}{'_line_no', '_line_no_tag_end'}=($line_no_start, $Line_no);
            $or->push_content($text);
            $self->tag_parse('SUPER::text', $or)
        }
        else {

            # No subst, process as normal
            #
            debug('processing as normal text');
            $self->tag_parse('SUPER::text', $text)
        }

    }


    #  Return self ref. Not really sure if this is what we should really return, but
    #  seems to work
    #
    $self;

}


sub comment {

    debug('comment');
    my $self=shift()->SUPER::comment(@_);
    debug("insert line_no $Line_no into object ref $self");
    @{$self}{'_line_no', '_line_no_tag_end'}=($Line_no_start, $Line_no);
    $self;

}


sub start_html {

    #  Need to handle this specially ..
    my ($self, $method, $tag, $attr_hr)=@_;
    if ($WEBDYNE_CONTENT_TYPE_HTML_META) {
        $attr_hr->{'head'} ||= &CGI::meta({"http-equiv" => "Content-Type", content => $WEBDYNE_CONTENT_TYPE_HTML})
    }
    my $html=&CGI::start_html_cgi($attr_hr);
    debug("html is $html");
    push @HTML_Wedge, $html;
    $self;
}


sub end_html {

    #  Need to handle this specially ..
    my ($self, $method, $tag, $attr_hr)=@_;
    my $html=&CGI::end_html_cgi($attr_hr);
    debug("html is $html");
    push @HTML_Wedge, $html;
    $self;
}


sub include {


    #  No special handling needed, just log for debugging purposes
    #
    my ($self, $method)=(shift, shift);
    debug("block self $self, method $method, @_ text_fg $Text_fg");
    $self->$method(@_);


}


