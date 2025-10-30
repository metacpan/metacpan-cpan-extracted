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
package WebDyne::Template;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);


#  Webmod Modules.
#
use WebDyne::Constant;
use WebDyne::Util;
use Data::Dumper;


#  External modules
#
use File::Spec;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='2.018';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my ($class, @param)=@_;
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    $self->set_handler('WebDyne::Chain');

    #$self->set_handler('WebDyne::Template');
    my %param=(@param == 1) ? (webdynetemplate => @param) : @param;
    my $meta_hr=$self->meta();
    push @{$meta_hr->{'webdynechain'}},  __PACKAGE__;
    push @{$meta_hr->{'webdynefilter'}}, __PACKAGE__;
    map {$meta_hr->{lc($_)}=$param{$_}} keys %param;

}


sub handler : method {


    #  Add ourselves as a filter
    #
    my ($self, $r)=(shift, shift);
    $self->set_filter(__PACKAGE__);
    $self->SUPER::handler($r, @_);

}


sub template {


    #  Name of template in use. Cannot be set here, too late - read only
    #
    my $self=shift();
    my $r=$self->r()                              || return err();
    my $meta_hr=$self->meta()                     || return err();
    my $template_cn=$meta_hr->{'webdynetemplate'} || $r->dir_config('WebDyneTemplate');
    $template_cn                                  || return err('no template file name specified %s !', Data::Dumper::Dumper($meta_hr));

    #  Must be full path, if not use current dir
    #
    unless ((File::Spec->splitpath($template_cn))[1]) {

        #  No dir, must use cwd
        #
        #my $dn=(File::Spec->splitpath($r->filename()))[1];
        my $dn=$self->cwd();
        $template_cn=File::Spec->catfile($dn, $template_cn);

    }
    \$template_cn

}


sub source_mtime {


    #  Get latest srce mtime for source file and template so engine can
    #  determine if cache is stale
    #
    my ($self, $srce_mtime)=@_;
    debug('menu source mtime');


    #  Get request object
    #
    my $r=$self->r() || return err();


    #  Get full path, mtime of menu template
    #
    my $template_cn=${$self->template() || return err()};
    my $template_mtime=(stat($template_cn))[9] ||
        return err("could not stat $template_cn, $!");


    #  Get appropriate mtime
    #
    my $return_mtime=($srce_mtime > $template_mtime) ? $srce_mtime : $template_mtime;
    debug("returning mtime $return_mtime");


    #  Return whichever is greater
    #
    return \$return_mtime;


}


sub filter {


    #  The real guts. Wedge one HTML page into a wrapper page
    #
    my ($self, $data_main_ar, $meta_main_hr)=@_;
    debug("in $self filter");


    #  Get request object
    #
    my $r=$self->r() ||
        return err('unable to get request object');


    #  Get the template path name
    #
    my $template_cn=${$self->template() || return err()};
    debug("template_pn $template_cn, %s", ref($r));
    $template_cn || return err('no template file name specified');


    #  If user is looking at template, don't try and
    #  recursively compile it for them, bad things happen,
    #  just show as is
    #
    ($template_cn eq $r->filename()) &&
        return $data_main_ar;


    #  Get the template structure data ref
    #
    my $container_ar=$self->compile({

            srce   => $template_cn,
            stage1 => 1,

        }) || return err();
    my ($meta_template_hr, $data_template_ar)=@{$container_ar};


    #  Concatenate meta perl sections
    #
    #my $perl_main_ar=$meta_main_hr->{'perl'};
    my $perl_template_ar=$meta_template_hr->{'perl'};
    push @{$meta_main_hr->{'perl'}}, @{$perl_template_ar};


    #  Below fixes up HEAD section
    #


    #  Find body block, ie <head> tag in data ref
    #
    my $data_template_head_ar=(
        $self->find_node({

                data_ar => $data_template_ar,
                tag     => 'head'

            })
            || return err())->[0];
    debug("data_template_head_ar $data_template_head_ar %s", Dumper($data_template_head_ar));


    #  Find the *parent* of the <block name=head> tag in the menu code. Note that this
    #  block in not necessarily immediately under the <head> tag, may be buried
    #  further down under a table etc
    #
    my $data_template_head_block_prnt_ar=(
        $self->find_node({

                data_ar => $data_template_head_ar,
                tag     => 'block',
                attr_hr => {name => 'head'},
                prnt_fg => 1,

            })
            || return err())->[0];
    debug(
        "data_template_head_block_prnt_ar $data_template_head_block_prnt_ar %s",
        Dumper($data_template_head_block_prnt_ar));


    #  Get the actual <block name=head> data ref
    #
    my $data_template_head_block_ar=(
        $self->find_node({

                data_ar => $data_template_ar,
                tag     => 'block',
                attr_hr => {name => 'head'}

            })
            || return err())->[0];
    debug(
        "data_template_head_block_ar $data_template_head_block_ar %s",
        Dumper($data_template_head_block_ar));


    #  Get the <head> section from the main HTML page, ie the page to be
    #  embedded
    #
    my $data_main_head_ar=(
        $self->find_node({

                data_ar => $data_main_ar,
                tag     => 'head'

            })
            || return err())->[0];
    debug(
        "data_main_head_ar $data_main_head_ar %s",
        Dumper($data_main_head_ar));


    #  Concatenate titles
    #
    my $data_main_title_ar=(
        $self->find_node({

                data_ar => $data_main_ar,
                tag     => 'title'

            })
            || return err())->[0];
    my $data_template_title_ar=(
        $self->find_node({

                data_ar => $data_template_ar,
                tag     => 'title'

            })
            || return err())->[0];
    $data_main_title_ar->[$WEBDYNE_NODE_CHLD_IX][0]=join(
        ' - ',
        grep {$_}
            $data_template_title_ar->[$WEBDYNE_NODE_CHLD_IX][0], $data_main_title_ar->[$WEBDYNE_NODE_CHLD_IX][0]);

    #debug('titles, %s, %s', Dumper($data_main_title_ar, $data_template_title_ar));


    #  Replace menu head attr with any head attr from main page
    #
    $data_template_head_ar->[$WEBDYNE_NODE_ATTR_IX]=
        $data_main_head_ar->[$WEBDYNE_NODE_ATTR_IX];


    #  Search for head block in head block parent
    #
    foreach my $data_chld_ix (0..$#{$data_template_head_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX]}) {


        #  Skip if not found
        #
        my $data_chld_ar=$data_template_head_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX][$data_chld_ix];
        next unless ($data_chld_ar eq $data_template_head_block_ar);


        #  Must have found node if get to here, splice in head
        #
        splice @{$data_template_head_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX]}, $data_chld_ix, 1,
            @{$data_main_head_ar->[$WEBDYNE_NODE_CHLD_IX]};
        last;

    }


    #  Below fixes up BODY section
    #


    #  Find body block, ie <body> tag in data ref
    #
    my $data_template_body_ar=(
        $self->find_node({

                data_ar => $data_template_ar,
                tag     => 'body'

            })
            || return err())->[0];
    debug("data_template_body_ar $data_template_body_ar %s", Dumper($data_template_body_ar));


    #  Find the *parent* of the <block name=body> tag in the menu code. Note that this
    #  block in not neccessarily immediately under the <body> tag, may be buried
    #  further down under a table etc
    #
    my $data_template_body_block_prnt_ar=(
        $self->find_node({

                data_ar => $data_template_body_ar,
                tag     => 'block',
                attr_hr => {name => 'body'},
                prnt_fg => 1,

            })
            || return err())->[0];
    debug(
        "data_template_body_block_prnt_ar $data_template_body_block_prnt_ar %s",
        Dumper($data_template_body_block_prnt_ar));


    #  Get the actual <block name=body> data ref
    #
    my $data_template_body_block_ar=(
        $self->find_node({

                data_ar => $data_template_ar,
                tag     => 'block',
                attr_hr => {name => 'body'}

            })
            || return err())->[0];
    debug(
        "data_template_body_block_ar $data_template_body_block_ar %s",
        Dumper($data_template_body_block_ar));


    #  Get the <body> section from the main HTML page, ie the page to be
    #  embedded
    #
    my $data_main_body_ar=(
        $self->find_node({

                data_ar => $data_main_ar,
                tag     => 'body'

            })
            || return err())->[0];
    debug(
        "data_main_body_ar $data_main_body_ar %s",
        Dumper($data_main_body_ar));


    #  Replace menu body attr with any body attr from main page
    #
    $data_template_body_ar->[$WEBDYNE_NODE_ATTR_IX]=
        $data_main_body_ar->[$WEBDYNE_NODE_ATTR_IX];


    #  Search for body block in body block parent
    #
    foreach my $data_chld_ix (0..$#{$data_template_body_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX]}) {


        #  Skip if not found
        #
        my $data_chld_ar=$data_template_body_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX][$data_chld_ix];
        next unless ($data_chld_ar eq $data_template_body_block_ar);


        #  Must have found node if get to here, splice in body
        #
        splice @{$data_template_body_block_prnt_ar->[$WEBDYNE_NODE_CHLD_IX]}, $data_chld_ix, 1,
            @{$data_main_body_ar->[$WEBDYNE_NODE_CHLD_IX]};
        last;


    }


    #  All done, pass onto next filter
    #
    return $data_template_ar;

}


__END__

=head1 Name

WebDyne::Template - WebDyne extension module that implements document templating

=head1 Description

WebDyne::Template is a WebDyne extension module that implements document
templating.  You can set templates for locations or sites, e.g.  menu
sidebars, header, copyright information etc.  All psp documents within the
scope of the location will then be embedded into the templates.

Templates are WebDyne documents also - they can dynamically change (e.g.
cascading menus, breadcrumb tracking etc.) based on any arbitrary criterea
you determine.

The target documents within the templating location do not have to be
modified - the WebDyne::Template module will parse out head and body
sections of requested documents and embed them into the location template as
appropriate

=head1 Documentation

Information on configuration and usage is availeble from the WebDyne site,
http://webdyne.org/ - or from a snapshot of current documentation in PDF
format available in the WebDyne module source /doc directory.

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-template at
rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Template


