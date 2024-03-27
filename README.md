# ld-workbench-configuration
This repository is used to document tests run with the [ld-workbench](https://github.com/netwerk-digitaal-erfgoed/ld-workbench) pipeline. 

See [ld-workbench](https://github.com/netwerk-digitaal-erfgoed/ld-workbench) for installation instructions. Assuming both the ld-workbench and the ld-workbench-configuration repo's are installed next to eachother, the tests can be run using the following syntax:

```sh
npm run ld-workbench -- --configDir ../ld-workbench-configuration/TESTDIR
``` 

Replace TESTDIR with the name of your test directory containing the config.yml and iterator/generator queries. 


