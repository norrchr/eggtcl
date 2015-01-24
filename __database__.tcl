namespace eval __database__ {

	package require sqlite3
	
	namespace export __sqldb
	
	proc __ondbload {} {
		if {![__sqldb exists {SELECT channel FROM channels WHERE channel = '#r0t3n'}]} {
			__sqldb eval {INSERT INTO channels (channel) VALUES ('#r0t3n')}
			puts "Inserted #r0t3n into channels db"
		}
		if {![__sqldb exists {SELECT channel FROM channels WHERE channel = '#mybdz'}]} {
			__sqldb eval {INSERT INTO channels (channel) VALUES ('#mybdz')}
			puts "Inserted #mybdz into channels db"
		}
		puts "__ondbload complete"
	}
	
	if {[catch {sqlite3 __sqldb ./eggtcl.db -nomutex true} err]} {
		puts "SQlite3 Error: $err -- Exiting"; exit
	} else {
		puts "Database opened successfully"
		puts "Creating users table (if not exists)"
		__sqldb eval {CREATE TABLE IF NOT EXISTS users( \
		handle TEXT UNIQUE NOT NULL, \
		created INTEGER(4) NOT NULL DEFAULT (strftime('%s','now')), \
		hosts TEXT NOT NULL, \
		authname TEXT NOT NULL DEFAULT '', \
		flags TEXT NOT NULL DEFAULT '')}
		puts "I have [llength [__sqldb eval {SELECT handle FROM users}]] user(s) saved in my database"
		puts "Creating channels table (if not exists)"
		__sqldb eval {CREATE TABLE IF NOT EXISTS channels(channel TEXT UNIQUE NOT NULL, created INTEGER(4) NOT NULL DEFAULT (strftime('%s','now')))}
		puts "I have [llength [__sqldb eval {SELECT channel FROM channels}]] channel(s) saved in my database"
		# db loaded, lets call the __ondbload function to get the ball rolling
		__ondbload
	}
	
	puts "__database__ loaded"
	
}
