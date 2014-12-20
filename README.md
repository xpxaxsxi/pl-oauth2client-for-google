pl-oauth2client-for-google
==========================

Oauth2 client for installed applications flow, for Swi-prolog, for Google Developer Accounts 

Tested with Google Compute Engine API, Windows XP (Windows 8 should work), Firefox, SWI-Prolog version 7.1.26. Needs a superuser/main user account for the redirection from user consent page (this is not the copy&paste authentication code version)

This is a installed application flow: https://developers.google.com/accounts/docs/OAuth2#installed

INSTRUCTIONS
-Clone the git
-Assert Your client id (Service Account Id) and Your client secret,  Google Developers find them   at Developer Console
-Call valid_refresh_token/0
--First time it should start a local server AND open a browser window to another site at Google's
--At consent page You can approve
--After approval You will directed to Your local server where it will display a message about a success
---refresh token is written to refresh_token.txt 
-Call from_refreshtoken_accesstoken/0

Now You will have a flag(access_token,AT,AT).


This is my first Github project and first collaborative project, so I will be making lots of newbie errors
