package WWW::Webrobot::Print::Html;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004-2006 ABAS Software AG

use UNIVERSAL;
use File::Path;
use WWW::Webrobot::Global;
use WWW::Webrobot::Ext::General::HTTP::Response;
use WWW::Webrobot::XHtml;
use WWW::Webrobot::HttpErrcode;
use WWW::Webrobot::XML2Tree;




=head1 NAME

WWW::Webrobot::Print::Html - write response content to the file system

=head1 DESCRIPTION

This module stores received content together with some navigation files
onto your file system.
You can view this site with any ordinary webbrowser
that supports frames
via the C<file://host/filename> protocol
(of course you may easily direct a webserver to show this site).

=head1 OUTPUT FORMAT

The output frames are numbered for reference purpose.

 +---+------------------------------+
 |   |                              |
 |   |               2              |
 |   |                              |
 |   +-----------------+------------+
 |   |                 |            |
 | 1 |                 |            |
 |   |       3         |    4       |
 |   |                 |            |
 |   |                 |            |
 |   |                 |            |
 +---+-----------------+------------+

 Frame  Description
 ======================================================================
 1      Single request/response.
        * select 'all' or 'failed' request
        * lines starting with '...' are dependend requests,
          see L<WWW::Webrobot::pod::Recur>
 2      * Testplan data along with result
        * Redirections and authentification
          * HTTP return code for every single request
          * click selects frames 3-4
 3      Request Header, Response Header, return code and code description
 4      Response content for
            source
                the source of the content
            display
                displayable (most browser don't do their best)
            display-xhtml
                xhtml if it was converted somewhere

=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=over

=cut


my $HTTP_ERRCODE = "http_errcode.html";
my $DOCTYPE = <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
EOF
my $green = "#808000";
my $SP = '&nbsp;';


=item $obj->new (%parms)

 dir   [optional] Directory name where to put the files
       DEFAULT: output_html/<testplanname>

=back

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    init($self, @_);
    return $self;
}

sub init {
    my $self = shift;
    my %p = (@_);

    $self->{navigation} = $p{navigation};
    $self->{_parm_dir} = $p{dir};

    $self->{entry_count} = 0;
    $self->{list_modes} = [
        [undef, "index.html", "list_all.html"],
        [undef, "index_fail.html", "list_fail.html"],
        [undef, "index_all_long.html", "list_all_long.html"],
    ];
}


sub global_start {
    my $self = shift;

    $self->{dir} = $self->{_parm_dir} ||
        "output_html/" . WWW::Webrobot::Global->plan_name();
    print "# " . __PACKAGE__ . " writing to $self->{dir}\n";
    -d $self->{dir} || mkpath([$self->{dir}], 1, 0777) ||
        die "Can't make dir=$self->{dir} err=$!";

    {
        local *ERRCODE;
        # create http error codes file
        open ERRCODE, ">$self->{dir}/$HTTP_ERRCODE" ||
            warn "Can't write HTTP errcodes";
        print ERRCODE WWW::Webrobot::HttpErrcode::as_html();
        close ERRCODE;
    }

    foreach (@{$self->{list_modes}}) {
        my ($dummy_handle, $index, $filename) = @$_;
        # toplevel frameset containing (1), (2 3 4)
        my $INDEX = open_die(">$self->{dir}/$index");
        print {$INDEX} make_html("WebRobot", <<EOF);
<frameset cols='90,1*'>
  <frame name='planlist' src='$filename'>
  <frame name='planentry' src='0/index.html'>
  <noframes>
     For better navigation enable frames in your browser.
     <a href='$filename'>Filename</a><br>
     <a href='0/index.html'>Entry 0</a><br>
  </noframes>
</frameset>
EOF
        close $INDEX;

        # create frame 1
        my $handle = open_die(">$self->{dir}/$filename");
        $_ -> [0] = $handle;
        autoflush($handle);
        my $navigation = $self->{navigation} || "";
        print $handle "$DOCTYPE\n<html>\n<body>\n";
        print $handle "$navigation" if $navigation;
        print $handle
            "<a href='list_all.html'>all</a><br>",
            "<a href='list_all_long.html' target='webrobot_source'>all-long</a><br>",
            "<a href='list_fail.html'>failed</a><hr>";
    }

    # print file for undefined frames
    my $FRAME = open_die(">$self->{dir}/frame_undef.html");
    print {$FRAME} make_html("FRAME", "<font size='6' color='green'>FRAME</font>");
    close $FRAME;
}

sub global_end {
    my $self = shift;
    foreach (@{$self->{list_modes}}) {
        my ($handle, $index, $filename) = @$_;
        print $handle "</body>\n</html>\n";
        close $handle;
    }
}


sub item_pre {
    #my ($self, $arg) = @_;
}

sub item_post_change {
    my ($self, $r, $arg, $index) = @_;
    $arg ||= $self->norm_args($r, $arg);
    $self -> item_write($r, $arg || {}, $index);
}

sub norm_args {
    my ($self, $r, $arg) = @_;
    return {
        fail => ($r->code() =~ m/[45]\d\d/) ? 1 : 0,
        method => $r->request()->method(),
        url => $r->request()->uri(),
        description => "THIRD PARTY USER",
        $arg ? (%$arg) : (),
    };
}

sub item_post {
    my ($self, $r, $arg) = @_;

    my ($LIST_ALL, $LIST_FAIL, $LIST_ALL_LONG) = map {$_->[0]} @{$self->{list_modes}};
    my $index = $self->{entry_count}++;
    $arg ||= $self->norm_args($r, $arg);

    $self -> item_write($r, $arg || {}, $index);

    print {$LIST_ALL} pr_index_item($r, $arg, $index, 0);
    print {$LIST_FAIL} pr_index_item($r, $arg, $index, 0) if $arg->{fail};
    print {$LIST_ALL_LONG} pr_index_item($r, $arg, $index, 1);
}

# private
sub item_write {
    my ($self, $r, $arg, $index) = @_;

    my $dir = $self->{dir} . "/" . $index;
    -d $dir || mkdir $dir || die "Can't make dir=$dir err=$!";

    # FILE: Frameset containing (2), (3 4)
    my $INDEX = open_die(">$dir/index.html");
    my $request_body_frame = ($r && $arg->{fail} != 2) ?
        "<frame name='requestbody' src='0/index.html'>" : "";
    print {$INDEX} make_html("Single Request", <<EOF);
<frameset rows='30%, 70%'>
    <frame src='plan_data.html'>
    $request_body_frame
</frameset>
<noframes>
    <a href='plan_data.html'>plan_data.html</a><br>
</noframes>
</frameset>
EOF
    close $INDEX;

    # FILE: write frame 2
    my $PLANDATA = open_die(">$dir/plan_data.html");

    # print navigation bar
    my $fail_str = fail2str([qw(Ok FAILED INVALID)], "[no assertion]", $arg->{fail}, ["b"]);
    my $count0 = ($index > 0) ? $index - 1 : 0;
    my $count1 = $index + 1;
    my $url = $arg->{url} || "";
    #???use Data::Dumper; die "R=", Dumper($r), "ARG=", Dumper($arg);
    print {$PLANDATA} <<EOF;
$DOCTYPE
<html>
<head><title>Data from Testplan</title></head>
<body>
<a href='../$count0/index.html' target='planentry'>prev</a>
<font color='#0000A0'><b>[$index]</b></font>
<a href='../$count1/index.html' target='planentry'>next</a>$SP$SP$SP
<font color='$green'>$arg->{description}</font><hr>
$fail_str&nbsp;$arg->{method}&nbsp;$url<br>
EOF

    # print all called requests
    my $subrequest_count = 0;
    my $req = $r;
    while (defined $req) {
        print $PLANDATA
            "<a href='../$HTTP_ERRCODE#$req->{_rc}' target='webrobot_source'>$req->{_rc}</a>",
            "$SP<a href='$subrequest_count/index.html' target='requestbody'>",
            "$req->{_request}->{_uri}</a><br>\n";
        $subrequest_count++;
        $req = $req -> {_previous};
    }
    print {$PLANDATA} "<hr>\n";

    # print POST data
    if (defined $arg->{data} && %{$arg->{data}}) {
        my @tbl = map {[$_, $arg->{data}->{$_}]} sort keys %{$arg->{data}};
        print {$PLANDATA} pr_table("Data section of GET or POST", ["Attribute", "Value"], \@tbl, alter_colors());
        print $PLANDATA "<br>\n";
    }

    # print assertions
    my $fail_out = $arg->{fail_str};
    $fail_out = [ $fail_out ] if ! ref $fail_out;
    my @bool = qw(false true);
    my @failed = map {
        $_->[0] = $bool[$_->[0]] || $_->[0];
        $_
    } map {
        (my $tmp = $_) =~ s/</&lt;/g;
        [ split(/\s+/, $tmp, 2) ]
    } @$fail_out;

    print {$PLANDATA} "<table border='0'>\n";
    print {$PLANDATA} "<tr><td valign='top'>\n", print_assert_xml("Define global assertion", $arg->{global_assert_xml}), "</td>\n" if $arg->{global_assert_xml};
    print {$PLANDATA} "<tr><td valign='top'>\n", pr_table("Predicates", [], \@failed, alter_colors()), "</td>\n";
    print {$PLANDATA} "<tr><td valign='top'>\n", print_assert_xml("Assertion (parsed source)", $_), "</td>\n" foreach(@{$arg->{assert_xml}});
    print {$PLANDATA} "</table>\n";

    # print xpath expressions
    my $assert = $arg->{assert};
    if (UNIVERSAL::isa($assert, "WWW::Webrobot::Assert")) {
        my $postfix = (($arg -> {assert} || {}) -> {evaluator} || {}) -> {postfix} || [];
        if ($postfix && scalar @$postfix) {
            my @xpath = ();
            foreach (@$postfix) {
                next if ref $_ ne 'ARRAY';
                my ($predicate, $parm) = @$_;
                next if $predicate ne 'xpath';
                my $xpath_expr = $parm->[0]->{xpath};
                (my $xpath_result = $r->xpath($xpath_expr)) =~ s/\n/<br>/g;
                push @xpath, [$xpath_expr, $xpath_result];
            }
            if (@xpath) {
                print {$PLANDATA} pr_table("XPath expressions", ["XPath", "Value"], \@xpath, alter_colors());
                print $PLANDATA "<br>\n";
            }
        }
    }

    # print variables that have been defined in this entry
    if (defined $arg->{new_properties} && scalar @{$arg->{new_properties}}) {
        print {$PLANDATA} pr_table("Defined variables", ["Name", "Value"], $arg->{new_properties}, alter_colors());
        print $PLANDATA "<br>\n";
    }

    # print caller pages
    if (my $cp = $arg->{caller_pages}) {
        print $PLANDATA "<p><b>This page was called by</b><br>\n";
        foreach (@$cp) {
            print $PLANDATA "$_<br>\n";
        }
    }

    # print elapsed time
    print $PLANDATA "Elapsed time: ", $r->elapsed_time(), " seconds<br>\n" if $r;

    # Finish this frame
    print $PLANDATA "</html>\n";
    close $PLANDATA;

    # FILE: write frame(3): print all subrequests
    $subrequest_count = 0;
    $req = $r;
    while (defined($req)) { # for all subrequests
        # define and make directory
        my $dir = "$self->{dir}/$index/$subrequest_count";
        -d $dir || mkdir $dir || die "Can't make dir=$dir err=$!";

        # write data for frame 3, request header
        my $HEADER = open_die(">$dir/req_head.html");
        my $xhtml_text0 = ($req->content_xhtml(1)) ?
            "<a href='source_xhtml.txt' target='webrobot_source'>source-xhtml</a>" : "";
        my $navi_source = <<EOF;
<b>Display&nbsp;content:</b>&nbsp;&nbsp;
<a href='source.txt' target='webrobot_source'>source</a>
$xhtml_text0
<a href='display.html' target='webrobot_source'>display</a>
EOF
        print {$HEADER} make_html("Request and Response, Header and Data",
            $navi_source,
            "<hr>\n",
            print_http_header(
                "Request Header",
                ($req->{_request}->{_method} || "no_method") . $SP . ($req->{_request}->{_uri} || "no_uri"),
                $req->{_request}->{_headers}
            ),
            "<hr>\n",
            print_http_header(
                "Response Header",
                ($req->{_protocol} || "(no_protocol)") . $SP .
                    "<a href='../../$HTTP_ERRCODE#$req->{_rc}' target='webrobot_source'>$req->{_rc}</a>" . $SP .
                    ($req->{_msg} || "(no_message)"),
                $req->{_headers}
            ),
        );
        close $HEADER;

        # FILE: write response body (source)
        my $SRC = open_die(">$dir/source.txt");
        print {$SRC} $req -> content();
        close $SRC;

        # FILE: write response body (xhtml source)
        if ($req->content_xhtml(1)) { #if (exists $req->{_content_xhtml})
            my $XSRC = open_die(">$dir/source_xhtml.txt");
            print {$XSRC} $req -> content_xhtml();
            close $XSRC;
        }

        # FILE: write frame(4): write display version
        my $content_type = norm_content_type($req->{_headers}->{"content-type"});
        my $DISPLAY = open_die(">$dir/display.html");
        SWITCH: for (@{$content_type}) {
            /text\/html/ and do {
                my $frame = "../../frame_undef.html";
                my $txt = $req -> content();
                # <frame ... src=...> in <frame ... src=$frame ...> aendern
                $txt =~ s/(<frame\s+.*?src\s*=\s*['"]).*?(['"].*?>)/$1$frame$2/gsi;
                print $DISPLAY $txt;
                last;
            };
            /text\/plain/ || /text\/xml/ || /text\/sgml/ and do {
                my $txt = encode_text($req -> content());
                print {$DISPLAY} make_html("", "<pre>$txt</pre>\n");
                last;
            };
            /image\/gif/ and do {
                print {$DISPLAY} make_html("", "<img src='display_1.gif'>");
                my $FILE = open_die(">$dir/display_1.gif");
                print $FILE $req->{_content};
                close $FILE;
                last;
            };
            /image\/png/ and do {
                print {$DISPLAY} make_html("", "<img src='display_1.png'>");
                my $FILE = open_die(">$dir/display_1.png");
                print $FILE $req->{_content};
                close $FILE;
                last;
            };
            /image\/jpeg/ and do {
                print {$DISPLAY} make_html("", "<img src='display_1.jpeg'>");
                my $FILE = open_die(">$dir/display_1.jpeg");
                print $FILE $req->{_content};
                close $FILE;
                last;
            };
            do { # else
                # ??? kann ein array sein!
                my ($type, $charset) = split(/; */,
                    $req->{_headers}->{"content-type"} || "", 2);
                my $mime_info = "";
                $mime_info .= "type='$type'" if $type;
                $mime_info .= " $charset" if $charset;

                my $FILE = open_die(">$dir/any-mime");
                if ($mime_info eq "") {
                    print {$FILE} make_html("EMPTY", "<h1>... Content is empty ...</h1>");
                }
                else {
                    my $txt = <<EOF;
This bodies MIME type is not treated specially.
You must possibly launch an external viewer
if your browser doesn't support this special link.
You may try:
<h1><a href='any-mime' $mime_info>Click me</a></h1>
$mime_info
EOF
                    print {$FILE} make_html("Link To Body Of Response", $txt);
                }
                close $FILE;
            }
        }
        close $DISPLAY;

        # write frameset ((3), (4)) [resquest/response]
        my $INDEX = open_die(">$dir/index.html");
        print {$INDEX} make_html("Request and Response, Header and Data", <<EOF);
<frameset cols='60%, 40%'>
    <frame name='requestheader' src='req_head.html'>
    <frame name='responsedatatxt' src='display.html'>
    <noframes>
        Follow these links (you'd better enable frames):<br>
        <a href='req_head.html'>Request/Response header</a><br>
        <a href='display.html'>Display response</a><br>
    </noframes>
</frameset>
EOF
        close $INDEX;

        # set loop control variables
        $subrequest_count++;
        $req = $req -> {_previous};
    }
}


########################################################################
### functions ##########################################################
########################################################################


sub print_http_header {
    my ($title, $firstline, $headers) = @_;

    my $color_obj = alter_colors();
    my $color = $color_obj->();
    my @tbl = map {[$_, $headers->{$_}]} sort keys %{$headers};
    my $tmp_table = pr_table("", [], \@tbl, $color_obj);
    my $txt = <<EOF;
<b>$title</b><br>
<table border='0'>
    <tr>
        <td colspan='2' $color nowrap><font size='-1'><b>$firstline</b></font></td>
    </tr>
</table>
<table>
$tmp_table
</table>
EOF
    return $txt;
}


sub autoflush { #static
    my ($handle) = @_;
    my $save_handle = select($handle);
    $| = 1;
    select($save_handle);
}


sub new_handle {
    do {local *FH; *FH};
}


sub open_die { #static
    my ($filename) = @_;
    my $handle = new_handle();
    my ($package, $file, $line) = caller();
    open($handle, $filename) or die("line $line: Can't open $filename, err=$!");
    return $handle;
}


sub alter_colors { #static object factory
    my @colors = @_;
    #@colors = ("#E0E0E0", "#F3F3F3") if ! scalar @colors;
    @colors = ("bgcolor='#E0E0E0'", "bgcolor='#F3F3F3'") if ! scalar @colors;
    my $state = 0;

    return sub {
        $state = 0 if $state >= scalar @colors;
        return $colors[$state++];
    };
}


sub first_blue { #static object factory
    my $state = 0;

    return sub {
        my $old_state = $state;
        $state = 1;
        return $old_state ? "black" : "blue";
    };
}


sub make_html { # static
    my ($title, @txt) = @_;
    my $txt = join "", @txt;
    return <<EOF;
$DOCTYPE
<html>
<head><title>$title</title></head>
$txt
</html>
EOF
}

sub pr_table {
    my ($title, $header, $tbl, $color_obj) = @_;
    return "" if scalar @$tbl == 0;
    my $ret = "";
    my $columns = scalar(@{$tbl->[0]});
    $ret .= "<table>\n";
    if ($title) {
        my $color = $color_obj -> ();
        $ret .= "<tr $color>\n";
        $ret .= "    <th align='left' colspan='$columns'><font size='-1'>$title</font></th>\n";
        $ret .= "</tr>\n";
    }
    if ($header && scalar @$header > 0) {
        my $color = $color_obj -> ();
        $ret .= "<tr $color>\n";
        $ret .= "    <th align='left'><font size='-1'>$_</font></th>\n" foreach (@$header);
        $ret .= "</tr>\n";
    }
    foreach my $row (@$tbl) {
        my $color = $color_obj -> ();
        my $fb = first_blue();
        $ret .= "<tr valign='top' $color>\n";
        foreach (@$row) {
            my $blue = $fb->();
            my $value = $_;
            $value = "[" . join(", ", @$value) . "]" if ref $value eq "ARRAY";
            $ret .= "    <td nowrap><font color='$blue' size='-1'>$value</font></td>\n";
        }
        $ret .= "</tr>\n";
    }
    $ret .= "</table>\n";
    return $ret;
}


sub print_assert_xml {
    my ($title, $assert_xml_parm) = @_;
    my $xml = WWW::Webrobot::XML2Tree::print_xml($assert_xml_parm);
    my @assert_html = map {
        $_ = encode_text($_);
        s/ /&nbsp;/g;
        [ "$_" ]
    } split /\n/, $xml;
    return pr_table($title, [], \@assert_html, alter_colors());
}


sub norm_content_type {
    my ($type) = @_;
    SWITCH: for ($type) {
        !defined       and do { return [ ] };
        ref eq ""      and do { return [ $type ] };
        ref eq "ARRAY" and do { return $type };
    }
    return [ ];
}


sub encode_text {
    my ($txt, $mode) = @_;
    $txt =~ s/&/&amp;/gs if ! $mode || "" eq "XML";
    $txt =~ s/</&lt;/gs;
    return $txt;
}


sub pr_index_item {
    my ($r, $arg, $index, $long) = @_;
    # append new entry to frame 1
    my $points = $arg->{is_recursive} ? "...$SP" : "";
    my $link = "<a href='$index/index.html' target='planentry'>$index</a>";
    my $ok = fail2str(["O", "F", "I"], "-", $arg->{fail}, ["b", "tt"]);

    my $long_text = "";
    $long_text = do {
        (my $description = $arg->{description}) =~ s/[\s\n]/\&nbsp;/gs;
        my $url = $arg->{url} || "";
        "$SP$SP<font size='-1'>$arg->{method}$SP$url</font>$SP$SP<font size='-1' color=$green>$description</font>";
    } if $long;

    return "$ok$SP$points$link$long_text<br>\n";
}


sub fail2str {
    my ($array, $default, $err_code, $type) = @_;
    my $colour = $err_code ? "red" : "green";
    my $text = (defined $err_code) ? ($array->[$err_code] || "") : ($default || "");
    if ($text) {
        $text = "<$_>$text</$_>" foreach (@$type);
        $text = "<font color='$colour'>$text</font>";
    }
    return $text;
}


1;
