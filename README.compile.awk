#!/usr/bin/awk -f

BEGIN {
	INACTIVE = 0
	WAITINGFORBLOCK = 1
	INBLOCK = 2
	state = INACTIVE
}

{
	if (/^:expandcommand:/) {
		print $0
		print "----";
		system(substr($0, 17));
		print "----";

		state = WAITINGFORBLOCK
		next
	}

	if (/^----/) {
		if (state == WAITINGFORBLOCK) { state = INBLOCK; next }
		if (state == INBLOCK) { state = INACTIVE; next }
	}

	if (state == WAITINGFORBLOCK) { state = INACTIVE }
	if (state == INBLOCK) { next }

	print $0
}
