for file in *svg
do
/c/Program\ Files/Inkscape/bin/inkscape --export-text-to-path --export-filename ${file} ${file}
done
