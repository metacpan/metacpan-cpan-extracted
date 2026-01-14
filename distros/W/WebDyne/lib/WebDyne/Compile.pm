#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Compile;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION %CGI_TAG_WEBDYNE %CGI_TAG_FORM %CGI_TAG_IMPLICIT);
use warnings;
no warnings qw(uninitialized redefine once);


#  External Modules
#
use WebDyne;
use WebDyne::HTML::TreeBuilder;
use Storable;
use IO::File;
use Data::Dumper;


#  WebDyne Modules
#
use WebDyne::HTML::Tiny;
use WebDyne::Constant;
use WebDyne::Util;


#  Version information
#
$VERSION='2.069';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Get WebDyne and CGI tags from TreeBuilder module
#
*CGI_TAG_WEBDYNE=\%WebDyne::CGI_TAG_WEBDYNE;
*CGI_TAG_FORM=\%WebDyne::HTML::TreeBuilder::CGI_TAG_FORM;
*CGI_TAG_IMPLICIT=\%WebDyne::HTML::TreeBuilder::CGI_TAG_IMPLICIT;


#  Var to hold package wide hash, for data shared across package
#
my %Package;


#  All done. Positive return
#
1;


#==================================================================================================


#  Packace init, attempt to load optional Time::HiRes module
#
BEGIN {
    eval {require Time::HiRes;    Time::HiRes->import('time')};
    eval {require Devel::Confess; Devel::Confess->import(qw(no_warnings))};
    eval {} if $@;
}


sub new {


    #  Only used when debugging from outside apache, eg test script. If so, user
    #  must create new object ref, then run the compile. See wdcompile script for
    #  example. wdcompile is only used for debugging - we do some q&d stuff here
    #  to make it work
    #
    my ($class, @opt)=@_;
    my %opt=(ref($opt[0]) eq 'HASH') ? %{$opt[0]} : @opt;
    debug("$class, opt: %s", Dumper(\%opt));


    #  Init WebDyne module
    #
    require WebDyne::Request::Fake;
    my $r=WebDyne::Request::Fake->new( filename=> ( $opt{'filename'} || $opt{'srce'} ) );


    #  Get appropriate cgi_or
    #
    my $html_tag_or=WebDyne::HTML::Tiny->new(mode => $WEBDYNE_HTML_TINY_MODE, r=>$r ) ||
        return err('unable to get new WebDyne::HTML::Tiny object');


    #  New self ref
    #
    my %self=(

        _r 	=> $r,
        _CGI  	=> $html_tag_or,

    );


    #  And return blessed ref
    #
    return bless(\%self, 'WebDyne');

}


sub compile {


    #  Compile HTML file into Storable structure
    #
    my ($self, $param_hr)=@_;


    #  Start timer so we can log how long it takes us to compile a file
    #
    my $time=($self->{'_time'}=time());


    #  Init class if not yet done
    #
    (ref($self))->{_compile_init} ||= do {
        $self->compile_init() || return err()
    };


    #  Debug
    #
    debug('compile %s', Dumper($param_hr));


    #  Get srce and dest
    #
    my ($html_cn, $dest_cn)=@{$param_hr}{qw(srce dest)};


    #  Need request object ref
    #
    my $r=$self->{'_r'} || $self->r() || return err();


    #  Open the file
    #
    my $html_fh=IO::File->new($html_cn, O_RDONLY) ||
        return err("unable to open file $html_cn, $!");


    #  Read over file handle until we get to the first non-comment line (ignores auto added copyright statements). Update - do
    #  this in Treebuilder code now so can account for comments when counting line numbers
    #
    while (0) {
        my $pos=tell($html_fh);
        my $line=<$html_fh>;
        if ($line=~/^#/) {
            next;
        }
        else {
            seek($html_fh, $pos, 0);
            last;
        }
    }
    
    
    #  Supply html_tiny object ref to Treebuilder so it can run things like start_html
    #
    my $html_tiny_or=$self->html_tiny() ||
        return err('unable to get html_tiny_or ref');


    #  Get new TreeBuilder object. Note api_version flows through to HTML::Parser constructor
    #
    my $tree_or=WebDyne::HTML::TreeBuilder->new(

        api_version 	=> 3,
        html_tiny_or   	=> $html_tiny_or,
        r		=> $r

    ) || return err('unable to create HTML::TreeBuilder object');


    #  Make sure this is off
    #
    $tree_or->unbroken_text(0);


    #  Tell HTML::TreeBuilder we do *not* want to ignore tags it
    #  considers "unknown". Since we use <PERL> and <BLOCK> tags,
    #  amongst other things, we need these to be in the tree
    #
    $tree_or->ignore_unknown(0);


    #  Tell it if we also want to see comments, use XML mode
    #
    $tree_or->store_comments(exists($param_hr->{'store_comments'})
        ? $param_hr->{'store_comments'}
        : $WEBDYNE_STORE_COMMENTS
    );
    $tree_or->xml_mode(1);    # Older versions on HTML::TreeBuilder


    #  No space compacting ?
    #
    $tree_or->ignore_ignorable_whitespace(exists($param_hr->{'ignore_ignorable_whitespace'})
        ? $param_hr->{'ignore_ignorable_whitespace'}
        : $WEBDYNE_COMPILE_IGNORE_WHITESPACE
    );
    $tree_or->no_space_compacting(exists($param_hr->{'no_space_compacting'})
        ? $param_hr->{'no_space_compacting'}
        : $WEBDYNE_COMPILE_NO_SPACE_COMPACTING
    );


    #  Get code ref closure of file to be parsed
    #
    my $parse_cr=$tree_or->parse_fh($html_fh) ||
        return err();


    #  Muck around with strictness of P tags
    #
    $tree_or->p_strict(
        exists($param_hr->{'p_strict'}) 
            ? $param_hr->{'p_strict'} 
            : $WEBDYNE_COMPILE_P_STRICT
    );
    $tree_or->implicit_body_p_tag(
        exists($param_hr->{'implicit_body_p_tag'})
            ? $param_hr->{'implicit_body_p_tag'}
            : $WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG
    );


    #  Now parse through the file, running eof at end as per HTML::TreeBuilder
    #  man page.
    #
    $tree_or->parse($parse_cr);
    

    #  Close handler if anything goes wrong below
    #
    my $close_cr=sub {

        $tree_or->delete;
        undef $tree_or;

    };


    #  Any errors ? Make sure clean-up before throwing error.
    #
    if (errstr()) {
        return err($close_cr->())
    }


    #  So far so good. Close tree and file
    #
    $tree_or->eof();
    $html_fh->close();
    
    
    #  Set flag (tagname) if we have seen <api> or <htmx> tags and want to compact
    #  our tree to remove unneccessary <html><head><body> etc. since these
    #  tags will never emit a full html page when used for real. Do here as lost
    #  after elementify
    #
    my $compact_tag=$tree_or->{'_webdyne_compact'};
    debug("compact_tag: $compact_tag");
    

    #  Elementify
    #
    $tree_or->elementify() ||
        return $close_cr->();


    #  Now start iterating through the treebuilder object, creating
    #  our own array tree structure. Do this in a separate method that
    #  is rentrant as the tree is descended
    #
    my %meta=(
        manifest => $param_hr->{'nomanifest'} ? undef : [$html_cn]
    );
    my $data_ar=$self->parse($tree_or, \%meta) || do {
        return err($close_cr->());
    };
    debug("meta after parse %s", Dumper(\%meta));
    
    
    #  Now destroy the HTML::Treebuilder object, or else mem leak occurs
    #
    $close_cr->();


    #  Meta block. Add any webdyne meta data to parse tree
    #
    my $head_ar=$self->find_node(
        {

            data_ar => $data_ar,
            tag     => 'head',

        }) || return err();
    my $meta_ar=$self->find_node(
        {

            data_ar => $head_ar->[0],
            tag     => 'meta',
            all_fg  => 1,

        }) || return err();
    debug('meta_ar: %s', Dumper($meta_ar));
    foreach my $tag_ar (@{$meta_ar}) {
        my $attr_hr=$tag_ar->[WEBDYNE_NODE_ATTR_IX] || next;
        debug('meta attr_hr: %s', Dumper($attr_hr));
        $attr_hr=$self->subst_attr(undef, $attr_hr);
        debug('meta attr_hr post subst: %s', Dumper($attr_hr));
        if ($attr_hr->{'name'}=~/^webdyne$/i) {
            my @meta=split(/;/, $attr_hr->{'content'});
            debug('meta %s', Dumper(\@meta));
            foreach my $meta (@meta) {
                my ($name, $value)=split(/[=:]/, $meta, 2);
                defined($value) || ($value=1);

                #  Eval any meta attrs like @{}, %{}..
                my $hr=$self->subst_attr(undef, {$name => $value}) ||
                    return err();
                $meta{$name}=$hr->{$name};
                if ($name eq 'cache') {
                    $meta{'static'} ||= 1;
                }
            }

            #  Do not want anymore
            $self->delete_node(
                {

                    data_ar => $data_ar,
                    node_ar => $tag_ar

                }) || return err();
        }
        elsif (ref($attr_hr->{'content'}) eq 'HASH') {
            while (my($meta_key, $meta_value)=each %{$attr_hr->{'content'}}) {
                if ($meta_key=~/^webdyne$/i) {
                    my @meta=split(/;/, $meta_value);
                    debug('meta %s', Dumper(\@meta));
                    foreach my $meta (@meta) {
                        my ($name, $value)=split(/[=:]/, $meta, 2);
                        defined($value) || ($value=1);
                        $meta{$name}=$value;
                        if ($name eq 'cache') {
                            $meta{'static'} ||= 1;
                        }
                    }
                }
            }
        } 
    }
    
    
    #  And look for any static or cache tags found in start_html and noted 
    #
    foreach my $attr (qw(static cache handler)) {
        if (my $value=$html_tiny_or->{"_${attr}"}) {
            $meta{$attr}=$value;
        }
    }
    debug('final inode meta: %s', Dumper(\%meta));
    
    
    #  If <api> or <htmx) tag used in page compress down to just the <api>/<htmx> nodes and throw
    #  everything else away.
    #
    if ($compact_tag) {
    
        #  Find all the api nodes
        #
        my $api_ar=$self->find_node({
            data_ar	=> $data_ar,
            tag		=> $compact_tag,
            all_fg	=> 1
        });
        
        
        #  And make a new data_ar structure to hold it, throwing everything else
        #  in the bin
        #
        $data_ar=[undef, undef, $api_ar];

    }
    

    #  Construct final webdyne container
    #
    my @container=(keys %meta ? \%meta : undef, $data_ar);


    #  Quit if user wants to see tree at this stage (stage0 | opt0)
    #
    $param_hr->{'stage0'} && (return \@container);


    #  Store meta information for this instance so that when perl_init (or code running under perl_init)
    #  runs it can access meta data via $self->meta();
    #
    $self->{'_meta_hr'}=\%meta if keys %meta;
    if ((my $perl_ar=$meta{'perl'}) && !$param_hr->{'noperl'}) {

        #  This is inline __PERL__ perl. Must be executed before filter so any filters added by the __PERL__
        #  block are seen
        #
        my $perl_debug_ar=$meta{'perl_debug'};
        $self->perl_init($perl_ar, $perl_debug_ar) || return err();


    }


    #  Quit if user wants to see tree at this stage
    #
    $param_hr->{'stage1'} && (return \@container);


    #  Filter ?
    #
    my @filter=@{$meta{'webdynefilter'}};
    unless (@filter) {
        my $filter=$self->{'_filter'} || $r->dir_config('WebDyneFilter');
        @filter=split(/\s+/, $filter) if $filter;
    }
    debug('filter %s', Dumper(\@filter));
    if ((@filter) && !$param_hr->{'nofilter'}) {
        local $SIG{'__DIE__'};
        foreach my $filter (@filter) {
            $filter=~s/::filter$//;
            eval("require $filter") ||
                return err("unable to load filter $filter, " . lcfirst($@));
            UNIVERSAL::can($filter, 'filter') ||
                return err("custom filter '$filter' does not seem to have a 'filter' method to call");
            $filter.='::filter';
            $data_ar=$self->$filter($data_ar, \%meta) || return err();
        }
    }


    #  Quit if user wants to see tree at this stage
    #
    $param_hr->{'stage2'} && (return \@container);


    #  Optimise tree, first step
    #
    $data_ar=$self->optimise_one($data_ar) || return err();
    $container[1]=$data_ar;


    #  Quit if user wants to see tree at this stage (stage3|opt1)
    #
    ($param_hr->{'stage3'} || $param_hr->{'opt1'}) && (return \@container);


    #  Optimise tree, second step
    #
    $data_ar=$self->optimise_two($data_ar) || return err();
    $container[1]=$data_ar;


    #  Quit if user wants to see tree at this stage (stage4|opt2)
    #
    ($param_hr->{'stage4'} || $param_hr->{'opt2'}) && (return \@container);


    #  Is there any dynamic data ? If not, set meta html flag to indicate
    #  document is complete HTML
    #
    unless (grep {ref($_)} @{$data_ar}) {
        $meta{'html'}=1;
    }


    #  Construct final webdyne container
    #
    @container=(keys %meta ? \%meta : undef, $data_ar);


    #  Quit if user wants to final container (stage5|final)
    #
    $param_hr->{'stage5'} && (return \@container);


    #  Save compiled object. Can't store code based cache refs, will be
    #  recreated anyway (when reloaded), so delete, save, then restore
    #
    my $cache_cr;
    if (ref($meta{'cache'}) eq 'CODE') {$cache_cr=delete $meta{'cache'}}


    #  Store to cache file if dest filename given
    #
    if ($dest_cn) {
        debug("attempting to cache to dest $dest_cn");
        local $SIG{'__DIE__'};
        eval {Storable::lock_store(\@container, $dest_cn)} || do {

            #  This used to be fatal
            #
            #return err("error storing compiled $html_cn to dest $dest_cn, $@");


            #  No more, just log warning and continue - no point crashing an otherwise
            #  perfectly good app because we can't write to a directory
            #
            $r->log_error(
                "error storing compiled $html_cn to dest $dest_cn, $@ - " .
                    'please ensure destination directory is writeable.'
                )
                unless $Package{'warn_write'}++;
            debug("caching FAILED to $dest_cn");

        };
    }
    else {
        debug('no destination file for compile - not caching');
    }


    #  Put the cache code ref back again now we have finished storing.
    #
    $cache_cr && ($meta{'cache'}=$cache_cr);


    #  Work out the page compile time, log
    #
    my $time_compile=sprintf('%0.4f', time()-$time);
    $meta{'time_compile_elapsed'}=$time_compile unless
        $param_hr->{'notimestamp'};
    $meta{'time_compile'}=$time unless
        $param_hr->{'notimestamp'};
    debug("form $html_cn compile time $time_compile");


    #  Destroy self
    #
    undef $self;


    #  Done
    #
    return \@container;

}


sub compile_init {


    #  Used to init package, move ugliness out of handler
    #
    my $class=shift();
    debug("in compile_init class $class");


    #  Used to do some custom stuff here but now stub. Add anything wanted
    #
    #*WebDyne::HTML::Tiny::start_html0=sub {
    #    my ($self, $attr_hr)=@_;
    #    keys %{$attr_hr} || ($attr_hr=$WEBDYNE_HTML_PARAM);
    #    my $html_attr=join(' ', map {qq($_="$attr_hr->{$_}")} keys %{$attr_hr});
    #    return $WEBDYNE_DTD . ($html_attr ? "<html $html_attr>" : '<html>');
    #};

    #  All done
    #
    return \undef;


}


sub optimise_one {


    #  Optimise a data tree
    #
    my ($self, $data_ar)=@_;


    #  Debug
    #
    debug('optimise stage one');


    #  Get CGI object and disable shortcut tags (e.g. start_html);
    #
    my $html_tiny_or=$self->{'_html_tiny_or'} || $self->html_tiny() ||
        return err("unable to get CGI object from self ref");
    debug("CGI $html_tiny_or");
    $html_tiny_or->shortcut_disable();


    #  Recursive anon sub to do the render
    #
    my $compile_cr=sub {


        #  Get self ref, node array
        #
        my ($compile_cr, $data_ar)=@_;


        #  Only do if we have children, if we do a foreach over nonexistent child node
        #  it will spring into existance as empty array ref, which we then have to
        #  wastefully store
        #
        if ($data_ar->[WEBDYNE_NODE_CHLD_IX]) {


            #  Process sub nodes to get child html data
            #
            foreach my $data_chld_ix (0..$#{$data_ar->[WEBDYNE_NODE_CHLD_IX]}) {


                #  Get data child
                #
                my $data_chld_ar=$data_ar->[WEBDYNE_NODE_CHLD_IX][$data_chld_ix];
                debug("data_chld_ar $data_chld_ar");


                #  If ref, recursivly run through compile process
                #
                ref($data_chld_ar) && do {


                    #  Run through compile sub-process
                    #
                    my $data_chld_xv=$compile_cr->($compile_cr, $data_chld_ar) ||
                        return err();
                    if (ref($data_chld_xv) eq 'SCALAR') {
                        $data_chld_xv=${$data_chld_xv}
                    }


                    #  Replace in tree
                    #
                    $data_ar->[WEBDYNE_NODE_CHLD_IX][$data_chld_ix]=$data_chld_xv;

                }

            }

        }


        #  Get this node tag and attrs
        #
        my ($html_tag, $attr_hr)=
            @{$data_ar}[WEBDYNE_NODE_NAME_IX, WEBDYNE_NODE_ATTR_IX];
        debug("tag $html_tag, attr %s", Dumper($attr_hr));


        #  Check to see if any of the attributes will require a subst to be carried out
        #
        my @subst_oper;
        my $subst_fg=$data_ar->[WEBDYNE_NODE_SBST_IX] || delete $attr_hr->{'subst'} ||
            grep {$_=~/([\$@%!+*^])\{(\1?)(.*?)\2\}/ && push(@subst_oper, $1)} values %{$attr_hr};


        #  Do not subst comments
        #
        ($html_tag=~/~comment$/) && ($subst_fg=undef);


        #  If subst_fg present, means we must do a subst on attr vars. Flag
        #
        $subst_fg && ($data_ar->[WEBDYNE_NODE_SBST_IX]=1);


        #  A CGI tag can be marked static, means that we can pre-render it for efficieny
        #
        my $static_fg=$attr_hr->{'static'};
        debug("tag $html_tag, static_fg: $static_fg, subst_fg: $subst_fg, subst_oper %s", Dumper(\@subst_oper));


        #  If static, but subst requires an eval, we can do now *only* if @ or % tags though,
        #  and some !'s that do not need request object etc. Cannot do on $
        #
        if ($static_fg && $subst_fg) {


            #  Cannot optimes subst values with ${value}, must do later
            #
            (grep {$_ eq '$'} @subst_oper) && return $data_ar;


            #  Do it
            #
            $attr_hr=$self->WebDyne::subst_attr(undef, $attr_hr) ||
                return err();

        }


        #  If not special WebDyne tag, see if we can render node
        #
        if ((!$CGI_TAG_WEBDYNE{$html_tag} && !$CGI_TAG_FORM{$html_tag} && !$subst_fg) || $static_fg) {
        #if ((!$CGI_TAG_WEBDYNE{$html_tag} && !$subst_fg) || $static_fg) {


            #  Check all child nodes to see if ref or scalar
            #
            debug("if 1");
            my $ref_fv=$data_ar->[WEBDYNE_NODE_CHLD_IX] &&
                grep {ref($_)} @{$data_ar->[WEBDYNE_NODE_CHLD_IX]};


            #  If all scalars (ie no refs found)t, we can simply pre render all child nodes
            #
            debug("ref_fv: $ref_fv");
            unless ($ref_fv) {


                #  Done with static tag, delete so not rendered
                #
                delete $attr_hr->{'static'};


                #  Special case. If WebDyne tag and static, render now via WebDyne. Experimental
                #
                if ($CGI_TAG_WEBDYNE{$html_tag}) {


                    #  Render via WebDyne
                    #
                    debug("about to render tag $html_tag, attr %s", Dumper($attr_hr));
                    my $html_sr=$self->$html_tag($data_ar, $attr_hr) ||
                        return err();
                    debug("html *$html_sr*, *${$html_sr}*");
                    return $html_sr;


                }
                else {
                    debug('not CGI_TAG_WEBDYNE')
                }


                #  Wrap up in our HTML tag. Do in eval so we can catch errors from invalid tags etc
                #
                #
                my @data_child=$data_ar->[WEBDYNE_NODE_CHLD_IX] ? @{$data_ar->[WEBDYNE_NODE_CHLD_IX]} : undef;
                debug("about to call $html_tag with attr_hr:%s, data_child: %s", Dumper($attr_hr, \@data_child));
                my $html=eval {
                    $attr_hr=undef unless keys %{$attr_hr};
                    if ($html_tiny_or->can($html_tag)) {
                        $html_tiny_or->$html_tag(grep {$_} $attr_hr, join(undef, @data_child))
                    }
                    else {
                        $html_tiny_or->tag($html_tag, grep {$_} $attr_hr, join(undef, @data_child))
                    }

                    #  Older attempts
                    #
                    #$html_tiny_or->$html_tag(grep {$_} $attr_hr || {}, join(undef, @data_child))
                    #$html_tiny_or->$html_tag($attr_hr || {}, join(undef, grep {$_} @data_child))
                } || 
                    
                    #  Use errsubst as CGI may have DIEd during eval and be caught by WebDyne SIG handler
                    return errsubst(
                    "CGI tag '<$html_tag>': %s",
                    $@ || sprintf("undefined error rendering tag '$html_tag', attr_hr:%s, data_child:%s", Dumper($attr_hr, \@data_child))
                    );


                #  Debug
                #
                #debug("html *$html*");


                #  Done
                #
                return \$html;

            }


        }
        else {
            debug('fell through node render, no webdyne, subst tags etc.');
        }


        #  Return current node, perhaps now somewhat optimised
        #
        $data_ar

    };


    #  Push data block onto stack as error hint
    #
    push @{$self->{'_data_ar_err'}}, $data_ar;
    
    
    #  Run it
    #
    $data_ar=$compile_cr->($compile_cr, $data_ar) || return err();
    
    
    #  No error, pop error hint
    #
    pop @{$self->{'_data_ar_err'}};
    
    
    #  Re-enable shortcuts
    #
    $html_tiny_or->shortcut_enable();


    #  If scalar ref returned it is all HTML - return as plain scalar
    #
    if (ref($data_ar) eq 'SCALAR') {
        $data_ar=${$data_ar}
    }


    #  Done
    #
    return $data_ar;

}


sub optimise_two {


    #  Optimise a data tree
    #
    my ($self, $data_ar)=@_;


    #  Debug
    #
    debug('optimise stage two');


    #  Get CGI object and turn off shortcuts like start_html
    #
    my $html_tiny_or=$self->{'_html_tiny_or'} || $self->html_tiny() ||
        return err("unable to get CGI object from self ref");
    $html_tiny_or->shortcut_disable();


    #  Recursive anon sub to do the render
    #
    my $compile_cr=sub {


        #  Get self ref, node array
        #
        my ($compile_cr, $data_ar, $data_uppr_ar)=@_;


        #  Only do if we have children, if do a foreach over nonexistent child node
        #  it will spring into existance as empty array ref, which we then have to
        #  wastefully store
        #
        if ($data_ar->[WEBDYNE_NODE_CHLD_IX]) {


            #  Process sub nodes to get child html data
            #
            my @data_child_ar=$data_ar->[WEBDYNE_NODE_CHLD_IX]
                ?
                @{$data_ar->[WEBDYNE_NODE_CHLD_IX]}
                : undef;
            foreach my $data_chld_ar (@data_child_ar) {


                #  Debug
                #
                #debug("found child node $data_chld_ar");


                #  If ref, run through compile process recursively
                #
                ref($data_chld_ar) && do {


                    #  Run through compile sub-process
                    #
                    $data_ar=$compile_cr->($compile_cr, $data_chld_ar, $data_ar) ||
                        return err();

                }


            }

        }


        #  Get this tag and attrs
        #
        my ($html_tag, $attr_hr)=
            @{$data_ar}[WEBDYNE_NODE_NAME_IX, WEBDYNE_NODE_ATTR_IX];
        debug("tag $html_tag");


        #  Check if this tag attributes will need substitution (eg ${foo});
        #
        my $subst_fg=$data_ar->[WEBDYNE_NODE_SBST_IX] || delete $attr_hr->{'subst'} ||
            grep {$_=~/([\$@%!+*^])\{(\1?)(.*?)\2\}/so} values %{$attr_hr};


        #  If subst_fg present, means we must do a subst on attr vars. Flag, also get static flag
        #
        $subst_fg && ($data_ar->[WEBDYNE_NODE_SBST_IX]=1);
        my $static_fg=delete $attr_hr->{'static'};


        #  If not special WebDyne tag, and no dynamic params we can render this node into
        #  its final HTML format
        #
        if (!$CGI_TAG_WEBDYNE{$html_tag} && !$CGI_TAG_IMPLICIT{$html_tag} && $data_uppr_ar && !$subst_fg) {


            #  Get nodes into array now, removes risk of iterating over shifting ground
            #
            debug("compile_cr: if 1");
            my @data_child_ar=$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]
                ?
                @{$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]}
                : undef;


            #  Get uppr node
            #
            foreach my $data_chld_ix (0..$#data_child_ar) {


                #  Get node, skip unless ref
                #
                my $data_chld_ar=$data_child_ar[$data_chld_ix];
                ref($data_chld_ar) || next;


                #  Debug
                #
                #debug("looking at node $data_chld_ix, $data_chld_ar vs $data_ar");


                #  Skip unless eq us
                #
                next unless ($data_chld_ar eq $data_ar);


                #  Get start and end tag methods
                #
                my ($html_tag_start, $html_tag_end)=
                    ("start_${html_tag}", "end_${html_tag}");


                #  Translate tags into HTML
                #
                my ($html_start, $html_end)=map {
                    debug("render tag $_");
                    eval {
                        $html_tiny_or->$_(grep {$_} $attr_hr)
                    } ||

                        #  Use errsubst as CGI may have DIEd during eval and be caught by WebDyne SIG handler
                        return errsubst(
                        "CGI tag '<$_>' error- %s",
                        $@ || "undefined error rendering tag '$_'"
                        );
                } ($html_tag_start, $html_tag_end);


                #  Splice start and end tags for this HTML into appropriate place
                #
                splice @{$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]}, $data_chld_ix, 1,
                    $html_start,
                    @{$data_ar->[WEBDYNE_NODE_CHLD_IX]},
                    $html_end;

                #  Done, no need to iterate any more
                #
                last;


            }


            #  Concatenate all non ref values in the parent. Var to hold results
            #
            my @data_uppr;


            #  Repopulate data child array, as probably changed in above foreach
            #  block.
            #
            @data_child_ar=$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]
                ?
                @{$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]}
                : undef;

            #@data_child_ar=@{$data_uppr_ar->[$WEBDYNE_NODE_CHLD_IX]};


            #  Begin concatenation
            #
            foreach my $data_chld_ix (0..$#data_child_ar) {


                #  Get child
                #
                my $data_chld_ar=$data_child_ar[$data_chld_ix];


                #  Can we concatenate with above node
                #
                if (@data_uppr && !ref($data_chld_ar) && !ref($data_uppr[$#data_uppr])) {


                    # Yes, concatentate
                    #
                    $data_uppr[$#data_uppr].=$data_chld_ar;

                }
                else {

                    #  No, push onto new data_uppr array
                    #
                    push @data_uppr, $data_chld_ar;

                }
            }


            #  Replace with new optimised array
            #
            $data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]=\@data_uppr;


        }
        elsif ($CGI_TAG_WEBDYNE{$html_tag} && $data_uppr_ar && $static_fg) {


            #  Now render to make HTML and modify the data arrat above us with the rendered code
            #
            debug("compile_cr: if 2");
            my $html_sr=$self->render_data_ar(
                data => [$data_ar],
            ) || return err();
            my @data_child_ar=$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]
                ?
                @{$data_uppr_ar->[WEBDYNE_NODE_CHLD_IX]}
                : undef;
            foreach my $ix (0..$#data_child_ar) {
                if ($data_uppr_ar->[WEBDYNE_NODE_CHLD_IX][$ix] eq $data_ar) {
                    $data_uppr_ar->[WEBDYNE_NODE_CHLD_IX][$ix]=${$html_sr};
                    last;
                }
            }


        }
        elsif (!$data_uppr_ar && $html_tag) {
        
        
            #  Must be at top node, as nothing above us,
            #  get start and end tag methods
            #
            debug("compile_cr: if 3");
            my ($html_tag_start, $html_tag_end)=
                ("start_${html_tag}", "end_${html_tag}");


            #  Get resulting start and ending HTML
            #
            my ($html_start, $html_end)=map {
                debug("render tag $_");
                eval {
                    $html_tiny_or->$_(grep {$_} $attr_hr)
                } ||
                    return errsubst(
                    "CGI tag '<$_>': %s",
                    $@ || "undefined error rendering tag '$_'"
                    );

                #return err("$@" || "no html returned from tag $_")
            } ($html_tag_start, $html_tag_end);
            my @data_child_ar=$data_ar->[WEBDYNE_NODE_CHLD_IX]
                ?
                @{$data_ar->[WEBDYNE_NODE_CHLD_IX]}
                : undef;

            #  Place start and end tags for this HTML into appropriate place
            #
            my @data=(
                $html_start,
                @data_child_ar,
                $html_end
            );


            #  Concatenate all non ref vals
            #
            my @data_new;
            foreach my $data_chld_ix (0..$#data) {

                if ($data_chld_ix && !ref($data[$data_chld_ix]) && !(ref($data[$data_chld_ix-1]))) {
                    $data_new[$#data_new].=$data[$data_chld_ix];
                }
                else {
                    push @data_new, $data[$data_chld_ix]
                }

            }


            #  Return completed array
            #
            $data_uppr_ar=\@data_new;


        }
        elsif (!$data_uppr_ar && !$html_tag) {
        
        
            #  Special case generated by page with <api> tags, means we're not going to wrap in <html>
            #
            $data_uppr_ar=$data_ar->[WEBDYNE_NODE_CHLD_IX];
            
        }
        
        
        #  Return current node
        #
        return $data_uppr_ar;


    };
    
    
    #  Push data block onto error hint stack in case of compile error
    #
    push @{$self->{'_data_ar_err'}}, $data_ar;


    #  Run it, return whatever it does, allowing for the special case that first stage
    #  optimisation found no special tags, and precompiled the whole array into a
    #  single HTML string. In which case return as array ref to allow for correct storage
    #  and rendering.
    #
    my $ret;
    if (ref($data_ar)) {
        $ret=$compile_cr->($compile_cr, $data_ar, undef) ||
            err()
    }
    else {
        $ret=[$data_ar];
    }
    
    
    #  No errors, pop error hint stack
    #
    pop @{$self->{'_data_ar_err'}};
    

    #  Re-enable shortcuts
    #
    $html_tiny_or->shortcut_enable();
    

    #  And return
    #
    return $ret;

}


sub parse {


    #  A recusively called method to parse a HTML::Treebuilder tree. content is an
    #  array ref of the HTML entity contents, return custom array tree from that
    #  structure
    #
    my ($self, $html_or, $meta_hr)=@_;
    my ($line_no, $line_no_tag_end)=@{$html_or}{'_line_no', '_line_no_tag_end'};
    my $html_fn_sr=\$meta_hr->{'manifest'}[0];
    debug("parse $self, $html_or line_no $line_no line_no_tag_end $line_no_tag_end");


    #  Create array to hold this data node
    #
    my @data;
    @data[
        WEBDYNE_NODE_NAME_IX,            # Tag Name
        WEBDYNE_NODE_ATTR_IX,            # Attributes
        WEBDYNE_NODE_CHLD_IX,            # Child nodes
        WEBDYNE_NODE_SBST_IX,            # Substitution Required
        WEBDYNE_NODE_LINE_IX,            # Source Line Number
        WEBDYNE_NODE_LINE_TAG_END_IX,    # What line this tag ends on
        WEBDYNE_NODE_SRCE_IX             # Source file name
        ]=(
        #undef, undef, undef, undef, $line_no, $line_no_tag_end, $meta_hr->{'manifest'}[0]
        undef, undef, undef, undef, $line_no, $line_no_tag_end, $html_fn_sr
        );


    #  Get tag
    #
    my $html_tag=$html_or->tag();


    #  Get tag attr
    #
    if (my %attr=map {$_ => $html_or->{$_}} (grep {!/^_/} keys %{$html_or})) {


        #  Save tagm attr into node
        #
        #@data[$WEBDYNE_NODE_NAME_IX, $WEBDYNE_NODE_ATTR_IX]=($html_tag, \%attr);


        #  Is this the inline perl __PERL__ block ?
        #
        if ($html_or->{'_code'} && $attr{'perl'}) {
            push @{$meta_hr->{'perl'}},       \$attr{'perl'};
            push @{$meta_hr->{'perl_debug'}}, [$line_no, $html_fn_sr];
        }
        else {
            @data[WEBDYNE_NODE_NAME_IX, WEBDYNE_NODE_ATTR_IX]=($html_tag, \%attr);
        }

    }
    else {


        #  No attr, just save tag
        #
        $data[WEBDYNE_NODE_NAME_IX]=$html_tag;

    }


    #  Child nodes
    #
    my @html_child=@{$html_or->content()};


    #  Get child, parse down the tree
    #
    foreach my $html_child_or (@html_child) {

        debug("html_child_or $html_child_or");


        #  Ref is a sub-tag, non ref is plain text
        #
        if (ref($html_child_or)) {


            #  Sub tag. Recurse down tree, updating to nearest line number
            #
            $line_no=$html_child_or->{'_line_no'};
            my $data_ar=$self->parse($html_child_or, $meta_hr) ||
                return err();


            #  If no node name returned is not an error, just a no-op
            #
            if ($data_ar->[WEBDYNE_NODE_NAME_IX]) {
                push @{$data[WEBDYNE_NODE_CHLD_IX]}, $data_ar;
            }

        }
        else {

            #  Node is just plain text. Used to not insert empty children, but this
            #  stuffed up <pre> sections that use \n for spacing/formatting. Now we
            #  are more careful
            #
            push(@{$data[WEBDYNE_NODE_CHLD_IX]}, $html_child_or)
                unless (
                $html_child_or=~/^\s*$/
                &&
                ($html_tag ne 'pre') && ($html_tag ne 'textarea') && !$WEBDYNE_COMPILE_NO_SPACE_COMPACTING
                );

        }

    }


    #  All done, return data node
    #
    return \@data;

}


