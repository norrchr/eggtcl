namespace eval __eggdrop__ {

	namespace export *

	proc rand {{max {2}}} {
		if {![string is integer $max]} { set max 2 }
		if {$max eq 1} { set max 2 }
		return [expr {int(rand()*$max)}]
	}
	
	puts "__eggdrop__ loaded"
	
}

namespace import __eggdrop__::*
