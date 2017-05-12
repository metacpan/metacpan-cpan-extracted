package Web::Dash;

use strict;
use warnings;
use Plack::Request;
use Plack::Util;
use File::Find ();
use Web::Dash::Lens;
use Encode;
use Future::Q 0.012;
use AnyEvent::DBus 0.31;
use AnyEvent;
use JSON qw(to_json);
use Try::Tiny;
use Carp;

my $index_page_template = <<'EOD';
<!DOCTYPE html>
<html>
  <head>
    <title>Web Dash</title>
    <style type="text/css">
body {
    padding: 3px 5px;
    color: #222;
    font-size: small;
}

a, a:visited, a:active {
    color: #302b95;
}

a:hover {
    text-decoration: underline;
}

ul {
    list-style-type: none;
    padding: 0;
    margin: 0;
}

li, .search-result-hint, .search-result-error {
    padding: 3px 4px;
    margin: 3px;
    border-width: 0;
    border-radius: 3px;
    background-color: #f6f6f6;
}

.search-result-hint {
    background-color: #dcffaf;
    padding-left: 10px;
}

.search-result-error {
    background-color: #ffafc2;
    padding-left: 10px;
}

#lens-selector {
    width: 200px;
    float: left;
}

#results {
    margin: 0 10px 0 210px;
}

.search-result {
    padding-left: 10px;
    overflow: auto;
}

.search-result-list-limited {
    overflow: auto;
    max-height: 200px;
}

.search-category {
    font-size: normal;
    margin: 5px 0px;
}

.search-category-num, .search-result-list-toggler {
    margin-left: 8px;
    font-size: small;
    font-weight: normal;
}

.search-result-name {
    margin: 0;
    padding: 0 0 5px 0;
    font-size: normal;
}

.search-result-icon {
    display: block;
    max-width: 80px;
    max-height: 80px;
    float: left;
    margin-right: 5px;
}

.search-result-desc {
    color: #505050;
    font-size: small;
}

    </style>
  </head>
  <body>
    <div>
      <input id="query" type="text" autofocus autocomplete="off" />
      <span id="spinner"></span>
      <span id="results-num"></span>
    </div>
    <ul id="lens-selector">
    [%LENSES_LIST%]
    </ul>
    <div id="results">
      <div class="search-result-hint">Hint: You can change lens with arrow Up and Down keys.</div>
    </div>
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript">
$(function() {
    var executeSearch = function(lens_name, query_string) {
        return $.ajax({
            url: "search.json",
            data: { lens: lens_name, q: query_string },
            dataType: "json",
            type: 'GET',
        }).then(null, function(jqxhr, text_status, error_thrown) {
            return $.Deferred().reject("ajax error: " + text_status + ", " + error_thrown);
        });
    };
    var SimpleSpinner = function(sel) {
        this.sel = sel;
        this.count = 0;
        this.timer = null;
        this.dot_pos = 0;
        this.dot_length = 4;
        this.full_length = 12;
        this.interval_ms = 100;
    };
    SimpleSpinner.prototype = {
        _clear: function() {
            $(this.sel).empty();
        },
        _render: function() {
            var self = this;
            var str = "";
            var i;
            var dot_min = (self.dot_pos + self.dot_length) % self.full_length;
            for(i = 0 ; i < self.full_length ; i++) {
                if((self.dot_pos <= dot_min && i >= self.dot_pos && i < dot_min)
                  || (self.dot_pos > dot_min && (i >= self.dot_pos || i < dot_min) )) {
                    str += ".";
                }else {
                    str += "&nbsp";
                }
            }
            $(self.sel).html(str);
        },
        _set: function(new_count) {
            var self = this;
            self.count = new_count;
            if(self.count <= 0) {
                self.count = 0;
                if(self.timer !== null) {
                    clearInterval(self.timer);
                    self.timer = null;
                }
                self._clear();
            }
            if(self.count > 0 && self.timer === null) {
                self.timer = setInterval(function() {
                    self.dot_pos = (self.dot_pos + 1) % self.full_length;
                    self._render();
                }, self.interval_ms)
            }
        },
        begin: function() { this._set(this.count + 1) },
        end: function() { this._set(this.count - 1) }
    };
    var EventRegulator = function(wait, handler) {
        this.wait_ms = wait;
        this.handler = handler;
        this.timeout_obj = null;
    };
    EventRegulator.prototype = {
        trigger: function(task) {
            var self = this;
            if(self.timeout_obj !== null) {
                clearTimeout(self.timeout_obj);
            }
            self.timeout_obj = setTimeout(function() {
                self.handler(task);
                self.timeout_obj = null;
            }, self.wait_ms);
        },
    };

    var spinner = new SimpleSpinner('#spinner');
    
    var results_manager = {
        LIMIT_THRESHOLD_ITEM_NUM: 5,
        sel: '#results',
        sel_num: '#results-num',
        showError: function(error) {
            $(this.sel_num).empty();
            var $results = $(this.sel);
            $results.empty();
            $('<div class="search-result-error"></div>').text(error).appendTo($results);
        },
        _createCategoryGroups: function(results) {
            var groups = {};
            var groups_list = [];
            $.each(results, function(i, result) {
                if(result.name === "") return true;
                if(!(result.category_index in groups)) {
                    groups[result.category_index] = [];
                }
                groups[result.category_index].push(result);
            });
            $.each(groups, function(i, group) {
                groups_list.push(group);
            });
            return groups_list.sort(function(list_a, list_b) {
                return list_a.length > list_b.length;
            });
        },
        _setListLimit: function($category_header, is_limited) {
            var $category_list = $category_header.next("ul");
            var $toggler = $category_header.find(".search-result-list-toggler");
            if($toggler.size() === 0) return;
            if(is_limited) {
                // toggle to limited
                $category_list.addClass("search-result-list-limited");
                $toggler.text("Show more");
            }else {
                // toggle to unlimited
                $category_list.removeClass("search-result-list-limited");
                $toggler.text("Show less");
            }
        },
        toggleListLimit: function($category_header) {
            this._setListLimit($category_header,
                               !$category_header.next("ul").hasClass("search-result-list-limited"));
        },
        show: function(results) {
            var self = this;
            var $results = $(self.sel);
            var category_group_list = self._createCategoryGroups(results)
            $(self.sel_num).text("total " + results.length + " result" + (results.length > 1 ? "s" : ""));
            $results.empty();
            $.each(category_group_list, function(group_index, group) {
                var $results_list = $('<ul></ul>');
                var $category = $('<h2 class="search-category"></h2>');
                $category.text(group[0].category.name);
                $('<span class="search-category-num"></span>')
                    .text(group.length + (group.length > 1 ? " results" : " result")).appendTo($category);
                if(group.length > self.LIMIT_THRESHOLD_ITEM_NUM) {
                    $('<a class="search-result-list-toggler" href="#"></a>').appendTo($category);
                }
                $category.appendTo($results);
                $.each(group, function(j, result) {
                    var $li = $('<li class="search-result"></li>');
                    var $name = $('<h3 class="search-result-name"></h3>');
                    if(result.dnd_uri === "") {
                        $name.text(result.name);
                    }else {
                        $('<a></a>').attr('href', result.dnd_uri).text(result.name).appendTo($name);
                    }
                    $li.append($name);
                    if(result.icon_hint && result.icon_hint.match("^https?://")) {
                        $('<img />').attr('src', result.icon_hint).addClass('search-result-icon').appendTo($li);
                    }
                    if(result.comment !== "") {
                        $('<div class="search-result-desc"></div>').text(result.comment).appendTo($li);
                    }
                    $li.appendTo($results_list);
                });
                $results_list.appendTo($results);
                self._setListLimit($category, (group_index !== category_group_list.length - 1));
            });
        },
    };
    var lens_manager = {
        lens_index: 0,
        sel_lens_index: '#lens-selector',
        on_change_listeners: [],
        setLensIndex: function(new_index) {
            var self = this;
            var $radios = $(self.sel_lens_index).find('input');
            var changed = (self.lens_index != new_index);
            self.lens_index = new_index % $radios.size();
            if(self.lens_index < 0) self.lens_index += $radios.size();
            
            $radios.removeAttr('checked');
            $radios.get(self.lens_index).checked = true;
            if(changed) {
                $.each(self.on_change_listeners, function(i, listener) {
                    listener(self);
                });
            }
        },
        getLensIndex: function() {
            return this.lens_index;
        },
        getCurrentLensName: function() {
            var self = this;
            return $(self.sel_lens_index).find('input').eq(self.lens_index).attr("value");
        },
        up: function() { this.setLensIndex(this.getLensIndex() - 1) },
        down: function() { this.setLensIndex(this.getLensIndex() + 1) },
        onChange: function(listener) {
            var self = this;
            self.on_change_listeners.push(listener);
        },
    };
    lens_manager.setLensIndex(0);
    
    var search_form = {
        sel_query: '#query',
        
        execute: function() {
            var query_string = $(this.sel_query).val();
            if(query_string === "") {
                return;
            }
            var lens_name = lens_manager.getCurrentLensName();
            spinner.begin();
            executeSearch(lens_name, query_string).then(function(result_object) {
                if(result_object.error !== null) {
                    return $.Deferred().reject(result_object.error);
                }
                if(result_object.results.length === 0) {
                    return $.Deferred().reject("No result for query '" + query_string + "'");
                }
                results_manager.show(result_object.results);
            }).then(null, function(error) {
                results_manager.showError(error);
                return $.Deferred().resolve();
            }).then(function() {
                spinner.end();
            });
        },
    };

    
    lens_manager.onChange(function() { search_form.execute() });
    var type_event_regulator = new EventRegulator(500, function() {
        search_form.execute();
    });
    $('#query').on('input', function() {
        type_event_regulator.trigger();
    }).on('keydown', function(e) {
        switch(e.keyCode) {
        case 38:
            lens_manager.up();
            break;
        case 40:
            lens_manager.down();
            break;
        }
    });
    $('#lens-selector').on('click', 'input', function(e) {
        lens_manager.setLensIndex($(this).data('lens-index'));
    });
    $('#results').on('click', '.search-result-list-toggler', function(e) {
        results_manager.toggleListLimit($(this).parent());
        return false;
    });
});
    </script>
  </body>
</html>
EOD

sub _render_lenses_info {
    my ($lenses_info_ref) = @_;
    return join "", map {
        my $lens = $lenses_info_ref->[$_];
        my $name = Plack::Util::encode_html($lens->{name});
        my $hint = Plack::Util::encode_html($lens->{hint});
        qq{<li><label><input type="radio" name="lens" value="$name" data-lens-index="$_" />$hint</label></li>\n};
    } 0 .. $#$lenses_info_ref;
}

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        lenses => [],
        lens_for_service_name => {},
        cache_index_page => undef,
    }, $class;
    if(defined $args{lenses}) {
        croak "lenses param must be an array-ref" if ref($args{lenses}) ne 'ARRAY';
        $self->{lenses} = $args{lenses};
    }else {
        $self->_init_lenses(defined($args{lenses_dir}) ? $args{lenses_dir} : '/usr/share/unity/lenses');
    }

    if(@{$self->{lenses}}) {
        ## ** Wait for all the lenses to respond and recreate them.
        ## ** This is because lenses can be unstable at first.
        ## ** See xt/spawning-lens.t for detail.
        my $cv = AnyEvent->condvar;
        foreach my $lens (@{$self->{lenses}}) {
            $cv->begin;
            $lens->search_hint->then(sub { $cv->end })
        }
        $cv->recv;
        $self->_recreate_lenses();
        %{$self->{lens_for_service_name}} = map { $_->service_name => $_ } @{$self->{lenses}};
    }
    
    return $self;
}

sub _init_lenses {
    my ($self, @search_dirs) = @_;
    File::Find::find(sub {
        my $filepath = $File::Find::name;
        return if $filepath !~ /\.lens$/;
        push(@{$self->{lenses}}, Web::Dash::Lens->new(lens_file => $filepath));
    }, @search_dirs);
}

sub _recreate_lenses {
    my ($self) = @_;
    my @new_lenses = map { $_->clone } @{$self->{lenses}};
    $self->{lenses} = \@new_lenses;
}

sub _render_index {
    my ($self, $req) = @_;
    return sub {
        my ($responder) = @_;
        if(defined $self->{cache_index_page}) {
            $responder->([
                200, ['Content-Type', 'text/html; charset=utf8'],
                [$self->{cache_index_page}]
            ]);
            return;
        }
        Future::Q->wait_all(map { $_->search_hint } @{$self->{lenses}})->then(sub {
            my (@search_hints) = map { $_->get } @_;
            my @lenses_info = map {
                my $hint = $search_hints[$_];
                my $lens = $self->{lenses}[$_];
                +{hint => $hint, name => $lens->service_name};
            } (0 .. $#search_hints);
            my $lenses_list = _render_lenses_info(\@lenses_info);
            my $page = $index_page_template;
            $page =~ s/\[%LENSES_LIST%\]/$lenses_list/;
            $page = Encode::encode('utf8', $page);
            $self->{cache_index_page} = $page;
            $responder->([
                200, ['Content-Type', 'text/html; charset=utf8'],
                [$page]
            ]);
        })->catch(sub {
            my $error = shift;
            $responder->([
                500, ['Content-Type', 'text/plain'],
                [Encode::encode('utf8', $error)]
            ]);
        });
    };
}

sub _json_response {
    my ($response_object, $code) = @_;
    if(!defined($code)) {
        $code = $response_object->{error} ? 500 : 200;
    }
    return [
        $code, ['Content-Type', 'application/json; charset=utf8'],
        [to_json($response_object, {ascii => 1})]
    ];
}

sub _render_search {
    my ($self, $req) = @_;
    return sub {
        my $responder = shift;
        my $lens_name = $req->query_parameters->{lens} || 0;
        my $query_string = Encode::decode('utf8', scalar($req->query_parameters->{'q'}) || '');
        my $lens = $self->{lens_for_service_name}{$lens_name};
        Future::Q->try(sub {
            if(not defined $lens) {
                die "Unknown lens name: $lens_name\n";
            }
            return $lens->search($query_string);
        })->then(sub {
            my @results = @_;
            if(@results) {
                return Future::Q->needs_all(map { $lens->category($_->{category_index}) } @results)->then(sub {
                    my (@categories) = @_;
                    foreach my $i (0 .. $#categories) {
                        $results[$i]{category} = $categories[$i];
                    }
                    return @results;
                })->catch(sub {
                    my $e = shift;
                    warn "WARN: $e";
                    return @results;
                });
            }
            return @results;
        })->then(sub {
            $responder->(_json_response({error => undef, results => \@_}), 200);
        })->catch(sub {
            my $e = shift;
            $responder->(_json_response({error => $e}, 500));
        });
    };
}

sub to_app {
    my $self = shift;
    return sub {
        my ($env) = @_;
        my $req = Plack::Request->new($env);
        if($req->path eq '/') {
            return $self->_render_index($req);
        }elsif($req->path eq '/search.json') {
            return $self->_render_search($req);
        }else {
            return [404, ['Content-Type', 'text/plain'], ['Not Found']];
        }
    };
}


our $VERSION = '0.041';

1;

__END__

=pod

=head1 NAME

Web::Dash - Unity Dash from Web browsers (experimental)

=head1 DESCRIPTION

L<Web::Dash> is a Web application version of Unity Dash.
Unity Dash is a powerful searching tool integrated in Unity desktop environment,
which is employed by Ubuntu Linux.

For detail of Unity, See L<https://wiki.ubuntu.com/Unity>

L<Web::Dash> acts like Unity Dash without the need of the whole Unity infrastructure.
All you need is some Lenses (searching agents) and your favorite Web browser,
and you can have the awesome searching power of Dash.

=head1 CAVEAT

=head2 This is an experimental application

L<Web::Dash> is quite an B<experimental> application.

It is not based on any official specification or documentation about Unity Dash or Unity Lens.
Instead, I analyzed the behavior of Unity Dash and Unity Lenses from outside,
and implemented what I guess was the correct usage of them.

I tested L<Web::Dash> in Ubuntu 12.04 and Xubuntu 12.04.
However it may not work as expected in other environments.
It is also possible for L<Web::Dash> to stop working in future versions of Unity or Ubuntu.

=head2 Privacy issues

Some Lenses are meant to search the local file system.
If you export those lenses to others, they are able to
see names of your files.

=head1 SCREENSHOTS

See L<https://github.com/debug-ito/Web-Dash/wiki/Screenshots>

=head1 TUTORIAL

=head2 Installation

To install L<Web::Dash>, first you need development tools and files for libexpat and libdbus.

    $ sudo apt-get install build-essential pkg-config libexpat1-dev libdbus-1-dev

Then, type

    $ sudo sh -c 'wget -O- http://cpanmin.us | perl - Web::Dash'

to install L<Web::Dash> from CPAN.

Of course, if you already have a CPAN client installed, you can type

    $ sudo cpanm Web::Dash


=head2 Installing some lenses

Most Unity Lenses are provided as .deb packages named C<unity-lens-*>.

In Ubuntu, some Lens packages are served by "extra" repository.
Make sure the repository is enabled in your system.

    $ grep extras /etc/apt/sources.list
    deb http://extras.ubuntu.com/ubuntu precise main
    deb-src http://extras.ubuntu.com/ubuntu precise main

Uncomment the deb lines if they are commented out.

To install Github lens, for example, type

    $ sudo apt-get update
    $ sudo apt-get install unity-lens-github


=head2 Start webdash

To start webdash, type

    $ webdash
    Twiggy: Accepting connections at http://127.0.0.1:5000/

Access the URL with a Web browser.


=head2 Run webdash in Ubuntu Server

In a non-GUI environment, first you need to execute the following.

    $ eval `dbus-launch --auto-syntax`

This will launch a DBus daemon for a session bus,
and set the environment variables necessary to access the bus.

After that, run C<webdash> as usual.

    $ webdash

If you run C<webdash> at startup (e.g., in /etc/rc.local),
B<< make sure to specify C<LANG> environment variable. >>
Lens processes need the C<LANG> environment variable to be set.


=head1 WEB API

L<Web::Dash> has a Web API for searching. See L<Web::Dash::WebAPI>.


=head1 AS A MODULE

As a Perl module, L<Web::Dash> provides a class object that can generate a L<PSGI> application.
You can use L<Web::Dash> in your .psgi file to customize which Lenses to export.

=head1 SYNOPSIS

In your app.psgi file.

    use Web::Dash;
    
    Web::Dash->new(lenses_dir => '/your/personal/lenses/directory')->to_app;

Or, if you want to select lenses...

    use Web::Dash;
    use Web::Dash::Lens;

    my @lenses;
    foreach my $lens_file (
        'extras-unity-lens-github', 'video'
    ) {
        push(@lenses, Web::Dash::Lens->new(
            lens_file => "/usr/share/unity/lenses/$lens_file/$lens_file.lens"
        ));
    }
    Web::Dash->new(lenses => \@lenses)->to_app;


=head1 CLASS METHODS

=head2 $dash = Web::Dash->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<lenses_dir> => DIRECTORY_PATH (optional, default: '/usr/share/unity/lenses')

Specifies the root directory path under which it searches for lens files.

It loads *.lens files under this directory and creates L<Web::Dash::Lens> objects from them.

=item C<lenses> => ARRAYREF_OF_LENSES (optional)

Specifies an array-ref of L<Web::Dash::Lens> objects that you want to use with L<Web::Dash>.

If this option is specified, C<lenses_dir> option is ignored.

=back

=head1 OBJECT METHODS

=head2 $psgi_app = $dash->to_app()

Creates a L<PSGI> application from the C<$dash>.

Note that the PSGI application uses L<AnyEvent> for asynchronous responses.
Use L<AnyEvent>-compatible PSGI servers (like L<Twiggy>) to run the app.

=head1 SEE ALSO

=over

=item L<webdash>

Web::Dash daemon runner script.

=item L<Web::Dash::Lens>

An experimental Unity Lens object.

=back

=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=head1 REPOSITORY

L<https://github.com/debug-ito/Web-Dash>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
