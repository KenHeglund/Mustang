#!/bin/sh

#  swiftlint.sh
#  Mustang
#
#  Created by Ken Heglund on 4/15/20.
#  Copyright © 2020 OrderedBytes. All rights reserved.

swiftlintPath=$(which swiftlint)

# Verify the swiftlint executable is available
if [ "${swiftlintPath}" == "" ]; then
	echo "warning: swiftlint not installed. (https://github.com/realm/SwiftLint)"
	exit 0
elif [ ! -x "${swiftlintPath}" ]; then
	echo "warning: ${swiftlintPath} is not executable"
	exit 0
fi

fileCount=0

# Add files that are modified or untracked, not staged, and not ignored.
for filePath in $(git ls-files -m -o --exclude-from=.gitignore | grep ".swift$"); do
	export SCRIPT_INPUT_FILE_$fileCount=$filePath
	fileCount=$((fileCount + 1))
done

# Add staged files.
for filePath in $(git diff --name-only --cached | grep ".swift$"); do
	export SCRIPT_INPUT_FILE_$fileCount=$filePath
	fileCount=$((fileCount + 1))
done

export SCRIPT_INPUT_FILE_COUNT=$fileCount

${swiftlintPath} --use-script-input-files
