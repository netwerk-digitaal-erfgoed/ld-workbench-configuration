# ld-workbench-configuration/ran/process.sh

cd ..
docker run -it -v .:/pipelines ghcr.io/netwerk-digitaal-erfgoed/ld-workbench:latest --config pipelines/ran

cp ran/data/ran.nt ~/github/lod-aggregator/data/

cd ~/github/lod-aggregator
docker run -v ~/github/ld-workbench-configuration/ran/data:/rdf stain/jena riot --output=rdfxml ran.nt > data/ran.xml
bin/convert.sh --data ran.xml --output ran.zip

rm data/ran.nt
mv data/ran.xml ~/github/ld-workbench-configuration/ran/data/
mv data/ran.zip ~/github/ld-workbench-configuration/ran/data/

cd ~/github/ld-workbench-configuration/ran/data/
ls -la
