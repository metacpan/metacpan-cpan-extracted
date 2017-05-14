#**Tinder::API** 
![Logo](http://cdn.bbmlive.com/wp-content/uploads/2013/09/Tinder_logo.png)
##Briefly
####Unofficial internal Tinder's API calls. 
##Synopsis

``` perl
my $API= new Tinder::API('facebookAuthToken',"Id");
```

##Description
**This** module was orginally the first Perl library to interract with **Tinder** app. As you may know, Tinder uses a series of non encrypted **API** calls in order to make the client-server possible. Those calls are greatly documented in [this](https://gist.github.com/rtt/10403467) repo. You can use Fiddler , install the trust certificate on your mobile device and use your Fiddler sniffer as a proxy for all traffic. Then you will get more or less the same pattern as the repo above. 
In the current library, I aim to provide an easy access to the calls.
Please note that you will need a **Facebook** Authentication Token for **Tinder::API** to work!
You can get it by going on [this link](https://www.facebook.com/dialog/oauth?client_id=464891386855067&redirect_uri=https://www.facebook.com/connect/login_success.html&scope=basic_info,email,public_profile,user_about_me,user_activities,user_birthday,user_education_history,user_friends,user_interests,user_likes,user_location,user_photos,user_relationship_details&response_type=token). 

##Subroutines
####new
Returns a new Tinder::API object

1. `_facebookAuthToken` : The Facebook Authentication Token for Tinder app. Check in the description on how to get it.
2. `_Id` : A Facebook Id associated with the token.

####auth
Takes a `facebookAuthToken` and a corresponding Id and returns a Tinder `X-Auth-Token`.

``` perl
 my XAUTHTOKEN=$API->auth() 
```

Please note that this is an internal method and is already called in the constructor `new`.

####relocate
Takes two coordinates (`lat,long`) and updates your coordinates on Tinder.

``` perl
$API->relocate(0.00000,0.00000) 
```

**NOTE** Sometimes Tinder spits out *Not significant change* for your location. This means in most cases that you have to feed it a pair with more distance to the old coordinates.

####getRecs
Returns a list of recommendations from Tinder.
``` perl
my $response=$API->getRecs()
``` 

####getUser
Takes a TinderId of a user (valid) and returns all information about him/her.

``` perl
 my $reponse=$API->getUser($id)
```

####sendMessage
Takes a TinderId of a user (valid) and the body of a message, and sends the message to the give TinderId.

``` perl
$API->sendMessage($id,$message)
```

####getUpdates
Returns a list of Tinder updates.

``` perl
my $reponse=$API->getUpdates()
```

####likeOrPass
Takes a TinderId of a user (valid) and a decision (like or pass him/her).

``` perl
$API->likeOrPass($id,$decision)
```

####getFbToken

Returns the current Facebook token being used;

``` perl
my $token=$API->getFbToken()
```

####getId

Returns the current Facebook id being used;
``` perl
my $id=$API->getId()
```

##License

Distributed according to GNU GPL and CPAN Terms and Conditions.
You may re-use and publish the code, but you have to mention the original AUTHOR and CPAN repo.
You may NOT sell this module.

##Author

**ArtificialBreeze** 

**Site:** [Web](http://xoreaxeax.me)

**GitHub:** [GitHub](http://github.com/ArtificialBreeze)

**CPAN:** [CPAN](https://metacpan.org/author/xxgh0stxx)

##See Also
`perlpod, perlpodspec, LWP::UserAgent, HTTP::Request`