package UserProfileFeedResponse;

our $CONTENTS=<<'JSON';

{
 "version": "1.0",
 "encoding": "UTF-8",
 "entry": {
  "xmlns": "http://www.w3.org/2005/Atom",
  "xmlns$media": "http://search.yahoo.com/mrss/",
  "xmlns$gd": "http://schemas.google.com/g/2005",
  "xmlns$yt": "http://gdata.youtube.com/schemas/2007",
  "gd$etag": "W/\"CUMMRn47eCp7ImA9WhZRFE8.\"",
  "id": {
   "$t": "tag:youtube.com,2008:user:testing"
  },
  "published": {
   "$t": "2010-04-24T06:09:01.000-07:00"
  },
  "updated": {
   "$t": "2011-04-10T01:18:07.000-07:00"
  },
  "category": [
   {
    "scheme": "http://schemas.google.com/g/2005#kind",
    "term": "http://gdata.youtube.com/schemas/2007#userProfile"
   },
   {
    "scheme": "http://gdata.youtube.com/schemas/2007/channeltypes.cat",
    "term": "Musician"
   }
  ],
  "title": {
   "$t": "testing Channel"
  },
  "link": [
   {
    "rel": "related",
    "type": "text/html",
    "href": "http://www.myurl.com"
   },
   {
    "rel": "alternate",
    "type": "text/html",
    "href": "http://www.youtube.com/profile?user\u003dtesting"
   },
   {
    "rel": "self",
    "type": "application/atom+xml",
    "href": "http://gdata.youtube.com/feeds/api/users/testing"
   }
  ],
  "author": [
   {
    "name": {
     "$t": "withnovo"
    },
    "uri": {
     "$t": "http://gdata.youtube.com/feeds/api/users/testing"
    }
   }
  ],
  "yt$aboutMe": {
   "$t": "you will learn all about me"
  },
  "yt$lastName": {
   "$t": "last name"
  },
  "yt$age": {
   "$t": 31
  },
  "gd$feedLink": [
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.favorites",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/favorites",
    "countHint": 0
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.contacts",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/contacts",
    "countHint": 2
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.inbox",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/inbox"
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.playlists",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/playlists"
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.subscriptions",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/subscriptions",
    "countHint": 0
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.uploads",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/uploads",
    "countHint": 9
   },
   {
    "rel": "http://gdata.youtube.com/schemas/2007#user.newsubscriptionvideos",
    "href": "http://gdata.youtube.com/feeds/api/users/testing/newsubscriptionvideos"
   }
  ],
  "yt$firstName": {
   "$t": "testing"
  },
  "yt$gender": {
   "$t": "m"
  },
  "yt$hometown": {
   "$t": "“Œ‹ž"
  },
  "yt$location": {
   "$t": "“Œ‹ž, JP"
  },
  "yt$statistics": {
   "lastWebAccess": "2011-04-10T01:12:59.000-07:00",
   "subscriberCount": "2",
   "videoWatchCount": 0,
   "viewCount": "657",
   "totalUploadViews": "1435"
  },
  "media$thumbnail": {
   "url": "http://i4.ytimg.com/i/c6H9RSpd0rg/1.jpg"
  },
  "yt$username": {
   "$t": "test"
  }
 }
}

JSON

1;
