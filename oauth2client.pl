/*  $Id$

    Author:
    E-mail:        pasikuuskasi  windowslive.com
    WWW:
    Copyright (C):

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

/** <module> Oauth2 client (for Google Accounts installed application flow)

 Module implements client-side for OAuth2 protocol for installed
 applications

 Tested with Google Compute Engine, Google Youtube
 Windows Xp, Windows 8, Firefox
 Module will use

refresh_token.txt permanent storage (plain text!)
flag(access_token(A,A) access_token for API calls
flag(refresh_token(A,A) refresh_token temporary
flag(server_port,A,A) port of localhost server where user is redirected
flag(redirect_uri,A,A) uri for localhost server
flag(autcode,A,A) authorization code from user approval

oauth2_clientid(CID) fact NEEDS to be asserted from Developers Console,
Service account Id
oauth2_clientsecret fact NEEDS to be asserted from Developers Console,
Client Secret
*/
:- module(oauth2client,[valid_refresh_token/0, from_refreshtoken_accesstoken/0]).

:- use_module(library(http/http_open)).
:- use_module(library(http/http_ssl_plugin)).
:- use_module(library(http/json)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/json_convert)).


:- http_handler(root(oauth2accesscode), handle_autcode, []).
:- http_handler(root(test), handle_test, []).



%%	oauth2_client_secret(CS) is det.
%Security stuff for OAuth2
%from personal Google API developers console
oauth2_client_secret(REPLACE_WITH_CLIENTSECRET_FROM_DEVELOPERS_CONSOLE).

%%	oauth2_client_id(CID) is det.
%security stuff for OAuth2
%from personal Google API console
oauth2_client_id(REPLACE_WITH_SERVICE_ACCOUNT_ID_FROM_DEVELOPER_CONSOLE).

%%	oauth2_endpoint_baseurl(EBU) is det.
%Security stuff for OAuth2
%from personal Google API developers console
oauth2_endpoint_baseurl('https://accounts.google.com/o/oauth2/auth').

%%	oauth2_endpoint_token(GoogleUrl) is det.
%
%	Used for refresh_token and access_token
%
oauth2_endpoint_token('https://accounts.google.com/o/oauth2/token').

%%	oauth2_scope(WhitespaceSeparatedScopesAtom) is det.
%
%	Used to specify what services user is asked for consent
oauth2_scope('https://www.googleapis.com/auth/compute https://www.googleapis.com/auth/devstorage.read_write').

%%	handle_test(Request) is det.
%
%	Test for checking http server
%
handle_test(_Request):-
	format('Content-type: text/plain~n~n', []),
	        format('This is a nice new test new response~n'),
		flag(server_port,Port,Port),
		http_current_worker(Port, ThreadID),
		format('Current worker threadID ~s~n',[ThreadID]),
		%tell('testRequest.txt'),writeln(Request),told,
		write_time.

%%	write_time is det.
%
%	Human readable time
%
write_time:-
		get_time(Time),
		format_time(atom(TD),'%a %d %b %Y %T',Time),
		format('~s',[TD]).

%%	autcode_server(Port) is det.
%
% https://developers.google.com/youtube/v3/guides/authentication
% Installed applications flow
% https://developers.google.com/accounts/docs/OAuth2InstalledApp
%
%local server to receive authorization code from Google
%After user approves the consent at consent page, user is
%redirected  here
autcode_server(Port) :-
        http_server(http_dispatch, [port(Port),timeout(10)]),
	flag(server_port,_,Port).

%Shows in the web browser the OAuth2 consent page at Google's.
%Shows up finally if no file named refreshtoken.txt
%Needs propably main/superuser user rights on Windows
show_consent(Port,Scope,Url):-
	oauth2_client_id(CID),
	atom_concat('http://localhost:',Port,A),
        atom_concat(A,'/oauth2accesscode',RDIRU),
	flag(redirect_uri,_,RDIRU),
	oauth2_endpoint_baseurl(Base),

	parse_url(Url,Base,
		    [search([
			 client_id=CID,
			 redirect_uri=RDIRU,
			 %scope='https://www.googleapis.com/auth/youtube',
			 scope=Scope,
			 response_type=code,
			 access_type=offline
			])]),
		win_shell(open, Url).

%% handle_autocode(Request) is det.
%
%	This is a handler for server where user is redirected after
%	approving consent
%
%gets here (What gets here?), this is a handler for the autcode_server
handle_autcode(Request) :-
	format('Content-type: text/plain~n~n'),
	flag(server_port,Port,Port),

        format('User consent received Ok~n'),
	member(search(A),Request),!,
	A=[(code=Code)],
	flag(autcode,_,Code),
	autcode_to_refreshtoken_accesstoken,

        format('Token(s) received Ok~n'),
	write_time.

%%	autcode_to_refreshtoken_accesstoken is det.
%
%with temporary authorization code, get the refresh- and accesstokens
autcode_to_refreshtoken_accesstoken:-
	oauth2_endpoint_token(Base),
	%Base='https://accounts.google.com/o/oauth2/token',
	flag(autcode,AC,AC),
	oauth2_client_id(CID),
	oauth2_client_secret(CS),
	%oauth2(redirect_uri,RDIRU),
	flag(redirect_uri,RDIRU,RDIRU),
	ListofData=[
		       code=AC,
		       client_id=CID,
		       client_secret=CS,
		       redirect_uri=RDIRU,
		       grant_type=authorization_code

			  ],
        http_open(Base, In,
                  [ cert_verify_hook(cert_verify),
		    method(post),post(form(ListofData))
                  ]),
	json_read(In,JSon),
	close(In),
	json(List)=JSon,
	member((access_token=AccToken),List),!,
	flag(access_token,_,AccToken),
	maybe_refreshtoken(List).

%%	from_refreshtoken_accesstoken is det.
%
%If refreshtoken is valid it gets a valid accesstoken and inserts it to
%flag(access_token,A,A)
%
%accesstoken expires in 60 minutes, 3600 seconds
from_refreshtoken_accesstoken:-
	oauth2_endpoint_token(Base),
	%Base='https://accounts.google.com/o/oauth2/token',
	flag(refresh_token,RT,RT),
	oauth2_client_id(CID),
	oauth2_client_secret(CS),
	ListofData=[
		       refresh_token=RT,
		       client_id=CID,
		       client_secret=CS, %from Google API console
		       grant_type=refresh_token

			  ],
        http_open(Base, In,
                  [ cert_verify_hook(cert_verify),
		    method(post),post(form(ListofData))
                  ]),
	json_read(In,JSon),
	close(In),

	JSon=json(List),
	member((access_token=AccToken),List),!,
	flag(access_token,_,AccToken).


%stupid name for a predicate
maybe_refreshtoken(JSon):-
	member((refresh_token=RefToken),JSon),
	!,
	flag(refresh_token,_,RefToken),
	save_refresh_token.
maybe_refreshtoken(_).


%%	u is det.
%
%	Shortcut for getting accesstoken
u:-
	from_refreshtoken_accesstoken.

%%	valid_refresh_token is nondet.
%
% If no refresh_token set up http
% server and show a webcite etc. etc.
% checks if already done
%
% run/0 is shortcut to this
%
% refresh_token is saved with plain text (bad idea)
% to file refresh_token.txt
valid_refresh_token:-

	\+ (flag(refresh_token,A,A),A=0),
	!.

valid_refresh_token:-
	catch((
	      see('refresh_token.txt'),
	    read(RefreshToken),
	    seen,
	    flag(refresh_token,_,RefreshToken)),
	      _,
	      fail),
	!,
	from_refreshtoken_accesstoken.

valid_refresh_token:-
	autcode_server(A),
	debug(oauth2client(valid_refresh_token),'~s ~s',['authorization server port',A]),
	flag(server_port,Port,Port),
	oauth2_scope(ScopesAtom),
	%show_consent(Port,'https://www.googleapis.com/auth/compute https://www.googleapis.com/auth/devstorage.read_write',Url),
		show_consent(Port,ScopesAtom,Url),

	!,
	debug(oauth2client(valid_refresh_token),'~s ~s',['consent url for local browser ',Url]).


%%	save_refresh_token is det.
%
%	Saves refresh_token to a plain txt file!
%
save_refresh_token:-
	flag(refresh_token,RT,RT),
	catch((
	    tell('refresh_token.txt'),
	    put('\''),write(RT),put('\''),put('.'),
	    told),_,true).

%%	stop is det.
%
%	Should stop local server that is used for redirection
%	after user approves consent
stop:-
	threads,
	flag(server_port,Port,Port),
	http_stop_server(Port,[]).

%%	cert_verify(SSL, ProblemCert, AllCerts, FirstCert, Error)
%	is det.
%
%	Is used with HTTPS
%
%
cert_verify(_SSL, _ProblemCert, _AllCerts, _FirstCert, _Error) :-
        debug(ytapp(cert_verify),'~s', ['Accepting certificate']).
