#!/bin/bash
# draw rose curve with twist range [0, 24)

START=$(date +%s)

if [ ! -d "test/roses" ]; then
    mkdir -p test/roses
fi

for i in {0..23}
do
    printf "Drawing rose curve %2d..." $i
    sed -i "24s/[0-9][0-9]*/$i/1" test/rose.logo
    node logo test/rose.logo
    # currently we cannot change output path
    mv output.png test/roses/twisted-$i.png
    printf "OK\n"
done

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "All jobs done in $DIFF seconds"
