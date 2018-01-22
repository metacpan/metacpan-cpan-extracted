use strict;
use warnings;

use File::Temp;
use Test::More tests => 2;
use XML::Saxtract qw(saxtract_string);

is_deeply(
    saxtract_string(
        q[<?xml version='1.0' encoding='UTF-8'?>
<tsResponse xmlns="http://tableau.com/api" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xsi:schemaLocation="http://tableau.com/api http://tableau.com/api/ts-api-2.2.xsd">
  <pagination pageNumber="1" pageSize="100" totalAvailable="5" />
  <sites>
    <site id="4ef6b8ee-0d3a-4aa8-9b4d-88f60c8897a1" 
      name="Asias (Default)" 
      contentUrl="" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="8fb15c1c-641b-4ee3-aec3-be70d2be7509" 
      name="Facility Safety" 
      contentUrl="facilitysafety" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="a8961b94-2f90-49d4-bfee-9dee84ec1d18" 
      name="Oversight" 
      contentUrl="oversight" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="b215d4c6-c244-448c-8ec6-f4d6a9ed9d5e" 
      name="Developers Only" 
      contentUrl="DevelopersOnly" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="a4b96a7f-d701-431c-a4ec-74a5874845be" 
      name="Asias" 
      contentUrl="Asias" 
      adminMode="ContentAndUsers" 
      state="Active" />
  </sites>
</tsResponse>],
        {   'http://tableau.com/api' => '',
            '/tsResponse/sites/site' => {
                name => 'sites',
                type => 'map',
                key  => 'content_url',
                spec => {
                    '/@id'         => 'id',
                    '/@name'       => 'name',
                    '/@contentUrl' => 'content_url',
                    '/@adminMode'  => 'admin_mode',
                    '/@state'      => 'state'
                }
            }
        }
    ),
    {   sites => {
            '' => {
                id          => "4ef6b8ee-0d3a-4aa8-9b4d-88f60c8897a1",
                name        => "Asias (Default)",
                content_url => "",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'facilitysafety' => {
                id          => "8fb15c1c-641b-4ee3-aec3-be70d2be7509",
                name        => "Facility Safety",
                content_url => "facilitysafety",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'oversight' => {
                id          => "a8961b94-2f90-49d4-bfee-9dee84ec1d18",
                name        => "Oversight",
                content_url => "oversight",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'DevelopersOnly' => {
                id          => "b215d4c6-c244-448c-8ec6-f4d6a9ed9d5e",
                name        => "Developers Only",
                content_url => "DevelopersOnly",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'Asias' => {
                id          => "a4b96a7f-d701-431c-a4ec-74a5874845be",
                name        => "Asias",
                content_url => "Asias",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            }
        }
    },
    'tableau stuff'
);

is_deeply(
    saxtract_string(
        q[<?xml version='1.0' encoding='UTF-8'?>
<tsResponse xmlns="http://tableau.com/api" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xsi:schemaLocation="http://tableau.com/api http://tableau.com/api/ts-api-2.2.xsd">
  <pagination pageNumber="1" pageSize="100" totalAvailable="5" />
  <sites>
    <site id="4ef6b8ee-0d3a-4aa8-9b4d-88f60c8897a1" 
      name="Asias (Default)" 
      contentUrl="" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="8fb15c1c-641b-4ee3-aec3-be70d2be7509" 
      name="Facility Safety" 
      contentUrl="facilitysafety" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="a8961b94-2f90-49d4-bfee-9dee84ec1d18" 
      name="Oversight" 
      contentUrl="oversight" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="b215d4c6-c244-448c-8ec6-f4d6a9ed9d5e" 
      name="Developers Only" 
      contentUrl="DevelopersOnly" 
      adminMode="ContentAndUsers" 
      state="Active" />
    <site id="a4b96a7f-d701-431c-a4ec-74a5874845be" 
      name="Asias" 
      contentUrl="Asias" 
      adminMode="ContentAndUsers" 
      state="Active" />
  </sites>
</tsResponse>],
        {   'http://tableau.com/api' => '',
            '/tsResponse/sites/site' => {
                name => 'sites',
                type => sub {
                    my ( $object, $value ) = @_;
                    $object->{ $value->{content_url} } = $value;
                },
                spec => {
                    '/@id'         => 'id',
                    '/@name'       => 'name',
                    '/@contentUrl' => 'content_url',
                    '/@adminMode'  => 'admin_mode',
                    '/@state'      => 'state'
                }
            }
        }
    ),
    {   sites => {
            '' => {
                id          => "4ef6b8ee-0d3a-4aa8-9b4d-88f60c8897a1",
                name        => "Asias (Default)",
                content_url => "",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'facilitysafety' => {
                id          => "8fb15c1c-641b-4ee3-aec3-be70d2be7509",
                name        => "Facility Safety",
                content_url => "facilitysafety",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'oversight' => {
                id          => "a8961b94-2f90-49d4-bfee-9dee84ec1d18",
                name        => "Oversight",
                content_url => "oversight",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'DevelopersOnly' => {
                id          => "b215d4c6-c244-448c-8ec6-f4d6a9ed9d5e",
                name        => "Developers Only",
                content_url => "DevelopersOnly",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            },
            'Asias' => {
                id          => "a4b96a7f-d701-431c-a4ec-74a5874845be",
                name        => "Asias",
                content_url => "Asias",
                admin_mode  => "ContentAndUsers",
                state       => "Active"
            }
        }
    },
    'tableau stuff'
);
