# This awk script will take the following lines from the borg check -v output:
#
# Analying archive foo (3/3)
# Analying archive bar (2/3)
# Analying archive foobar (1/3)
#
# and turn them into:
#
# Analyzed 3 archives: foobar, bar, foo

{
	if (/^Analyzing archive/) {
		# Get the name, which is everything after analyzing archives and before (X/Y)
		name=""
		for (c = 3; c < NF; c++) {
			name = name " " $c
		}

		# Parse the X/Y part
		split(substr($c, 2, length($c) - 3), count, "\/")

		# Store the archive name
		archives[count[1]] = substr(name, 2)

		# If this is the last archive (which is number 1, for some reason), print summary
		if (count[1] == 1) {
			printf("Analyzed %d archives: ", count[2])
			for (i = 1; i < count[2]; i++) {
				printf("%s, ", archives[i])
			}
			printf("%s\n", archives[count[2]])
		}

		next
	}
	print $0
}
