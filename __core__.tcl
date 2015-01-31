source [pwd]/__overwrite__.tcl

namespace eval __core__ {

	namespace export die rehash __writetosock putquick putserv puthelp
	
	variable __version "0.0.0.2 BETA"
	
	variable __die 0
	variable __rehash 0
	variable __configfile ""
	
	variable __botnick "eggtcl"
	variable __altnick "eggdroptcl"
	variable __botusername "eggtcl"
	variable __botrealname "Eggdrop-puretcl 0.0.0.2 BETA"
	variable __myaddr ""
	variable __myport ""
	variable __servip "irc.quakenet.org"
	variable __servport "6667"
	
	variable __sock ""
	variable __connected 0
	
	if {![array exists __timers]} {
		array set __timers {}
	}
	
	if {![array exists __joined]} {
		array set __joined {}
	}

	proc die {reason} {
		variable __die
		set __die 1
		vwait ::__dead
		puts "DIE: $reason"
		exit
	}
	
	proc rehash {} {
		variable __rehash; variable __configfile
		set __rehash 1
		source $__configfile
	}
	
	proc putquick {text {options {}}} {
		variable __sock; variable __connected
		if {$__sock ne "" || !$__connected} {
			__writetosock $text
		}
	}
	
	proc putserv {text {options {}}} {
		variable __sock; variable __connected
		if {$__sock ne "" || !$__connected} {
			__writetosock $text
		}
	}
	
	proc puthelp {text {options {}}} {
		variable __sock; variable __connected
		if {$__sock ne "" || !$__connected} {
			__writetosock $text
		}
	}
	
	proc __writetosock {message} {
		variable __sock; variable __connected
		if {$__sock ne "" || !$__connected} {
			puts "$__sock [clock milliseconds] >> $message"
			puts $__sock "$message"
		}
	}
	
	proc __doconnection {} {
		variable __myaddr; variable __myport; variable __servip; variable __servport; variable __botnick; variable __altnick; variable __sock; variable __connected; variable __botusername; variable __botrealname
		if {$__sock != "" || $__connected} { puts "Socket already established -- Exiting"; exit }
		puts "Attempting to connect to ${__servip}:${__servport}..."
		if {[catch {set __sock [socket $__servip $__servport]} err]} {
			puts "Socket Error: $err -- Exiting"; exit
		} else {
			puts "Connection established..."
			set __connected 1
			fconfigure $__sock -blocking 0
			fconfigure $__sock -buffering line
			puts "$__sock [clock milliseconds] >> USER $__botusername . . :$__botrealname"
			puts $__sock "USER $__botusername . . :$__botrealname"
			puts "$__sock [clock milliseconds] >> NICK $__botnick"
			puts $__sock "NICK $__botnick"
			puts "calling __loop"
			__loop
		}
	}
	
	proc __loop {} {
		variable __sock; variable __die; variable __rehash; variable __events; variable __timers; variable __bindtimets; variable __botnick; variable __connected; variable __joined
		puts "starting __loop"
		while {1} {
			if {$__die} {
				# kill the socket
				puts "$__sock >> QUIT :My Master Killed Me :("
				puts $__sock "QUIT :My Master Killed Me :("
				exit
			} elseif {$__rehash} {
				# config file rehashed, do we need to change our nickname??
				continue
			} else {
				# process incoming messages
				if {[gets $__sock __line] < 0} {
					if {[eof $__sock]} {
						close $__sock; set __sock ""; set __connected 0;
						__channel__::__clearlists
						__users__::__clearlists
						puts "Got EOF from socket -- Reconnecting"; break
					}
				} else {
					# Got a line from the server
					puts "$__sock [clock milliseconds] << $__line"		
					if {[string equal -nocase "PING" [lindex [split $__line] 0]]} {
						puts "$__sock [clock milliseconds] >> PONG [lindex [split $__line] 1]"
						puts $__sock "PONG [lindex [split $__line] 1]"
					} elseif {[string equal -nocase "001" [lindex [split $__line] 1]]} {
						puts "Successfully connected to [lindex [split $__line] 0] as [set __botnick [lindex [split $__line] 2]]"
						set __connected 1
						__channel__::__loadchannels
					} elseif {[string equal -nocase "433" [lindex [split $__line] 1]]} {
						set nickname "[lindex [split $__line] 3]"
						puts "__loop 433: '$nickname' already in use, trying '${nickname}_'"
						__writetosock "NICK ${nickname}_"
					} elseif {[string equal -nocase "NICK" [lindex [split $__line] 1]]} {
						set nickname [string trimleft [lindex [split [lindex [split $__line] 0] !] 0] :]
						set newnickname [string trimleft [lindex [split $__line] end] :]
						if {[string equal -nocase $nickname $__botnick]} {
							set __botnick $newnickname
						}
						__channel__::__updatechanlistbynick $nickname $newnickname
						__users__::__updateinfolistbynick $nickname $newnickname
					} elseif {[string equal -nocase "JOIN" [lindex [split $__line] 1]]} {
						set channel [string tolower [lindex [split $__line] 2]]
						if {![validchan $channel]} { puts "__loop raw JOIN error: JOIN for unknown channel $channel"; continue }
						set nickname [string trimleft [lindex [split [lindex [split $__line] 0] !] 0] :]
						set hostname [lindex [split [lindex [split $__line] 0] !] 1]
						if {[string equal -nocase $nickname $__botnick]} {
							#set __joined($channel) [clock clicks]
						} else {
							__channel__::__addusertochanlist $channel $nickname ""
						}
					} elseif {[string equal -nocase "PART" [lindex [split $__line] 1]]} {
						set channel [string tolower [lindex [split $__line] 2]]
						if {![validchan $channel]} { puts "__loop raw JOIN error: JOIN for unknown channel $channel"; continue }
						set nickname [string trimleft [lindex [split [lindex [split $__line] 0] !] 0] :]
						set hostname [lindex [split [lindex [split $__line] 0] !] 1]
						if {[string equal -nocase $nickname $__botnick]} {
							__channel__::__clearchanlistforchannel $channel
						} else {
							__channel__::__removeuserfromchanlist $channel $nickname
						}
					} elseif {[string equal -nocase "QUIT" [lindex [split $__line] 1]]} {
						set nickname [string trimleft [lindex [split [lindex [split $__line] 0] !] 0] :]
						set hostname [lindex [split [lindex [split $__line] 0] !] 1]
						set reason [string trimleft [join [lrange $__line 2 end]] :]
						__channel__::__removeuserfromchanlists $nickname
						__users__::__removeuserfromuserinfo $nickname				
					} elseif {[string equal -nocase "353" [lindex [split $__line] 1]]} {
						# only process for binds
						continue
						set for [lindex [split $__line] 2]
						set channel [lindex [split $__line] 4]
						if {![string equal -nocase "$for" "$__botnick"]} { puts "__loop raw 353 error: Reply meant for '$for' not me"; continue }
						if {![validchan $channel]} { puts "__loop raw 353 error: Reply for unknown channel $channel"; continue }
						set users [lrange $__line 5 end]; set op 0; set voice 0; set total 0
						foreach user $users {
							if {$user eq ""} { continue }
							__channel__::__addusertochanlist $channel [string map { @ {} + {} } $user] ""
						}
					} elseif {[string equal -nocase "366" [lindex [split $__line] 1]]} {
						# only process this for binds
						set for [lindex [split $__line] 2]
						set channel [lindex [split $__line] 3]
						if {![string equal -nocase "$for" "$__botnick"]} { puts "__loop raw 366 error: Reply meant for '$for' not me"; continue }
						if {![validchan $channel]} { puts "__loop raw 366 error: Reply for unknown channel $channel"; continue }
						__writetosock "WHO $channel n%chilnruaf"
					} elseif {[string equal -nocase "354" [lindex [split $__line] 1]]} {
						set channel [string tolower [lindex [split $__line] 3]]
						if {![validchan $channel]} { puts "__loop raw 354 error: Reply for unknown channel $channel"; continue }
						if {![info exists __joined($channel)]} { set __joined($channel) [clock clicks] }
						set ident [lindex [split $__line] 4]
						set ip [lindex [split $__line] 5]
						set rdns [lindex [split $__line] 6]
						set nickname [lindex [split $__line] 7]
						set flags [lindex [split $__line] 8]
						set idletime [lindex [split $__line] 9]
						set authname [lindex [split $__line] 10]
						set realname [string trimleft [lrange $__line 11 end] :]
						set status ""
						if {[string match "*@*" $flags]} { append status o }
						if {[string match "*+*" $flags]} { append status v }
						__channel__::__addusertochanlist $channel $nickname $status
						__users__::__adduserinfotolist $nickname $ident $rdns $ip $authname $idletime $realname
					} elseif {[string equal -nocase "315" [lindex [split $__line] 1]]} {
						set for [lindex [split $__line] 2]
						set channel [string tolower [lindex [split $__line] 3]]
						if {![string equal -nocase "$for" "$__botnick"]} { puts "__loop raw 315 error: Reply meant for '$for' not me"; continue }
						if {![validchan $channel]} { puts "__loop raw 315 error: Reply for unknown channel $channel"; continue }
						set ms "[format "%.2f" [expr {([clock clicks]-$__joined($channel)) / 1000.0}]]ms"
						set op 0; set voice 0; set authed 0
						foreach user [chanlist $channel] {
							if {[isop $user $channel]} { incr op }
							if {[isvoice $user $channel]} { incr voice }
							if {[isauthed $user]} { incr authed }
						}
						__writetosock "PRIVMSG $channel :Processed $channel in $ms (Users: [llength [chanlist $channel]] - Op: $op - Voice: $voice - Authed: $authed)"
						#puts "$channel [llength [chanlist $channel]]: [join [chanlist $channel] ", "]"
					}						
					# process this line and fire off the binds
					__binds__::__checkbinds $__line
				}
				set minute [clock format [clock seconds] -format %M]
				if {![info exists __bindtimets] || $__bindtimets eq ""} { set __bindtimets $minute }
				if {$minute != $__bindtimets} {
					# process our bind time's once every minute
					set __bindtimets $minute
					puts "PROCESS BIND TIME FOR $minute"
					# fire off our bind time's
				}					
				# process our timers
				if {[llength [array names __timers]]>0} {
					foreach _tid [array names __timers] {
						set delaytil [lindex [split $__timers($_tid)] 2]
						if {$delaytil <= [clock milliseconds]} {
							# fire off this event
							if {[catch {[lindex [split $__timers($_tid)] end]} err]} {
								puts "Timer error: $err"
							}
							# remove the timer entry
							unset __timers($_tid)
						}
					}
				}
				# process outgoing queue
				variable __putquick; variable __putserv; variable __puthelp
				# process each queue here
				continue
			}
		}
		# if we get here, the loop was broken due to a socket issue
		# attempt to create a new connection after a 3 second delay
		after 3000
		__doconnection
	}
	
	puts "__core__ loaded"
	
}

source [pwd]/__database__.tcl
source [pwd]/__channel__.tcl
source [pwd]/__users__.tcl
source [pwd]/__binds__.tcl
source [pwd]/__eggdrop__.tcl

namespace import __channel__::channel __channel__::chanlist __channel__::isop __channel__::isvoice __channel__::channels __channel__::validchan __channel__::onchan
namespace import __core__::__writetosock __core__::putquick __core__::putserv __core__::puthelp __core__::die __core__::rehash
namespace import __users__::isauthed

if {[file exists [pwd]/__config__.tcl]} {
	source [pwd]/__config__.tcl
}

puts "__core__::__doconnection"
__core__::__doconnection
