#!/bin/bash
# draw rose curve with twist range [0, 24)

OUTPUT_DIR=test/roses
START=$(date +%s)

if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p $OUTPUT_DIR
fi

for i in {0..23}
do
    printf "Drawing rose curve %2d..." $i
    sed -i "24s/[0-9][0-9]*/$i/1" test/rose.logo
    ./bin/logo test/rose.logo -o $OUTPUT_DIR/twisted-$i.png
    printf "OK\n"
done

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "All jobs done in $DIFF seconds"
