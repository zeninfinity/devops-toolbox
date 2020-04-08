# Bash

## For Loops
for file in ./check-*
do
  ls -l "$file" >> results.out
done
