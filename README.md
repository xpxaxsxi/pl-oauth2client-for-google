pl-oauth2client-for-google
==========================

Oauth2 client for installed applications flow, for Swi-prolog, for Google Developer Accounts 

Tested with Google Compute Engine API, Windows XP (Windows 8 should work), Firefox, SWI-Prolog version 7.1.26. Needs a superuser/main user account for the redirection from user consent page (this is not the copy&paste authentication code version)

This is a installed application flow: https://developers.google.com/accounts/docs/OAuth2#installed

Here is a experimental concept map of a Oauth2 flow https://cmapscloud.ihmc.us/viewer/cmap/1P3FCZL5C-6RN9BZ-54D

INSTRUCTIONS

FIRST TIME

Get the code (download a zip-file or use git)

Assert Your client id (Service Account Id) and Your client secret,  Google Developers find them   at Developer Console

Call valid_refresh_token/0

First time it should start a local server AND open a browser window to another site at Google's

At consent page You can approve

After approval You will directed to Your local server where it will display a message about a success

refresh token is written to refresh_token.txt 

Call from_refreshtoken_accesstoken/0

Now You will have a flag(access_token,AT,AT).

OTHER TIMES

Call from_refreshtoken_accesstoken/0

Now You have a fresh accesstoken that is usable for 3600 seconds, it was fetched from Google using the refresh_token.txt-file. If you get authorization errors, You propably have on outdated accesstoken, and you can get a fresh access token by calling from_refreshtoken_accesstoken/0

ABOUT REFRESH TOKEN

It will be valid for weeks or months?? Also it is a offline token, You don't have to login anywhere, You can start up Swi-prolog, get access token with from_refreshtoken_accesstoken and... 

START CODING  with the FUTURE TOOL OF ALL REAL PROGRAMMERS: Swi-Prolog http://www.swi-prolog.org


This is my first Github project and first collaborative project, so I will be making lots of newbie errors
