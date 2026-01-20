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
package WebDyne::Cache;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information
#
$VERSION='2.073';


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
    my %param=(@param == 1) ? (cache => @param) : @param;
    my $meta_hr=$self->meta() || return err();
    $meta_hr->{'cache'}=$param{'cache'};
    $meta_hr->{'static'}=1;

}


sub handler : method {


    #  Handler is a no-op, all work is done by filter code. Need a handler so
    #  module is seen by WebDyne autoload method when tracking back through
    #  chained modules
    #
    my ($self, $r)=(shift, shift);
    my $cache=$r->dir_config('WebDyneCacheHandler') ||
        return $self->err_html(
        'unable to get cache handler name - have you set the WebDyneCacheHandler var ?'
        );
    $self->cache($cache);
    $self->static(1);
    $self->SUPER::handler($r, @_);

}

__END__


=pod

=head1 WebDyne::Cache(3pm)

=head1 NAME

WebDyne::Cache - WebDyne module to cache dynamic output for improved performance.

=head1 SYNOPSIS

    #  Sample time.psp compiled to cached HTML. Every time this page is requested it will show
    #  the same time unless an interval of more than 10 seconds has elapsed.
    #
    <start_html>
    The most recent time this page was run was <? localtime ?>
    __PERL__
    use WebDyne::Cache (\&cache);
    
    sub cache {
        
        #  Self ref
        #
        my $self=shift();
    
        #  Get file last modified time (mtime)
        #
        my $mtime=${ $self->cache_mtime() };
    
        #  If older than 10 seconds force recompile
        #
        if ((time()-$mtime) > 10) { 
            $self->cache_compile(1) 
        };
    
        #  Done
        #
        return 1;
    
    }

=head1 DESCRIPTION

The WebDyne::Cache module works in conjunction with the WebDyne::Static module to allow less frequent running of dynamic code, speeding up responsiveness for CPU or I/O heavy pages.

The WebDyne framework will continue to monitor for changes in the source file and recompile if the source .psp file is updated, regardless of the response of any caching directive.

=head1 USAGE

The WebDyne::Cache code must be invoked in the requested page via one of the following methods:

=over

=item 1. Via use of the WebDyne::Cache module, supplying a code ref as an parameter option as in the synopis:

    <start_html>
    ...
    __PERL__
    use WebDyne::Cache qw(\&cache);
    sub cache {
    ...

=item 2. Via use of the meta-data field, with supply of the code ref in the <head> section of the document, e.g.

    <start_html meta="%{ 'WebDyne' => 'cache=&cache' }">
    ...
    __PERL__
    sub cache {
    ...

Or:

    <html>
    <head>
    <title>Cache Demo</title>
    <meta name="WebDyne" content="cache=&cache">
    </head>
    <body>
    ...
    __PERL__
    sub cache {
    ...

=item 3. Via use of the cache attribute in the start_html tag:

    <start_html cache="&cache">
    ...
    __PERL__
    sub cache {
    ...

=back

In all cases the routine must flag to the WebDyne engine that the page should be recompiled. After whatever logic is required to make that determination (time elapsed, user input etc.) it should call the cache_compile() method with a true value to flag recompilation is required.

=head1 METHODS

Methods below are not actually specific to the WebDyne::Cache module (they are presented by the main WebDyne module), but are listed here for convenience:

=over

=item * B<<< cache_mtime() >>>

Return a scalar ref of the cache file modification time in Unix epoch seconds.

=item * B<<< cache_compile() >>>

Flag that page recompilation is required by supplying a true value.

=item * B<<< inode() >>>

Get or set the UUID for a page. See Notes for usage in context of caching

=back

=head1 OPTIONS

WebDyne::Cache takes a single subroutine reference as an import parameter. No other options are available

=head1 NOTES

Pages are cached to static HTML via their inode (UUID) value. You can change the inode value in the cache code (usually according to an input parameter) to generate multiple cached versions of a single page, e.g.

    <start_html cache="&cache">
    <start_form>
    <popup_menu name="month" values="@{qw(Jan Feb Mar)}">
    <submit>
    __PERL__
    sub cache {
        my $self=shift();
        ... some tests ..
        $self->inode($_{'month'});
        $self->cache_compile(1) if <...something..>
        return 1;
    }
    
        return 

=head1 AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut