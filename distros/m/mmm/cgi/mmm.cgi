#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use DBI;
use lib ('../lib');
use MMM::Host;
use MMM::MirrorList;
use URI;

sub encoding { 'utf-8' }

my $db = DBI->connect( "dbi:Pg:dbname=mmm;host=virgo",
    "nobody", "nobody", { AutoCommit => 0 } );
my $cgi = new CGI;

sub list_sources {
    my $q = $db->prepare(qq{select name from sources order by name});
    $q->execute();
    my @sources;
    while ( my $res = $q->fetchrow_hashref() ) {
        push( @sources, $res->{name} );
    }
    @sources;
}

sub list_hosts {
    my $q =
      $db->prepare(
qq{select hostname from hosts where hostname in (select hostname from mirrors) order by hostname}
      );
    $q->execute();
    my @hosts;
    while ( my $res = $q->fetchrow_hashref() ) {
        push( @hosts, $res->{hostname} );
    }
    @hosts;

}

if ( $cgi->path_info =~ m@^/*$@ ) {
    print $cgi->header( -type => 'text/html; charset=' . encoding ),
      $cgi->start_html( -title => 'mmm', -encoding => encoding );
    print menu();
    print '<div style="float : left; border : ridge; padding : 5px;">';
    print "<p>Sources:</p>\n";
    print $cgi->start_ul(), (
        map {
            $cgi->li(
                $cgi->a(
                    { href => $cgi->url( -query => 0 ) . "?source=$_" }, $_
                )
              )
          } grep { $_ } list_sources()
      ),
      $cgi->end_ul();
    print "<p>Mirrors:</p>\n";
    print $cgi->start_ul(), (
        map {
            $cgi->li(
                $cgi->a(
                    { href => $cgi->url( -query => 0 ) . "?host=$_" }, $_
                )
              )
          } grep { $_ } list_hosts()
      ),
      $cgi->end_ul();
    print '</div>';

    if ( $cgi->param('source') ) {
        my $qs = $db->prepare(qq{select * from sources where name = ?});
        $qs->execute( $cgi->param('source') );
        if ( $qs->rows ) {
            print '<div style="float : left; border : ridge; padding : 5px;">';
            print $cgi->h2( $cgi->param('source') );
            my $ress = $qs->fetchrow_hashref();
            if ( $ress->{description} ) {
                print "<p>", $cgi->escapeHTML( $ress->{description} ), "</p>\n";
            }

            my $q =
              $db->prepare(
                qq{select * from mirrorlist where source = ? order by level});
            $q->execute( $cgi->param('source') );
            if ( $q->rows ) {

                print '<p>',
                  $cgi->a(
                    {
                        href => $cgi->url( -query => 0 )
                          . "/mirrors.xml?source=$ress->{name}"
                    },
                    "XML list for $ress->{name}"
                  ),
                  "</p>\n";
                print '<table border="1">',
                  '<tr><th>URL</th><th>level</th><th>frequency</th></tr>', "\n";
                while ( my $res = $q->fetchrow_hashref() ) {
                    print "<tr>";
                    print "<td>$res->{url}<br />",
                      $cgi->a(
                        {
                            href => $cgi->url( -query => 0 )
                              . "?host=$res->{hostname}"
                        },
                        $res->{hostname}
                      )

                      , "</td>",
                      "<td>"
                      . ( defined( $res->{level} ) ? $res->{level} : '' )
                      . "</td>", "<td>" . ( $res->{frequency} || '' ) . "</td>";
                    print "</tr>\n";
                }

                print "</table>\n";
            }
            print "</div>\n";

        }
    }
    elsif ( $cgi->param('host') ) {
        print '<div style="float : left; border : ridge; padding : 5px;">';
        print $cgi->h2( $cgi->param('host') );

        my $qh = $db->prepare(qq{select * from hosts where hostname = ?});
        $qh->execute( $cgi->param('host') );

        my $hostinfo = $qh->fetchrow_hashref();

        print $cgi->h3("Localisation");
        my $location = join( ', ',
            grep { $_ } map { $hostinfo->{$_} } qw(continent country city) );
        print "<p>Location: $location</p>\n" if ($location);

        if (   defined( $hostinfo->{latitude} )
            && defined( $hostinfo->{longitude} ) )
        {
            printf "<p>Latitude: %f %s, Longitude: %f %s</p>\n",
              abs( $hostinfo->{latitude} ),
              $hostinfo->{latitude} < 0 ? 'S' : 'N',
              abs( $hostinfo->{longitude} ),
              $hostinfo->{longitude} > 0 ? 'E' : 'W';

            printf
'<p><img src="http://maps.fallingrain.com/perl/map.cgi?kind=topo&lat=%f=&long=%f&name=%s&scale=8&x=350&y=240" alt="Map of location"></p>',
              $hostinfo->{latitude}, $hostinfo->{longitude},
              $cgi->param('host');
        }

        print $cgi->h3("Availlable mirrors");
        my $qs =
          $db->prepare(
            qq{select * from mirrorlist where hostname = ? order by source});
        $qs->execute( $cgi->param('host') );
        print '<table border="1">',
'<tr><th>Source</th><th>URL</th><th>level</th><th>frequency</th></tr>',
          "\n";
        while ( my $res = $qs->fetchrow_hashref() ) {
            print "<tr>";
            print "<td>"
              . $cgi->a(
                { href => $cgi->url( -query => 0 ) . "?source=$res->{source}" },
                $res->{source}
              )
              . "</td>", "<td>$res->{url}</td>",
              "<td>"
              . ( defined( $res->{level} ) ? $res->{level} : '' )
              . "</td>", "<td>" . ( $res->{frequency} || '' ) . "</td>";
            print "</tr>\n";
        }
        print "</table>\n";

        print '</div>';
    }

    print $cgi->end_html();

}
elsif ( $cgi->path_info =~ m/\/*new(?:\/*([^\/]*))?/ ) {
    print $cgi->header( -type => 'text/html; charset=' . encoding );
    my $selfurl = $cgi->self_url();
    $1 ||= '';
    if ( $1 eq 'list' ) {
        print $cgi->start_html(
            -title    => 'MMM: New mirror list to fetch',
            -encoding => encoding
          ),
          menu();
        my $add_result;
        do {
            {
                if ( !$cgi->param('url') ) {
                    last;
                }

                # anti spam check
                if (
                    !(
                        $cgi->param('passc')
                        && crypt( $cgi->param('pass') || "", 'mm' ) eq
                        $cgi->param('passc')
                    )
                  )
                {
                    $add_result = "Please, fill correctly the password";
                    last;
                }
                my $url = $cgi->param('url');
                $url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                my $uri = URI->new($url);
                if ( !( $uri->scheme && $uri->authority ) ) {
                    $add_result = "This url seems to be invalid";
                    last;
                }
                my $path = $uri->path;
                $path =~ s://*:/:g;

                my $addurl =
                  $db->prepare('insert into mirrorslist (url) values (?)');
                my $urltoadd = sprintf( "%s://%s%s%s",
                    $uri->scheme, lc( $uri->authority ),
                    $path, ( $uri->query ? '?' . $uri->query : '' ) );
                if ( $addurl->execute($urltoadd) > 0 ) {
                    print $cgi->p(
                        { -align => 'CENTER' },
"The Url added $urltoadd has been added into the database."
                          . "It's content will be added soon."
                      ),
                      $cgi->p(
                        { -align => 'CENTER' },
                        "Thanks for your submission."
                      ),
                      $cgi->end_html();
                    $db->commit;
                    exit(0);
                }
                elsif ( $db->err == 7 ) {
                    $add_result = "This url already exist in the database";
                }
                else {
                    $add_result = $db->errstr;
                }
            }
        } while (0);
        my $pass = join( "", map { chr( 97 + rand(26) ) } ( ('') x 8 ) );
        $cgi->param( -name => 'passc', -value => crypt( $pass, 'mm' ) );
        $cgi->param( -name => 'pass', -value => '' );
        print $cgi->start_form( action => $selfurl ),
          $cgi->hidden( -name => 'passc' ), $cgi->table(
            { -align => 'CENTER' },

            map { $cgi->Tr( {}, [ $cgi->td($_) ] ) } grep { defined($_) } (
                (
                      $add_result
                    ? $cgi->p( { -style => 'Color: red;' }, $add_result )
                    : undef
                ),
                '',
                "Enter the url where your own can be fetched",
                $cgi->textfield( -name => 'url', -size => 60 ),
                'Just to avoid spam, please retype this password above: '
                  . "<strong>$pass</strong>",
                $cgi->textfield( -name => 'pass' ),
                $cgi->submit(),
              )

          ),
          $cgi->end_form();

    }
    elsif ( $1 eq 'source' ) {
    }
    else {
        print $cgi->start_html( -title => 'MMM', -encoding => encoding );
        print <<EOF;
<a href="$selfurl/list">List</a><br/> 
<a href="$selfurl/source">source</a><br/> 
EOF
    }

    print $cgi->end_html();
}
elsif ( $cgi->path_info =~ m@^/*mirrors.xml$@ ) {
    print $cgi->header( -type => 'text/xml; charset=' . encoding );

    my $ml = MMM::MirrorList->new();
    foreach my $source (
        $cgi->param('source') ? $cgi->param('source') : list_sources() )
    {
        my $q  = $db->prepare(qq{select * from mirrorlist where source = ?});
        my $qh = $db->prepare(qq{select * from hosts where hostname = ?});
        $q->execute($source);
        while ( my $res = $q->fetchrow_hashref() ) {
            $qh->execute( $res->{hostname} );
            if ( my $hres = $qh->fetchrow_hashref() ) {
                $res->{hostinfo} = MMM::Host->new(%$hres);
            }
            $ml->add_mirror( $res, $source );
        }
    }

    print $ml->xml_output();
}

sub menu {
    return $cgi->h1( { align => 'center' }, 'MMM Mirror database' )
      . $cgi->table(
        { -border => 0, -align => 'CENTER' },
        $cgi->Tr(
            { -align => 'CENTER', -valign => 'TOP' },
            [
                $cgi->td(
                    [
                        $cgi->a(
                            { href => 'http://mmm.zarb.org/' },
                            'Main website'
                        ),
                        $cgi->a(
                            {
                                href =>
                                  $cgi->self_url( -query => 0, -path => 0 )
                            },
                            "Browse the database"
                        ),
                        $cgi->a(
                            {
                                href => $cgi->self_url( -query => 0 )
                                  . "/new/list"
                            },
                            "Add you list url"
                        ),

                    ]
                ),
            ]
        )
      ) . "\n\n";
}
