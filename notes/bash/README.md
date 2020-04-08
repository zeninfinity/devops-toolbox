# Bash

## For Loops
```
for file in sensu_config_translated/checks/*
do
  ls -l "$file" >> results.out
done
```

### One Line:
`for file in sensu_config_translated/checks/*; do ls -l "$file"; done;`
