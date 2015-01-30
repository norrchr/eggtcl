namespace eval __overwrite__ {}

if {[info procs __overwrite__::set]=={}} then {rename set __overwrite__::set}
proc set {args} {
	switch [llength $args] {
		0 {return -code error {wrong # args: should be set varname ?newvalue? ?varname ?newvalue?? ...}}
		1 {return [uplevel [list __overwrite__::set [lindex $args 0]]]}
		2 {return [uplevel [list __overwrite__::set [lindex $args 0] [lindex $args 1]]]}
		default {
			uplevel [list __overwrite__::set [lindex $args 0] [lindex $args 1]]
			return [uplevel [list set [lrange $args 2 end]]]
		}
	}
}

puts "__overwrite__ loaded"
