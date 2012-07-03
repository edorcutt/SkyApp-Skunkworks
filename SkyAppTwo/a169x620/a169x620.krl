ruleset a169x620 {
	meta {
		name "SkyAppTwo"
		description <<
			
		>>

		// --------------------------------------------
		// ent:SkySessionToken

		author "Ed Orcutt"
		logging on

		use module a169x568 alias twitterBootstrap
		use module a169x618 alias skyNav
    use module a169x625 alias CloudOS
	}

	global {
    thisRID = meta:rid();

	  // --------------------------------------------
		showNavLogin = defaction() {
		  {
			  emit <<
				  $K('#navLogin').hide();
				  $K('#navProfile').show();
				  $K('#navLogout').show();
				>>;
			}
		};

	  // --------------------------------------------
		showNavLogout = defaction() {
		  {
			  emit <<
				  $K('#navLogin').show();
				  $K('#navProfile').hide();
				  $K('#navLogout').hide();
				>>;
			}
		};

	  // --------------------------------------------
		showSpinner = defaction() { emit << $K('#modalSpinner').modal('show'); >>; };
		hideSpinner = defaction() { emit << $K('#modalSpinner').modal('hide'); >>; };
	}

  // ========================================================================
  // Section: Init
  // ========================================================================

  // ------------------------------------------------------------------------
  rule webapp_Init {
    select when pageview
    {
		  twitterBootstrap:init();
		  skyNav:init();
    }
  }

  // ========================================================================
  // Section: Site Navigation
  // ========================================================================

  // ------------------------------------------------------------------------
  rule webapp_Router {
    select when pageview
    {
			watch("#formLogin", "submit");
			watch("#formSignup", "submit");

      emit <<
        // --------------------------------------------
				// initialize the spinner modal
				$K('#modalSpinner').modal({
				  backdrop: false,
				  keyboard: false,
					show: true
				});

        // --------------------------------------------
        // set watcher for url fragment changes
        // http://www.windley.com/archives/2011/04/kblog_making_the_back_button_work.shtml

        self.document.location.hash='!/';

        $KOBJ(window).hashchange(function() {
				  var newHash = self.document.location.hash;

          if(KOBJ.skyNav.previous == undefined ||
             KOBJ.skyNav.previous != newHash) {
            var app = KOBJ.get_application(thisRID);

						// view Home
 					  if (newHash === '#!/') {
						  KOBJ.skyNav.SetActive('#navHome');
							KOBJ.skyNav.ShowView('#viewHome');
					  }
						// view About
					  else if (newHash === '#!/about') {
						  KOBJ.skyNav.SetActive('#navAbout');
							KOBJ.skyNav.ShowView('#viewAbout');
						}
						// view Login
					  else if (newHash === '#!/login') {
						  KOBJ.skyNav.SetActive('#navLogin');
							KOBJ.skyNav.ShowView('#viewLogin');
					  }
						// view Signup
					  else if (newHash === '#!/signup') {
						  KOBJ.skyNav.SetActive('#navLogin');
							KOBJ.skyNav.ShowView('#viewSignup');
					  }
						// view Logout
					  else if (newHash === '#!/logout') {
						  $K('#modalSpinner').modal('show');
              app.raise_event("hash_change", {"newhash": newHash});
					  }
						// view Profile
					  else if (newHash === '#!/profile') {
						  KOBJ.skyNav.SetActive('#navProfile');
							KOBJ.skyNav.ShowView('#viewProfile');
              app.raise_event("hash_change", {"newhash": newHash});
						}

						// otherwise just event back into KRE
					  else {
              app.raise_event("hash_change", {"newhash": newHash});
						}

            KOBJ.skyNav.previous = newHash;
          }
        });
      >>;

			hideSpinner();
			emit <<
			  $K('#formLogin').submit(function() {
					$K('#modalSpinner').modal('show');
				});
			  $K('#formSignup').submit(function() {
					$K('#modalSpinner').modal('show');
				});
      >>;
    }
  }

  // ------------------------------------------------------------------------
	rule check_login {
	  select when pageview
		if (ent:SkySessionToken) then {
		  skyNav:setHash("/profile");
			showNavLogin();
		}
	}

  // ------------------------------------------------------------------------
	rule sky_logout {
    select when web hash_change newhash "/logout$"
		{
			showNavLogout();
			skyNav:setHash("/");
			hideSpinner();
		}
		fired {
		  clear ent:SkySessionToken;
		}
	}

  // ------------------------------------------------------------------------
  // DEBUG
  rule test_hash_change is inactive {
    select when web hash_change
    pre {
      newHash = event:attr("newhash");
    }
    {
      notify("Hash Changed", "newhash: " + newHash) with sticky = true;
    }
  }

  // ------------------------------------------------------------------------
	rule formLogin_hideSpinner {
	  select when web submit "#formLogin"
		{ hideSpinner(); }
  }

	rule formLogin_submit {
	  select when web submit "#formLogin"
		pre {
			loginEmail  = event:attr("loginEmail");
			loginPass   = event:attr("loginPassword");

			penAuth    = CloudOS:cloudAuth(loginEmail, loginPass);
			authStatus = penAuth{"status"};
			authToken  = penAuth{"token"};
		}
		if (authStatus) then {
				skyNav:setHash("/profile");
				showNavLogin();
		}
		fired {
			set ent:SkySessionToken authToken;
		} else {
		  raise explicit event formLogin_fail for thisRID
			  with penAuth = penAuth;
		}
  }

  // ------------------------------------------------------------------------
	rule formLogin_fail {
	  select when explicit formLogin_fail
		pre {
		  penAuth = event:attr("penAuth");
			msgAuth = penAuth{"msg"};
		}
		{
			skyNav:showAlert("#alertLogin", msgAuth);
		}
	}

  // ------------------------------------------------------------------------
	rule formSignup_hideSpinner {
	  select when web submit "#formSignup"
		{ hideSpinner(); }
  }

	rule formSignup_submit {
	  select when web submit "#formSignup"
		pre {
			signupEmail = event:attr("signupEmail");
			signupPass  = event:attr("signupPassword");

			penAuth    = CloudOS:cloudCreate(signupEmail, signupPass);
			authStatus = penAuth{"status"};
			authToken  = penAuth{"token"};
		}
		if (authStatus) then {
				skyNav:setHash("/profile");
				showNavLogin();
		}
		fired {
			set ent:SkySessionToken authToken;
		} else {
		  raise explicit event formSignup_fail for thisRID
			  with penAuth = penAuth;
		}
  }

  // ------------------------------------------------------------------------
	rule formSignup_fail {
	  select when explicit formSignup_fail
		pre {
		  penAuth = event:attr("penAuth");
			msgAuth = penAuth{"msg"};
		}
		{
			skyNav:showAlert("#alertSignup", msgAuth);
		}
	}

  // ------------------------------------------------------------------------
	rule viewProfile {
    select when web hash_change newhash "/profile$"
		pre {
		  //goo = CloudOS:rulesetAdd("a169x625", ent:SkySessionToken);
		  //boo = CloudOS:rulesetRemove("a169x625", ent:SkySessionToken);
			// zoo = CloudOS:channelCreate("TESTING123", ent:SkySessionToken);
			//moo = CloudOS:channelDestroy("00a4be10-65b6-012f-5cd0-00163e64d091", ent:SkySessionToken);
		  appListJSON = CloudOS:rulesetList(ent:SkySessionToken);

			appList = appListJSON.map( function(x) {
			  appName = x{"name"};
				appRID  = x{"rid"};
			  appItem = "<li>#{appName} (#{appRID})</li>";
				appItem
			});
			appListNav = appList.join("");

			channelListJSON = CloudOS:channelList(ent:SkySessionToken).pick("$.channels", true).head();
			channelList = channelListJSON.map( function(x) {
			  channelName = x{"name"};
				channelCID  = x{"cid"};
			  channelItem = "<li>#{channelName}</li>";
				channelItem
			});
			channelListNav = channelList.join("");

		}
		{
		  notify("viewProfile", "hello neo ...") with sticky = true;
			after("#sideNavApps", appListNav);
			after("#sideNavChannels", channelListNav);
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
