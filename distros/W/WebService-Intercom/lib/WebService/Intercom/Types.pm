use Moops -strict;

library WebService::Intercom::Types
    extends Types::Standard
    declares CustomAttributeNameType,
    CustomAttributeValueType,
    IPAddressType,
    CustomAttributesType,
    EventNameType,
    EventMetadataURLValueType,
    EventMetadataPriceValueType,
    EventMetadataType,
    SocialProfileListType,
    SocialProfileType,
    AvatarType,
    LocationDataType,
    CompaniesListType,
    SegmentsListType,
    SegmentType,
    TagsListType,
    TagUserIdentifierType,
    TagCompanyIdentifierType,
    MessagePersonType
    {
        
        declare "MessagePersonType", as Dict[
            type => StrMatch[qr/^(admin|user)$/],
            user_id => Optional[Str],
            email => Optional[Str],
            id => Optional[Str]
        ];
        coerce MessagePersonType, from HashRef, via {
            MessagePersonType->new($_);
        };
        
        declare "CustomAttributeNameType", as StrMatch[qr/^[^[.\$]+$/];
        declare "IPAddressType", as StrMatch[qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/];
        coerce IPAddressType, from Str, via {
            IPAddressType->new($_);
        };
        
        
        declare "CustomAttributeValueType", as Value|Bool;
        
        declare "CustomAttributesType", as Map[CustomAttributeNameType, CustomAttributeValueType];
        coerce CustomAttributesType, from HashRef, via {
            CustomAttributesType->new($_);
        };
        
        declare "SocialProfileType", as Dict[type => Str,
                                             name => Maybe[Str],
                                             username => Maybe[Str],
                                             url => Maybe[Str],
                                             id => Maybe[Str]
                                         ];
        coerce SocialProfileType, from HashRef, via {
            SocialProfileType->new($_);
        };
        
        declare "SocialProfileListType", as Dict[type => Str,
                                                 social_profiles => ArrayRef[SocialProfileType]
                                             ];
        coerce SocialProfileListType, from HashRef, via {
            SocialProfileListType->new($_);
        };
        
        declare "EventNameType", as StrMatch[qr/^[^[.\$]+$/];
        
        declare "EventMetadataURLValueType", as Dict[url => Str,
                                                     value => Optional[Str]];
        coerce EventMetadataURLValueType, from HashRef, via {
            EventMetadataURLValueType->new($_);
        };
        
        declare "EventMetadataPriceValueType", as Dict[amount => Int,
                                                       currency => Str];
        
        coerce EventMetadataPriceValueType, from HashRef, via {
            EventMetadataPriceValueType->new($_);
        };


        declare "EventMetadataType", as Map[Str, Value|EventMetadataURLValueType|EventMetadataPriceValueType];
        coerce EventMetadataType from HashRef, via {
            EventMetadataType->new($_);
        };


        declare "TagUserIdentifierType", as Dict[id => Optional[Str],
                                                 email => Optional[Str],
                                                 user_id => Optional[Str],
                                                 untag => Optional[Bool],
                                             ];
        coerce TagUserIdentifierType, from HashRef, via {
            TagUserIdentifierType->new($_)
        };


        declare "TagCompanyIdentifierType", as Dict[id => Optional[Str],
                                                    company_id => Optional[Str],
                                                    untag => Optional[Bool],
                                                ];
        coerce TagCompanyIdentifierType, from HashRef, via {
            TagCompanyIdentifierType->new($_)
        };

        

        declare "AvatarType", as Dict[type => Str,
                                      image_url => Maybe[Str]];

        declare "LocationDataType", as Dict[type => Str,
                                            city_name => Maybe[Str],
                                            continent_code => Maybe[Str],
                                            country_code => Maybe[Str],
                                            country_name => Maybe[Str],
                                            latitude => Maybe[Num],
                                            longitude => Maybe[Num],
                                            postal_code => Maybe[Str],
                                            region_name => Maybe[Str],
                                            timezone => Maybe[Str]
                                        ];

        declare "CompaniesListType", as Dict[type => Str,
                                             companies => ArrayRef[Dict[id => Str]]];
        

        declare "SegmentType", as Dict[type => Str,
                                       id => Str,
                                       name => Str,
                                       created_at => Int,
                                       updated_at => Int];
        
        declare "SegmentsListType", as Dict[type => Str,
                                            segments => ArrayRef[Dict[type => Str, id => Str]]];


        declare "TagsListType", as Dict[type => Str,
                                        tags => ArrayRef[Dict[id => Str,
                                                              type => Str,
                                                              name => Optional[Str]
                                                          ]]];

};
    
1;
