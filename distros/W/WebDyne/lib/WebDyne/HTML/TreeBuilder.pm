#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::HTML::TreeBuilder;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %CGI_TAG_WEBDYNE %CGI_TAG_FORM %CGI_TAG_IMPLICIT %CGI_TAG_SPECIAL);
use warnings;
no warnings qw(uninitialized redefine once);


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::HTML::Tiny;
use WebDyne::Util;


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
$VERSION='2.017';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Form based tags we don't want to compile as their value may change if keeping state
#
%CGI_TAG_FORM=map {$_ => 1} (qw(

        textfield
        textarea
        password_field
        checkbox
        checkbox_group
        radio_group
        popup_menu
        scrolling_list

));


#  Make a hash of our implictly closed tags.
#
%CGI_TAG_IMPLICIT=map {$_ => 1} (keys(%CGI_TAG_FORM), qw(

        filefield
        hidden
        submit
        reset
        defaults
        image_button
        start_form
        end_form
        start_multipart_form
        end_multipart_form
        isindex
        dump
        include
        json
        api

));


#  Update - get from CGI module, add special dump tag
#
#%CGI_TAG_IMPLICIT=map {$_ => 1} (
#
#    @{$CGI::EXPORT_TAGS{':form'}},
#    'dump'
#D#
#);
#delete @CGI_TAG_IMPLICIT{qw(
#    button
#)};


#  Get WebDyne tags from main module
#
%CGI_TAG_WEBDYNE=%WebDyne::CGI_TAG_WEBDYNE;


#  The tags below need to be handled specially at compile time - see the method
#  associated with each tag below.
#
#map {$CGI_TAG_SPECIAL{$_}++} qw(perl script style start_html end_html include);
map {$CGI_TAG_SPECIAL{$_}++} qw(perl script style start_html end_html include div api json);


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


#  All done. Positive return
#
1;


#==================================================================================================


sub new {

    my $class=shift();
    debug('in %s new(), class: %s', __PACKAGE__, ref($class) || $class);
    my $self=$class->SUPER::new(@_) ||
        return err('unable to initialize from %s, using ISA: %s', ref($class) || $class, Dumper(\@ISA));
    $self->{'_html_tiny_or'}=
        WebDyne::HTML::Tiny->new(mode => 'html', @_);
    return $self;

}


sub parse_fh {


    #  Get self ref, file handle
    #
    my ($tree_or, $html_fh)=@_;
    debug("parse $html_fh");


    #  Delete any left over wedge segments
    #
    delete $tree_or->{'_html_wedge_ar'};


    #  Read over file handle until we get to the first non-comment line (ignores auto added copyright statements)
    #
    while (1) {
        my $pos=tell($html_fh);
        my $line=<$html_fh>;
        if ($line=~/^#/) {
            ($tree_or->{'_line_no'} ||= 0)++;
            $tree_or->{'_line_no_next'}=$tree_or->{'_line_no'}+1;
            next;
        }
        else {
            seek($html_fh, $pos, 0);
            last;
        }
    }


    #  Return closure code ref that understands how to count line
    #  numbers and wedge in extra code
    #
    my $parse_cr=sub {


        #  Read in lines of HTML, allowing for "wedged" bits, e.g. from start_html
        #
        my $line;
        my $html=@{$tree_or->{'_html_wedge_ar'}} ? shift @{$tree_or->{'_html_wedge_ar'}} : ($line=<$html_fh>);
        if ($line) {
            debug("line *$line*");
            my @cr=($line=~/\n/g);
            $tree_or->{'_line_no'}=($tree_or->{'_line_no_next'} || 1);
            $tree_or->{'_line_no_next'}=$tree_or->{'_line_no'}+@cr;
            debug("Line %s, Line_no_next %s, Line_no_start %s cr %s", @{$tree_or}{qw(_line_no _line_no_next _line_no_start)}, scalar @cr);
        }


        #  To this or last line not processed by HTML::Parser properly (in one chunk) if no CR
        #
        if ($html_fh->eof() && $html) {
            debug("add CR at EOF");
            $html.=$/ unless $html=~/(?:\r?\n|\r)$/;
        }


        #  Done, return HTML
        #
        return $html;

    };
    return $parse_cr;

}


sub delete {


    #  Destroy tree, reset any globals
    #
    my $self=shift();
    debug('delete');


    #  Reset script and line number vars
    #
    delete $self->{'_html_wedge_ar'};


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
    debug("tag_parse $method, *%s*, line_no: %s, line_no_start: %s, attr_hr:%s ", $tag, @{$self}{qw(_line_no _line_no_start)}, Dumper($attr_hr));


    #  Get the parent tag
    #
    my $pos;
    my $tag_parent=(
        $pos=$self->{'_pos'} || $self
    )->{'_tag'};
    debug("tag $tag, tag_parent $tag_parent");
    
    
    #  Is chomp detected ?
    #
    if (delete $attr_hr->{'chomp'}) {
    
        #  Yes, flag for later processing
        #
        debug('chomp attribute detected, setting flag');
        $self->{'_chomp'}++;
        
    }


    #  Var to hold returned html element object ref
    #
    my $html_or;


    #  If it is an below an implicit parent tag close that tag now.
    #
    #if ($CGI_TAG_IMPLICIT{$tag_parent} || $tag_parent=~/^start_/i || $tag_parent=~/^end_/i) {
    if ($CGI_TAG_IMPLICIT{$tag_parent} || ($tag_parent=~/^(?:start_|end_)/i)) {

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
        $html_or=$self->$method(@_);

    }


    #  Same for body tag as above
    #
    elsif ($CGI_TAG_WEBDYNE{$tag_parent} && ($tag eq 'body')) {

        debug("found $tag_parent above $tag, modifying tree");
        $self->{'_body'}->preinsert($pos);
        $self->{'_body'}->detach();
        $pos->push_content($self->{'_body'});
        $html_or=$self->$method(@_);

    }


    #  If it is an custom webdyne tag, massage with methods below
    #  before processing
    #
    elsif ($CGI_TAG_SPECIAL{$tag} && ($method ne 'SUPER::text')) {


        #  Yes, is WebDyne tag
        #
        debug("webdyne tag_special ($tag) dispatch");
        $html_or=$self->$tag($method, $tag, $attr_hr);

    }


    elsif ((my ($modifier, $tag_actual)=($tag=~/^(start_|end_)(.*)/i)) && ($method ne 'SUPER::text')) {


        #  Yes, is WebDyne tag
        #
        debug("webdyne tag start|end ($tag) dispatch, method $method");
        if ($modifier=~/end_/) {
            debug('end tag so changing method to SUPER::end');
            $method='SUPER::end'
        }

        #if (UNIVERSAL::can('WebDyne::HTML::Tiny', $tag) {
        $html_or=$self->tag_parse($method, $tag_actual, $attr_hr);


    }


    #  If it is an custom CGI tag that we need to close implicityly
    #
    #elsif ($CGI_TAG_IMPLICIT{$tag_parent} || $tag=~/^start_/i || $tag=~/^end_/) {
    elsif ($CGI_TAG_IMPLICIT{$tag_parent}) {


        #  Yes, is CGI tag
        #
        debug("webdyne tag_implicit ($tag) dispatch");
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
    debug("insert line_no: %s, line_no_start: %s into object ref $html_or", @{$self}{qw(_line_no _line_no_start)});
    ref($html_or) && (@{$html_or}{'_line_no', '_line_no_tag_end'}=(@{$self}{qw(_line_no_start _line_no)}));


    #  Returm object ref
    #
    $html_or;


}


sub block {


    #  No special handling needed, just log for debugging purposes
    #
    my ($self, $method)=(shift, shift);
    debug("block self $self, method $method, *%s* text_block_tag %s", join('*', @_), $self->_text_block_tag());
    $self->$method(@_);

}


sub script {

    my ($self, $method, $tag, $attr_hr, @param)=@_;
    debug("$self script, attr: %s", Dumper($attr_hr));
    my $script_or=$self->$method($tag, $attr_hr, @param);
    if ($attr_hr->{'type'} eq 'application/perl') {

        my $perl_or=HTML::Element->new('perl', inline => 1);
        push @{$self->{'_script_stack'}}, [$script_or, 'perl', $perl_or];
        debug('perl script !');

    }
    else {

        push @{$self->{'_script_stack'}}, undef;
        $self->_text_block_tag('script') unless $self->_text_block_tag();
    }

    #$self->$method($tag, $attr_hr, @param);
    return $script_or;

}


sub json {


    #  No special handling needed, just log for debugging purposes
    #
    my ($self, $method, @param)=@_;
    $self->_text_block_tag('json') unless $self->_text_block_tag();
    debug("json self $self, method $method text_block_tag %s", $self->_text_block_tag());
    return $self->$method(@param);

}


sub api {


    #  Handle normally but set flag showing we are an <api> page, will optimise differently
    #
    my ($self, $method, @param)=@_;
    debug("api self $self, method $method");
    $self->{'_api_webdyne'}++;
    return $self->$method(@param);

}


sub style {

    my ($self, $method)=(shift, shift);
    debug('style');
    $self->_text_block_tag('style') unless $self->_text_block_tag();
    return $self->$method(@_);

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
        unless (grep {exists $attr_hr->{$_}} qw(package method handler)) {
            $html_perl_or->attr(inline => ++$inline);
        }
    }
    if ($inline) {

        #  Inline tag, set global var to this element so any extra text can be
        #  added here
        #
        $self->_html_perl_or($html_perl_or);
        $self->_text_block_tag('perl') unless $self->_text_block_tag();


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
    my $html_or=HTML::Element->new('perl', inline => 1, perl => $text);
    debug("insert line_no: %s into object ref $html_or", $self->{'_line_no'});
    @{$html_or}{'_line_no', '_line_no_tag_end'}=@{$self}{qw(_line_no_start _line_no)};
    $self->tag_parse('SUPER::text', $html_or)

}


sub start {


    #  Ugly, make sure if in perl or script tag, whatever we see counts
    #  as text
    #
    my ($self, $tag)=(shift, shift);
    my $text=$_[2];
    ref($tag) || ($tag=lc($tag));
    debug("$self start tag '$tag' line_no: %s, %s", $self->{'_line_no'}, Dumper(\@_));
    
    my $html_or;
    if ($self->_text_block_tag()) {
        $html_or=$self->text($text)
    }
    else {
        my @cr=($text=~/\n/g);
        $self->{'_line_no_start'}=$self->{'_line_no'}-@cr;
        debug("tag $tag line_no: %s, line_no_start: %s", @{$self}{qw(_line_no _line_no_start)});
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
    debug("$self end tag: %s,%s text_block_tag: %s, line_no: %s", Dumper($tag, \@_), $self->_text_block_tag(), $self->{'_line_no'});
    
    
    #  Var to hold HTML::Element ref if returned, but most methods don't seem to return a HTML ref, just an integer ?
    #
    my $ret;


    #  Div tag gets handles specially as start tag might have been a webdyne tag aliases into a div tag (see div tag for more details)
    #
    if ($tag eq 'div') {

        #  Hit on div, check
        #
        debug("hit on div tag: $tag");


        #  Can we pop an array ref off div_stack ? If so means was webdyne tag
        #
        #if (my $div_ar=pop(@div_stack)) {
        if (my $div_ar=pop(@{$self->{'_div_stack'}})) {


            #  Yes, separate out to components stored by div subroutine
            #
            my ($div_or, $webdyne_tag, $webdyne_tag_or)=@{$div_ar};
            debug("popped div tag: $div_or, %s, about to end webdyne tag: $webdyne_tag (%s)", $div_or->tag(), $webdyne_tag_or->tag());


            #  Set the Text_fg to whatever the webdyne tag was (e.g. perl, etc), that way they will see a match and
            #  turn off text mode. NOTE: Not sure this works ?
            #
            $self->_text_block_tag($webdyne_tag_or->tag()) if $self->_text_block_tag();
            debug("text_block_tag now %s, ending $webdyne_tag", $self->_text_block_tag());
            $self->SUPER::end($webdyne_tag, @_);

            #  Now end the original div tag
            #
            debug("ending $tag now");
            $ret=$self->SUPER::end($tag, @_);


            #  Can now unset text flag. See NOTE above, need to check this
            #
            $self->_text_block_tag(undef);


            #  Now replace div tag with webdyne output unless a wrap attribute exists or class etc. given - in which
            #  case the output will be wrapped in that tag and any class, style or id tags presevered
            #
            my @div_attr_name=grep {$div_or->attr($_)} qw(class style id);
            if ((my $tag=$div_or->attr('wrap')) || @div_attr_name) {

                #  Want to wrap output in another tag or use <div> if class etc. given but no tag
                #
                $tag ||= 'div';
                $webdyne_tag_or->push_content($div_or->detach_content());
                my %tag_attr=(
                    map {$_ => $div_or->attr($_)}
                        @div_attr_name
                );
                debug("tag: $tag, tag_attr: %s", Dumper(\%tag_attr));
                my $tag_or=HTML::Element->new($tag, %tag_attr);
                $tag_or->push_content($webdyne_tag_or);
                $div_or->replace_with($tag_or);

            }
            else {
                $webdyne_tag_or->push_content($div_or->detach_content());
                $div_or->replace_with($webdyne_tag_or);
            }
            return $ret;

        }
        else {


            #  Vanilla div tag, nothing to do
            #
            debug('undef pop off div stack');
            return $ret=$self->SUPER::end($tag, @_);
        }
    }
    elsif ($tag eq 'script') {


        #  Script tag, presumably of type application/perl
        #
        debug('hit on script tag');


        #  Can we pop an array ref off script_stack ? If so means was webdyne tag
        #
        if (my $script_ar=pop(@{$self->{'_script_stack'}})) {


            #  Get vars from array ref
            #
            my ($script_or, $perl_tag, $perl_tag_or)=@{$script_ar};
            debug("popped script tag: $script_or, %s, about to end perl tag: $perl_tag (%s)", $script_or->tag(), $perl_tag_or->tag());


            #  End perl tag
            #
            debug("end $perl_tag now");
            $self->_text_block_tag($perl_tag_or->tag()) if $self->_text_block_tag();
            debug("text_block_tag now %s, ending $perl_tag", $self->_text_block_tag());
            $self->SUPER::end($perl_tag, @_);


            #  End script tag
            #
            debug("end $tag now");
            $self->SUPER::end($tag, @_);
            $self->_text_block_tag(undef);


            #  Re-arrange tree
            #
            debug('script content %s', Dumper($script_or->content_list));

            #$perl_tag_or->push_content($script_or->detach_content());
            $perl_tag_or->attr('perl', $script_or->detach_content());
            $script_or->replace_with($perl_tag_or);
            return 1;

        }
        elsif (0) {

            debug('null script stack pop, ignoring');
            $self->_text_block_tag(undef);
            return $ret=$self->SUPER::end($tag, @_);
        }
    }


    if ($self->_text_block_tag() && ($tag eq $self->_text_block_tag())) {
        debug("match on tag $tag to text_block_tag %s, clearing text_block_tag", $self->_text_block_tag());
        $self->_text_block_tag(undef);
        $ret=$self->SUPER::end($tag, @_)
    }
    elsif ($self->_text_block_tag()) {
        debug('text segment via text_block_tag %s, passing to text handler', $self->_text_block_tag());
        $ret=$self->text($_[0])
    }
    elsif (!$_[0] && delete($self->{'_end_ignore'})) {
        #  In this case $_[0] is the actual text of the end tag from the document. If the parser is signalling and end of a tag
        #  but $_[0] is empty it means it is an implicit close. We might want to ignore it, especially if it is triggered by a
        #  <div data-webdyne-perl> type tag.
        debug("attempt to close tag: $tag with active _div_stack, ignoring");
        $ret=undef;
    }
    else {
        debug("normal tag end");
        $ret=$self->SUPER::end($tag, @_)
    }


    #  Done, return
    #
    debug("end ret $ret");
    return $ret;


}


#  Reminder to self. Keep this in, or implicit CGI tags will not be closed
#  if text block follows implicit CGI tag immediately
#
sub text {


    #  get self ref, text we will process
    #
    my ($self, $text)=@_;
    debug('text *%s*, text_block_tag %s, pos: %s', $text, $self->_text_block_tag(), $self->{'_pos'});
    
    
    #  Are we chomping text ?
    #
    if (delete $self->{'_chomp'}) {
    
        #  Yes. It's actually includes a "pre-chomp" as newline will be at start of the string
        #
        debug('chomp flag detected, chomping text');
        $text=~s/^\n//;

    }


    #  Ignore empty text. UPDATE - don't ignore or you will mangle CR in <pre> sections, especially if they contain tags
    #  like <span> in the <pre> section. Process and keep them inline. See also fact that trailing and leading CR's are
    #  converted to space characters by HTML::Parser as per convention.
    #
    #  Leave this here as a reminder.
    #
    #return if ($text =~ /^\r?\n?$/);


    #  Are we in an inline perl block ?
    #
    if ($self->_text_block_tag() eq 'perl') {


        #  Yes. We have inline perl code, not text. Just add to perl attribute, which
        #  is treated specially when rendering
        #
        debug('in __PERL__ tag, appending text to __PERL__ block');
        my $html_perl_or=$self->_html_perl_or();
        $html_perl_or->{'perl'}.=$text;
        $html_perl_or->{'_line_no_tag_end'}=$self->{'_line_no'};


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
        $self->_text_block_tag('perl');
        $self->implicit(0);

        my $html_perl_or;
        $self->push_content($self->_html_perl_or($html_perl_or=HTML::Element->new('perl', inline => 1)));
        debug('insert line_no: %s into object ref: %s', @{$self}{qw(_line_no _html_perl_or)});
        @{$html_perl_or}{qw(_line_no _line_no_tag_end)}=@{$self}{qw(_line_no _line_no)};
        $html_perl_or->{'_code'}++;
        

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
        if ($text=~/([\$!+\^*]+)\{([\$!+]?)(.*?)\2\}/s) {

            #  Meeds subst. Get rid of cr's at start and end of text after a <perl> tag, stuffs up formatting in <pre> sections
            #
            debug("found subst tag line_no_start: %s, line_no: %s, text '$text'", @{$self}{qw(_line_no_start _line_no)});
            my @cr=($text=~/\n/g);
            if (my $html_or=$self->{'_pos'}) {
                debug("parent %s", $html_or->tag());
                if (($html_or->tag() eq 'perl') && !$html_or->attr('inline')) {
                    debug('hit !');

                    #  Why did I comment this out ?
                    #
                    #$text=~s/^\n//;
                    #$text=~s/\n$//;
                }
            }

            my $html_or=HTML::Element->new('subst');
            debug("insert line_no: %s, line_no_tag_end: %s into object ref $html_or for text $text, cr %s", @{$self}{qw(_line_no_start _line_no)}, scalar @cr);
            @{$html_or}{'_line_no', '_line_no_tag_end'}=@{$self}{qw(_line_no _line_no)};
            $html_or->push_content($text);
            $self->tag_parse('SUPER::text', $html_or)
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

    #  Handle comments in HTML. Get HTML::Element ref
    #
    my $self=shift();
    my $html_or=$self->SUPER::comment(@_);
    debug("$self html_or: $html_or comment: %s", Dumper(\@_));


    #  Change tag to 'comment' from '~comment' so we can call comment render sub in WebDyne::HTML::Tidy (can't call sub starting with ~ in perl)
    #
    #$self->tag('comment'); # No longer needed, make ~comment sub work in WebDyne::HTML::Tiny
    debug("insert line_no: %s into object ref $self", $self->{'_line_no'});
    @{$html_or}{qw(_line_no _line_no_tag_end)}=@{$self}{qw(_line_no_start _line_no)};
    return $html_or

}


sub start_html {

    my ($self, $method, $tag, $attr_hr)=@_;
    push @{$self->{'_html_wedge_ar'}}, (my $html=$self->{'_html_tiny_or'}->$tag($attr_hr));
    return $self;

}


sub end_html {
    &start_html(@_);
}


sub include {


    #  No special handling needed, just log for debugging purposes
    #
    my ($self, $method)=(shift, shift);
    debug("block self $self, method $method, @_ text_block_tag %s", $self->_text_block_tag());
    $self->$method(@_);


}


sub div {


    #  Handle div tag specially, looking if they hold any webdyne aliases
    #
    my ($self, $method, $tag, $attr_hr, @param)=@_;
    debug("$self in $tag, method:$method attr:%s", Dumper($attr_hr));


    #  Get the div tag HTML::Element ref. Note now do this later in (if) blocks because it triggeres
    #  auto-close if implicit tags like <p>, which we want to flag and stop happening if it's a webdyne
    #  flag
    #
    #my $div_or=$self->$method($tag, $attr_hr, @param) ||
    #    return err('unable to get HTML::Element ref for div tag: $tag, attr:%s', Dumper($attr_hr));


    #  Do we have a pseudo webdyne command aliased in a div tag with a "data-webdyne" attributre  (usually to keep a HTML editor happy
    #  because it doesn't know anything about native webdyne tags
    #
    if (my @tag=grep {/^data-webdyne-/} keys %{$attr_hr}) {
    
    
        #  Set end_ignore flag to ignore parser trying to auto-close <p> etc. when we run this tag
        #
        $self->{'_end_ignore'}++;
        my $div_or=$self->$method($tag, $attr_hr, @param) ||
            return err('unable to get HTML::Element ref for div tag: $tag, attr:%s', Dumper($attr_hr));


        #  Yes, we have one, get it
        #
        my $webdyne_tag=$tag[0];


        #  And delete it from attribute list so it doesn't pollute, strip off data-webdyne lead
        #
        delete $attr_hr->{$webdyne_tag};
        $webdyne_tag=~s/^data-webdyne-//;
        debug("found webdyne tag $webdyne_tag in div");

        #  Convert to a start tag for HTML Tiny
        #
        my $html_tiny_tag="start_${webdyne_tag}";


        #  Var to hold HTML::Element version of tag
        #
        debug("generating $html_tiny_tag");
        my $webdyne_tag_or=$self->tag_parse('SUPER::start', $webdyne_tag, $attr_hr, @param) ||
            return err("unable to create HTML::Element ref for tag:$webdyne_tag, attr_hr:%s", Dumper($attr_hr));


        #  Now push onto div stack and return div HTML::Element ref
        #
        push @{$self->{'_div_stack'}}, [$div_or, $webdyne_tag, $webdyne_tag_or];
        return $div_or;

    }
    else {

        #  Normal div tag, push undef onto stack to denote vanilla
        #
        debug('hit on vanilla div tag');
        my $div_or=$self->$method($tag, $attr_hr, @param) ||
            return err('unable to get HTML::Element ref for div tag: $tag, attr:%s', Dumper($attr_hr));
        push @{$self->{'_div_stack'}}, undef;
        return $div_or;

    }

}


#  Getter setter. Not used for line numbers yet, prep for future cleanup
#
sub _get_set {

    my ($key, $self, $value)=@_;
    return (@_==3) ? $self->{$key}=$value : $self->{$key}
    
}

map { eval("sub $_ { &_get_set($_, \@_) }") }  qw(_text_block_tag _line_no _line_no_next _line_no_start _html_perl_or);


#  Done
#
1;
