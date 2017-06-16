# This awk script will take the following lines from the borg check -v output:
#
# Analying archive foo (3/3)
# Analying archive bar (2/3)
# Analying archive foobar (1/3)
#
# and turn them into:
#
# Analyzed 3 archives

{
	if (/^Analyzing archive/) {
		# Parse the X/Y part
		split(substr($NF, 2, length($NF) - 3), count, "\/")

		# If this is the last archive (which is number 1, for some reason), print summary
		if (count[1] == 1) {
			printf("Analyzed %d archives\n", count[2])
		}

		next
	}
	print $0
}
