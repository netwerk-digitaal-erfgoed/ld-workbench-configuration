# Preparing the Amateurfilm dataset for Europeana 

## Setting up your Environment

### 1 - install LD-Workbench (Docker)
See the [LD-Workbench Github repo](https://github.com/netwerk-digitaal-erfgoed/ld-workbench) for instructions how to install the tool from source. The next steps describe running LD-Workbench via Docker:
```
git clone https://github.com/netwerk-digitaal-erfgoed/ld-workbench.git
cd ld-workbench
mkdir pipelines
mkdir pipelines/configurations
mkdir pipelines/data
docker run -it -v $(pwd)/pipelines:/pipelines ghcr.io/netwerk-digitaal-erfgoed/ld-workbench:latest
```
On first install the Docker image will be fetched and do a first run of the Example pipeline.

**Note**: be sure to regularly check out the [latest version](https://github.com/netwerk-digitaal-erfgoed/ld-workbench/pkgs/container/ld-workbench) by exucuting `docker pull ghcr.io/netwerk-digitaal-erfgoed/ld-workbench:latest`. Just running won't check if it is actually the lastest version, it does show the current version.

### 2 - install Qlever 
The LD-Workbench can run on local N-triple files, for larger datasets a SPARQL-endpoint is preferred. When the SPARQL-endpoint of the dataset is not fully cooperating, just install a local [Qlever](https://github.com/ad-freiburg/qlever/ based SPARQL-endpoint:
```
git clone https://github.com/ad-freiburg/qlever.git
cd qlever
docker build -t qlever .
docker run qlever
```
The last command shows the qlever help, showing that install via Docker is successfull.

### 3 - install LOD-Aggregator 
The Metis Sandbox can't handle N-triples (yet), so a special RDF/XML ZIP file has to be created. Tooling from the [LOD-Aggregator](https://github.com/netwerk-digitaal-erfgoed/lod-aggregator) is used for the conversion:
```
git clone https://github.com/netwerk-digitaal-erfgoed/lod-aggregator.git
```
### 4 - install Apache Jena
In order to convert the N-triples to RDF/XML for the EDM XML ZIP file for Metis the Apache tool `riot` is needed. You can install is directly on your system, or use [Jena-Docker](https://github.com/stain/jena-docker):
```
git clone https://github.com/stain/jena-docker.git
cd jena-docker
docker build -t jena jena
# test install via
docker run stain/jena riot --help
```

## Data input preperation

### Qlever index + SPARL endpoint

- Make a data directory (eg. within the ld-workbench directory)
- Change to this directory
- Put the datadump file (eg. lod_exporter_amateurfilm_sdo_20241014_dedup.nt) here
  > TBD: get datadump URL via Dataset Register
- Make a file called Qleverfile with the following contents:
```
[data]
NAME         = amateurfilm
DESCRIPTION  = B&G Amateurfilm
[index]
INPUT_FILES = *.nt
CAT_INPUT_FILES = cat ${INPUT_FILES}
SETTINGS_JSON   = { "num-triples-per-batch": 1000000 }
[server]
PORT         = 8890
ACCESS_TOKEN = _iKdX02Xpo41q
[runtime]
SYSTEM = native
IMAGE  = docker.io/adfreiburg/qlever:latest
```
Now the Qlever index can be made as follows (from the data directory):
```
docker run -it --rm -u 1000:1000  -v $(pwd):/data -w /data qlever -c "qlever index"
```
When successfull, the data directory contains amateurfilm.* index files.

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

The pipeline configurations are kept in a seperate [LD-Workbench configuration Github repo](https://github.com/netwerk-digitaal-erfgoed/ld-workbench-configuration). The following commands will fetch them and put the amateurfilm files in the ld-workbench directory from the previous step.
```
git clone https://github.com/netwerk-digitaal-erfgoed/ld-workbench-configuration.git
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
