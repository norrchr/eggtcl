namespace eval __users__ {

	if {![array exists ___ircusers]} {
		array set __ircusers {}
	}

	proc __adduserinfotolist {nickname ident rdns ip {authname {0}} {idletime {0}} {realname {}}} {
		variable __ircusers
		if {$nickname eq ""} { return -err "__adduserinfotolist: No nickname supplied" }
		if {$ident eq ""} { return -err "__adduserinfotolist: No ident supplied" }
		if {$rdns eq ""} { return -err "__adduserinfotolist: No rdns supplied" }
		if {$ip eq ""} { return -err "__adduserinfotolist: No ip supplied" }
		set nickname [string tolower $nickname]
		if {[string equal -nocase $rdns $ip]} {
			set __ircusers($nickname,hostname) "$ident@$ip"
		} else {
			set __ircusers($nickname,hostname) "$ident@$rdns"
		}
		set __ircusers($nickname,rdns) "$rdns"
		set __ircusers($nickname,ip) "$ip"
		set __ircusers($nickname,authname) "$authname"
		set __ircusers($nickname,idletime) "$idletime"
		set __ircusers($nickname,realname) "$realname"
		return 1
	}
	
	proc __updateinfolistbynick {nickname newnickname} {
		variable __ircusers
		set nickname [string tolower $nickname]
		set newnickname [string tolower $newnickname]
		foreach {ele val} [array get __ircusers $nickname,*] {
			if {$ele eq ""} { continue }
			set __ircusers($newnickname,[lindex [split $ele ,] 1]) $val
			unset __ircusers($ele)
		}
		return 1
	}
	
	proc __clearlists {} {
		variable __ircusers
		foreach element [array names __ircusers] {
			if {$element eq ""} { continue }
			unset __ircusers($element)
		}
	}
	
	puts "__users__ loaded"
	
}
