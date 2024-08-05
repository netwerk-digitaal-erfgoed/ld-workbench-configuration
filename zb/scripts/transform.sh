#!/bin/bash

# Controleer of er precies twee argumenten zijn doorgegeven
if [ "$#" -ne 2 ]; then
    echo "Gebruik: $0 input_file output_file"
    exit 1
fi

# Haal de input- en outputbestandsnamen uit de parameters
input_file="$1"
output_file="$2"

# Controleer of het inputbestand bestaat
if [ ! -f "$input_file" ]; then
    echo "Het inputbestand $input_file bestaat niet."
    exit 1
fi

# clear the output file
> "$output_file"

first=1
# Lees elk nummer uit het input bestand
while IFS=$'\r' read -r number
do
    if [ $first != 1 ]; 
    then 
      # Gebruik printf om het nummer naar 9 tekens op te vullen met voorloopnullen
      formatted_number=$(printf "%09s" "$number" | tr ' ' '0')

      # Schrijf het resultaat naar het output bestand
      echo "<https://data.dezb.nl/id/p${formatted_number}> <http://data.bibliotheken.nl/def#ppn> \"${formatted_number}\" ." >> $output_file
      #echo "<https://data.dezb.nl/id/p${formatted_number}> <http://schema.org/isPartOf>  <https://data.dezb.nl/id/zeelandcollectie> ." >> $output_file 
    fi
    first=0
done < "$input_file"

echo "Het formatteren is voltooid. Geformatteerde gegevens zijn opgeslagen in $output_file."