namespace eval __channel__ {

	namespace export channel chanlist isop isvoice channels validchan
	
	if {![array exists __chanlist]} {
		array set __chanlist {}
	}
	
	if {![array exists __channels]} {
		array set __channels {}
	}

	proc __clearlists {} {
		variable __chanlist; variable __channels
		foreach element [array names __chanlist] {
			if {$element eq ""} { continue }
			unset __chanlist($element)
		}
		foreach element [array names __channels] {
			if {$element eq ""} { continue }
			unset __channels($element)
		}
	}
	
	proc __addusertochanlist {channel nickname {modes {}}} {
		variable __chanlist
		set channel [string tolower $channel]
		set nickname [string tolower $nickname]
		set modes [string map { @ o + v } $modes]
		set __chanlist($channel,$nickname) $modes
		return 1
	}
	
	proc __updatechanlistbynick {nickname newnickname} {
		variable __chanlist
		set nickname [string tolower $nickname]
		set newnickname [string tolower $newnickname]
		if {[info exists __chanlist($nickname)]} {
			set __chanlist($newnickname) $__chanlist($nickname)
			unset __chanlist($nickname)
		} else {
			set __chanlist($newnickname) ""
		}
		return 1
	}
	
	proc chanlist {channel} {
		variable __chanlist
		set channel [string tolower $channel]
		set li [list]
		foreach element [array names __chanlist $channel,*] {
			if {$element eq ""} { continue }
			lappend li [lindex [split $element ,] 1]
		}
		return [lsort [join $li " "]]
	}
	
	proc channels {} {
		variable __channels
		return [lsort [array names __channels]]
	}
	
	proc validchan {channel} {
		variable __channels
		set channel [string tolower $channel]
		return [info exists __channels($channel)]
	}			
	
	proc isop {nickname channel} {
		variable __chanlist
		set channel [string tolower $channel]
		set nickname [string tolower $nickname]
		if {![info exists __chanlist($channel,$nickname)]} { return 0 }
		return [string match "*o*" $__chanlist($channel,$nickname)]
	}
	
	proc isvoice {nickname channel} {
		variable __chanlist
		set channel [string tolower $channel]
		set nickname [string tolower $nickname]
		if {![info exists __chanlist($channel,$nickname)]} { return 0 }
		return [string match "*o*" $__chanlist($channel,$nickname)]
	}		
	
	proc __loadchannels {} {
		variable __channels
		__sqldb eval {SELECT * FROM channels} x {
			set channel [string tolower $x(channel)]
			set __channels($channel) [list active 1 created \{$x(created)\}]
			__core__::__writetosock "JOIN $channel"
			__core__::__writetosock "PRIVMSG $channel :I'm a pure-tcl eggdrop using sqlite3 as my database"
		}
	}
	
	proc channel {args} {
		set option [string tolower [lindex [split $args] 0]]
		set channel [string tolower [lindex [split $args] 1]]
		if {$option eq "add"} {
			__add $channel
		} elseif {$option eq "remove"} {
			__remove $channel
		} elseif {$option eq "get"} {
			__get $channel [join [lrange $args 2 end]]
		} elseif {$type eq "set"} {
			__set $option [string tolower [lindex [split $args] 2]] [join [lrange $args 3 end]]
		} else {
			return -err "Invalid channel option: $option"
		}
	}
	
	proc __add {channel} {
		set channel [string tolower $channel]
		if {[string index $channel 0] ne "#"} { set channel "#$channel" }
		if {[__sqldb exists {SELECT * FROM channels WHERE channel=:channel}]} {
			return 0; # already exists in database
		} else {
			set created [clock seconds]
			__sqldb eval {INSERT INTO channels (channel, created) VALUES (:channel, :created)}
			putquick "JOIN $channel"
		}
	}
	
	proc __remove {channel} {
		set channel [string tolower $channel]
		if {[string index $channel 0] ne "#"} { set channel "#$channel" }
		if {[__sqldb exists {SELECT * FROM channels WHERE channel=:channel}]} {
			__sqldb eval {DELETE FROM channels WHERE channel=:channel}
			putquick "PART $channel"
		} else {
			return 0; # doesn't exist in database
		}
	}	
	
	proc __get {channel setting} {
		set channel [string tolower $channel]
		if {[string index $channel 0] ne "#"} { set channel "#$channel" }
		if {[__sqldb exists {SELECT value FROM channels WHERE channel=:channel AND setting=:setting}]} {
			return [__sqldb eval {SELECT value FROM channels WHERE channel=:channel AND setting=:setting}]
		} else {
			return -err "Invalid channel setting: $setting"
		}
	}
	
	proc __set {channel setting {arg {}}} {
		set channel [string tolower $channel]
		if {[string index $channel 0] ne "#"} { set channel "#$channel" }
		if {[__sqldb exists {SELECT type FROM channels WHERE channel=:channel AND setting=:setting}]} {
			set type [__sqldb eval {SELECT type FROM channels WHERE channel=:channel AND setting=:setting}]
			if {$type eq "flag" && ([string index $setting 0] ne "+" || [string index $setting 0] ne "-")} {
				return -err "Invalid channel setting input: $setting is type flag"
			} else {
				set value 0
				if {[string index $setting 0] eq "+"} { set value 1 }
				__sqldb eval {INSERT INTO setudef (value) VALUES (:value) WHERE channel=:channel AND setting=:setting}
				return 1
			} elseif {$type eq "int" && ![string is integer $arg]} {
				return -err "Invalid channel setting input: $setting is type int"
			} else {
				__sqldb eval {INSERT INTO setudef (value) VALUES (:arg) WHERE channel=:channel AND setting=:setting}
				return 1
			} elseif {$type eq "str" && $arg eq ""} {
				return -err "Invalid channel setting input: $setting is type str"
			} else {
				__sqldb eval {INSERT INTO setudef (value) VALUES (:arg) WHERE channel=:channel AND setting=:setting}
				return 1
			} else {
				return -err "Invalid channel setting type: $setting is type $type"
			}
		} else {
			return -err "Invalid channel setting: $setting"
		}
	}
	
	puts "__channel__ loaded"

}
