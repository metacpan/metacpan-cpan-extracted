package WWW::SmartSheet;

our $VERSION = '0.06';

use Moo;
use MooX::late;

use Carp ();
use Data::Dumper qw(Dumper);
use LWP::UserAgent;
use JSON qw(from_json to_json);

has token => (is => 'ro', required => 1);

has sheets => (is => 'rw', isa => 'ArrayRef');

my $API_URL = "https://api.smartsheet.com/2.0";
my @ACCESS_LEVELS = qw(VIEWER EDITOR EDITOR_SHARE ADMIN);

sub ua {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new( agent => "WWW::SmartSheet v$VERSION https://github.com/szabgab/WWW-SmartSheet" );
    $ua->timeout(10);
    $ua->default_header("Authorization" => "Bearer " . $self->token);
    $ua->default_header("Content-Type" => "application/json");
    return $ua;
}

sub get_current_user {
  my ($self) = @_;

  my $current_user = $self->_get('users/me');
  return $current_user;
}

sub get_sheets {
    my ($self, $pagesize, $page) = @_;

    my $all_sheets = $self->_get("sheets",
                                 ("pageSize" => $pagesize,
                                  "page" => $page,
                                 )
        );
    return $all_sheets;
}

sub get_columns {
    my ($self, $sheetid, $pagesize, $page) = @_;

    my $cols = $self->_get("sheets/$sheetid/columns",
                           ("pageSize" => $pagesize,
                            "page" => $page,
                           )
        );
    return $cols;
}

sub share_sheet {
    my ($self, $sheetid, $email, $access_level) = @_;

    my $result = $self->_post("sheets/$sheetid/shares?sendEmail=true", {email => $email, accessLevel => $access_level});
    return $result;
}

sub create_sheet {
    my ($self, %args) = @_;

    return $self->_post('sheets', \%args);
}

sub delete_sheet {
    my ($self, $id) = @_;

    $self->_delete("sheets/$id");
}

sub add_column {
    my ($self, $sheet_id, $column) = @_;

    return $self->_post("sheets/$sheet_id/columns", $column );
}

sub insert_rows {
    my ($self, $sheet_id, $loc, @rows) = @_;

    my @full_rows;
    foreach my $row (@rows) {
        my $lv = 1;

        my %r;
        $r{"cells"} = $row;

        if ($loc =~ m/(=)/) {

	    my $l = $loc;
	    if ($l =~ m/,above/) {
                $l =~ s/,above//;
                $r{"above"} = 1;
	    }
	    my ($k, $v) = split(/=/, $l);
	    if ($v) {
                $r{$k}=$v;
	    }

        } else {

	    $r{"$loc"} = 1;

        }
        push (@full_rows, \%r);
    }

    return $self->_post("sheets/$sheet_id/rows", \@full_rows);
}

sub get_sheet_by_id {
    my ($self, $id, $pagesize, $page) = @_;

    my $sheet = $self->_get("sheets/$id",
                            ("pageSize" => $pagesize,
                             "page" => $page,
                            )
        );
    return $sheet;
}

sub _post {
    my ($self, $path, $data) = @_;

    my $url = "$API_URL/$path";
    my $ua = $self->ua;
    my $json = to_json($data);

    my $req = HTTP::Request->new( 'POST', $url );
    $req->content( $json );
    my $res = $ua->request( $req );

    Carp::croak $res->status_line . $res->content if not $res->is_success;
    return from_json $res->decoded_content;
}

sub _get {
    my ($self, $path, %params) = @_;

    my $paramstr;
    my $url = "$API_URL/$path";

    foreach my $param (keys %params) {

        if (!$params{$param}) {
	    # ignore empty params
	    next;
        }

        $paramstr .= $param . "=" . $params{$param} . "&";
    }

    if ($paramstr) {
        $paramstr =~ s/&$//;
        $url .= "?$paramstr";
    }

    my $res = $self->ua->get($url);
    Carp::croak $res->status_line . $res->content if not $res->is_success;
    return from_json $res->decoded_content;
}

sub _delete {
    my ($self, $path) = @_;

    my $url = "$API_URL/$path";
    my $res = $self->ua->delete($url);
    Carp::croak $res->status_line . $res->content if not $res->is_success;
    return from_json $res->decoded_content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::SmartSheet - Interface to SmartSheet API v2.

=head1 VERSION

version 0.06

=head2 get_current_user

   returns a hash of info on the current user

=head2 get_sheets($pagesize, $page)

optional parameters default to $pagesize=100 and $page=1
sample returned info:

  {
      "pageNumber": 1,
      "pageSize": 100,
      "totalPages": 1,
      "totalCount": 2,
      "data": [
          {
              "accessLevel": "OWNER",
              "id": 4583173393803140,
              "name": "sheet 1",
              "permalink": "https://app.smartsheet.com/b/home?lx=xUefSOIYmn07iJJesvSHCQ",
              "createdAt": "2015-06-05T20:05:29Z",
              "modifiedAt": "2015-06-05T20:05:43Z"
          },
          {
              "accessLevel": "OWNER",
              "id": 2331373580117892,
              "name": "sheet 2",
              "permalink": "https://app.smartsheet.com/b/home?lx=xUefSOIYmn07iJJrthEFTG",
              "createdAt": "2015-06-05T20:05:29Z",
              "modifiedAt": "2015-06-05T20:05:43Z"
          }
      ]
  }

=head2 get_columns

http://smartsheet-platform.github.io/api-docs/#get-all-columns
Takes a sheetid and returns "IndexResult Object containing an array of Column Objects"

    Example Response:

    {
        "pageNumber": 1,
        "pageSize": 100,
        "totalPages": 1,
        "totalCount": 3,
        "data": [
            {
               "id": 7960873114331012,
               "index": 0,
               "symbol": "STAR",
               "title": "Favorite",
               "type": "CHECKBOX",
               "validation": false
            },
            {
               "id": 642523719853956,
               "index": 1,
               "primary": true,
               "title": "Primary Column",
               "type": "TEXT_NUMBER",
               "validation": false
            },
            {
               "id": 5146123347224452,
               "index": 2,
               "title": "Status",
               "type": "PICKLIST",
               "validation": false
            }
        ]
    }

=head2 share_sheet

sheet_id
email => 'foo@examples.com',
access_level => one of the following strings: VIEWER EDITOR EDITOR_SHARE ADMIN

Note: This only creates a new share and will not update or delete an exising one

Sample returned data:

    {
        "resultCode": 0,
        "result": [
            {
                "id": "AAAFeF82FOeE",
                "type": "USER",
                "userId": 1539725208119172,
                "email": "jane.doe@smartsheet.com",
                "name": "Jane Doe",
                "accessLevel": "EDITOR",
                "scope": "ITEM"
            }
         ],
         "message": "SUCCESS"
     }

=head2 create_sheet

Uses "Create Sheet in 'Sheets' folder" (http://smartsheet-platform.github.io/api-docs/#create-sheet-in-quot-sheets-quot-folder)

Requires, name of sheet, columns (title, primary, type)

    $w->create_sheet(
        name    => 'Name of the sheet',
	columns =>  [

                    { title => "Baked Good", type => 'TEXT_NUMBER', primary => 1 },
                    { title => 'Baker', type => 'CONTACT_LIST' },
                    { title => 'Price Per Item', type => 'TEXT_NUMBER' },
                    { title => "Gluten Free?", "type" => "CHECKBOX", "symbol" => "FLAG"},
                    { title => 'Status', type => 'PICKLIST', options => ['Started', 'Finished' , 'Delivered'] }
        ]
     );

Returns:

     {
          'resultCode' => 0,
          'result' => {
                        'id' => '2331373580117892',
                        'permalink' => 'https://app.smartsheet.com/b/home?lx=0HHzeGnfHik-N13ZT8pU7g',
                        'name' => 'Name of the sheet',
                        'accessLevel' => 'OWNER',
                        'columns' => [
                                       {
                                         'index' => 0,
                                         'primary' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                                         'width' => 150,
                                         'type' => 'TEXT_NUMBER',
                                         'validation' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
                                         'title' => 'Baked Good',
                                         'id' => '7960873114331012'
                                       },
                                       {
                                         'id' => '6430209165167777',
                                         'validation' => $VAR1->{'result'}{'columns'}[0]{'validation'},
                                         'title' => 'Baker',
                                         'type' => 'CONTACT_LIST',
                                         'width' => 150,
                                         'index' => 1
                                       },
                                       {
                                         'validation' => $VAR1->{'result'}{'columns'}[0]{'validation'},
                                         'title' => 'Price Per Item',
                                         'id' => '3580578411771296',
                                         'type' => 'TEXT_NUMBER',
                                         'width' => 150,
                                         'index' => 2
                                       },
                                       {
                                         'id' => '7306226134567921',
                                         'validation' => $VAR1->{'result'}{'columns'}[0]{'validation'},
                                         'title' => 'Gluten Free?',
                                         'symbol' => 'FLAG',
                                         'type' => 'CHECKBOX',
                                         'width' => 150,
                                         'index' => 3
                                       },
                                       {
                                         'validation' => $VAR1->{'result'}{'columns'}[0]{'validation'},
                                         'title' => 'Status',
                                         'id' => '1425783243468763',
                                         'type' => 'PICKLIST',
                                         'options' => [
                                                        'Started',
                                                        'Finished',
                                                        'Delivered'
                                                      ],
                                         'width' => 150,
                                         'index' => 4
                                       }
                                     ]
                      },
          'message' => 'SUCCESS'
        };

=head2 delete_sheet

Given sheetid, deletes the sheet.

=head2 add_column

multiple columns can be added at one time

     $w->add_column(
                 $sheet_id,
                          [
                            { title => 'Delivered', type => 'DATE', index => 5},
                            { title => 'AnotherCol', type => 'TEXT_NUMBER', index => 5}
                          ]
                  );

returns

     {
        "resultCode": 0,
        "result": [
            {
                "id": 4503594425063547,
                "index": 4,
                "title": "New Date Column",
                "type": "DATE",
                "validation": true,
                "width": 150
            },
            {
                "id": 9007194052434043,
                "index": 4,
                "title": "New Picklist Column 1",
                "type": "TEST_NUMBER",
                "width": 150
            }
        ],
        "message": "SUCCESS"
     }

=head2 insert_rows

    curl https://api.smartsheet.com/2.0/sheets/{sheetId}/rows \
        -H "Authorization: Bearer ll352u9jujauoqz4gstvsae05" \
        -H "Content-Type: application/json" \
        -X POST \
        -d '[{"toTop":true, "cells": [ {"columnId": 7960873114331012, "value": true}, {"columnId": 642523719853956, "value": "New status", "strict": false} ] }, {"toTop":true, "cells": [ {"columnId": 7960873114331012, "value": true}, {"columnId": 642523719853956, "value": "New status", "strict": false} ] }]'

$location can be: toTop, toBottom, parentId=<rowid>, or "siblingId=<rowid>,above" (or leave off ,above for below)

    $w->insert_rows($sheet_id, $location, @rows);

@rows should be something like

    [
       [
          {"columnId" =>  7960873114331012, "value" =>  JSON::true},
          {"columnId" =>  642523719853956, "value" =>  "New status 1", "strict" =>  false}
       ],
       [
          {"columnId" =>  7960873114331012, "value" =>  JSON::false},
          {"columnId" =>  642523719853956, "value" =>  "New status 2", "strict" =>  false}
       ]
    ]

Note: JSON::true instead of "true" or 1 is necessary

=head2 get_sheet_by_id

Given sheet id, returns the entire sheet:

    {
        "accessLevel": "OWNER",
        "projectSettings": {
            "workingDays": [
                "MONDAY",
                "TUESDAY",
                "WEDNESDAY"
            ],
            "nonWorkingDays": [
                "2018-01-01"
            ],
            "lengthOfDay": 6
        },
        "columns": [
            {
                "id": 4583173393803140,
                "index": 0,
                "primary": true,
                "title": "Primary Column",
                "type": "TEXT_NUMBER",
                "validation": false
           },
           {
                "id": 2331373580117892,
                "index": 1,
                "options": [
                    "new",
                    "in progress",
                    "completed"
                ],
                "title": "status",
                "type": "PICKLIST",
                "validation": true
            }
       ],
       "createdAt": "2012-07-24T18:22:29-07:00",
       "id": 4583173393803140,
       "modifiedAt": "2012-07-24T18:30:52-07:00",
       "name": "sheet 1",
       "permalink": "https://app.smartsheet.com/b/home?lx=pWNSDH9itjBXxBzFmyf-5w",
       "rows": []
    }

=head1 OTHER

The code of this client is free software.
Access to the services of L<Smartsheet|http://www.smartsheet.com/> requires registration and payment.

L<API Documentation|http://smartsheet-platform.github.io/api-docs/>

=head2 TODO

Probably needs a get_all_sheet_shares, update_sheet_share, delete_sheet_share, delete_column

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
