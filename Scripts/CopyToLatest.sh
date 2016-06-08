#!/bin/sh

# CopyToLatest.sh
#  Copy the product and associated DWARF file to a 'Latest' folder

LATEST_DIR="$BUILD_ROOT/Latest"

SOURCE_PRODUCT="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
LATEST_PRODUCT="$LATEST_DIR/$FULL_PRODUCT_NAME"

SOURCE_DWARF="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME"
LATEST_DWARF="$LATEST_DIR/$DWARF_DSYM_FILE_NAME"

if [ ! -e "$LATEST_DIR" ]; then
    echo "Creating '$LATEST_DIR'"
    mkdir "$LATEST_DIR"
fi

if [ -e "$LATEST_PRODUCT" ]; then
    echo "Removing existing product '$LATEST_PRODUCT'"
    rm -Rf "$LATEST_PRODUCT"
fi

if [ -e "$SOURCE_PRODUCT" ]; then
    echo "Copying product '$SOURCE_PRODUCT' -> '$LATEST_PRODUCT'"
    cp -R "$SOURCE_PRODUCT" "$LATEST_DIR"
fi

if [ -e "$LATEST_DWARF" ]; then
    echo "Removing existing DWARF '$LATEST_DWARF'"
    rm -Rf "$LATEST_DWARF"
fi

if [ -e "$SOURCE_DWARF" ]; then
    echo "Copying DWARF '$SOURCE_DWARF' -> '$LATEST_DWARF'"
    cp -R "$SOURCE_DWARF" "$LATEST_DWARF"
fi
