#! /usr/bin/perl

package Tk::PerlMethodList;
our $VERSION = 0.07;

use warnings;
use strict;
#use Data::Dumper;
use File::Slurp qw /read_file/;
require Tk;
require Tk::LabEntry;
require Tk::NumEntry;
require Tk::ROText;
require Class::Inspector;
require B ;
use MRO::Compat;
use Devel::Peek qw(CvGV);
our @ISA    = ('Tk::Toplevel');

=head1 NAME

Tk::PerlMethodList - query the Symbol-table for methods (subroutines) defined in a class (package) and its parents.

=head1 SYNOPSIS


require Tk::PerlMethodList;

my $instance = $main_window->PerlMethodList();

=head1 DESCRIPTION

Tk::PerlMethodList is a Tk::Toplevel-derived widget.

The window contains entry fields for a classname and a regex. The list below displays the subroutine-names in the package(s) of the given classname and its parent classes. The list displays the sub-names present in the the symbol-table. In case of imported subs, the last field of a row contains the name of the aliased sub as reported by DevelPeek::CvGV. Tk::PerlMethodList will not show subs which can be - but have not yet been autoloaded. It will show declared subs though. The 'Filter' entry takes a regex to filter the returned List of sub/methodnames.

If the file containing a subroutine definition can be found in %INC, a green mark will be displayed at the beginning of the line. The sourcecode will be displayed by clicking on the subs list-entry.


Method list and source window have Control-plus and Control-minus bindings to change fontsize.



=head1 METHODS

B<Tk::PerlMethodList> supports the following methods:

=over 4

=item B<classname(>'A::Class::Name'B<)>

Set the classname-entry to 'A::Class::Name'.

=item B<filter(>'a_regex'B<)>

Set the filter-entry to 'a_regex'.

=item B<show_methods()>

Build the list for classname and filter present in the entry-fields.

=back

=head1 OPTIONS

B<Tk::PerlMethodList> supports the following options:

=over 4

=item B<-classname>

$instance->configure(-classname =>'A::Class::Name')
Same as classname('A::Class::Name').

=item B<-filter>

$instance->configure(-filter =>'a_regex')
Same as filter('a_regex').


=back

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut


Tk::Widget->Construct('PerlMethodList');
unless (caller()) {
    _test_();
}

sub Populate{
    my ($self,@args) = @_;
    $self->SUPER::Populate(@args);
    my $frame    = $self -> Frame()->pack(-fill => 'x',
                                          -padx => 20,
                                          -pady => 4,
                                      );
    my $fr_left  = $frame-> Frame()->pack(-side => 'left',
                                          -fill => 'y');
    my $fr_mid = $frame-> Frame(-relief      => 'sunken',
                                  -borderwidth => 2,
                              )->pack(-side => 'left',
                                      -padx => 10);
    my $fr_right  = $frame-> Frame()->pack(-side => 'left',
                                           -fill => 'y',
                                           -padx => 20);

    my $fr_overr = $fr_left->Frame()->pack(-anchor => 'nw',
                                           -pady   => 1
                                       );
    my $fr_source= $fr_left->Frame()->pack(-anchor => 'nw',
                                           -pady   => 1,
                                       );
    $fr_overr->Label(-width => 1,
                     -bg    => 'orange')->pack(-side => 'left');
    $fr_overr->Label(-text  => 'overridden if called as a method',
                 )->pack(-side => 'left');
    $fr_source->Label(-width => 1,
                      -bg    => 'green')->pack(-side => 'left');
    $fr_source->Label(-text  => 'sourcecode can be displayed',
                 )->pack(-side => 'left');
    my @btn_data = (['Classname',\$self->{classname}],
                    ['Filter'   ,\($self->{filter}||='')]);

    @$self{qw/entry_cl entry_f/}= 
        map {my $e = $fr_mid -> LabEntry(-label       => $_->[0],
                                         -textvariable=> $_->[1],
                                         -labelPack   => [-side=>'left'],
                                    ) ->pack(-anchor => 'e');
             $e->Subwidget('entry')->configure(-background => 'white');
             $e;
         } @btn_data;


    my $btn   = $fr_mid -> Button (-text   => 'show methods',
                                     -command=> sub{$self->show_methods}
                                 )->pack;
    my $text  = $self -> Scrolled('ROText',
                                  -wrap         => 'none',
                                  -insertontime => 0,
                              )->pack(-fill   => 'both',
                                      -expand => 1,
                                  );
    my $font  = $self -> fontCreate(-family => 'Courier',
                                    -size   => 12,
                                );
    $text->configure(-font=>$font);
    $text->tagConfigure('overridden',-background => 'orange');
    $text->tagConfigure('source_ok' ,-background => 'green');
    $text->tagConfigure('white'     ,-background => 'white');

    $text->menu(undef);         #disable

    $self -> Label(-textvariable=>\$self->{status})->pack;

    $fr_right->Label(-text => 'Fontsize:',
                 )->pack(-side => 'left',
                         -padx => 10,
                         );
    my $ne;
    $ne  = $fr_right->NumEntry(-minvalue => 8,
                               -maxvalue => 16,
                               -value    => 12,
                               -width    => 3,
                               -readonly => 1,
                               -browsecmd=> sub{
                                   $self->_change_fontsize($ne->cget('-value'))
                               },
                           )->pack(-side => 'left');
    
    $text->bind('<Control-plus>',sub{$ne->incdec(1)});
    $text->bind('<Control-minus>',sub{$ne->incdec(-1)});
    $text->bind('<1>',sub{$self->_text_click});
    $text->bind('<Motion>',sub {$self->_adjust_selection});
    for my $w (@$self{qw/entry_cl entry_f/}) {
        $w->bind('<Return>',sub{$btn->Invoke});
    }
    $text->focus;

    @$self{qw/text font list/}= ($text,$font,[]);

    $self->ConfigSpecs(-background  => [$text,'','','white'],
                       -classname   => ['METHOD'],
                       -filter      => ['METHOD'],
                       DEFAULT      => ['SELF'],
                   );
    return $self;
}

sub _adjust_selection{
    my $self = shift;
    my $w = $self->{text};
    $w->unselectAll;
    $w->adjustSelect;
    $w->selectLine;
}

sub _change_fontsize{
    my $self = shift;
    my $size = $_[0];
    my ($text,$font) = @$self{qw/text font/};
    $text->fontConfigure($font,'-size',$size);
}


sub _text_click{
    my $self = shift;
    my $w    = $self->{text};
    my $position = $w->index('current');
    my $line;
    if ($position =~ m/^(\d+)\./) {
        $line = $1;
    } else {
        return
    }
    my $idx  = $line - 1; #line range starts at 1

    my $file = $self->{list}[$idx]{file};
    my $methodname = $self->{list}[$idx]{sourcesymbol};
    my $re = qq/sub\\s+$methodname(\\W.*)?\$/;
    $self->_start_code_view($file,$re);
}

sub _get_methods{
    my $self = shift;
    my $class_name = $self->{classname};
    my $filter = $self->{filter};
    my $regex = qr/$filter/i ;

    my @function_list;
    my $classes = mro::get_linear_isa($class_name);
    my %overridden;
    foreach my $class (@$classes) {
        no strict 'refs';
        my @list;
        my $s_t_r = \%{$class."::"};
        use strict ;
        foreach my $key ( keys %$s_t_r) {
            next unless ($key =~ $regex);
            my $var =  \ ( $s_t_r->{$key} );
            my $state;
            ref $var eq 'GLOB' && *{$var}{CODE}
                && ($state = 'declared')
                && defined &{*{$var}{CODE}} && ($state = 'defined');

            ref $var eq 'SCALAR' && $$var == -1 && ($state = 'declared');
            
            if ($state) {
                my $overridden = $overridden{$key} || 0;
                my $definition = '';
                my $file = '';
                if ($state eq 'defined'){
                    $definition .= CvGV(*{$var}{CODE});
                    my $o = B::svref_2object(*{$var}{CODE});
                    $file = $o->FILE;# to do: fix .al
                }
                $overridden{$key} = 1;
                push @list , {symbol       => $key,
                              state        => $state,
                              package      => $class,
                              overridden   => $overridden,
                              defined_as   => $definition,
                              file         => $file,
                          };
            }
        }
        @list = sort {lc $a->{symbol}cmp lc $b->{symbol}} @list;
        push @function_list,@list;
    }
    $self->{list} = \@function_list;
    return $self;
}

sub _grep_sources{
    my $self = shift;
    my $list = $self->{list};
    $self->_set_source_fields;
    my $last_filename = '';
    my $module_source = '';
    for my $element (@$list) {

        my $converted    = $self-> _convert_filename($element->{file});
        $element->{file} = $converted if  $converted; 
        unless ($element->{file}){
            # fallback: check package file for autosplit defs
            $element->{file}
                = $self-> _convert_packagename($element->{package});
        }
        my $filename = $element->{file};
        next unless $filename;
        if ($filename && ($filename ne $last_filename)){
            $module_source = read_file($filename, err_mode=>'quiet') || '';
            $last_filename = $filename;
        }
        my $symbol = $element->{sourcesymbol};
        $element->{source_avail} 
            = ($module_source =~/sub\s+$symbol(\W.*)?$/m)?
                1 : 0;
        
    }
    return $self;
}

sub _set_source_fields{
    my $self = shift;
    my $list = $self->{list};
    for my $element (@$list) {
        if ($element->{defined_as} =~ /\*(.*)::(.*)$/){
            $element->{sourcepackage} = $1;
            $element->{sourcesymbol}  = $2;
            $element->{defined_as} =~ s/^\*/alias to:  /;
        }
        my $is_alias = 0;
        for (qw/symbol package/){
            $element->{"source$_"}||= $element->{$_};
            unless($element->{$_} eq $element->{"source$_"}){
               # $defined_as = $element->{defined_as};
                $is_alias = 1;
                last;
            }
        }
        $element->{defined_as} = '' unless $is_alias;
    }
}


sub show_methods{
    my $self = shift;
    my ($text,$classname) = @$self{qw/text classname/};
    $text->delete('1.0','end');
    $self->{indexmap} = [];

    eval "require $classname";
    # now check if package $classname is loaded -
    # package $classname needn't be defined in the required file...


    unless (Class::Inspector->loaded($classname)) {
        $self->{list}= [];
        $self->{status}="Error: package '$classname' not loaded!";
        return;
    }

    $self->{status}="Showing methods for '$classname'";

    $self->{inc_files} = {map {$INC{$_}, 1} keys(%INC)};

    $self->_get_methods
         ->_grep_sources;
    my $list = $self->{list};
    my %max_width = ( symbol     => 0,
                      package    => 0,
                      defined_as => 0,
                      file       => 0,
                  );
    for my $element (@$list) {
        map {my $length = length($element->{$_})+2;
             $max_width{$_} =  $length if $length > $max_width{$_};
         } qw/symbol package defined_as file/;
    }
    for my $element (@$list) {
            my $line = sprintf( '%-'.$max_width{package}.'s'
                               .'%-'.$max_width{symbol}.'s'
                               .'%-'.$max_width{file}.'s'
                               .'%-12s'
                               .'%-'.$max_width{defined_as}.'s',

                               $element->{package},
                               $element->{symbol} ,
                               $element->{file},
                               $element->{state},
                               $element->{defined_as},
                           )."\n";
            $text->insert('end',# provide pairs of content, tag:
                          '  ',
                          $element->{overridden} ? 'overridden': 'white',# tag
                           '  ',
                          $element->{source_avail}? 'source_ok': 'white',# tag
                          $line, '');
    }
    return $self;
}

sub _convert_filename{
    my ($self,$filename) = @_;
    my $inc_files = $self->{inc_files};

    my $path_name =  exists ($inc_files->{$filename})? $filename : '';
    # If $filename is not in $inc_files, it might be a .al file:
    unless ($path_name){
        if ($filename =~ m|autosplit into .*lib.auto.(.*\.al)|){
            my $seg = $1;
            $seg =~ y|\\|/|;
            for (keys %$inc_files){
                if ($_ =~ /$seg/){
                    $path_name = $_;
                    last;
                }
            }
        }
    }
    return $path_name;
}
sub _convert_packagename{
    my ($self,$package) = @_;
    $package =~  s#::#/#g;
    $package.='.pm';
    return $INC{$package}||'';
}
sub classname{
    my ($self,$classname) = @_;
    $self->{classname} = $classname if $classname;
    $self->{classname};
}
sub filter{
    my ($self,$filter) = @_;
    $self->{filter} = $filter;
    $filter;
}

sub _start_code_view{
    my $self = shift;
    my ($filename,$regex)=@_;
    return unless $filename;
    my $c_v = $self->{c_v};
    $self->{c_v_entry_filter}= $regex;
    unless ($c_v && $c_v->Exists){
        $self->_code_view_init_top();
        $c_v = $self->{c_v};
    } else {
        $c_v->deiconify;
        $c_v->raise;
    }
    my $text = $self->{c_v_text};
    $text->delete('0.0','end');

    my $content = read_file($filename,
                          err_mode=> 'quiet',
                      );
    unless ($content){
        $self->messageBox(-message => "No file '$filename' found",
                         # -font    => 'Helvetica 14',
                          -title   => 'Error',
                      );
        $c_v->withdraw;
        return;
    }
    $c_v->configure(-title=>$filename);
    $text->insert('end',$content);
    $c_v->focus();
    $self->_c_v_filter_changed() if $regex;
}
sub _code_view_init_top{
    my $self = shift;
    my $c_v = $self->Toplevel();
    my $top_fr = $c_v->Frame()->pack;
    my $frame = $top_fr->Frame()->pack;
    my $text     = $c_v->Scrolled('ROText',
                                  -wrap => 'none',
                                  -bg   => 'white',
                              )->pack(-fill   => 'both',
                                      -expand => 1,
                                  );
    my $entry = $frame ->LabEntry(-label       => 'Filter',
                                  -labelPack   => [-side=>'left'],
                                  -textvariable=>\($self->{c_v_entry_filter}||=''),
                                  -bg          =>'white'
                              )->pack(-side => 'left',
                                      );
    my $font  = $self -> fontCreate(-family => 'Courier',
                                    -size   => 12,
                                );

    $text->configure(-font => $font);

    $entry->bind('<Return>',sub {$self->_c_v_filter_changed});

    $frame->Button(-text    =>'Find Next',
                   -command => sub{$self->_c_v_filter_changed},
               )->pack(-side => 'left',
                       -padx => 10);
    $frame->Label(-text => 'Fontsize:')->pack(-side => 'left',
                                             -padx => 10);
    my $ne;
    $ne  = $frame->NumEntry(-minvalue => 8,
                            -maxvalue => 16,
                            -value    => 12,
                            -width    => 3,
                            -readonly => 1,
                            -browsecmd=> sub{
                                   $self->_c_v_change_fontsize(
                                            $ne->cget('-value'))
                               },
                        )->pack(-side => 'left');

    $text->bind('<Control-plus>',sub{$ne->incdec(1)});
    $text->bind('<Control-minus>',sub{$ne->incdec(-1)});

    @$self{qw/c_v c_v_text c_v_font/} = ($c_v,$text,$font);
    #allow one code_view window only:
    $c_v->protocol("WM_DELETE_WINDOW",sub{$c_v->withdraw});
}
sub _c_v_filter_changed{
    my $self = shift;
    my $text = $self->{c_v_text};
    $text->focus;
    $text->FindNext(-forward=>'-regex','-case',$self->{c_v_entry_filter});
}

sub _c_v_change_fontsize{
    my $self = shift;
    my $size = $_[0];
    my ($text,$font) = @$self{qw/c_v_text c_v_font/};
    $text->fontConfigure($font,'-size',$size);
}

sub _test_{
    my $mw = Tk::tkinit();
    $mw->PerlMethodList(-classname=>'Tk::MainWindow')->show_methods;

    Tk::MainLoop();
}
1;
