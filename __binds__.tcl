namespace eval __binds__ {

	namespace export bind unbind binds

	variable __types [list pubm pub]

	set __pubm [list]
	set __pub [list]
	
	proc binds {args} {
		variable __pubm; variable __pub
		return [join "$__pubm $__pub" ", "]
	}
	
	# bind type flags cmd/mask ?procname?"
	proc bind {type flags mask procname} {
		variable __types
		set type [string tolower $type]
		if {[lsearch -exact $__types $type] eq -1} { return -err "Invalid bind type: $type" }
		if {$type eq "pubm"} {
			variable __pubm
			set __pubm [linsert $__pubm end "$flags 0 $procname $mask"]
		} elseif {$type eq "pub"} {
			variable __pub
			set __pub [linsert $__pub end "$flags 0 $procname $mask"]
		}
		return 1
	}

	proc unbind {type flags mask procname} {
		variable __types
		set type [string tolower $type]
		if {[lsearch -exact $__types $type] eq -1} { return -err "Invalid bind type: $type" }
		variable __$type
		set f -1
		foreach bind $__type {
			incr f
			if {$bind eq ""} { continue }
			if {[lindex [split $bind] 0] eq $flags && [lindex [split $bind] 2] eq $proc && [string equal -nocase [lrange $bind 3 end] $procname]} { break }
		}
		if {$f<0} { return 0 }
		set __$type [lreplace $__${type} $f $f]
	}
	
	proc __checkbinds {line} {
		if {[string equal -nocase "PRIVMSG" [lindex [split $line] 1]]} {
			set nickname [string trimleft [lindex [split [lindex [split $line] 0] !] 0] :]
			set hostname [lindex [split [lindex [split $line] 0] !] 1]
			#set handle [nick2hand $nickname]
			set handle "*"
			set target [lindex [split $line] 2]
			#puts "message:"
			set message [string trimleft [join [lrange [split $line] 3 end]] :]
			#puts "$message"
			if {[string index $target 0] eq "#"} {
				variable __pub; variable __pubm
				#puts "checking pub binds"
				set f 0
				foreach bind "$__pub" {
					if {$bind eq ""} { continue }
					#if {![matchattr $handle [lindex [split $bind] 0] $target]} { continue }
					if {[string equal -nocase [lindex [split $bind] end] [lindex [split $message] 0]]} {
						puts "Bind match: [lindex [split $bind] end]"
						set f 1
						if {[catch {set r [::[lindex [split $bind] 2] $nickname $hostname $handle $target [join [lrange $message 1 end]]]} err]} {
							puts "Bind error for \"[lindex [split $bind] end]\" (::[lindex [split $bind] 2]): $err"
						} elseif {$r eq "1"} {
							return 
						}
					}
				}
				if {$f} { return }
				#puts "checking pubm binds"
				foreach bind "$__pubm" {
					if {$bind eq ""} { continue }
					set mask [join [lrange $bind 3 end]]
					#if {![matchattr $handle [lindex [split $bind] 0] $target]} { continue }
					if {[string index [lindex [split $mask] 0] 0] eq "#" && ![string equal -nocase [lindex [split $mask] 0] $target]} { continue }
					if {[string match -nocase "$mask" "$message"]} {
						if {[catch {set r [::[lindex [split $bind] 2] $nickname $hostname $handle $target $message]} err]} {
							puts "Bind error for \"$mask\" (::[lindex [split $bind] 2]): $err"
						} elseif {$r eq "1"} {
							return 
						}
					}
				}
			} else {
				# ignore for now
				return
				variable __msg; variable __msgm
				foreach bind "$__msg" {
					if {$bind eq ""} { continue }
					#if {![matchattr $handle [lindex [split $bind] 0]]} { continue }
					if {[string equal -nocase [lindex [split $bind] 2] [lindex [split $message] 0]]} {
						set f 1
						if {[catch {set r [::[lindex [split $bind] 2] $nickname $hostname $handle $message]} err]} {
							puts "Bind error: $err"
						} elseif {$r eq "1"} {
							return 
						}
					}
				}
				if {$f} { return }
				foreach bind "$__msgm" {
					if {$bind eq ""} { continue }
					#if {![matchattr $handle [lindex [split $bind] 0]]} { continue }
					if {[string match -nocase [lindex [split $bind] 2] $target] || [string match -nocase [lindex [split $bind] 2] $message]} {
						if {[catch {set r [::[lindex [split $bind] 2] $nickname $hostname $handle $message]} err]} {
							puts "Bind error: $err"
						} elseif {$r eq "1"} {
							return 
						}
					}
				}
			}
		}
	}
	
	puts "__binds__ loaded"
	
}

namespace import __binds__::bind __binds__::unbind __binds__::binds
