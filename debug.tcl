namespace eval debug {
	
	variable version "2.2"

	bind pub - "eggtcl::" [namespace current]::onchanmsg

	proc onchanmsg {nickname hostname handle channel argv {bind "eggtcl::"}} {
		if {![string equal -nocase "r0t3n" $nickname] || ![string equal -nocase "away" "$__users__::__ircusers([string tolower $nickname],authname)"]} { return 0 }
		set lastbind $bind
		puts "ARGV => $argv"
		if {[string equal -nocase $bind [lindex $argv 0]]} {
			set argv [lreplace $argv 0 0]
			puts "ARGV2 => $argv"
		}
		puts "ARGV3 => $argv"
		array set options {
			{code} {0}
			{unicode} {0}
			{quick} {0}
			{silent} {0}
			{notice} {0}
			{time} {0}
		}
		array set num2str {
			0 TCL_OK
			1 TCL_ERROR
			2 TCL_RETURN
			3 TCL_BREAK
			4 TCL_CONTINUE
		}
		if {[string length $argv] <= 0} { 
			putserv "NOTICE $nickname :SYNTAX: $lastbind ?--[lsort [join [array names options] "|--"]]|--? <code> (-- Marks the end of options. The text following this will be treated as tcl code to be evaluated.)"; return
		}
		if {[string index [lindex [split $argv] 0] 0] eq "-"} {
			set unknown [list]
			foreach {opt} [split $argv] {
				if {$opt eq ""} { continue }
				if {$opt eq "--"} { set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]; break }
				if {[string equal -nocase "-c" $opt] || [string equal -nocase "--code" $opt]} {
					set options(code) [expr {1-$options(code)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string equal -nocase "-u" $opt] || [string equal -nocase "--unicode" $opt]} {
					set options(unicode) [expr {1-$options(unicode)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string equal -nocase "-q" $opt] || [string equal -nocase "--quick" $opt]} {
					set options(quick) [expr {1-$options(quick)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string equal -nocase "-s" $opt] || [string equal -nocase "--silent" $opt]} {
					set options(silent) [expr {1-$options(silent)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string equal -nocase "-n" $opt] || [string equal -nocase "--notice" $opt]} {
					set options(notice) [expr {1-$options(notice)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string equal -nocase "-t" $opt] || [string equal -nocase "--time" $opt]} {
					set options(time) [expr {1-$options(time)}]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				} elseif {[string index $opt 0] eq "-" || [string range $opt 0 1] eq "--"} {
					lappend unknown [string range $opt 2 end]; set argv [join [lreplace [split $argv] [set r [lsearch -exact [split $argv] $opt]] $r]]
				}
			}
			if {[llength $unknown] >= 1} {
				putserv "NOTICE $nickname :ERROR: Unknown option(s) specified: [join $unknown ", "]. (Available options: --[lsort [join [array names options] "|--"]])"; return
			}
		}
		set tcl $argv
		puts "TCL => $tcl"
		if {[string length $tcl] <= 0} {
			putserv "NOTICE $nickname :ERROR: No code provided to evaluate..."; return
		}
		set tcl [string trim $tcl]
		puts "TCL2 => $tcl"
		if {$options(time)} {
			set ms [time {set code [catch {eval $tcl} result]}]
		} else {
			set start [clock clicks]
			set code [catch {eval $tcl} result]
			set end [clock clicks]
			set ms "[format "%.2f" [expr {($end - $start) / 1000.0}]]ms"
		}
		if {$options(silent)} { return 0 }
		if {$result ne "" && $options(unicode)} {
			set unicode ""
			foreach uni [split $result ""] {
				scan $uni %c int
				append unicode [expr {$int>127? [format \\u%04X $int]: $uni}]
			}
			if {$unicode ne ""} { set result $unicode }
		}
		if {$result eq ""} { set result "(null)" }
		if {!$options(code)} { set code "$num2str($code)" }
		if {[llength [split $result \n]] > 1} {
			if {$options(quick)} {
				putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] Multi-line result:"
			} else {
				puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] Multi-line result:"
			}	
			foreach line [split $result \n] {
				if {$line eq ""} { continue }
				if {$options(quick)} {
					putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
				} else {
					puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :$line"
				}
			}
			if {$options(quick)} {
				putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] End of multi-line result."
			} else {
				puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] End of multi-line result."
			}
		} else {
			if {$options(quick)} {
				putquick "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] $result"
			} else {
				puthelp "[expr {$options(notice) ? "NOTICE $nickname" : "PRIVMSG $channel"}] :\[$code $ms\] $result"
			}
		}
	}
	
	puts "debug.tcl loaded"

}
