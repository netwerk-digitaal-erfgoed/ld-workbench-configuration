# Preparing the Amateurfilm dataset for Europeana 

## Setting up your Environment

### 1 - install LD-Workbench (Docker)

```
gh repo clone netwerk-digitaal-erfgoed/ld-workbench
cd ld-workbench
mkdir pipelines
mkdir pipelines/configurations
mkdir pipelines/data
docker run -it -v $(pwd)/pipelines:/pipelines ghcr.io/netwerk-digitaal-erfgoed/ld-workbench:latest
```
On first install the Docker image will be fetched and do a first run of the Example pipeline.

### 2 - install Qlever (needed for larger datasets where SPARQL-endpoint is not fully cooperating)
```
gh repo clone ad-freiburg/qlever
cd qlever
docker build -t qlever .
docker run qlever
```
The last command shows the qlever help, showing that install via Docker is successfull.

### 3 - install LOD-Aggregator (needed voor testing results in Mets Sandbox)

```
git clone https://github.com/netwerk-digitaal-erfgoed/lod-aggregator.git
```
### 4 - install Apache Jena (needed for conversion via riot)
```
gh repo clone stain/jena-docker
cd jena-docker
docker build -t jena jena
# test install via
docker run stain/jena riot --help
```

## Data input preperation
The LD-workbench tool can work on datadumps, but for bigger files, a SPARQL endpoint is advisable.

### Qlever index + SPARL endpoint

- Make a data directory (eg. within the ld-workbench directory)
- Change to this directory
- Put the datadump file (eg. lod_exporter_amateurfilm_sdo_20241014_dedup.nt) here (TBD: get datadump URL via Dataset Register)
- Make a file called Qleverfile with the following contents:
```
# Default Qleverfile, use with https://github.com/ad-freiburg/qlever-control
#
# If you have never seen a Qleverfile before, we recommend that you first look
# at the example Qleverfiles on http://qlever.cs.uni-freiburg.de/qlever-control/
# src/qlever/Qleverfiles . Or execute `qlever setup-config <dataset>` on the
# command line to obtain the example Qleverfiles for <dataset>.

# As a minimum, each dataset needs a name. If you want `qlever get-data` to do
# something meaningful, you need to define GET_DATA_CMD. Otherwise, you need to
# generate (or download or copy from somewhere) the input files yourself. Each
# dataset should have a short DESCRIPTION, ideally with a date.
[data]
NAME         = amateurfilm
GET_DATA_CMD =
DESCRIPTION  = B&G Amateurfilm

# The format for INPUT_FILES should be such that `ls ${INPUT_FILES}` lists all
# input files. CAT_INPUT_FILES should write a concatenation of all input files
# to stdout. For example, if your input files are gzipped, you can write `zcat
# ${INPUT_FILES}`. Regarding SETTINGS_JSON, look at the other Qleverfiles for
# examples. Several batches of size `num-triples-per-batch` are kept in RAM at
# the same time; increasing this, increases the memory usage but speeds up the
# loading process.
[index]
INPUT_FILES = *.nt
CAT_INPUT_FILES = cat ${INPUT_FILES}
SETTINGS_JSON   = { "num-triples-per-batch": 1000000 }

# The server listens on PORT. If you want to send privileged commands to the
# server, you need to specify an ACCESS_TOKEN, which you then have to set via a
# URL parameter `access_token`. It should not be easily guessable, unless you
# don't mind others to get privileged access to your server.
[server]
PORT         = 8890
ACCESS_TOKEN = _iKdX02Xpo41q

# Use SYSTEM = docker to run QLever inside a docker container; the Docker image
# will be downloaded automatically. Use SYSTEM = native to use self-compiled
# binaries `IndexBuilderMain` and `ServerMain` (which should be in you PATH).
[runtime]
SYSTEM = native
IMAGE  = docker.io/adfreiburg/qlever:latest

# UI_PORT specifies the port of the QLever UI web app, when you run `qlever ui`.
# The UI_CONFIG must be one of the slugs from http://qlever.cs.uni-freiburg.de
# (see the dropdown menu on the top right, the slug is the last part of the URL).
# It determines the example queries and which SPARQL queries are launched to
# obtain suggestions as you type a query.
[ui]
UI_PORT   = 8176
UI_CONFIG = default
```
Now the Qlever index can be made as follows (from the data directory):
```
docker run -it --rm -u 1000:1000  -v $(pwd):/data -w /data qlever -c "qlever index"
```
When successfull, the data directory contains amateurfilm.* files.
To start the Qlever SPARQL-endpoint (from the data directory):
```
docker run -d -u 1000:1000 -p 8890:8890 -v $(pwd):/data -w /data qlever -c "qlever start && tail -f /dev/null"
```
You can test the SPARQL-endpoint via:
```
curl "http://0.0.0.0:8890/?query=SELECT%20%2A%20WHERE%20%7B%20%3Fs%20%3Fp%20%3Fo%20%7D%20LIMIT%205"
```
Note: the port is configured in the Qleverfile, change this if the port is already in use.

### SPARQL constructs

The pipeline configurations are kept in a seperate Github repo. The following commands will fetch them and put them in the ld-workbench directory from the previous step.
```
gh repo clone netwerk-digitaal-erfgoed/ld-workbench-configuration
cd ld-workbench
cp -r ../ld-workbench-configuration/amateurfilm pipelines/configurations
```
Be sure to check the `pipelines/configurations/amateurfilm/config.yml` file and make sure the endpoint IP-address/port corresponds with the Qlever install in the step above. Use the IP address of the machine (127.0.0.0 or 0.0.0.0 **won't work** because of Docker use).

The `pipelines/configurations/amateurfilm/config.yml` file also defines the stages - in this case 2: one for the amateurfilm data and one for the GTAA data - each with an iterator (to get URI's) and generator (with the actual SPARQL constructs stored in separate files in the `pipelines/configurations/amateurfilm/` directory:
- `iterator-stage-1.rq`
- `generator-stage-1.rq`
- `iterator-stage-2.rq`
- `generator-stage-2.rq`

These files - especially the generator files - will have to be refined to get the desired output. After each change in these files, rerun the ld-workbench as described in the next section.

## Converting the Linked Data to EDM flavour

Running the pipeline:
```
docker run -it -v $(pwd)/pipelines:/pipelines ghcr.io/netwerk-digitaal-erfgoed/ld-workbench:latest \
  --config pipelines/configurations/amateurfilm
```
After completion, you can find the result in the file `pipeline/data/amateurfilm.nt`.

## Converting the Linked Data to EDM XML for Metis Sandbox

From the lod-aggregator directory run the following to convert the N-triples to XML:
```
docker run -v ../ld-workbench/pipelines/data:/rdf stain/jena riot --output=rdfxml amateurfilm.nt > data/amateurfilm.xml
```
Finally, run the LOD Aggregator convert script via:
```
bin/convert.sh --data amateurfilm.xml --output amateurfilm.zip
```
The resulting `data/amateurfilm.zip` file can be uploaded to Metis.

## Adding a distribution to the dataset description

Europeana can ingest Linked Data which is registered in the NDE Dataset Register. Europeana queries for datasets which have a distribution which conform to the [EDM](http://www.europeana.eu/schemas/edm/) model. The dataset description needs to have RDF like (here shown in Turtle):
```
<amateurfilm-dataset-uri> dcat:distribution [
	a dcat:Distribution ;
	dct:conformsTo <http://www.europeana.eu/schemas/edm/> ;
	dct:created "2025-06-17T15:57:43Z"^^xsd:dateTime ;  # change to created data of .nt file
	dct:license <http://creativecommons.org/publicdomain/zero/1.0/> ;
	dct:description "Amateurfilm dataset converted to EDM model via the LD-Workbench"
	dcat:mediaType <https://www.iana.org/assignments/media-types/application/n-triples> 
	dcat:byteSize "15698980"^^xsd:nonNegativeInteger ; # optional, change to size of .nt file in bytes
	dcat:downloadURL <https://..../amateurfilm.nt> . # important, change to URL where the .nt file can be downloaded
] .
```
