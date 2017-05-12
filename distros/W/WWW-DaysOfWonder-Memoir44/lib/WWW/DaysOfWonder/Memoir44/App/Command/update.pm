#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::App::Command::update;
# ABSTRACT: update db from dow website
$WWW::DaysOfWonder::Memoir44::App::Command::update::VERSION = '3.000';
use HTML::TreeBuilder;
use LWP::UserAgent;
use Term::ProgressBar::Quiet;
use Term::Twiddle::Quiet;
use Text::Trim;

use WWW::DaysOfWonder::Memoir44::App -command;
use WWW::DaysOfWonder::Memoir44::Scenario;
use WWW::DaysOfWonder::Memoir44::DB::Scenarios;
use WWW::DaysOfWonder::Memoir44::Url;


# -- public methods

sub description {
'Update the database after the list of scenarios from days of wonder
website. This will *not* download the scenarios themselves - see the
download command for this action.';
}

sub opt_spec {
    my $self = shift;
    return;
}

sub execute {
    my $self    = shift;
    my $twiddle = Term::Twiddle::Quiet->new;
    my $db      = WWW::DaysOfWonder::Memoir44::DB::Scenarios->new;

    # the user agent will be reused
    my $ua = LWP::UserAgent->new;
    $ua->agent('WWW::DaysOfWonder::Memoir44');
    $ua->env_proxy;

    # remove all existing scenarios from db
    $db->clear;

    foreach my $source ( qw{ game approved classified public } ) {
        # create the source url
        my $url = WWW::DaysOfWonder::Memoir44::Url->new({source=>$source});
        say "* updating $source scenarios";
        say "- url: $url";

        # downloading url listing the scenarios
        print "- downloading url: ";
        $twiddle->start;
        my $response = $ua->get("$url");
        $twiddle->stop;
        die $response->status_line unless $response->is_success;
        say "done";

        # parse html to find list of scenarios
        print "- parsing: ";
        $twiddle->start;
        my $tree  = HTML::TreeBuilder->new_from_content( $response->content );
        my $table = $tree->find_by_tag_name( 'table' );
        #die $table->dump;
        my $depth = $table->depth;
        # find rows, but only one level deep. otherwise, it would also
        # find rows of tables embedded in some cells.
        my @rows  = $table->look_down(
            '_tag', 'tr',
            sub { $_[0]->depth == $depth+1 },
        );
        shift @rows; # trim title line
        $twiddle->stop;
        say "found ", scalar(@rows), " scenarios";

        # extracting scenarios from table rows
        my $prefix = "- extracting scenarios";
        my $progress = Term::ProgressBar::Quiet->new( {
            count     => scalar(@rows),
            bar_width => 50,
            remove    => 1,
            name      => $prefix,
        } );
        $progress->minor(0); # don't know why this doesn't work as constructor param
        foreach my $row ( @rows ) {
            # extract scenario data from row
            my %data = _scenario_data_from_html_row($row);
            $data{source} = $source;
            # create a scenario object and store it in the database
            my $scenario = WWW::DaysOfWonder::Memoir44::Scenario->new(%data);
            $db->add( $scenario );
            $progress->update;
        }
        say "${prefix}: done";

        # source complete
        print "\n";
    }
    $db->write;
}


# -- private methods

#
# my %data = _scenario_data_from_html_row($row);
#
# given a $row of the table fetched from dow website, parse it and
# return a hash with all scenario properties extracted. the hash
# keys are:
#  - id:        id of the scenario
#  - name:      scenario name
#  - operation: operation the scenario is part of
#  - front:     west, east, mediterranean, etc.
#  - author:    who wrote the scenario
#  - rating:    average scenario rating (1, 2 or 3)
#  - updated:   date of last scenario update
#  - format:    standard, overlord, breakthru
#  - board:     country, beach, winter, desert
#  - need_tp:   whether terrain pack is needed
#  - need_ef:   whether eastern front is needed
#  - need_mt:   whether mediterranean theater is needed
#  - need_pt:   whether pacific theater is needed
#  - need_ap:   whether air pack is needed
#  - need_bm:   whether battle maps is needed
#  - need_cb:   whether campaign book is needed
#
sub _scenario_data_from_html_row {
    my $row = shift;
    my %data;

    # split row in cells
    my $depth = $row->depth;
    my @cells = $row->look_down(
        '_tag', 'td',
        sub { $_[0]->depth == $depth+1 },
    );

    # extract values and fill in the hash
    my $link = $cells[0]->find_by_tag_name('a')->attr('href');
    ($data{id}) = ($link =~ /id=(\d+)/);
    $data{name}      = trim($cells[0]->as_text);
    $data{operation} = trim($cells[2]->as_text);
    $data{front}     = trim($cells[3]->as_text);
    $data{author}    = trim($cells[4]->as_text);
    $data{rating}    = substr $cells[6]->find_by_tag_name('img')->attr('alt'), 0, 1;

    my $updated = trim($cells[5]->as_text);                    # dd/mm/yyyy
    $data{updated}   = join '-', reverse split /\//, $updated; # yyyy-mm-dd

    # fill in langs, board & booleans
    # - langs
    my @subcells = $cells[8]->find_by_tag_name('td');
    my @langs = map { $_->attr('alt') } $subcells[1]->find_by_tag_name('img');
    $data{languages} = \@langs;
    # - board types
    my $boardimg = $subcells[2]->find_by_tag_name('img')->attr('src');
    $boardimg =~ /mm_board_([^_]+)_([^.]+)\.gif/
        or die "unknwon board image: $boardimg";
    $data{format} = $1;
    $data{board}  = $2;
    # - booleans
    my @imgs =
        map { $_->attr('src') }
        $subcells[3]->find_by_tag_name('img');
    $data{need_tp} = grep { /pack_terrain/ } @imgs;
    $data{need_ef} = grep { /pack_eastern/ } @imgs;
    $data{need_pt} = grep { /pack_pacific/ } @imgs;
    $data{need_mt} = grep { /pack_mediterranean/ } @imgs;
    $data{need_ap} = grep { /pack_air/ } @imgs;
    $data{need_bm} = 0; # grep { /pack_/ } @imgs;
    $data{need_cb} = 0; # grep { /pack_/ } @imgs;

    return %data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::App::Command::update - update db from dow website

=head1 VERSION

version 3.000

=head1 DESCRIPTION

This command updates the database of scenarios available from days of
wonder website.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
