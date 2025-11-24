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
package WebDyne::HTML::Tiny;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;


#  Constants, inheritance
#
our $AUTOLOAD;
our @ISA=qw(HTML::Tiny);


#  External Modules
#
use HTML::Tiny;
use CGI::Simple;
use Data::Dumper;
use HTML::Element;


#  WebDyne Modules
#
use WebDyne::Constant;
use WebDyne::Util;


#  Constants
#
use constant {

    URL_ENCODED => 'application/x-www-form-urlencoded',
    MULTIPART   => 'multipart/form-data'

};


#  Package state
#
my %Package;


#  Version information
#
$VERSION='2.034';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Trick to allow use of illegal subroutine name to suppport treebuilder comment format
#
*{'WebDyne::HTML::Tiny::~comment'}=\&_comment;
*{'WebDyne::HTML::Tiny::entity_encode'}=sub { return $_[1] };


#  All done. Positive return
#
return ${&_init()} || err('error running init code');


#==================================================================================================


sub new {


    #  Start new instance
    #
    my ($class, @param)=@_;
    my %param;
    if (ref($param[0]) eq 'HASH') {
        %param=%{$param[0]};
    }
    else {
        %param=@param;
    }
    debug("$class new, %s", Dumper(\%param));
    
    
    #  Were we supplied with a CGI::Simple and/or webdyne object ?
    #
    my $cgi_or=delete $param{'CGI'};
    my $webdyne_or=delete $param{'webdyne'};
    

    #  Shortcuts (start_html, start_form etc.) enabled by default.
    #
    &shortcut_enable() unless
        $param{'noshortcut'}; # no sense before ? was || $Package{'_shortcut_enable'};
        
        
    #  Get HTML::Tiny ref
    #
    my $self=$class->SUPER::new(%param);
    
    
    #  Save away CGI object and return
    #
    ($self->{'_CGI'} ||= $cgi_or) if $cgi_or;
    ($self->{'_webdyne'} ||= $webdyne_or) if $webdyne_or;
    
    
    #  Done
    #
    return $self;

}


sub Vars { 

    #  Get CGI::Simple Vars to ensure we can find values needed to persist choices across form submissions
    #
    my $self=shift();
    debug("$self Vars");
    return ($self->{'_Vars'} ||= $self->CGI()->Vars());    

}


sub CGI {

    
    #  Get CGI::Simple object ref
    #
    my $self=shift();
    debug("$self CGI");
    return ($self->{'_CGI'} ||= CGI::Simple->new());
    
}


sub _init {


    #  Initialise various subs
    #
    *HTML::Tiny::start=\&HTML::Tiny::open || *HTML::Tiny::start;    # || *HTML::Tiny::Start stops warning
    *HTML::Tiny::end=\&HTML::Tiny::close  || *HTML::Tiny::end;      # || as above


    #  Translate CGI.pm shortcut field to HTML::Tiny equiv
    #
    my %type=(
        textfield      => 'text',
        password_field => 'password',
        filefield      => 'file',
        defaults       => 'submit',
        image_button   => 'image',
        button         => 'button'
    );
    

    #  Which tags do we need to persist value ?
    #
    my %persist=(
        textfield	=> 1,
        password_field	=> 1,
        filefield	=> 1
    );


    #  Re-impliment CGI input shortcut tags
    #
    foreach my $tag (qw(textfield password_field filefield button submit reset defaults image_button hidden button)) {
            
        *{$tag}=sub {
            my ($self, $attr_hr, @param)=@_;
            debug("$self $tag, attr_hr: %s", Dumper($attr_hr));
            if (defined($attr_hr)) {
                #  Copy attr so don't pollute ref
                my %attr=%{$attr_hr};
                my $param_hr=$self->Vars();
                if ($persist{$tag}) {
                    if ($attr{'name'} && (my $value=$param_hr->{$attr{'name'}}) && !$attr{'force'}) {
                        $attr{'value'}=$value;
                    }
                }
                return $self->input({type => $type{$tag} || $tag, %attr}, @param);
            }
            else {
                return $self->input({type => $type{$tag} || $tag}, @param)
            }

            }
            unless UNIVERSAL::can(__PACKAGE__, $tag);

    }


    #  Isindex deprecated but reimplement anyway
    #
    foreach my $tag (qw(isindex)) {

        no strict qw(refs);
        *{$tag}=sub {shift()->closed($tag, @_)}
            unless UNIVERSAL::can(__PACKAGE__, $tag);

    }


    #  Done return OK
    #
    return \1;

}


sub shortcut {

    #  Set or return passthough flag which flags us to ignore all start_* methods
    #
    my $self=shift();
    debug("self: $self, shortcut: %s", Dumper(\@_));
    if (@_) {
        return shift() ? $self->shortcut_enable() : $self->shortcut_disable()
    }
    else {
        return $self->{'_shortcut'}
    }

}


sub shortcut_disable {

    no warnings qw(redefine);
    debug('shortcut_disable: %s', Dumper(\@_));
    foreach my $sub (grep {/^(?:_start|_end)/} keys %{__PACKAGE__ . '::'}) {
        (my $sub_start=$sub)=~s/^_//;

        #print "disable $sub_start=>$sub";
        if (my ($action, $tag)=($sub_start=~/^(start|end)_([^:]+)$/)) {

            #print "action: $action, tag: $tag\n";
            *{$sub_start}=sub {shift()->$action($tag, @_)};
        }
    }
    delete $Package{'_shortcut_enable'};
    
    #  || *start_html to remove warnings
    *start_html=sub {shift()->_start_html_bare(@_)} || *start_html

}


sub shortcut_enable {

    no warnings qw(redefine);
    debug('shortcut_enable: %s', Dumper(\@_));
    foreach my $sub (grep {/^(?:_start|_end])/} keys %{__PACKAGE__ . '::'}) {
        (my $sub_start=$sub)=~s/^_//;

        #if ( *{__PACKAGE__ . "::${sub_start}"}{'CODE'} eq \&{$sub} ) {
        #    debug("code for $sub_start exists, skipping");
        #    last;
        #}
        #else {
        #    debug("code for $sub_start needed, creating");
        #}

        debug("enable $sub_start=>$sub, %s", *{__PACKAGE__ . "::${sub_start}"}{'CODE'});
        *{$sub_start}=\&{$sub};
    }
    $Package{'_shortcut_enable'}++;

    #*start_html=\&_start_html_bare;

}


#  Start_html shorcut and include DTD
#
sub _start_html {


    #  Get self ref and any attributes passed
    #
    my ($self, $attr_hr, @param)=@_;
    debug("$self _start_html, attr: %s, param: %s", Dumper($attr_hr, \@param));

    #return $self->SUPER::start_html($attr_hr, @param) if $self->{'_passthrough'};


    #  Attributes we are going to use
    #
    debug('WEBDYNE_START_HTML_PARAM: %s', Dumper($WEBDYNE_START_HTML_PARAM));
    my %attr=(
        %{$WEBDYNE_HTML_PARAM},
        %{$WEBDYNE_START_HTML_PARAM},
        %{$attr_hr}
    );
    debug('attr: %s', Dumper(\%attr));
    #die Dumper(\%attr);


    #  If no attributes passed used defaults from constants file
    #
    #keys %{$attr_hr} || ($attr_hr=$WEBDYNE_HTML_PARAM);


    #  Pull out meta attributes leaving rest presumably native html tag attribs
    #
    #my %attr_page=map {$_=>delete $attr_hr->{$_}} qw(
    my %attr_page=map {$_ => delete $attr{$_}} qw(
        title
        meta
        style
        base
        target
        author
        script
        include
        include_script
        include_style
    );
    debug('start_html %s', Dumper(\%attr_page));


    #  Start with the DTD
    #
    my @html=$WEBDYNE_DTD;


    #  Add meta section
    #
    my @meta;
    if (my $hr=$attr_page{'meta'}) {
        debug('have meta hr: %s', Dumper($hr));
        @meta=$self->meta({content => $attr_page{'meta'}})
    }
    else {
        debug('no meta run');
    }


    #  Logic error below, replaced by above
    #
    #my @meta=$self->meta({ content=>$attr_page{'meta'} })
    #    if $attr_page{'meta'};
    ##debug('meta: %s', Dumper(\@meta));
    ##while (my ($name, $content)=each %{$attr_page{'meta'}}) {
    ##    push @meta, $self->meta({name => $name, content => $content});
    ##}
    #  Used to do this
    #while (my ($name, $content)=each %{$WEBDYNE_META}) {
        #push @meta, $self->meta({$name => $content});

    #}
    #  Now this
    ##push @meta, $self->meta({ content => $WEBDYNE_META }) unless 


    #  Add any stylesheets
    #
    my @link;
    if (my $style=$attr_page{'style'}) {
    
        #  Generate HTML for link tag stylheet
        #
        push @link, $self->_start_html_tag('link', 'href', $style, 
            { rel=>'stylesheet'});

    }
    if (my $include_style=$attr_page{'include_style'}) {

        #  Generate HTML to make an include section for any styles user wants, wrap in <style> tag
        #
        push @link, $self->_start_html_tag('include', 'file', $include_style, 
            { wrap =>'style'});
            
            
        #  Used to do this way but only could do single file
        #
        #my $html_or=HTML::Element->new('include', wrap=>'style', file => $include_style);
        #push @link, $html_or->as_HTML();
    }

    if (my $author=$attr_page{'author'}) {
        $author=$self->url_encode($author);
        my $html_or=HTML::Element->new('link', rel=> 'author', href => sprintf('mailto:%s', $author));
        push @link, $html_or->as_HTML();
    }
    

    #  Scripts
    #
    my @script;
    if (my $script=$attr_page{'script'}) {
    
        #  Script same as style above
        #
        push @script, $self->_start_html_tag('script', 'src', $script);
    }
    if (my $include_script=$attr_page{'include_script'}) {
    
        #  Include script same as style above
        #
        push @script, $self->_start_html_tag('include', 'file', $include_script, 
            { wrap =>'script'});

    }
    
    
    #  Include any other files
    #
    my @include;
    if (my $fn=$attr_page{'include'}) {
    
        
        #  Same as other tags above, generate <include> HTML
        #
        push @include, $self->_start_html_tag('include', 'file', $fn);
        
        
        #  Used to do this way
        #
        #my $html_or=HTML::Element->new('include', file => $fn);
        #push @include, $html_or->as_HTML();
        

        #  Older way was experimental
        #
        #$include=${
        #    $webdyne_or->include({ file=>$fn, head=>1 }) ||
        #        return err();
        #};
        #debug("include: $include");

    }
    else {
        
        #  No included file (which should include default metadata) so add default
        #
        debug('no include file, adding default metadata');
        push @meta, $self->meta({ content => $WEBDYNE_META });
        
    }

    
    
    #  Build title
    #
    my $title;
    unless (@include && (grep {/<title>.*?<\/title>/i} @include)) {
        $title=$attr_page{'title'} || $WEBDYNE_HTML_DEFAULT_TITLE;
    }
    debug('title: %s', $title || '*undef*');
        

    #  Build head, adding a title section, empty if none specified
    #
    my $head=$self->SUPER::head(
        join(
            $/,
            grep {$_}
                #$self->title($attr_page{'title'} ? $attr_page{'title'} : $WEBDYNE_HTML_DEFAULT_TITLE),
                $title && $self->title($title),
            #$title,
            @meta,
            @link,
            @script,
            @include
        ));


    #  Put all together and return
    #
    #push @html, $self->open('html', $attr_hr), $head . $self->open('body');
    push @html, $self->open('html', \%attr), $head . $self->open('body');
    debug('html: %s', Dumper(\@html));
    return join($/, @html);

}


sub _start_html_tag {

    my ($self, $tag, $attr, $param_ar, $attr_hr)=@_;
    my @html;
    unless (ref($param_ar) eq 'ARRAY') {
        $param_ar=[$param_ar];
    }
    if ($WEBDYNE_START_HTML_PARAM_STATIC) {
        $attr_hr->{'static'}=1;
    }
    foreach my $param (@{$param_ar}) {
        my $html_or=HTML::Element->new($tag, $attr=>$param, %{$attr_hr} );
        push @html, $html_or->as_HTML();
    }
    return join('', @html);
    
}
        

sub _end_html {

    #  Stub for WebDyne UNIVERSAL::can to find
    #
    #shift()->SUPER::end_html(@_);
    my ($self, $attr_hr)=@_;
    debug("$self _start_html, attr: %s, param: %s", Dumper($attr_hr, \@_));

    #return $self->SUPER::end_html($attr_hr) if $self->{'_passthrough'};
    my @html;
    push @html, $self->close('body'), $self->close('html');
    return join($/, @html);

    #return shift()->close('html', @_);

}


sub html {

    my $self=shift();
    debug("$self html() param: %s", Dumper(\@_));
    #  Move default attributes into <html> tag unless user has explicitely supplied
    unshift (@_, $WEBDYNE_HTML_PARAM) unless (ref $_[0] eq 'HASH');
    return $WEBDYNE_DTD . $self->SUPER::html(@_);

}


sub head {

    my ($self, $html, @param)=@_;
    #debug("$self head, html:$html, attr:%s", Dumper(\@_));
    debug("$self head, param:%s", Dumper($_[2]));
    $html.=$WEBDYNE_HEAD_INSERT;
    return $self->SUPER::head(grep {$_} ($html, @param));
    
}


sub _start_html_bare {

    #  Special. Called by optimise_two in WebDybe compile instead of start_html above
    #
    my $self=shift();
    debug("$self _start_html_bare param:%s", Dumper(\@_));
    return $WEBDYNE_DTD . $self->SUPER::open('html', @_);
    #return $WEBDYNE_DTD

}


#  Start_form shortcut
#
sub _start_form {

    my ($self, $attr_hr, @param)=@_;
    debug("$self _start_form, attr_hr:%s param:%s", Dumper($attr_hr, \@param));
    my %default=(
        method  => 'post',
        enctype => +URL_ENCODED
    );
    map {$attr_hr->{$_} ||= $default{$_}}
        keys %default;
    return $self->start('form', $attr_hr, @param);

}


#  Start multi-part form shortcut
#
sub _start_multipart_form {
    debug("$_[0] _start_multipart_form");
    return shift()->start_form({enctype => +MULTIPART, %{$_[0] ? shift() : {}}}, @_);
}


sub _end_multipart_form {
    debug("$_[0] _end_multipart_form");
    return shift()->end_form(@_);
}


#  Support CGI comment syntax. See aliasing to ~comment in top section
#
sub _comment {

    my ($self, $attr_hr)=@_;
    debug("$self comment, attr:%s", Dumper($attr_hr));
    return sprintf('<!-- %s -->', $attr_hr->{'text'});

}


#  Meta tag
#
sub meta {

    my ($self, $attr_hr)=@_;
    debug("$self in meta, attr %s", Dumper($attr_hr));
    my @html;
    if (ref(my $meta_hr=$attr_hr->{'content'}) eq 'HASH') {
        debug('meta is HASH');
        
        #  Want to be determenistic so sort keys unless tied
        #
        my @name=keys(%{$meta_hr});
        unless(my $or=tied(%{$meta_hr})) {
            #  Not tied hash to sort keys
            #
            debug('meta hash not tied, sorting');
            @name=sort { $a cmp $b } @name;
        }
        else {
            debug("meta_hr is tied to $or");
        }
        
        #while (my ($name, $content)=each %{$attr_hr->{'content'}}) {
        foreach my $name (@name) {
            my $content=$meta_hr->{$name};
            if ((my ($key, $value)=split(/=/, $name)) == 2) {

                #  Self contained
                #
                debug("split to $key: $value");
                if ($content) {
                    push @html, $self->SUPER::meta({$key => $value, content => $content});
                }
                else {
                    push @html, $self->SUPER::meta({$key => $value});
                }
            }
            else {
                push @html, $self->SUPER::meta({name => $name, content => $content});
            }
        }
    }
    else {
        debug('meta is plain');
        push @html, $self->SUPER::meta($attr_hr)
    }
    return join($/, @html);

}


#  Link tag - expand array into multiple if needed
#
sub link {

    my ($self, $attr_hr)=@_;
    debug("$self link, attr %s", Dumper($attr_hr));
    my @html;
    if (ref($attr_hr->{'href'}) eq 'ARRAY') {
        my %attr=%{$attr_hr};
        my $href_ar=delete $attr{'href'};
        map {push @html, $self->SUPER::link({%attr, href => $_})} @{$href_ar}
    }
    else {
        push @html, $self->SUPER::link($attr_hr)
    }
    return join($/, @html);

}


#  Script tag - same deal
#
sub script {

    my ($self, $attr_hr, @param)=@_;
    debug("$self script, attr %s", Dumper($attr_hr));
    
    
    #  Take copy of attribute hash ref so we don't alter original
    #
    my @html;
    my %attr=%{$attr_hr};
    if ($attr{'src'}) {
    
    
	    #  Convert to array
	    #
        my $script_ar;
        unless (ref($script_ar=$attr{'src'}) eq 'ARRAY') {
            $script_ar=[$script_ar]
        }
        debug('attr_hr: %s, script_ar: %s', Dumper($attr_hr, $script_ar));
        
        #  Iterate over each one
        #
        foreach my $src (@{$script_ar}) {
            debug("src: $src");
            my %src_attr=%attr;
            
            #  Split off any fragments and use them as attributes, e.g. #defer becomes defer, ?foo=bar becomes foo=bar in attr
            my @src=split(/#/, $src);
            $src=$src[0];
            debug("src post split: $src");
            if ($src[1]) {
                debug('split src: %s', Dumper(\@src));
                foreach my $kv (split /&/, $src[1]) {
                    next unless length($kv);
                    if ( $kv =~ /^([^=]+)=(.*)$/ ) {
                        $src_attr{$1}=$2;
                    }
                    else {
                        # no “=” means flag parameter
                        $src_attr{$kv} = [];
                    }
                }
                debug("fragment attr: $src[1] decoded as %s from query_param: %s", Dumper(\%attr, \@src));
            }
            push @html, $self->SUPER::script({%src_attr, src => $src}, @param)
        }
    }
    else {
        push @html, $self->SUPER::script($attr_hr, @param)
    }
    debug('html: %s', Dumper(\@html));
    return join($/, @html);

}


sub _radio_checkbox {


    #  Return a radio or checkboxinput field, adding label tags if needed
    #
    my ($self, $tag, $attr_hr, $html)=@_;
    debug("$self _radio_checkbox, tag:$tag attr_hr:%s", Dumper($attr_hr));
    my %attr=%{$attr_hr};
    if (my $label=delete $attr{'label'}) {
        return $self->label($self->input({type => $tag, %attr}) . join('', grep {$_} $html, $label));
    }
    else {
        return $self->input({type => $tag, %attr}) . $html;
    }

}


#  Checkbox group
#
sub _radio_checkbox_group {


    #  Build a checkbox or radio group
    #
    my ($self, $tag, $attr_hr)=@_;
    debug("$self _radio_checbox_group tag:$tag attr: %s", Dumper($attr_hr));
    my %attr=%{$attr_hr};


    #  Get hash ref of any existing CGI param
    #
    my $param_hr=($self->{'_Vars'} ||= $self->Vars()) ||
        return err('unable able to CGI::Simple Vars');


    #  Hold generated HTML in array until end
    #
    my @html;


    #  Convert arrays of default values (i.e checked/enabled) and any disabled entries into hash - easier to check
    #
    my %attr_group;
    foreach my $attr (qw(defaults checked disabled)) {
        map {$attr_group{$attr}{$_}=1} @{(ref($attr{$attr}) eq 'ARRAY') ? $attr{$attr} : [$attr{$attr}]}
            if $attr{$attr};
    }


    #  If values is a hash not an array then convert to array and use hash as values
    #
    if (ref($attr{'values'}) eq 'HASH') {


        #  It's a hash - use as labels, and push keys to values
        #
        $attr{'labels'}=(my $hr=delete $attr{'values'});
        $attr{'values'}=[keys %{$hr}]

    }


    #  Make sure checked values persist by default unless "force" attribute used to override
    #
    if ($attr_hr->{'name'} && (my $checked=$param_hr->{$attr_hr->{'name'}}) && !$attr_hr->{'force'}) {

        #  The tag has a name, and has some selected (checked) values from a form submision. Map the submitted values 
        #  into the checked attribute, splitting on \0 as per spec
        #
        $attr_group{'checked'} = { map { $_=>1 } (split(/\0/, $checked)) }

    }
    else {

        #  Convert 'defaults' key to 'selected'
        #
        do {$attr_group{'checked'} ||= (delete($attr_group{'default'}) || delete($attr_group{'defaults'}))}
            if ($attr_group{'default'} || $attr_group{'defaults'});
            
    }


    #  Radio groups can only have one option checked. If multiple discard and only use first one in alphabetical order
    #
    if ($tag eq 'radio') {
        #%{$attr_group{'defaults'}}=map {$_ => $attr_group{'defaults'}{$_}} ([sort keys %{$attr_group{'defaults'}}]->[0])
        #    if $attr_group{'defaults'};
        %{$attr_group{'checked'}}=map {$_ => $attr_group{'checked'}{$_}} ([sort keys %{$attr_group{'checked'}}]->[0])
            if $attr_group{'checked'};
    }


    #  Now iterate and build actual tag, push onto HTML array
    #
    foreach my $value (@{$attr{'values'}}) {
        my %attr_tag=$attr{'attributes'}{$value}
            ?
            (%{$attr{'attributes'}{$value}})
            :
            ();
        $attr_tag{'name'}=$attr{'name'} if $attr{'name'};
        $attr_tag{'value'}=$value;

        #  Note use of empty array for checked and disabled values as per HTML::Tiny specs
        #$attr_tag{'checked'}=[]  if $attr_group{'defaults'}{$value};
        $attr_tag{'checked'}=[]  if $attr_group{'checked'}{$value};
        $attr_tag{'disabled'}=[] if $attr_group{'disabled'}{$value};
        $attr_tag{'label'}=$attr{'labels'}{$value} ? $attr{'labels'}{$value} : $value;
        push @html, $self->_radio_checkbox($tag, \%attr_tag);
    }


    #  Return, separating with linebreaks if that is what is wanted.
    #
    return join($attr{'linebreak'} ? $self->br() : '', @html);

}


sub checkbox_group {
    debug("$_[0] checkbox_group");
    return shift()->_radio_checkbox_group('checkbox', @_)
}


sub radio_group {
    debug("$_[0] radio_group");
    return shift()->_radio_checkbox_group('radio', @_)
}


sub checkbox {
    

    #  Bit more complex
    #
    my ($self, $attr_hr, @html)=@_;
    debug("$self checkbox, attr_hr:%s", Dumper($attr_hr));
    
    
    #  Mirror attributes so if we change we don't alter originals
    #
    my %attr=%{$attr_hr};


    #  Get hash ref of any existing CGI param
    #
    my $param_hr=($self->{'_Vars'} ||= $self->Vars()) ||
        return err('unable able to CGI::Simple Vars');

    
    #  Massage to set default value of "1" for checkboxes if no value
    #  attr found. If one is found assume user knows what they are doing
    #
    unless (my $value=$attr_hr->{'value'}) {
        if (my $name=$attr_hr->{'name'}) {
        
            #  Add hidden field with same name but 0 value
            #
            debug("using hidden field for checkbox: $name, setting checked value to 1 if selected");
            push @html, $self->hidden({ name=>$name, value=>0, force=>1 });
            
            
            #  Set value of this checkbox (if checked) to 1
            #
            $attr{'value'}=1;
            
            
            #  Add up all values for this checkbox now.
            #
            my $checked;
            if (my $value=$param_hr->{$name}) {
                map { $checked+=int($_) } split(/\0/, $value);
            }
            
            
            #  Run checkbox logic
            #
            if(exists($param_hr->{$name}) && $checked) {
            
                debug("param name:$name exists and is checked, setting checked to true");
                $attr{'checked'}=[];
                
            }
            elsif(exists($param_hr->{$name}) && !$checked) {
                
                debug("param name:$name exists but is not defined, clearing checked attribute");
                delete $attr{'checked'};
                
            }
            else {
                
                debug("no $name param, using tag default: %s", $attr{'checked'} ? 'checked=1' : '<unchecked>');
                
            }
        }
        else {
        
            debug('no name attr');
            
        }
    }
    else {
    
        #  Custom value
        #
        debug("custom value: $value, checkbox logic bypassed");
        
    }
    
    
    #  Done, return result
    #
    #return shift()->_radio_checkbox('checkbox', @_)
    #return $self->_radio_checkbox('checkbox', grep {$_} $attr_hr, @_) . join(undef, grep {$_} @html);
    debug('calling radio_checkbox');
    return $self->_radio_checkbox('checkbox', \%attr, join('', @html))
}


#  Popup menu or scrolling list
#
sub popup_menu {


    #  Build a checkbox or radio group
    #
    my ($self, $attr_hr)=@_;
    my %attr_select=%{$attr_hr};
    debug("$self popup_menu, attr_hr:%s", Dumper($attr_hr));
    
    
    #  Get hash ref of any existing CGI param
    #
    my $param_hr=($self->{'_Vars'} ||= $self->Vars()) ||
        return err('unable able to CGI::Simple Vars');


    #  Hold generated HTML in array until end
    #
    my @html;


    #  If values is a hash not an array then convert to array and use hash as values
    #
    if (ref($attr_select{'values'}) eq 'HASH') {


        #  It's a hash - use as labels, and push keys to values
        #
        $attr_select{'labels'}=(my $hr=delete $attr_select{'values'});
        $attr_select{'values'}=[keys %{$hr}]

    }

    #  Convert arrays of default values (i.e checked/enabled) and any disabled entries into hash - easier to check
    #
    my %attr_option=(
        values     => delete $attr_select{'values'},
        attributes => delete $attr_select{'attributes'},
        labels     => delete $attr_select{'labels'}
    );


    #  Carefully handle options
    #
    foreach my $attr (qw(default selected disabled)) {

        next unless exists $attr_select{$attr};
        my @values;
        if (ref($attr_select{$attr}) eq 'ARRAY') {
            @values=@{$attr_select{$attr}}
        }
        else {
            #  Single value
            @values=(grep {$_} $attr_select{$attr})
        }

        unless ($attr eq 'disabled') {
            foreach my $value (@values) {
                debug("value $value");
                $attr_option{$attr}{$value}=1;
            }
            delete $attr_select{$attr};
        }
        else {    # handle disabled attr carefully
            if (@values) {
                foreach my $value (@values) {
                    $attr_option{$attr}{$value}=1;
                }
                delete $attr_select{$attr};
            }
            else {
                $attr_select{$attr}=[];
            }
        }
    }


    #  Debug
    #
    debug('in popup_menu attr_option: %s', Dumper(\%attr_option));
    
    
    #  Make sure selected values persist by default unless "force" attribute used to override
    #
    if ($attr_hr->{'name'} && (my $selected=$param_hr->{$attr_hr->{'name'}}) && !$attr_hr->{'force'}) {

        #  The tag has a name, and has some selected (checked) values from a form submision. Map the submitted values 
        #  into the selected field, splitting on \0 as per spec
        #
        $attr_option{'selected'} = { map { $_=>1 } (split(/\0/, $selected)) }

    }
    else {

        #  Convert 'defaults' key to 'selected'
        #
        do {$attr_option{'selected'} ||= (delete($attr_option{'default'}) || delete($attr_option{'defaults'}))}
            if ($attr_option{'default'} || $attr_option{'defaults'});
            
    }

    #  If disabled option is an array but is empty then it is meant for the parent tag
    #
    #if ($attr_option{'disabled'} && !@{$attr_option{'disabled'}}) {
    #if ($attr_option{'disabled'} && !@{$attr_options{'disabled'}}) {
    #if (exists $attr_option{'disabled'} && !(keys %{$attr_option{'disabled'}})) {

    #  Yes, it is empty, so user wants whole option disabled
    #
    #    debug('disable entire popup_menu');
    #    $attr_select{'disabled'}=[]

    #}
    #else {

    #    debug('deleting attr_select disabled attr');
    #    delete $attr_select{'disabled'};

    #}

    #map { delete $attr_select{$_} } (qw(default selected disabled));


    #  Fix multiple tag if true
    #
    $attr_select{'multiple'}=[] if $attr_select{'multiple'};

    #map { delete $attr_select{$_} } (qw(default selected disabled));
    debug('in popup_menu attr_select: %s', Dumper(\%attr_select));


    #  Now iterate and build actual tag, push onto HTML array
    #
    foreach my $value (@{$attr_option{'values'}}) {
        my %attr_tag=$attr_option{'attributes'}{$value}
            ?
            (%{$attr_option{'attributes'}{$value}})
            :
            ();
        $attr_tag{'value'}=$value;

        #  Note use of empty array for checked and disabled values as per HTML::Tiny specs
        $attr_tag{'selected'}=[] if $attr_option{'selected'}{$value};
        $attr_tag{'disabled'}=[] if $attr_option{'disabled'}{$value};
        my $label=$attr_option{'labels'}{$value} ? $attr_option{'labels'}{$value} : $value;

        #if ($label) {
        #    push @html, $self->label($self->option(\%attr_tag) . $label);
        #}
        #else {
        debug("pushing option tag with label: $label, attr_tag: %s", Dumper(\%attr_tag));
        push @html, $self->option(\%attr_tag, $label)

        #}
    }


    #  Return
    #
    debug('creating select group with attr: %s, options:%s', Dumper(\%attr_select, \@html));
    return $self->select(\%attr_select, join($/, @html));

}


sub scrolling_list {

    #  Only difference between popup_menu and scrolling list is size attrribute, which we calculate  -if
    #  supplied will overwrite calculated value
    #
    my ($self, $attr_hr, @param)=@_;
    debug("self $self scrolling_list, attr_hr: %s", Dumper($attr_hr));
    my $size=(ref($attr_hr->{'values'}) eq 'ARRAY') ? scalar @{$attr_hr->{'values'}} : scalar keys %{$attr_hr->{'values'}};
    #return shift()->popup_menu({size => scalar @{$_[0]->{'values'}}, %{shift()}}, @_);
    return $self->popup_menu({size => $size, %{$attr_hr}}, @param);

}


sub textarea {

    #  Slightly different handling for textarea
    #
    my ($self, $attr_hr, @param)=@_;
    debug("self $self textarea, attr_hr: %s", Dumper($attr_hr));


    #  Get hash ref of any existing CGI param
    #
    my $param_hr=($self->{'_Vars'} ||= $self->Vars()) ||
        return err('unable able to CGI::Simple Vars');
        
        
    #  Copy attr_hr so don't mangle original
    #
    my %attr=%{$attr_hr};
        

    #  Make sure entered text persists unless force in effect
    #
    my $content=delete($attr{'default'});
    if ($attr{'name'} && (my $entered=$param_hr->{$attr{'name'}}) && !$attr{'force'}) {

        #  The tag has a name, and has some already entered text. That wins
        #
        $content=$entered

    }
    
    
    #  Have enough to build now
    #
    return $self->SUPER::textarea(grep {$_} \%attr, $content);
    
}


sub AUTOLOAD {
    if (my ($action, $tag)=($AUTOLOAD=~/\:\:(start|end|open|close)_([^:]+)$/)) {
        *{$AUTOLOAD}=sub {shift()->$action($tag, @_)};
        return &{$AUTOLOAD}(@_);
    }
}
