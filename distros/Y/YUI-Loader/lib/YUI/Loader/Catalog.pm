package YUI::Loader::Catalog;

use strict;
use warnings;

use Moose;
use JSON;
use Scalar::Util qw/blessed/;
use YUI::Loader::Entry;
use YUI::Loader::Item;
use YUI::Loader::Carp;

BEGIN { 
    my $json = JSON->new->relaxed(1);
    my $catalog = $json->decode(map { local $_ = $_; s/'/"/g; $_ } (<<_END_));
{
        'animation': {
            'type': 'js',
            'path': 'animation/animation-min.js',
            'requires': ['dom', 'event']
        },

        'autocomplete': {
            'type': 'js',
            'path': 'autocomplete/autocomplete-min.js',
            'requires': ['dom', 'event', 'datasource'],
            'optional': ['connection', 'animation'],
            'skinnable': true
        },

        'base': {
            'type': 'css',
            'path': 'base/base-min.css',
            'after': ['reset', 'fonts', 'grids']
        },

        'button': {
            'type': 'js',
            'path': 'button/button-min.js',
            'requires': ['element'],
            'optional': ['menu'],
            'skinnable': true
        },

        'calendar': {
            'type': 'js',
            'path': 'calendar/calendar-min.js',
            'requires': ['event', 'dom'],
            'skinnable': true
        },

        'charts': {
            'type': 'js',
            'path': 'charts/charts-min.js',
            'requires': ['element', 'json', 'datasource']
        },

        'colorpicker': {
            'type': 'js',
            'path': 'colorpicker/colorpicker-min.js',
            'requires': ['slider', 'element'],
            'optional': ['animation'],
            'skinnable': true
        },

        'connection': {
            'type': 'js',
            'path': 'connection/connection-min.js',
            'requires': ['event']
        },

        'container': {
            'type': 'js',
            'path': 'container/container-min.js',
            'requires': ['dom', 'event'],
            'optional': ['dragdrop', 'animation', 'connection'],
            'supersedes': ['containercore'],
            'skinnable': true
        },

        'containercore': {
            'type': 'js',
            'path': 'container/container_core-min.js',
            'requires': ['dom', 'event'],
            'pkg': 'container'
        },

        'cookie': {
            'type': 'js',
            'path': 'cookie/cookie-min.js',
            'requires': ['yahoo']
        },

        'datasource': {
            'type': 'js',
            'path': 'datasource/datasource-min.js',
            'requires': ['event'],
            'optional': ['connection']
        },

        'datatable': {
            'type': 'js',
            'path': 'datatable/datatable-min.js',
            'requires': ['element', 'datasource'],
            'optional': ['calendar', 'dragdrop'],
            'skinnable': true
        },

        'dom': {
            'type': 'js',
            'path': 'dom/dom-min.js',
            'requires': ['yahoo']
        },

        'dragdrop': {
            'type': 'js',
            'path': 'dragdrop/dragdrop-min.js',
            'requires': ['dom', 'event']
        },

        'editor': {
            'type': 'js',
            'path': 'editor/editor-min.js',
            'requires': ['menu', 'element', 'button'],
            'optional': ['animation', 'dragdrop'],
            'skinnable': true
        },

        'element': {
            'type': 'js',
            'path': 'element/element-min.js',
            'requires': ['dom', 'event']
        },

        'event': {
            'type': 'js',
            'path': 'event/event-min.js',
            'requires': ['yahoo']
        },

        'fonts': {
            'type': 'css',
            'path': 'fonts/fonts-min.css'
        },

        'get': {
            'type': 'js',
            'path': 'get/get-min.js',
            'requires': ['yahoo']
        },

        'grids': {
            'type': 'css',
            'path': 'grids/grids-min.css',
            'requires': ['fonts'],
            'optional': ['reset']
        },

        'history': {
            'type': 'js',
            'path': 'history/history-min.js',
            'requires': ['event']
        },

         'imagecropper': {
             'type': 'js',
             'path': 'imagecropper/imagecropper-min.js',
             'requires': ['dom', 'event', 'dragdrop', 'element', 'resize'],
             'skinnable': true
         },

         'imageloader': {
            'type': 'js',
            'path': 'imageloader/imageloader-min.js',
            'requires': ['event', 'dom']
         },

         'json': {
            'type': 'js',
            'path': 'json/json-min.js',
            'requires': ['yahoo']
         },

         'layout': {
             'type': 'js',
             'path': 'layout/layout-min.js',
             'requires': ['dom', 'event', 'element'],
             'optional': ['animation', 'dragdrop', 'resize', 'selector'],
             'skinnable': true
         }, 

        'logger': {
            'type': 'js',
            'path': 'logger/logger-min.js',
            'requires': ['event', 'dom'],
            'optional': ['dragdrop'],
            'skinnable': true
        },

        'menu': {
            'type': 'js',
            'path': 'menu/menu-min.js',
            'requires': ['containercore'],
            'skinnable': true
        },

        'profiler': {
            'type': 'js',
            'path': 'profiler/profiler-min.js',
            'requires': ['yahoo']
        },


        'profilerviewer': {
            'type': 'js',
            'path': 'profilerviewer/profilerviewer-min.js',
            'requires': ['profiler', 'yuiloader', 'element'],
            'skinnable': true
        },

        'reset': {
            'type': 'css',
            'path': 'reset/reset-min.css'
        },

        'reset-fonts-grids': {
            'type': 'css',
            'path': 'reset-fonts-grids/reset-fonts-grids.css',
            'supersedes': ['reset', 'fonts', 'grids', 'reset-fonts'],
            'rollup': 4
        },

        'reset-fonts': {
            'type': 'css',
            'path': 'reset-fonts/reset-fonts.css',
            'supersedes': ['reset', 'fonts'],
            'rollup': 2
        },

         'resize': {
             'type': 'js',
             'path': 'resize/resize-min.js',
             'requires': ['dom', 'event', 'dragdrop', 'element'],
             'optional': ['animation'],
             'skinnable': true
         },

        'selector': {
            'type': 'js',
            'path': 'selector/selector-min.js',
            'requires': ['yahoo', 'dom']
        },

        'simpleeditor': {
            'type': 'js',
            'path': 'editor/simpleeditor-min.js',
            'requires': ['element'],
            'optional': ['containercore', 'menu', 'button', 'animation', 'dragdrop'],
            'skinnable': true,
            'pkg': 'editor'
        },

        'slider': {
            'type': 'js',
            'path': 'slider/slider-min.js',
            'requires': ['dragdrop'],
            'optional': ['animation']
        },

        'tabview': {
            'type': 'js',
            'path': 'tabview/tabview-min.js',
            'requires': ['element'],
            'optional': ['connection'],
            'skinnable': true
        },

        'treeview': {
            'type': 'js',
            'path': 'treeview/treeview-min.js',
            'requires': ['event'],
            'skinnable': true
        },

        'uploader': {
            'type': 'js',
            'path': 'uploader/uploader.js',
            'requires': ['yahoo', 'dom', 'event', 'element']
        },

        'utilities': {
            'type': 'js',
            'path': 'utilities/utilities.js',
            'supersedes': ['yahoo', 'event', 'dragdrop', 'animation', 'dom', 'connection', 'element', 'yahoo-dom-event', 'get', 'yuiloader', 'yuiloader-dom-event'],
            'rollup': 8
        },

        'yahoo': {
            'type': 'js',
            'path': 'yahoo/yahoo-min.js'
        },

        'yahoo-dom-event': {
            'type': 'js',
            'path': 'yahoo-dom-event/yahoo-dom-event.js',
            'supersedes': ['yahoo', 'event', 'dom'],
            'rollup': 3
        },

        'yuiloader': {
            'type': 'js',
            'path': 'yuiloader/yuiloader-min.js',
            'supersedes': ['yahoo', 'get']
        },

        'yuiloader-dom-event': {
            'type': 'js',
            'path': 'yuiloader-dom-event/yuiloader-dom-event.js',
            'supersedes': ['yahoo', 'dom', 'event', 'get', 'yuiloader', 'yahoo-dom-event'],
            'rollup': 5
        },

        'yuitest': {
            'type': 'js',
            'path': 'yuitest/yuitest-min.js',
            'requires': ['logger'],
            'skinnable': true
        },

	'paginator': {
		'type': 'js',
		'path': 'paginator/paginator-min.js',
		'requires': ['event', 'element'],
		'optional': ['selector'],
		'skinnable': true
	}
}
_END_

    my $catalog_meta = $json->decode(map { local $_ = $_; s/\b(name|type)\b/"$1"/g; s/'/"/g; $_ } (<<_END_));
{
    "animation": {name: "Animation Utility", type: "utility"},
    "autocomplete": {name: "AutoComplete Control", type: "widget"},
    "base":{name: "Base CSS Package", type: "css"},
    "button":{name: "Button Control", type: "widget"},
    "calendar":{name:"Calendar Control", type: "widget"},
    "charts":{name:"Charts Control", type: "widget"},
    "colorpicker":{name:"Color Picker Control", type: "widget"},
    "connection":{name:"Connection Manager", type: "utility"},
    "container":{name:"Container Family", type: "widget"},
    "containercore":{name:"Container Core (Module, Overlay)", type: "widget"},
    "cookie":{name:"Cookie Utility", type: "utility"},
    "datasource":{name:"DataSource Utility", type: "utility"},
    "datatable":{name:"DataTable Control", type: "widget"},
    "dom":{name:"Dom Collection", type: "core"},
    "dragdrop":{name:"Drag &amp; Drop Utility", type: "utility"},
    "editor":{name:"Rich Text Editor", type: "widget"},
    "element":{name:"Element Utility", type: "utility"},
    "event":{name:"Event Utility", type: "core"},
    "fonts":{name:"Fonts CSS Package", type: "css"},
    "get":{name:"Get Utility", type: "utility"},
    "grids":{name:"Grids CSS Package", type: "css"},
    "history":{name:"Browser History Manager", type: "utility"},
    "imagecropper":{name:"ImageCropper Control", type: "widget"},
    "imageloader":{name:"ImageLoader Utility", type: "utility"},
    "json":{name:"JSON Utility", type: "utility"},
    "layout":{name:"Layout Manager", type: "widget"},
    "logger":{name:"Logger Control", type: "tool"},
    "menu":{name:"Menu Control", type: "widget"},
    "profiler":{name:"Profiler", type: "tool"},
    "profilerviewer":{name:"ProfilerViewer Control", type: "tool"},
    "reset":{name:"Reset CSS Package", type: "css"},
    "resize":{name:"Resize Utility", type: "utility"},
    "selector":{name:"Selector Utility", type: "utility"},
    "simpleeditor":{name:"Simple Editor", type: "widget"},
    "slider":{name:"Slider Control", type: "widget"},
    "tabview":{name:"TabView Control", type: "widget"},
    "treeview":{name:"TreeView Control", type: "widget"},
    "uploader":{name:"Uploader", type: "widget"},
    "yahoo":{name:"Yahoo Global Object", type: "core"},
    "yuiloader":{name:"Loader Utility", type: "utility"},
    "yuitest":{name:"YUI Test Utility", type: "tool"},
    "reset-fonts":{name:"reset-fonts.css", type: "rollup"},
    "reset-fonts-grids":{name:"reset-fonts-grids.css", type: "rollup"},
    "utilities":{name:"utilities.js", type: "rollup"},
    "yahoo-dom-event":{name:"yahoo-dom-event.js", type: "rollup"},
    "yuiloader-dom-event":{name:"yuiloader-dom-event.js", type: "rollup"},
    "paginator":{name:"Paginator Control", type: "widget"}
}
_END_

    while (my ($name, $value) = each %$catalog) {
        next unless $value->{skinnable};
        $catalog->{"$name-skin"} = {
            type => "css",
            path => "$name/assets/skins/sam/$name.css",
        };
        $catalog_meta->{"$name-skin"} = {
            type => "css",
            name => "Sam Skin for $name",
        };
    }

    my %catalog;
    my %dependency_graph;
    for my $entry (keys %$catalog) {
        $dependency_graph{$entry} = [ @{ $catalog->{$entry}->{requires} || [] } ];
        $catalog{$entry} = YUI::Loader::Entry->parse($entry => $catalog->{$entry});
        $catalog{$entry}->kind($catalog_meta->{$entry}->{type});
        $catalog{$entry}->description($catalog_meta->{$entry}->{name});
    }
    $catalog{'reset'}->rank(-300);
    $catalog{'reset-fonts'}->rank(-20);
    $catalog{'reset-fonts-grids'}->rank(-10);
    $catalog{'fonts'}->rank(-200);
    $catalog{'grids'}->rank(-100);
    $catalog{'base'}->rank(0);

    sub catalog {
        return \%catalog;
    }

    sub dependency_graph {
        return \%dependency_graph;
    }
}

sub name_list {
    my $self = shift;
    return keys %{ $self->catalog };
}

sub entry_list {
    my $self = shift;
    return values %{ $self->catalog };
}

sub entry {
    my $self = shift;
    my $name = shift;

    croak "Can't look up an entry without a name" unless $name;
    return $name if blessed $name && $name->isa("YUI::Loader::Entry");
    croak "Couldn't find entry for name \"$name\"" unless my $entry = $self->catalog->{$name};
    return $entry;
 
}

sub item {
    my $self = shift;
    my $name = shift;
    croak "Can't make an item without a name" unless $name;
    return $name if blessed $name && $name->isa("YUI::Loader::Item");
    my $filter;
    if (ref $name eq "ARRAY") {
        ($name, $filter) = @$name;
    }
    else {
        if      ($name =~ s/-min$//i) { $filter = "min" }
        elsif   ($name =~ s/-debug$//i) { $filter = "debug" }
    }
    my $entry = $self->entry($name);
    my $item = YUI::Loader::Item->new(entry => $entry, filter => $filter);
    return $item;
}

1;
