#!/bin/sh

#  swiftlint.sh
#  Mustang
#
#  Created by Ken Heglund on 4/15/20.
#  Copyright © 2020 OrderedBytes. All rights reserved.

swiftlintPath=$(which swiftlint)

# Run from the repository root
repositoryRoot=$(git rev-parse --show-toplevel)
cd ${repositoryRoot}
echo "swiftlint.sh: Running from ${repositoryRoot}"

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

# Exit if there is nothing to lint
if [ $fileCount -eq 0 ]; then
	echo "swiftlint.sh: Nothing to lint"
	exit 0
fi

export SCRIPT_INPUT_FILE_COUNT=$fileCount

${swiftlintPath} --use-script-input-files
