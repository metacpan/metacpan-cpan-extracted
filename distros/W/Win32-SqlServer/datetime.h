/*---------------------------------------------------------------------
 $Header: /Perl/OlleDB/datetime.h 1     07-12-24 21:39 Sommar $

  All routines converting between Perl values and the datetime data types
  in SQL Server.

  Copyright (c) 2004-2008   Erland Sommarskog

  $History: datetime.h $
 * 
 * *****************  Version 1  *****************
 * User: Sommar       Date: 07-12-24   Time: 21:39
 * Created in $/Perl/OlleDB
  ---------------------------------------------------------------------*/


extern BOOL SV_to_date (SV           * sv,
                        DBDATE        &date,
                        SV           * olle_ptr);

extern BOOL SV_to_time (SV      * sv,
                        BYTE      scale,
                        DBTIME2  &time,
                        SV      * olle_ptr);

extern BOOL SV_to_datetime(SV          *sv,
                           BYTE         scale,
                           DBTIMESTAMP &datetime,
                           SV          *olle_ptr,
                           int          firstyear,
                           int          lastyear);

extern BOOL SV_to_datetimeoffset(SV                * sv,
                                 BYTE                scale,
                                 tzinfo              TZOffset,
                                 DBTIMESTAMPOFFSET &dtoffset,
                                 SV                * olle_ptr);

extern BOOL SV_to_ssvariant_datetime(SV          * sv,
                                     SSVARIANT     &variant,
                                     SV          * olle_ptr,
                                     provider_enum provider);


extern SV * date_to_SV (SV          * olle_ptr,
                        DBDATE       dateval,
                        formatoptions opts);

extern SV * time_to_SV (SV          * olle_ptr,
                        DBTIME2       timeval,
                        formatoptions opts,
                        BYTE          precision,
                        BYTE          scale);

extern SV * datetime_to_SV (SV             * olle_ptr,
                            DBTIMESTAMP      datetime,
                            formatoptions    opts,
                            BYTE             precision,
                            BYTE             scale);

extern SV * datetimeoffset_to_SV (SV                   * olle_ptr,
                                  DBTIMESTAMPOFFSET      dtoffset,
                                  formatoptions          opts,
                                  BYTE                   precision,
                                  BYTE                   scale);


