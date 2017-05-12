#!/usr/bin/perl -w
=head1 TODO

- javascript scrolling when changing people.
- get size of window from web browser

- editable pages (in center box), switching between graph and person view, photo

- display other relatives (e.g. siblings, cousins)

- rcs checkin of each revision

- deletions

- code cleanup, perlcritic

- taint checking

=cut

#
# family.cgi
#
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use IO::File;
use File::stat qw(stat);
use Data::Dumper;
use Fcntl qw(:DEFAULT :flock);
use Tree::Family;
use Tree::Family::Person;
use Lingua::EN::NameParse qw(case_surname);

use strict;

our $BaseDir = '/var/www/html';
our $ImageDir = '/var/www/html/images';
our $ImageRoot= '/images';
our $CSSRoot = '/css';
our $DataDir = '/var/www/html/data';
our $DotFile = '/var/www/html/data/family.dot';
our $LockFile = $DotFile.'.lock';
our $ScriptURL = '/cgi-bin/family.cgi';
$Tree::Family::urlBase = $ScriptURL;

our $TreeFile = '/var/www/html/data/tree.dmp';

# TODO Get these from the browser :
our $Vsize   = 450;
our $Hsize   = 900; 
our $maxSize = 10;
our $HeaderPrinted = 0;

&main;

sub increments {
    my ($startw, $starth) = qw(2 2.5);

    my $out = `dot -Tplain $DotFile 2>/dev/null | head -1`;
    my ($one,$width,$height) = $out =~ /^graph (.*) (.*) (.*)$/;

    my @ret;
    my $incw = ($width-$startw) / ($maxSize - 1);
    my $i = 0;
    for (my $w=$startw;$w<$width;$w+=$incw) {
        push @ret, sprintf('%.1f',$w);
    }
    push @ret, undef while @ret < 10;
    return @ret;
}

sub rebuild_commands {
    my @commands;
    my $i = 1;
    for my $size (increments(), undef) {
        for my $type (qw(gif cmapx)) {
            push @commands,
            "dot ".($size ? "-Gsize=$size,$size" : '')." -T$type $DotFile 2>/dev/null > $DataDir/family_$i.$type ".  
            "&& mv $DataDir/family_$i.$type $ImageDir";
        }
        $i++;
    }
    push @commands, "dot -Tps -Gpage='8.5,11' -Gmargin=0 $DotFile 2>/dev/null > $DataDir/family.ps";
    push @commands, "ps2pdf $DataDir/family.ps $DataDir/family.pdf < /dev/null 2>/dev/null && mv $DataDir/family.pdf $ImageDir";
    @commands; 
}

sub rebuild {
    my $q = shift;
    local $| = 1;
    print $q->header,$q->start_html(-title => 'family tree',-style=>{-src=>"$CSSRoot/family.css"});
    our $HeaderPrinted;
    $HeaderPrinted = 1;
    sysopen(FH, $LockFile, O_WRONLY | O_CREAT) or die "can't open filename: $!";
    flock(FH, LOCK_EX) or die "can't lock $LockFile : $!";
    print "Rebuilding...<pre class='rebuild'>";
    for (rebuild_commands()) {
        #print "Running $_\n";
        print ".";
        system($_)==0 or warn "error executing $_ : $?";
    }
    print "</pre>";
}

sub id2coords {
    my $id = shift;
    my $size = shift || $maxSize;
    my @line = grep { /id=$id\W/ } IO::File->new("<$ImageDir/family_$size.cmapx")->getlines;
    unless (@line>=1) {
        print STDERR "$id not in map file";
        return (0,0);
    }
    my ($x1,$y1,$x2,$y2) = ($line[0] =~ /coords="(\d+),(\d+),(\d+),(\d+)"/);
    return (($x1 + $x2)/2 - $Hsize/2,($y1 + $y2)/2 - $Vsize/2);
}

sub frontpage {
    my %args = @_;
    my ($q,$message,$tree) = @args{qw(q message tree)};
    my ($id,$size) = map scalar $q->param($_), qw(id size);
    my @coords = (0,0);
    if ($id) {
        $size ||= $maxSize;
        @coords = id2coords($id,$size);
    }
    $size ||= '1';
    my $idp = $id ? "&id=$id" : "";
    $message &&= "<b>$message</b>";
    my $person = $message;
    $person .= '<hr>' if $person;
    $person .= person_form(q => $q, tree => $tree);
    my %people = map { ($_->id => $_->full_name) } $tree->people;
    my @values = sort { $people{$a} cmp $people{$b} } keys %people;
    my $person_dropdown = "<form method=GET action=$ScriptURL>".
            $q->popup_menu(-name=>'id',
                -default => '',
                -values => ['',@values], -labels => {''=>'',%people}).
            $q->submit(-name=>'go',-value=>'go').
            "</form>";
    my $printable = $q->a({-href=>"$ImageRoot/family.pdf"}, 'printable version');
    my $links = join ' ', 
        map {
            my $class = ($_ eq $size ? 'page_selected' : 'page_unselected');
            "<a class=$class href=$ScriptURL?size=$_$idp>$_</a>"
            }
        (1..$maxSize);
    $links = '<center>zoom : out '.$links.' in</center>';
    print (($HeaderPrinted ? '' : ($q->header, $q->start_html(-style=>{-src=>"$CSSRoot/family.css"}))),<<EOHTML);
<body onload='window.frames[0].scrollBy($coords[0],$coords[1])'>
<table width=100%>
<tr>
<td align='left' width='20%'>family tree</td>
<td width='60%'>$links</td>
<td width='20%' align='right'><nobr>$person_dropdown</nobr>
$printable</td>
</tr></table>
<br>
<hr>
<iframe style='border:0;' width='100%' height='${Vsize}px' src='$ScriptURL?act=show&size=$size'>
</iframe>
<hr>
$person
</body>
</html>
EOHTML
}

sub show { # show the image
    my %args = @_;
    my $q = $args{q};
    my $size = '_' . ($q->param('size') || $maxSize);
    my $file = IO::File->new("<$ImageDir/family$size.cmapx");
    unless( $file) {
        print $q->header,$q->start_html,$q->h2('please add a person below'),$q->end_html;
        return;
    }
    my @map = $file->getlines;
    @map = ( $map[0], (grep {/area/} @map), $map[-1] );
    my $time = stat("$ImageDir/family$size.gif")->mtime; # stop image caching
    print $q->header, $q->start_html(
        -target => '_top', -style => {-src=>"$CSSRoot/family.css"}), <<EOH;
    <center>
    <img ismap="ismap" usemap="#family" src="$ImageRoot/family$size.gif?$time">
    </center>
    @map
EOH

}

sub person_link {
    my $q = shift;
    my $person = shift;
    $person ? 
        $q->a({-class=>$person->gender,
            -href=>"$ScriptURL?id=".$person->id},$person->first_name) 
        : '';
}

sub add_relative_link {
    my ($q,$person, $relation) = @_;
    return $q->a({-class=>'addnew',-href=>"$ScriptURL?id=".$person->id."&add=1&relation=$relation"},
        "add new person");
}

sub relative_dropdown {
    my ($q,$person,$rel,$selected,$tree) = @_;
    my @list;
    for ($rel) {
        /^spouse$/ and do {
            # same generation, unmarried.
            @list = $tree->find(generation => $person->generation, spouse => undef);
            warn "found list : ".Dumper(\@list);
            push @list, $person->spouse() if $person->spouse;
        };
        /^dad$/ and do {
            # one generation up, male
            @list = $tree->find(generation => $person->generation - 1, gender => 'm');
        };
        /^mom$/ and do {
            # one generation up, female
            @list = $tree->find(generation =>$person->generation - 1, gender => 'f');
        };
    }
    @list = grep $_->id ne $person->id, sort {$a->first_name cmp $b->first_name} @list;
    $selected = $selected ? $selected->id : '';
    my %labels = map { ($_->id => $_->full_name) } @list;
    return $q->popup_menu( -name => $rel, 
            -values => [ '', map $_->id, @list ], -labels => \%labels, -default => $selected );
}

sub person_form {
    my %args = @_;
    my $q = $args{q};
    my $tree = $args{tree};
    my $id = $q->param('id');
    my $edit = $q->param('edit');
    my $add = $q->param('add');
    my @disabled = ($edit || $add) ? () : (-disabled => 1);
    my @all = Tree::Family::Person->all;
    if (!$id) {
        return "Click on the image to select a person." if @all;
        $add = 1;
        @disabled = ();
    }
    my $person = $add ? Tree::Family::Person->new(firstname => 'new' ) : $tree->find(id => $id);
    if ($add && (my $rel = $q->param('relation'))) {
        my $other = $tree->find(id => $id);
        $person->add_kid($other) if $rel =~ /mom|dad/;
        $person->gender('m') if $rel eq 'dad';
        $person->gender('f') if $rel eq 'mom';
        $person->gender( { m => 'f', f => 'm'}->{$other->gender} ) if $rel eq 'spouse';
        $person->spouse( $other ) if $rel eq 'spouse';
        $person->mom($other) if $rel eq 'kid' && $other->gender eq 'f';
        $person->dad($other) if $rel eq 'kid' && $other->gender eq 'm';
        $person->generation($other->generation + 1) if $rel eq 'kid';
    }
    die "error searching for id $id" unless $person;
    my $gender = 
        !$disabled[1] ? 
            $q->popup_menu(-class=>'name',-name=>'gender',
                -values=>['',qw(m f)],-labels=>{m=>'Mr.',f=>'Ms.'},
                 @disabled,-default=>$person->gender) :
        $q->textfield(-class=>'gender',-value=>{m=>'Mr.',f=>'Ms.'}->{$person->gender},
            @disabled);
    my $name = $gender.
        (join '', map $q->textfield(-class => 'name', -name => $_, -value=>$person->$_, @disabled),
        qw(first_name middle_name last_name));
    my $birth_death_dates = join ' - ',
        $q->textfield(-class=>'date',-name=>'birth_date',
            -value=>$person->birth_date,@disabled),
        $q->textfield(-class=>'date',-name=>'death_date',
            -value=>$person->death_date,@disabled);
    my $birth_place = $q->textfield(-size=>44,-class=>'location',-name=>'birth_place',
            -value=>$person->birth_place, @disabled);
    
    my ($father,$mother,$spouse) = 
    map { 
        ($add || $edit) ? relative_dropdown($q,$person,$_,$person->$_,$tree)
        : (person_link($q,$person->$_) || add_relative_link($q,$person,$_)) } qw(dad mom spouse);
    my $kids = join '<br>', (map person_link($q,$_), $person->kids), ($add || $edit ? () : add_relative_link($q,$person,'kid'));
    my $submit =
        $add ? $q->submit(-name => 'addnew')
      : $edit ? $q->submit(-name => 'save') . ' or ' . $q->submit(-name => 'delete') 
      . $q->checkbox(-name  => 'delete_confirm',
                     -value => 'delete_confirm',
                     -label => 'confirm')
      : $q->a({ -class => 'edit_button', -href => "$ScriptURL?id=" . $id . "&edit=1" },
              $q->button(name => 'edit',value => 'edit'));
    my ($form_start,$form_end) = ('','');
    ($edit || $add) and ($form_start, $form_end) = (
                         "<form action=$ScriptURL method=POST>",
                         $q->hidden(-name => 'id') . 
                         $q->hidden(-name => 'relation') . 
                         $q->hidden(-name => 'size') . 
                         '</form>'
      );
    return $form_start."<div class='person'>\n".
        $q->table($q->Tr({-valign => 'top' }, 
$q->td({width=>'50%'},$q->table($q->Tr([
                        $q->td(['Name',$name]),
                        $q->td(['Born-deceased',$birth_death_dates]),
                        $q->td(['Birth place',$birth_place])]))),
$q->td({width=>'25%'},$q->table($q->Tr([
                        $q->td(['Father',$father]),
                        $q->td(['Mother',$mother]),
                        $q->td(['Spouse',$spouse]),
                ]))),
$q->td({width=>'25%'},$q->table($q->Tr([
                        $q->td(['Children',$kids]),
                ]))),
)).
    "<center>$submit</center>".
    "</div>".$form_end; 
}

sub edit {
    my %args = @_;
    my $q    = $args{q};
    my $tree = $args{tree};
    my $person = $tree->find(id => $q->param('id')) || die "could not find ".$q->param('id')." in the tree";
    $person->set($_ => scalar($q->param($_))) for qw(gender first_name middle_name last_name
      birth_date death_date birth_place);
    for ('spouse','mom','dad') {
        my $id = $q->param($_);
        my $found = $id ? $tree->find(id => $id) : undef;
        warn "setting $_ of ".$person->first_name." to be ".($found ? $found->first_name : 'undef');
        if ($id) {
            $person->$_($found);
        } else {
            $person->$_(undef);
        }
    }
    $tree->write;
    $tree->write_dotfile($DotFile);
    rebuild($q);
    $q->delete_all;
    $q->param('id', $person->id);
    "saved dotfile and rebuilt";
}

sub add {
    my %args     = @_;
    my $q        = $args{q};
    my $tree     = $args{tree} || die "missing tree";
    my %new = map {( $_ => scalar($q->param($_)))} qw(gender first_name middle_name
      birth_date death_date birth_place);
    $new{last_name} = case_surname($q->param('last_name') || '');
    $new{first_name} = ucfirst ($q->param('first_name') || '');
    my $new_person = Tree::Family::Person->new(%new);
    my $relative = $q->param('id') ? $tree->find(id => $q->param('id')) : undef;
    my $relation = $q->param('relation') || '';
    if (my $mom_id = $q->param('mom')) {
        my $mom = Tree::Family::Person->find(id => $mom_id) or die "couldn't find $mom_id";
        $new_person->mom($mom);
    }
    if (my $dad_id = $q->param('dad')) {
        my $dad = Tree::Family::Person->find(id => $dad_id) or die "couldn't find $dad_id";
        $new_person->dad($dad);
    }
    if (my $spouse_id = $q->param('spouse')) {
        my $spouse = Tree::Family::Person->find(id => $spouse_id) or die "couldn't find $spouse_id";
        $new_person->spouse($spouse);
    }
    for ($relation) {
        /dad/    and $relative->dad($new_person);
        /mom/    and $relative->mom($new_person);
    }
    $tree->add_person($new_person);
    $tree->write or die "Couldn't write tree";
    $tree->write_dotfile($DotFile);
    rebuild($q);
    my $id = $q->param('id');
    $q->delete_all;
    $q->param('id', $new_person->id);
    "saved dotfile and rebuilt";
}

sub delete_entry {
    my ($q,$tree) = @_;
    my $id = $q->param('id');
    my $record = $tree->find(id => $id);
    my $name = $record->first_name;
    $tree->delete_person($record);
    $tree->write_dotfile($DotFile);
    rebuild($q);
    $q->delete('id');
    $tree->write;
    return "deleted $name and rebuilt";
}

sub main {
    my $q = new CGI;
    my $id = $q->param('id');
    my $act = $q->param('act') || 'front';
    my $message;
    my $tree = Tree::Family->new(filename => $TreeFile);
    my $selected = $id ? $tree->find(id => $id) : undef;
    $message = edit(q => $q, tree => $tree) if $q->param('save');
    $message = add(q => $q, tree => $tree)  if $q->param('addnew');
    $message = delete_entry($q, $tree) if $q->param('delete') && $q->param('delete_confirm');
    for ($act) {
        /^front$/ and do { frontpage(q => $q, message => $message, tree => $tree); last; };
        /^show$/ and do { show(q => $q); last; };
        die "unknown action $act";
    }
}

